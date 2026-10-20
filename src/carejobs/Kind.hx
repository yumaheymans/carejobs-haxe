package carejobs;

/**
	A kind of healthcare job, the `kind` filter of the API. The value of each
	constant is the slug the API uses.
**/
enum abstract Kind(String) to String {
	var Nurses = "nurses";
	var NursePractitioners = "nurse-practitioners";
	var Physicians = "physicians";
	var NursingAssistants = "nursing-assistants";
	var Caregivers = "caregivers";
	var TherapyRehab = "therapy-rehab";
	var MentalHealth = "mental-health";
	var Pharmacy = "pharmacy";
	var Imaging = "imaging";
	var Lab = "lab";
	var SurgicalTechs = "surgical-techs";
	var EmtsParamedics = "emts-paramedics";
	var MedicalAssistants = "medical-assistants";
	var Dental = "dental";
	var Admin = "admin";
	var AlliedHealth = "allied-health";
	var AiTraining = "ai-training";

	/** All 17 kinds of job, in the order the API documents them. **/
	public static function all():Array<Kind> {
		return [
			Nurses, NursePractitioners, Physicians, NursingAssistants, Caregivers, TherapyRehab, MentalHealth, Pharmacy, Imaging, Lab,
			SurgicalTechs, EmtsParamedics, MedicalAssistants, Dental, Admin, AlliedHealth, AiTraining
		];
	}

	/** The kind with this API slug, or `null`. **/
	public static function fromSlug(slug:String):Null<Kind> {
		for (kind in all())
			if ((kind : String) == slug)
				return kind;
		return null;
	}
}
