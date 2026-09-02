"""Human-readable labels for eligibility rules.

These strings are shown directly to citizens in match explanations
("You may be eligible because: you are a farmer; you are aged 18 or above").
They are **content, not code** -- review them as copy.

Two rules govern the wording:

1. **Second person, affirmative.** "You are a farmer", not "Farmer: true".
   The user is reading about themselves.

2. **Never assert ineligibility.** Eligibility ranks rather than filters
   (REBUILD_PLAN Assumption A-3), so these labels only ever explain why
   something *matched*. There is no "You are not eligible because..." form,
   deliberately.

Hindi is included at launch; the hero copy in v1 was already bilingual and the
audience requires it. Translations use the plain register a government form
would use, not literary Hindi.
"""

from __future__ import annotations

from schememedia.db.models.enums import EligibilityAttribute as A

# ---------------------------------------------------------------------------
# Boolean attributes: shown when the user's value matches the rule's value.
# Each entry is (label when True is required, label when False is required).
# The False form is needed for exclusions such as `not_govt_employee` in the
# source data, which collapses onto is_govt_employee = false.
# ---------------------------------------------------------------------------

BOOLEAN_LABELS: dict[A, tuple[str, str]] = {
    # --- Demographic ---
    A.IS_WOMAN: (
        "You are a woman",
        "This scheme is not restricted to women",
    ),
    A.IS_SC_ST: (
        "You belong to a Scheduled Caste or Scheduled Tribe",
        "This scheme is not restricted by caste",
    ),
    A.IS_OBC: (
        "You belong to an Other Backward Class",
        "This scheme is not restricted by caste",
    ),
    A.IS_MINORITY: (
        "You belong to a minority community",
        "This scheme is not restricted by community",
    ),
    A.IS_DIVYANG: (
        "You are a person with a disability",
        "This scheme is not restricted by disability status",
    ),
    # --- Economic ---
    A.IS_EWS: (
        "You are in the Economically Weaker Section",
        "This scheme is not restricted to EWS applicants",
    ),
    A.IS_LIG: (
        "You are in the Low Income Group",
        "This scheme is not restricted to LIG applicants",
    ),
    A.IS_MIG: (
        "You are in the Middle Income Group",
        "This scheme is not restricted to MIG applicants",
    ),
    A.HAS_BPL_CARD: (
        "You hold a Below Poverty Line card",
        "A BPL card is not required",
    ),
    A.HAS_YELLOW_RATION_CARD: (
        "You hold a yellow ration card",
        "A yellow ration card is not required",
    ),
    A.HAS_ORANGE_RATION_CARD: (
        "You hold an orange ration card",
        "An orange ration card is not required",
    ),
    A.IS_TAXPAYER: (
        "You pay income tax",
        "You do not pay income tax",
    ),
    A.IS_PENSIONER_ABOVE_10K: (
        "You receive a pension above Rs 10,000",
        "You do not receive a pension above Rs 10,000",
    ),
    # --- Occupation ---
    A.IS_FARMER: (
        "You are a farmer",
        "This scheme is not restricted to farmers",
    ),
    A.OWNS_CULTIVABLE_LAND: (
        "You own cultivable land",
        "Owning cultivable land is not required",
    ),
    A.IS_MGNREGA_WORKER: (
        "You are an MGNREGA worker",
        "MGNREGA registration is not required",
    ),
    A.IS_UNORGANIZED_WORKER: (
        "You work in the unorganised sector",
        "This scheme is not restricted to unorganised-sector workers",
    ),
    A.HAS_ESHRAM_CARD: (
        "You hold an e-Shram card",
        "An e-Shram card is not required",
    ),
    A.IS_GOVT_EMPLOYEE: (
        "You are a government employee",
        "You are not a government employee",
    ),
    A.IS_STUDENT: (
        "You are a student",
        "This scheme is not restricted to students",
    ),
    A.HAS_BUSINESS_PLAN: (
        "You have a business plan",
        "A business plan is not required",
    ),
    # --- Housing and location ---
    A.IS_RURAL: (
        "You live in a rural area",
        "You live in an urban area",
    ),
    A.NO_PUCCA_HOUSE: (
        "You do not own a pucca house",
        "Owning a pucca house does not affect this scheme",
    ),
    # --- Health ---
    A.IS_PREGNANT_OR_LACTATING: (
        "You are pregnant or lactating",
        "This scheme is not restricted to pregnant or lactating women",
    ),
}

BOOLEAN_LABELS_HI: dict[A, tuple[str, str]] = {
    A.IS_WOMAN: ("आप एक महिला हैं", "यह योजना केवल महिलाओं के लिए नहीं है"),
    A.IS_SC_ST: (
        "आप अनुसूचित जाति या अनुसूचित जनजाति से हैं",
        "इस योजना में जाति की शर्त नहीं है",
    ),
    A.IS_OBC: ("आप अन्य पिछड़ा वर्ग से हैं", "इस योजना में जाति की शर्त नहीं है"),
    A.IS_MINORITY: ("आप अल्पसंख्यक समुदाय से हैं", "इस योजना में समुदाय की शर्त नहीं है"),
    A.IS_DIVYANG: ("आप दिव्यांग हैं", "इस योजना में दिव्यांगता की शर्त नहीं है"),
    A.IS_EWS: (
        "आप आर्थिक रूप से कमजोर वर्ग में हैं",
        "यह योजना केवल EWS के लिए नहीं है",
    ),
    A.IS_LIG: ("आप निम्न आय वर्ग में हैं", "यह योजना केवल LIG के लिए नहीं है"),
    A.IS_MIG: ("आप मध्यम आय वर्ग में हैं", "यह योजना केवल MIG के लिए नहीं है"),
    A.HAS_BPL_CARD: ("आपके पास बीपीएल कार्ड है", "बीपीएल कार्ड आवश्यक नहीं है"),
    A.HAS_YELLOW_RATION_CARD: (
        "आपके पास पीला राशन कार्ड है",
        "पीला राशन कार्ड आवश्यक नहीं है",
    ),
    A.HAS_ORANGE_RATION_CARD: (
        "आपके पास नारंगी राशन कार्ड है",
        "नारंगी राशन कार्ड आवश्यक नहीं है",
    ),
    A.IS_TAXPAYER: ("आप आयकर देते हैं", "आप आयकर नहीं देते"),
    A.IS_PENSIONER_ABOVE_10K: (
        "आपको ₹10,000 से अधिक पेंशन मिलती है",
        "आपको ₹10,000 से अधिक पेंशन नहीं मिलती",
    ),
    A.IS_FARMER: ("आप किसान हैं", "यह योजना केवल किसानों के लिए नहीं है"),
    A.OWNS_CULTIVABLE_LAND: (
        "आपके पास कृषि योग्य भूमि है",
        "कृषि योग्य भूमि आवश्यक नहीं है",
    ),
    A.IS_MGNREGA_WORKER: ("आप मनरेगा श्रमिक हैं", "मनरेगा पंजीकरण आवश्यक नहीं है"),
    A.IS_UNORGANIZED_WORKER: (
        "आप असंगठित क्षेत्र में काम करते हैं",
        "यह योजना केवल असंगठित श्रमिकों के लिए नहीं है",
    ),
    A.HAS_ESHRAM_CARD: ("आपके पास ई-श्रम कार्ड है", "ई-श्रम कार्ड आवश्यक नहीं है"),
    A.IS_GOVT_EMPLOYEE: ("आप सरकारी कर्मचारी हैं", "आप सरकारी कर्मचारी नहीं हैं"),
    A.IS_STUDENT: ("आप विद्यार्थी हैं", "यह योजना केवल विद्यार्थियों के लिए नहीं है"),
    A.HAS_BUSINESS_PLAN: ("आपके पास व्यवसाय योजना है", "व्यवसाय योजना आवश्यक नहीं है"),
    A.IS_RURAL: ("आप ग्रामीण क्षेत्र में रहते हैं", "आप शहरी क्षेत्र में रहते हैं"),
    A.NO_PUCCA_HOUSE: (
        "आपके पास पक्का मकान नहीं है",
        "पक्का मकान होने से कोई अंतर नहीं पड़ता",
    ),
    A.IS_PREGNANT_OR_LACTATING: (
        "आप गर्भवती या स्तनपान कराने वाली हैं",
        "यह योजना केवल गर्भवती या स्तनपान कराने वाली महिलाओं के लिए नहीं है",
    ),
}

# ---------------------------------------------------------------------------
# Numeric attributes: templated, since the threshold varies per scheme.
# Keyed by (attribute, operator).
# ---------------------------------------------------------------------------

NUMERIC_LABEL_TEMPLATES: dict[tuple[A, str], str] = {
    (A.AGE, "gte"): "You are aged {value} or above",
    (A.AGE, "lte"): "You are aged {value} or below",
    (A.ANNUAL_INCOME, "lte"): "Your annual income is Rs {value} or less",
    (A.ANNUAL_INCOME, "gte"): "Your annual income is Rs {value} or more",
}

NUMERIC_LABEL_TEMPLATES_HI: dict[tuple[A, str], str] = {
    (A.AGE, "gte"): "आपकी आयु {value} वर्ष या अधिक है",
    (A.AGE, "lte"): "आपकी आयु {value} वर्ष या कम है",
    (A.ANNUAL_INCOME, "lte"): "आपकी वार्षिक आय ₹{value} या उससे कम है",
    (A.ANNUAL_INCOME, "gte"): "आपकी वार्षिक आय ₹{value} या उससे अधिक है",
}

# ---------------------------------------------------------------------------
# Text attributes
# ---------------------------------------------------------------------------

TEXT_LABEL_TEMPLATES: dict[A, str] = {
    A.STATE_CODE: "You live in {value}",
}

TEXT_LABEL_TEMPLATES_HI: dict[A, str] = {
    A.STATE_CODE: "आप {value} में रहते हैं",
}


def format_indian_number(value: float) -> str:
    """Group digits the Indian way: 12,34,567 rather than 1,234,567.

    Western grouping reads as wrong to the audience, and income thresholds are
    the numbers users scrutinise most closely.
    """
    integer = int(value)
    text = str(abs(integer))
    if len(text) <= 3:
        grouped = text
    else:
        last_three = text[-3:]
        rest = text[:-3]
        parts: list[str] = []
        while len(rest) > 2:
            parts.insert(0, rest[-2:])
            rest = rest[:-2]
        if rest:
            parts.insert(0, rest)
        grouped = ",".join([*parts, last_three])
    return f"-{grouped}" if integer < 0 else grouped
