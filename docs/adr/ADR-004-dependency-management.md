# ADR-004: Dependency Management

Status: Accepted

## Decision

Keep dependencies minimal.

Preferred dependencies:

* Faraday
* RSpec
* VCR
* WebMock
* Rubocop

Every dependency must have a clear justification.

## Consequences

Positive:

* Easier maintenance
* Faster installs
* Reduced security risk

Negative:

* More internal implementation work
