# carejobs-haxe

Haxe client for the [CareJobs.Now](https://carejobs.now) healthcare jobs API. Search open US healthcare jobs, see the hourly pay employers post, and look up employers and states.

- Free, no API key.
- Standard library only (`haxe.Http`, `haxe.Json`). Haxe 4.0 or newer.
- Callbacks, so it works the same on JavaScript (asynchronous) and on the sys targets (the callbacks run before the method returns). Checked on the eval interpreter, JavaScript and Python.
- Typed results (`typedef`s), one `CareJobsError` class.
- The same API is a remote MCP server at <https://carejobs.now/api/mcp>, so any MCP client can use it too.

## Install

```sh
haxelib install carejobs
```

Then add `-lib carejobs` to your `.hxml` file.

## Quick start

```haxe
import carejobs.CareJobs;

class Main {
	static function main() {
		var client = new CareJobs();

		client.searchJobs({query: "ICU", kind: Nurses, state: "TX", limit: 5}, function(res) {
			trace(res.total + " jobs match");
			for (job in res.jobs)
				trace(job.title + " | " + job.employer + " | " + job.location + " | " + job.url);
		}, function(err) trace(err.toString()));

		client.payByKind(Nurses, function(res) {
			if (res.pay != null)
				trace("Median posted pay for nurses: $" + res.pay.median + "/hr");
		}, function(err) trace(err.toString()));
	}
}
```

Build and run it with `haxe -lib carejobs -main Main --interp`.

## Methods

| Method | What it answers | Result |
| --- | --- | --- |
| `new CareJobs(?baseUrl)` | A client for the live API | `CareJobs` |
| `searchJobs(?params, onResult, onError)` | Open jobs by query, kind, state and limit | `SearchResult` |
| `payByKind(kind, onResult, onError)` | Posted hourly pay for one kind of job, and the employers posting the most | `PayResult` |
| `employers(?query, ?limit, onResult, onError)` | The employers, AI-training programs and job boards the site reads | `EmployerList` |
| `states(onResult, onError)` | Open jobs in every US state | `Array<StateSummary>` |
| `CareJobs.kinds()` | The 17 kinds of job (no request) | `Array<Kind>` |
| `callTool(name, arguments, onResult, onError)` | Any tool of the server, as raw data | `Dynamic` |

Every `SearchParams` field is optional. `Kind` is an `enum abstract` over `String` with the 17 kinds (`Nurses`, `NursePractitioners`, and so on); its value is the slug the API uses (`"nurse-practitioners"`), and `Kind.fromSlug("nurses")` reads one back.

Every `Job` carries `url`, its page on CareJobs.Now, where a person applies. The server has no separate job lookup by id: a job is described by the search answer.

Where the API sends `null`, the field is `null` (`Job.pay`, `SearchResult.pay`, `PayResult.pay`, and so on): `PayResult.pay` is `null` when too few jobs post an hourly rate to measure.

### Errors and timeouts

Every failure (network, HTTP status, JSON-RPC error, a tool the server refuses to run) goes to `onError` as a `CareJobsError` with `message`, `status` (the HTTP status or 0) and `tool`.

On the sys targets `client.timeout` (seconds, default 60) limits how long a connection may wait. The server answers a query it has not seen before in up to about 25 seconds (its database may be waking up), then repeats of it in a fraction of one, so a first call can be slow.

## Tests

```sh
haxe test.hxml    # offline, on answers recorded from the live API
haxe live.hxml    # the same calls against the real API
```

## Data

Data from [CareJobs.Now](https://carejobs.now), CC BY 4.0. Docs and downloads: <https://carejobs.now/data>.

## License

Code: MIT, copyright O-mega Enterprise, Inc. See [LICENSE](LICENSE).
