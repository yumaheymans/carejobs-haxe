package carejobs;

/** Why a call failed. **/
class CareJobsError {
	/** What went wrong, in the server's words where it gave any. **/
	public var message(default, null):String;

	/** The HTTP status, or 0 when there was none. **/
	public var status(default, null):Int;

	/** The tool that was called, or `null`. **/
	public var tool(default, null):Null<String>;

	public function new(message:String, status:Int = 0, ?tool:String) {
		this.message = message;
		this.status = status;
		this.tool = tool;
	}

	public function toString():String {
		return "CareJobsError: " + message + (status > 0 ? " (HTTP " + status + ")" : "");
	}
}
