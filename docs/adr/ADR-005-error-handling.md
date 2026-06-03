# ADR-005: Error Handling Strategy

Status: Accepted

## Decision

Map API failures into meaningful exceptions.

Examples:

* AuthenticationError
* AuthorizationError
* ValidationError
* RateLimitError
* ServerError

Expose:

* HTTP status
* Correlation ID
* Response body

Never expose raw Faraday exceptions.

## Consequences

Positive:

* Better debugging
* Better developer experience
