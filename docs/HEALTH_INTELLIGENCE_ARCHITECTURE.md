# HEALTH INTELLIGENCE ARCHITECTURE

Internal planning document. No LLM is integrated in the current product.

TARU is a provenance-first personal health system. Intelligence, if added
later, consumes structured user-owned context. It does not become a source of
health records.

## Planned pipeline

USER DATA
→ STRUCTURED HEALTH CONTEXT (`HealthContextSnapshot`, read-only)
→ EVIDENCE RETRIEVAL
→ DETERMINISTIC SAFETY CHECKS
→ MODEL REASONING
→ CITED RESPONSE
→ USER ACTION / FOLLOW-UP

**LLM output is NOT authoritative health data.** It must not be written back as
conditions, allergies, medicines, diet, or other TARU records unless the user
explicitly reviews and saves a separate user-owned artifact.

## Evidence source hierarchy (future)

These classes are not equal:

1. CURRENT AUTHORITATIVE GUIDELINES
2. SYSTEMATIC REVIEWS / META-ANALYSES
3. CONTROLLED CLINICAL RESEARCH
4. OBSERVATIONAL / LOWER-CERTAINTY RESEARCH
5. REGULATORY DRUG INFORMATION
6. TRADITIONAL / HISTORICAL SOURCES

Traditional/historical status must stay visible. Do not blend them into
guideline-grade claims.

## Likely future India source families (not ingested here)

- ICMR Standard Treatment Workflows
- ICMR-NIN nutrition guidance
- WHO guidance
- PubMed / NLM literature metadata
- Ministry of Ayush research resources
- future drug-label / regulatory sources

Do not scrape sources whose terms prohibit it. No website dump in this phase.

## Future mapping (not implemented)

Internal records should remain mappable later without storing codes now:

| TARU domain | Possible later mapping |
| --- | --- |
| Conditions | Condition |
| Allergies | AllergyIntolerance |
| Medications | MedicationStatement |
| Measurements / lifestyle observations | Observation |
| Family history | FamilyMemberHistory |
| Procedures | Procedure |
| Immunizations | Immunization |
| Health goals | Goal |

No FHIR package, no SNOMED/LOINC/ICD assignment in this phase.

## Outcome horizon

`HealthGoalRecord.desiredBy` is a **user goal date**. It is not a predicted
recovery date, cure date, or medical promise. A future Outcome-Horizon Planner
may read it; it must not silently convert it into a prognosis.

## Temporal truth

A health fact may have all of:

- VALUE
- EFFECTIVE / EVENT TIME (when the real-world event happened or was true)
- RECORDED TIME (when TARU first stored the representation)
- SOURCE / provenance (how TARU received it)

Future AI must not collapse those concepts. `recordedAt` is not an event date.
`HealthContextSnapshot.generatedAt` is only when a derived in-memory view was
assembled.

## Conflict preservation

If two user or report sources disagree, TARU should preserve and surface the
disagreement. Future AI must not silently choose one source as truth unless a
specific authoritative policy exists. Conflict resolution is not implemented
in this phase.

## Future AI data-scope (not implemented)

Future Health AI should receive an explicit allowed context scope (for example
medicines, reports, measurements, diet, family history). A future answer should
be able to explain: "What TARU information was used for this answer?" No
permissions UI in this phase.
