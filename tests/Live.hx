import carejobs.CareJobs;
import carejobs.Kind;

/** Asks the live API. Run with: haxe live.hxml **/
class Live {
	static function main() {
		var client = new CareJobs();
		var fail = function(e:carejobs.CareJobsError) {
			Sys.println(e.toString());
			Sys.exit(1);
		};
		client.searchJobs({query: "ICU", kind: Nurses, state: "TX", limit: 3}, function(res) {
			Sys.println(res.total + " jobs match");
			for (job in res.jobs)
				Sys.println(job.title + " | " + job.employer + " | " + job.location + " | " + job.url);
		}, fail);
		client.payByKind(Nurses, function(res) Sys.println("Median posted pay for nurses: $" + res.pay.median + "/hr"), fail);
		client.employers("Kaiser", 3, function(res) Sys.println(res.entries.length + " employers"), fail);
		client.states(function(res) Sys.println(res.length + " states"), fail);
	}
}
