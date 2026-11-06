# Organizational Risk Assessment

This is my security risk analysis of Cedar Elm Rehab Partners against NIST CSF 2.0. I structured it around the HIPAA Security Rule's risk analysis and risk management standards (45 CFR 164.308(a)(1)(ii)(A)-(B)).

| File | Contents |
|---|---|
| `cedar-elm-risk-register.xlsx` | Methodology (likelihood, impact, and maturity scales), Risk Register (16 risks with inherent and residual scoring), Heat Map (inherent vs. residual), CSF 2.0 Profile (22 categories, current vs. 12-month target) |
| `cedar-elm-poam.xlsx` | Plan of Action and Milestones: 26 items (4 verified closed, 3 in progress) linking each weakness to a risk, NIST SP 800-53 control, HIPAA citation, owner, and date |

## Results at a glance

CSF 2.0 maturity (0-4 scale)

| Function | Current | 12-month target |
|---|---|---|
| Govern | 0.83 | 2.83 |
| Identify | 0.67 | 2.67 |
| Protect | 1.20 | 3.00 |
| Detect | 0.50 | 2.50 |
| Respond | 0.50 | 2.50 |
| Recover | 0.00 | 2.50 |
| Overall | 0.73 | 2.73 |

Recover scores lowest because restores have never been tested and no recovery plan exists. That matters most in a ransomware event, which is also the top-rated risk.

Risk distribution

| Rating | Inherent | Residual (after planned treatment) |
|---|---|---|
| Critical | 4 | 0 |
| High | 7 | 0 |
| Moderate | 5 | 10 |
| Low | 0 | 6 |

Average risk score falls from 12.0 to 5.3 if the POA&M is completed.

Top risks (inherent)
1. R-01 Ransomware reaches on-prem servers and the only backup copy (20, Critical)
2. R-02 Microsoft 365 account takeover / business email compromise (16, Critical)
3. R-03 Compromise of the internet-facing Referral Intake Portal (15, Critical); tested directly in `02-technical-audit`
4. R-05 Backups cannot be restored (15, Critical)

## How scores were derived
The likelihood and impact scores (the blue cells) are my own judgments, made with the scales on the Methodology sheet. They rest on the interviews, document review, technical testing and sector data such as IBM's 2025 Cost of a Data Breach report, which puts healthcare's average breach lifecycle at 279 days. Every score, rating, heat-map count and average is a live formula, so a reviewer can disagree with a judgment and see the effect right away.
