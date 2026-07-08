# Implementation Guidance

## Architecture

- Tokens compile into theme extensions and typed constants.
- Shared widgets live in a design-system package or feature-agnostic module.
- Role wrappers own route-level composition and permissions, not primitive component styling.

## State and Safety

- Components should accept explicit state enums instead of inferring from null values.
- Sensitive support and audit widgets should centralize redaction and access checks.
- Offline, loading, and empty states should reuse shared state surfaces rather than custom one-offs.
