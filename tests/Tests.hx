import carejobs.CareJobs;
import carejobs.CareJobsError;
import carejobs.Kind;
import carejobs.Types;
import haxe.Json;
import sys.io.File;

class Tests {
	static var failures = 0;
	static var count = 0;

	static function check(ok:Bool, what:String) {
		count++;
		if (!ok) {
			failures++;
			Sys.println("FAIL: " + what);
		}
	}

	static function fixture(name:String):String {
		return File.getContent("tests/fixtures/" + name + ".json");
	}

	static function answer(name:String):String {
		return '{"jsonrpc":"2.0","id":1,"result":{"content":[],"structuredContent":' + fixture(name) + '}}';
	}

	static function main() {
		check(Kind.all().length == 17, "17 kinds");
		check((Kind.NursePractitioners : String) == "nurse-practitioners", "slug of nurse practitioners");
		check(Kind.fromSlug("emts-paramedics") == Kind.EmtsParamedics, "fromSlug");
		check(Kind.fromSlug("nope") == null, "unknown slug");
		check(CareJobs.kinds().length == 17, "CareJobs.kinds");

		var body = Json.parse(CareJobs.requestBody("search_healthcare_jobs", {state: "TX"}));
		check(body.method == "tools/call", "request method");
		check(body.params.name == "search_healthcare_jobs", "request tool");
		check(body.params.arguments.state == "TX", "request arguments");

		CareJobs.handleAnswer("search_healthcare_jobs", 200, answer("search"), function(data) {
			var r:SearchResult = data;
			check(r.total >= 2, "search total");
			check(r.jobs.length == 2, "two jobs");
			check(r.jobs[0].kind == "Nurses", "job kind");
			check(r.jobs[0].via == null, "via is null");
			check(r.jobs[0].url.indexOf("https://carejobs.now/jobs/") == 0, "job url");
			check(r.pay != null && r.pay.median == 45, "search pay median");
		}, function(e) check(false, "search failed: " + e));

		CareJobs.handleAnswer("get_healthcare_pay", 200, answer("pay"), function(data) {
			var r:PayResult = data;
			check(r.kind == "nurses", "pay kind");
			check(r.pay != null && r.pay.market_rate == true, "market rate");
			check(r.best_paying.length == 2, "best paying");
			check(r.best_paying[0].slug != "", "best paying slug");
		}, function(e) check(false, "pay failed: " + e));

		CareJobs.handleAnswer("list_healthcare_employers", 200, answer("employers"), function(data) {
			var r:EmployerList = data;
			check(r.entries.length == 2, "two employers");
			check(r.entries[0].slug == "cross-country-healthcare", "employer slug");
			check(r.entries[0].posted_median_hourly == null, "no median");
		}, function(e) check(false, "employers failed: " + e));

		CareJobs.handleAnswer("get_healthcare_jobs_by_state", 200, answer("states"), function(data) {
			var r:StateList = data;
			check(r.states[0].code == "TX", "first state");
			check(r.states[0].top_kinds.length == 3, "top kinds");
		}, function(e) check(false, "states failed: " + e));

		var refused:CareJobsError = null;
		CareJobs.handleAnswer("t", 200, '{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"kind needs a state"}],"isError":true}}',
			function(_) check(false, "a refusal must not succeed"), function(e) refused = e);
		check(refused != null && refused.message == "kind needs a state" && refused.tool == "t", "tool refusal");

		var rpc:CareJobsError = null;
		CareJobs.handleAnswer("t", 200, '{"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Unknown tool"}}', function(_) check(false, "rpc error must not succeed"),
			function(e) rpc = e);
		check(rpc != null && rpc.message == "Unknown tool", "rpc error");

		var bad:CareJobsError = null;
		CareJobs.handleAnswer("t", 200, "<html>", function(_) check(false, "bad body must not succeed"), function(e) bad = e);
		check(bad != null, "bad body");

		check(new CareJobs("https://example.org/").baseUrl == "https://example.org", "trailing slash ignored");

		Sys.println(count + " checks, " + failures + " failures");
		Sys.exit(failures == 0 ? 0 : 1);
	}
}
