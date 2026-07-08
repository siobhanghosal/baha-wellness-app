# Authentication

## Identity Types

- student
- parent or guardian
- teacher
- school counselor
- BAHA clinician
- BAHA admin
- content reviewer

## Auth Requirements

- secure credentials and TLS-only transit
- guardian linkage for minor consent flows
- role-based claims embedded in token/session
- school context for teacher and school counselor roles
- BAHA operational scopes for staff roles

## Authorization Strategy

- coarse role gate at route level
- fine-grained resource policy within services
- privacy-tier filtering at projection layer
- case data exposure only when case access conditions are met
