# Infinite Scrolling

## Scope

- BAHA content library
- Audit log
- Support queue
- Notification center

## Rules

- Use explicit page or cursor loading on operational datasets above one screenful.
- Show a skeleton continuation rather than a full-screen loader for subsequent pages.
- Preserve keyboard focus and screen-reader position after new rows append.
- Student and parent routes should prefer smaller bounded lists over endless feeds unless the architecture explicitly requires otherwise.
