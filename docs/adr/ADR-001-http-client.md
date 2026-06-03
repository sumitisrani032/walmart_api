# ADR-001: HTTP Client Selection

Status: Accepted

## Context

The Walmart API gem requires:

* Middleware support
* Request retries
* Logging
* Testability
* Flexible adapters

## Decision

Use Faraday 2.x.

## Rationale

Benefits:

* Mature ecosystem
* Middleware architecture
* Excellent testing support
* Flexible adapters

Alternatives considered:

### Net::HTTP

Rejected because it is too low-level.

### HTTParty

Rejected because middleware support is limited.

## Consequences

Positive:

* Easy authentication middleware
* Easy retry middleware
* Easy testing

Negative:

* Additional dependency
