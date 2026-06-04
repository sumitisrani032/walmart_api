# ADR-007: Response Handling

Status: Accepted

## Decision

All Walmart API responses will be normalized into Ruby objects.

The SDK should not expose raw Faraday responses to consumers.

Consumers should interact with:

- domain objects
- response wrappers
- SDK exceptions

## Rationale

Provides a stable API even if underlying HTTP implementation changes.

## Consequences

Positive:
- Better developer experience
- Easier testing
- Easier future refactoring

Negative:
- Additional abstraction layer