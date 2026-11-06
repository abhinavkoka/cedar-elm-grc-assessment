# Third-Party Risk Assessment of ePHI Vendors

Client Cedar Elm Rehab Partners (fictional) | Assessed October 2026 | Workbook `cedar-elm-vendor-risk-assessment.xlsx`

## Scope and method

Cedar Elm shares ePHI with at least six vendors and had never reviewed any of them. This assessment covers the three that hold the most patient data. All evidence is public (vendor security pages, legal terms and documentation, accessed October 24, 2026). I chose that limit on purpose. It shows what a covered entity can learn before sending a questionnaire, and it gives a precise request list for each vendor.

1. Tier each vendor by ePHI sensitivity, operational criticality, and integration (Tiering sheet).
2. Score eight domains from 0 to 3 based on the strength of evidence, weighted toward attestation, BAA terms, encryption, and data location (Scorecard sheet).
3. Record every observation with its source URL (Evidence sheet).
4. Request the specific documents that would close each gap (Follow-up Requests sheet).

## Results

| Vendor | Tier | Score | Rating | Headline |
|---|---|---|---|---|
| Microsoft 365 | 1 | 90 | Satisfactory | Strong, contractual evidence: ISO 27001 and HITRUST audits, a BAA included by default, and 72-hour breach notice in the DPA. The risk sits in Cedar Elm's own configuration (MFA), not in Microsoft. |
| Weave | 2 | 50 | Follow-up required | Good technical detail (encryption, pen testing, bug bounty), but no Weave-specific attestation, no breach-notice deadline in the BAA, and no stated data region. |
| WebPT | 1 | 28 | Insufficient evidence | Publishes current BAA and terms but little verifiable security detail: no named SOC 2 report, no data location and no binding resilience commitments. For the system of record, that isn't enough to rely on. |

A low score means missing public evidence, not a confirmed weakness. WebPT very likely has more to share under NDA, and the real problem is that Cedar Elm has never asked.

## Key findings

1. No vendor has confirmed U.S. data storage (Texas SB 1188). Weave runs on Google Cloud with an unstated region and cross-region DR. WebPT does not publish hosting details. Microsoft offers residency commitments, but Cedar Elm has not recorded its tenant's data location.
2. BAA gaps. Cedar Elm's WebPT BAA is from 2014, while WebPT published a new one in July 2026. No executed Weave BAA was retained.
3. Breach-notice timing is undefined for two of three vendors. Cedar Elm must notify the Texas AG within 30 days for breaches affecting 250+ Texans, so vendor notice terms matter.
4. Customer-side controls are the bigger M365 risk. Entra ID MFA and Conditional Access are licensed but not enforced (risk R-02).

## Recommendations

| # | Action | Owner | Due |
|---|---|---|---|
| 1 | Send each vendor its request list (Follow-up Requests sheet) | Privacy Officer | Dec 15, 2026 |
| 2 | Execute current BAAs with WebPT and Weave; store all BAAs in one repository | Privacy Officer | Dec 15, 2026 |
| 3 | Collect written U.S. data-location attestations; add a data-location clause to renewals | Privacy Officer | Dec 31, 2026 |
| 4 | Adopt the tiering model: annual review for Tier 1, every two years for Tier 2, and review at onboarding for every new ePHI vendor | Privacy Officer | Jan 31, 2027 |
| 5 | Extend the assessment to eFax and the MSP (TriCounty Tech Partners) | Privacy Officer | Mar 31, 2027 |

## Sources

- [WebPT: Administration and Security](https://www.webpt.com/admin-security)
- [WebPT: Legal / Service Agreement documents](https://www.webpt.com/legal/service-agreement)
- [Microsoft: HIPAA/HITECH compliance offering](https://learn.microsoft.com/en-us/compliance/regulatory/offering-hipaa-hitech)
- [Microsoft: Incident management and customer notification](https://learn.microsoft.com/en-us/compliance/assurance/assurance-incident-management)
- [Microsoft: Microsoft 365 encryption](https://learn.microsoft.com/en-us/training/modules/audit-encryption/introduction)
- [Microsoft: Where your data is located](https://www.microsoft.com/en/trust-center/privacy/data-location)
- [Weave: Security](https://www.getweave.com/security/)
- [Weave: Business Associate Agreement](https://www.getweave.com/legal/baa/)
