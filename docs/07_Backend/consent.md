# Consent Architecture

## Consent Artifacts

- student assent record
- parent or guardian consent record
- self-consent record for ages 18-19
- school permission record
- privacy tier agreement record
- chatbot profile-building opt-out state

## Consent Lifecycle

1. policy version published
2. student completes age-band and legal-band routing
3. parent consent or self-consent collected
4. privacy tier state recorded
5. consent version changes trigger re-acknowledgement
6. withdrawal request propagates within 24 hours

## Enforcement Rules

- no student feature processing before required consent is active
- parent view is derived from privacy tier projection, not raw data exposure
- acute safety override bypasses privacy tier only for defined categories and is logged
