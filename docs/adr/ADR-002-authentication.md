# ADR-002: Authentication Architecture

Status: Accepted

## Context

Walmart Marketplace APIs require:

* OAuth Access Token
* RSA Request Signature

Authentication complexity should be hidden from developers.

## Decision

Implement:

* Auth::TokenManager
* Auth::SignatureGenerator
* Middleware::WalmartAuth

### TokenManager

Responsibilities:

* Token acquisition
* Token caching
* Token refresh
* Thread safety

### SignatureGenerator

Responsibilities:

* RSA signing
* Stateless operation

### WalmartAuth Middleware

Responsibilities:

* Inject authentication headers
* Generate correlation IDs
* Coordinate authentication services

## Consequences

Positive:

* Clear separation of responsibilities
* Easier testing
* Easier maintenance

Negative:

* Additional classes
