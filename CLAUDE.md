# Walmart API Ruby Gem

## Project Goal

Build a production-grade Ruby SDK for Walmart Marketplace APIs.

The gem should provide:

* Simple and intuitive Ruby interface
* Automatic authentication
* Thread-safe token management
* Robust error handling
* Rails-friendly integration
* Stable public API
* Excellent developer experience
* High test coverage

---

## Current Project Phase

ADLC Define Phase

No implementation should begin until architecture and API design are documented and approved.

---

## Source Of Truth

Always use Walmart Marketplace documentation as the authoritative source.

Developer Portal:
https://developer.walmart.com/

Marketplace Documentation:
https://developer.walmart.com/us-marketplace/docs

Authentication:
https://developer.walmart.com/us-marketplace/docs/authentication

Orders API:
https://developer.walmart.com/us-marketplace/reference/getallorders

Inventory API:
https://developer.walmart.com/us-marketplace/reference/getinventory

Items API:
https://developer.walmart.com/us-marketplace/reference/getanitem

If documentation and existing implementation differ:

1. Verify latest Walmart documentation.
2. Explain discrepancy.
3. Never silently change behavior.

---

## Development Methodology

This project follows Agentic Development Lifecycle (ADLC).

Stages:

1. Architect
2. Define
3. Launch
4. Cycle
5. Close

Every phase must pass review before moving to the next phase.

---

## Architecture Decisions

Before generating code:

* Read CLAUDE.md
* Read all ADR documents
* Review existing implementation
* Preserve existing architecture decisions

ADR documents are authoritative.

---

## Public API Philosophy

The public API is the product.

Priorities:

1. Developer Experience
2. Predictability
3. Consistency
4. Backward Compatibility

Preferred API style:

```ruby
client.orders.list

client.orders.find(order_id)

client.inventory.get(sku)

client.items.find(item_id)
```

Avoid exposing implementation details.

---

## Coding Standards

### General Principles

* Prefer readability over cleverness
* Write code for humans first
* Keep classes small and focused
* Keep methods short and understandable
* Prefer composition over inheritance
* Avoid premature abstraction
* Follow SOLID principles
* Favor explicit code over magic
* Minimize complexity

### Ruby Standards

* Follow Ruby community best practices
* Follow Rubocop
* Use frozen string literals
* Use keyword arguments when appropriate
* Avoid monkey patches
* Avoid global state
* Avoid unnecessary metaprogramming

### Rails Standards

When Rails integrations are introduced:

* Follow Rails conventions
* Prefer POROs for business logic
* Avoid callback-heavy designs
* Prefer service objects
* Use dependency injection when appropriate

### Production Readiness

Every feature must include:

* Error handling
* Edge case handling
* Tests
* Documentation
* Logging where appropriate

---

## Dependency Policy

Before introducing a dependency:

* Justify why it is needed
* Prefer Ruby standard library when practical
* Prefer mature, actively maintained gems
* Minimize dependency footprint

Preferred dependencies:

* Faraday
* RSpec
* VCR
* WebMock
* Rubocop

---

## Error Handling Standards

Never expose raw Faraday exceptions.

Map failures into domain-specific exceptions.

Examples:

```ruby
WalmartApi::AuthenticationError
WalmartApi::AuthorizationError
WalmartApi::RateLimitError
WalmartApi::ValidationError
WalmartApi::ServerError
```

---

## Testing Standards

Every feature must include:

* Unit tests
* Error path tests
* Edge case tests

Integration testing:

* VCR
* WebMock

CI must never depend on live Walmart APIs.

Tests should be:

* Fast
* Deterministic
* Reliable

Avoid flaky tests.

---

## Security Standards

Never:

* Log private keys
* Log secrets
* Log access tokens

Sensitive values must be filtered.

Authentication logic requires dedicated tests.

---

## Versioning

Follow Semantic Versioning.

Patch:

* Bug fixes

Minor:

* New features

Major:

* Breaking changes

Public API changes require discussion.

---

## Commit Strategy

Commits must be:

* Small
* Focused
* Review-friendly
* Reversible
* Feature-based

Examples:

c001 docs: establish architecture decisions

c002 build: generate gem scaffold

c003 feat: add configuration object

c004 feat: add oauth token manager

c005 feat: add rsa signature generator

Avoid mixed-purpose commits.

---

## Definition Of Done

A feature is complete only when:

* Implementation exists
* Tests exist
* Documentation updated
* Rubocop passes
* RSpec passes
* Review completed

---

## Release Goal

v0.1.0

Resources:

* Orders
* Inventory
* Items

Future releases:

* Returns
* Feeds
* Reports

---

## Instructions For Claude Code

Before implementing:

1. Read CLAUDE.md
2. Read all ADR files
3. Understand current architecture
4. Review existing patterns

When generating code:

* Generate tests with implementation
* Keep code simple
* Maintain consistency
* Explain tradeoffs
* Preserve backward compatibility

Never sacrifice maintainability for brevity.
