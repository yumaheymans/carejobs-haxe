package carejobs;

import carejobs.Types;
import haxe.Http;
import haxe.Json;

/**
	Client for the CareJobs.Now healthcare jobs API (https://carejobs.now).

	Search open US healthcare jobs, see the hourly pay employers post, and look
	up employers and states. The API is free and needs no key. It is a remote
	MCP server (https://carejobs.now/api/mcp); this class posts the JSON-RPC
	calls for you and hands typed results to callbacks, so it works the same on
	JavaScript (asynchronous) and on the sys targets (the callbacks run before
	the method returns). Standard library only.

	```haxe
	var client = new carejobs.CareJobs();
	client.searchJobs({query: "ICU", kind: Nurses, state: "TX", limit: 5}, function(res) {
		trace(res.total + " jobs match");
		for (job in res.jobs)
			trace(job.title + " | " + job.employer + " | " + job.url);
	}, function(err) trace(err.toString()));
	```

	Data from CareJobs.Now (https://carejobs.now), CC BY 4.0.
**/
class CareJobs {
	/** Version of this library, sent in the default User-Agent. **/
	public static inline var VERSION = "1.0.0";

	/** The CareJobs.Now site. The MCP endpoint is this plus `/api/mcp`. **/
	public static inline var DEFAULT_BASE_URL = "https://carejobs.now";

	/** Another host than `DEFAULT_BASE_URL` (a mirror or a test server), without a trailing slash. **/
	public var baseUrl:String;

	/**
		Seconds a connection may wait on the sys targets (JavaScript uses the
		browser's own limit). The server answers a query it has not seen before in
		up to about 25 seconds, then repeats of it in a fraction of one.
	**/
	public var timeout:Float = 60;

	/** The User-Agent header, ignored by browsers. **/
	public var userAgent:String = "carejobs-haxe/" + VERSION;

	public function new(?baseUrl:String) {
		var url = baseUrl == null ? DEFAULT_BASE_URL : baseUrl;
		while (StringTools.endsWith(url, "/"))
			url = url.substr(0, url.length - 1);
		this.baseUrl = url;
	}

	/** All 17 kinds of job. **/
	public static function kinds():Array<Kind> {
		return Kind.all();
	}

	/** Search the open healthcare jobs. Every filter is optional. **/
	public function searchJobs(?params:SearchParams, onResult:SearchResult->Void, onError:CareJobsError->Void):Void {
		var args:Dynamic = {};
		if (params != null) {
			if (params.query != null)
				Reflect.setField(args, "query", params.query);
			if (params.kind != null)
				Reflect.setField(args, "kind", (params.kind : String));
			if (params.state != null)
				Reflect.setField(args, "state", params.state);
			if (params.limit != null)
				Reflect.setField(args, "limit", params.limit);
		}
		callTool("search_healthcare_jobs", args, function(data) onResult(data), onError);
	}

	/** What open jobs of one kind post as hourly pay, and the employers posting the most for it. **/
	public function payByKind(kind:Kind, onResult:PayResult->Void, onError:CareJobsError->Void):Void {
		callTool("get_healthcare_pay", {kind: (kind : String)}, function(data) onResult(data), onError);
	}

	/**
		The employers, AI-training programs and job boards CareJobs.Now reads, most
		open jobs first. `query` is part of a name ("Kaiser"), `limit` is 1 to 100
		(server default 20).
	**/
	public function employers(?query:String, ?limit:Int, onResult:EmployerList->Void, onError:CareJobsError->Void):Void {
		var args:Dynamic = {};
		if (query != null)
			Reflect.setField(args, "query", query);
		if (limit != null)
			Reflect.setField(args, "limit", limit);
		callTool("list_healthcare_employers", args, function(data) onResult(data), onError);
	}

	/** Open jobs for every US state, most first. **/
	public function states(onResult:Array<StateSummary>->Void, onError:CareJobsError->Void):Void {
		callTool("get_healthcare_jobs_by_state", {}, function(data:StateList) onResult(data.states), onError);
	}

	/**
		Run any tool and hand its `structuredContent` to `onResult`. The typed
		methods are built on it; use it for a tool or a field this library does not
		know yet.
	**/
	public function callTool(tool:String, arguments:Dynamic, onResult:Dynamic->Void, onError:CareJobsError->Void):Void {
		var http = new Http(baseUrl + "/api/mcp");
		http.setHeader("Content-Type", "application/json");
		http.setHeader("Accept", "application/json");
		#if !js
		http.setHeader("User-Agent", userAgent);
		#end
		#if sys
		http.cnxTimeout = timeout;
		#end
		http.setPostData(requestBody(tool, arguments));

		var status = 0;
		var finished = false;
		http.onStatus = function(code) status = code;
		http.onData = function(body) {
			if (finished)
				return;
			finished = true;
			handleAnswer(tool, status, body, onResult, onError);
		};
		http.onError = function(message) {
			if (finished)
				return;
			finished = true;
			var detail = serverMessage(http.responseData);
			onError(new CareJobsError(detail != null ? detail : message, status, tool));
		};
		http.request(true);
	}

	/** The JSON-RPC `tools/call` request for `tool`. **/
	public static function requestBody(tool:String, arguments:Dynamic):String {
		return Json.stringify({
			jsonrpc: "2.0",
			id: 1,
			method: "tools/call",
			params: {name: tool, arguments: arguments}
		});
	}

	/** Read the answer of a `tools/call` request. Public so it can be tested. **/
	public static function handleAnswer(tool:String, status:Int, body:String, onResult:Dynamic->Void, onError:CareJobsError->Void):Void {
		var message:Dynamic;
		try {
			message = Json.parse(body);
		} catch (e:Dynamic) {
			onError(new CareJobsError("the server did not answer with a JSON-RPC message", status, tool));
			return;
		}
		if (message == null || Type.typeof(message) != TObject) {
			onError(new CareJobsError("the server did not answer with a JSON-RPC message", status, tool));
			return;
		}
		if (message.error != null) {
			var text:String = message.error.message;
			onError(new CareJobsError(text != null ? text : "JSON-RPC error", status, tool));
			return;
		}
		var result:Dynamic = message.result;
		if (result == null) {
			onError(new CareJobsError("the answer held no result", status, tool));
			return;
		}
		if (result.isError == true) {
			var text = "";
			var content:Array<Dynamic> = result.content;
			if (content != null)
				for (part in content)
					if (part.type == "text" && part.text != null)
						text += part.text;
			onError(new CareJobsError(text != "" ? text : tool + " failed", status, tool));
			return;
		}
		if (result.structuredContent == null) {
			onError(new CareJobsError("the tool answered without structured content", status, tool));
			return;
		}
		onResult(result.structuredContent);
	}

	/** The message of a JSON-RPC error body, or `null`. **/
	static function serverMessage(body:Null<String>):Null<String> {
		if (body == null || body == "")
			return null;
		try {
			var message:Dynamic = Json.parse(body);
			if (message != null && message.error != null && message.error.message != null)
				return message.error.message;
		} catch (e:Dynamic) {}
		return null;
	}
}
