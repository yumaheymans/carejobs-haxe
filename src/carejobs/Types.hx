package carejobs;

// The types of the answers. Where the API sends `null`, a field is `null`.
// The field names are the keys the API sends.

/** Filters of `CareJobs.searchJobs`. Every field is optional. **/
typedef SearchParams = {
	/** Words every job must carry in its title, place, department or schedule ("ICU", "night"). **/
	@:optional var query:String;

	/** One kind of job. **/
	@:optional var kind:Kind;

	/** A US state: its two-letter code ("TX") or its name ("Texas"). **/
	@:optional var state:String;

	/** How many jobs to return, 1 to 25 (the server default is 10). **/
	@:optional var limit:Int;
}

/** One open job. `url` is its page on CareJobs.Now, where a person applies. **/
typedef Job = {
	var title:String;
	var employer:String;

	/** The job board the job was read through, when it is another employer's job. **/
	var via:Null<String>;

	/** The label of the kind of job, for example "Nurses". **/
	var kind:String;

	/** The posted pay as text, for example "$42.43-$86.19/hr". `null` when the posting states none. **/
	var pay:Null<String>;

	var schedule:Array<String>;
	var facility:Null<String>;
	var location:Null<String>;

	/** ISO date (YYYY-MM-DD) the job was first listed. **/
	var listed:String;

	var url:String;
	var employer_page:Null<String>;
}

/** Posted hourly pay in US dollars across the jobs a search matches. **/
typedef SearchPay = {
	var typical_low:Float;
	var typical_high:Float;
	var median:Float;
	var rate_samples:Int;

	/** How many matching jobs post an hourly rate. **/
	var priced:Int;

	/** How many jobs match. **/
	var open:Int;
}

/** The answer of `CareJobs.searchJobs`. **/
typedef SearchResult = {
	/** Every open job that matches, not only the ones in `jobs`. **/
	var total:Int;

	/** `null` when no matching job posts a rate. **/
	var pay:Null<SearchPay>;

	var jobs:Array<Job>;

	/** The same search on the CareJobs.Now site. **/
	var more:String;
}

/** Posted hourly pay in US dollars, before shift differentials and bonuses. **/
typedef PayStats = {
	var median:Float;
	var typical_low:Float;
	var typical_high:Float;
	var rate_samples:Int;
	var employers:Int;
	var open_jobs:Int;
	var no_rate:Int;

	/** True only where at least three employers post a rate. **/
	var market_rate:Bool;
}

/** The pay one employer posts for a kind of job. **/
typedef EmployerPay = {
	> PayStats,
	var slug:String;
	var name:String;
}

/** The answer of `CareJobs.payByKind`. **/
typedef PayResult = {
	/** ISO date the figures were measured. **/
	var as_of:String;

	var kind:String;
	var open_jobs:Int;

	/** `null` when too few jobs post an hourly rate to measure. **/
	var pay:Null<PayStats>;

	/** The employers posting the most for this kind of job. **/
	var best_paying:Array<EmployerPay>;
}

/** An employer, AI-training program or job board. **/
typedef Employer = {
	var slug:String;
	var name:String;

	/** "employer", "ai-program" or "job-board". **/
	var type:String;

	var model:Null<String>;
	var care:Null<String>;
	var hq:Null<String>;
	var states:Array<String>;
	var open_jobs:Int;
	var posted_median_hourly:Null<Float>;
	var url:String;
}

/** The answer of `CareJobs.employers`. **/
typedef EmployerList = {
	/** Every match, not only the ones in `entries`. **/
	var total:Int;

	var entries:Array<Employer>;
}

/** The open jobs of one kind of job inside a state. **/
typedef KindCount = {
	var kind:String;
	var label:String;
	var open_jobs:Int;
	var url:Null<String>;
}

/** One US state: open jobs, employers and the kinds of job it has the most of. **/
typedef StateSummary = {
	var code:String;
	var name:String;
	var open_jobs:Int;
	var employers:Int;
	var top_kinds:Array<KindCount>;
	var url:String;
}

/** The answer of `CareJobs.states`. **/
typedef StateList = {
	var states:Array<StateSummary>;
}
