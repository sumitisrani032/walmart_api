# Implementation Plan: v0.1.0

## Overview

This plan covers the full implementation of walmart_api v0.1.0, from test infrastructure through Orders, Inventory, and Items resources.

Each commit is self-contained, independently testable, and builds on the previous commit. The sequence follows the dependency graph: infrastructure first, then authentication, then shared abstractions, then the client, then individual resources.

All decisions follow ADR-001 through ADR-006 and the public API surface defined in `docs/api_examples.md`.

---

## Dependency Graph

```
c003: Dependencies + Test Infrastructure
  │
  ├── c004: Configuration
  │     │
  │     ├── c005: Error Hierarchy
  │     │
  │     ├── c006: RSA Signature Generator
  │     │     │
  │     │     └── c007: OAuth Token Manager
  │     │           │
  │     │           └── c008: Authentication Middleware
  │     │
  │     └── c009: Error Mapping Middleware
  │
  ├── c010: Base Resource (depends on c008, c009)
  │     │
  │     ├── c012: Orders Resource
  │     ├── c013: Inventory Resource
  │     └── c014: Items Resource
  │
  └── c011: Client (depends on c010)
        │
        └── c015: Gemspec Finalization
```

---

## Commit Sequence

---

### c003 — build: configure runtime and development dependencies

**Purpose:** Establish the dependency set (ADR-004), test infrastructure, and linting configuration so that all subsequent commits can include tests.

**Files affected:**

| File | Action |
|---|---|
| `walmart_api.gemspec` | Modify — add `faraday` runtime dependency (~> 2.0), fix summary/description/homepage TODOs |
| `Gemfile` | Modify — add development dependencies: rspec (~> 3.0), webmock (~> 3.0), vcr (~> 6.0), rubocop (~> 1.0), rubocop-rspec |
| `.rubocop.yml` | Create — configure Rubocop with frozen string literal enforcement, reasonable line length, RSpec cops |
| `.rspec` | Create — configure RSpec defaults (--format documentation, --color, --require spec_helper) |
| `spec/spec_helper.rb` | Create — require walmart_api, configure RSpec, configure WebMock to disable net connections |
| `Rakefile` | Modify — add RSpec and Rubocop tasks, set default task |

**Tests required:**

- `spec/walmart_api_spec.rb` — verify `WalmartApi` module loads, verify `WalmartApi::VERSION` equals "0.1.0"

**Acceptance criteria:**

- [ ] `bundle install` succeeds
- [ ] `bundle exec rspec` runs and passes
- [ ] `bundle exec rubocop` runs with zero offenses
- [ ] Faraday is a declared runtime dependency
- [ ] No TODO placeholders remain in gemspec

---

### c004 — feat: add configuration object

**Purpose:** Implement the `WalmartApi::Configuration` class and the `WalmartApi.configure` DSL. This is the foundation everything else depends on.

**Design decisions:**

- Supports both global configuration (`WalmartApi.configure`) and per-client overrides (passed to `Client.new`)
- `private_key` (string) and `private_key_path` (file path) are mutually supportive — if both are set, `private_key` takes precedence
- Default environment is `:production`
- Base URLs: production → `https://marketplace.walmartapis.com`, sandbox → `https://sandbox.walmartapis.com`
- Raises `WalmartApi::ConfigurationError` when required fields are missing (validated on demand, not on set)

**Files affected:**

| File | Action |
|---|---|
| `lib/walmart_api/configuration.rb` | Create — Configuration class with accessors, defaults, validation, base_url resolution |
| `lib/walmart_api.rb` | Modify — add `configure`, `configuration`, `reset_configuration` class methods; require configuration |

**Tests required:**

- `spec/walmart_api/configuration_spec.rb`
  - Sets and reads `client_id`
  - Sets and reads `client_secret`
  - Sets and reads `private_key`
  - Sets and reads `private_key_path`
  - Resolves private key from path when `private_key` is not set
  - Prefers `private_key` over `private_key_path` when both are set
  - Default environment is `:production`
  - Sets environment to `:sandbox`
  - Returns correct `base_url` for production
  - Returns correct `base_url` for sandbox
  - Sets and reads `channel_type`
  - `validate!` raises `ConfigurationError` when `client_id` is missing
  - `validate!` raises `ConfigurationError` when `client_secret` is missing
  - `validate!` raises `ConfigurationError` when both `private_key` and `private_key_path` are missing
  - `validate!` raises `ConfigurationError` when `private_key_path` points to nonexistent file
  - `validate!` passes when all required fields are present
- `spec/walmart_api_spec.rb`
  - `WalmartApi.configure` yields configuration object
  - `WalmartApi.configuration` returns current configuration
  - `WalmartApi.reset_configuration` clears configuration

**Acceptance criteria:**

- [ ] Configuration block DSL works as shown in `docs/api_examples.md`
- [ ] All required fields are validated
- [ ] Private key can be provided as string or file path
- [ ] Environment defaults to production
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes

---

### c005 — feat: add error hierarchy

**Purpose:** Implement the full exception hierarchy per ADR-005 and `docs/api_examples.md`. These classes must exist before any HTTP-calling code.

**Design decisions:**

- `WalmartApi::Error` is the root (already exists in scaffold — extend it)
- `WalmartApi::ConfigurationError < Error` (non-HTTP, raised during setup)
- `WalmartApi::ApiError < Error` with `status`, `correlation_id`, `body`, `message` attributes
- Subclasses: `AuthenticationError`, `AuthorizationError`, `NotFoundError`, `ValidationError`, `RateLimitError`, `ServerError`
- `RateLimitError` adds `retry_after` attribute
- Constructor: `ApiError.new(status:, body:, correlation_id: nil)` — message is derived from body or a default

**Files affected:**

| File | Action |
|---|---|
| `lib/walmart_api/errors.rb` | Create — full exception hierarchy |
| `lib/walmart_api.rb` | Modify — require errors, remove inline Error class |

**Tests required:**

- `spec/walmart_api/errors_spec.rb`
  - `WalmartApi::Error` inherits from `StandardError`
  - `WalmartApi::ConfigurationError` inherits from `Error`
  - `WalmartApi::ApiError` inherits from `Error`
  - `WalmartApi::ApiError` exposes `status`, `correlation_id`, `body`, `message`
  - `WalmartApi::AuthenticationError` inherits from `ApiError`
  - `WalmartApi::AuthorizationError` inherits from `ApiError`
  - `WalmartApi::NotFoundError` inherits from `ApiError`
  - `WalmartApi::ValidationError` inherits from `ApiError`
  - `WalmartApi::RateLimitError` inherits from `ApiError`
  - `WalmartApi::RateLimitError` exposes `retry_after`
  - `WalmartApi::ServerError` inherits from `ApiError`
  - `rescue WalmartApi::ApiError` catches all HTTP subclasses
  - `rescue WalmartApi::Error` catches everything
  - ApiError generates a human-readable message from the response body
  - ApiError falls back to a default message when body has no error details

**Acceptance criteria:**

- [ ] Full hierarchy matches `docs/api_examples.md` exception tree
- [ ] All error attributes are accessible
- [ ] `rescue WalmartApi::Error` catches everything from the gem
- [ ] `rescue WalmartApi::ApiError` catches all HTTP-related errors
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes

---

### c006 — feat: add RSA signature generator

**Purpose:** Implement `WalmartApi::Auth::SignatureGenerator` per ADR-002. Walmart requires RSA-SHA256 signatures on every API request.

**Design decisions:**

- Stateless: receives private key content, returns signature
- Signs the concatenation of: consumer_id, timestamp, key_version (hardcoded to "1")
- Uses OpenSSL from Ruby stdlib (no additional dependency)
- Returns Base64-encoded signature string

**Files affected:**

| File | Action |
|---|---|
| `lib/walmart_api/auth/signature_generator.rb` | Create — SignatureGenerator class |
| `lib/walmart_api.rb` | Modify — require auth/signature_generator |

**Tests required:**

- `spec/walmart_api/auth/signature_generator_spec.rb`
  - Generates a valid RSA-SHA256 signature
  - Signature is Base64-encoded
  - Signature is deterministic for the same inputs
  - Different timestamps produce different signatures
  - Raises an error for an invalid private key
  - Uses a test RSA key fixture (not a real Walmart key)

**Acceptance criteria:**

- [ ] Signs request data using RSA-SHA256
- [ ] Returns Base64-encoded string
- [ ] Uses only Ruby stdlib (OpenSSL)
- [ ] No private keys logged or exposed
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes

---

### c007 — feat: add OAuth token manager

**Purpose:** Implement `WalmartApi::Auth::TokenManager` per ADR-002. Handles OAuth 2.0 client_credentials flow with caching and thread-safe refresh.

**Design decisions:**

- Acquires token via POST to `/v3/token` with Basic auth (base64 of client_id:client_secret)
- Caches token in memory with expiry tracking
- Thread-safe via `Mutex`
- Refreshes token when expired or within a buffer window (e.g., 60 seconds before expiry)
- Uses its own Faraday connection (minimal, no auth middleware) to avoid circular dependency
- Does not retry — caller handles retry logic

**Files affected:**

| File | Action |
|---|---|
| `lib/walmart_api/auth/token_manager.rb` | Create — TokenManager class |
| `lib/walmart_api.rb` | Modify — require auth/token_manager |

**Tests required:**

- `spec/walmart_api/auth/token_manager_spec.rb`
  - Fetches access token from Walmart token endpoint (stubbed via WebMock)
  - Sends correct Authorization header (Basic base64)
  - Sends correct Content-Type (application/x-www-form-urlencoded)
  - Sends correct grant_type (client_credentials)
  - Caches token after first fetch
  - Returns cached token when not expired
  - Refreshes token when expired
  - Refreshes token within buffer window before expiry
  - Is thread-safe (concurrent access does not duplicate token requests)
  - Raises `AuthenticationError` when token endpoint returns 401
  - Raises `ServerError` when token endpoint returns 500
  - Never logs the access token value

**Acceptance criteria:**

- [ ] Acquires OAuth token via client_credentials flow
- [ ] Caches token and respects expiry
- [ ] Thread-safe via Mutex
- [ ] Raises domain exceptions on failure
- [ ] No tokens or secrets appear in logs
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes

---

### c008 — feat: add authentication middleware

**Purpose:** Implement `WalmartApi::Middleware::Authentication` per ADR-002. This Faraday middleware injects all required Walmart authentication headers into every outgoing request.

**Design decisions:**

- Faraday middleware (inherits `Faraday::Middleware`)
- Injects headers:
  - `WM_SEC.ACCESS_TOKEN` — from TokenManager
  - `WM_SVC.NAME` — service name (gem name)
  - `WM_QOS.CORRELATION_ID` — generated UUID per request
  - `WM_SEC.TIMESTAMP` — Unix timestamp in milliseconds
  - `WM_SEC.AUTH_SIGNATURE` — from SignatureGenerator
  - `WM_CONSUMER.CHANNEL.TYPE` — from configuration (if set)
- Coordinates TokenManager and SignatureGenerator
- Generates a new correlation ID (SecureRandom.uuid) for each request

**Files affected:**

| File | Action |
|---|---|
| `lib/walmart_api/middleware/authentication.rb` | Create — Faraday middleware |
| `lib/walmart_api.rb` | Modify — require middleware/authentication |

**Tests required:**

- `spec/walmart_api/middleware/authentication_spec.rb`
  - Adds `WM_SEC.ACCESS_TOKEN` header
  - Adds `WM_SVC.NAME` header
  - Adds `WM_QOS.CORRELATION_ID` header (UUID format)
  - Adds `WM_SEC.TIMESTAMP` header (millisecond Unix timestamp)
  - Adds `WM_SEC.AUTH_SIGNATURE` header
  - Adds `WM_CONSUMER.CHANNEL.TYPE` header when configured
  - Omits `WM_CONSUMER.CHANNEL.TYPE` header when not configured
  - Each request gets a unique correlation ID
  - Calls TokenManager to get access token
  - Calls SignatureGenerator to generate signature

**Acceptance criteria:**

- [ ] All required Walmart headers are injected
- [ ] Correlation ID is a unique UUID per request
- [ ] Coordinates TokenManager and SignatureGenerator correctly
- [ ] Channel type header is conditional
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes

---

### c009 — feat: add error mapping middleware

**Purpose:** Implement `WalmartApi::Middleware::ErrorHandler` — a Faraday response middleware that maps HTTP error responses to domain exceptions. This keeps error handling out of resource classes.

**Design decisions:**

- Faraday response middleware
- Maps HTTP status codes to exception classes:
  - 400 → `ValidationError`
  - 401 → `AuthenticationError`
  - 403 → `AuthorizationError`
  - 404 → `NotFoundError`
  - 429 → `RateLimitError` (parses `Retry-After` header)
  - 5xx → `ServerError`
- Extracts correlation ID from `WM_QOS.CORRELATION_ID` response header
- Passes through successful responses unchanged (2xx, 3xx)
- Parses response body as JSON when possible

**Files affected:**

| File | Action |
|---|---|
| `lib/walmart_api/middleware/error_handler.rb` | Create — Faraday response middleware |
| `lib/walmart_api.rb` | Modify — require middleware/error_handler |

**Tests required:**

- `spec/walmart_api/middleware/error_handler_spec.rb`
  - Passes through 200 responses unchanged
  - Passes through 201 responses unchanged
  - Raises `ValidationError` for 400
  - Raises `AuthenticationError` for 401
  - Raises `AuthorizationError` for 403
  - Raises `NotFoundError` for 404
  - Raises `RateLimitError` for 429
  - Raises `RateLimitError` with `retry_after` parsed from header
  - Raises `ServerError` for 500
  - Raises `ServerError` for 502
  - Raises `ServerError` for 503
  - Raises `ServerError` for 504
  - Extracts correlation ID from response header
  - Sets correlation ID to nil when header is absent
  - Parses JSON response body into exception
  - Handles non-JSON response body gracefully

**Acceptance criteria:**

- [ ] All error status codes map to the correct exception class
- [ ] Correlation ID is extracted from response headers
- [ ] `RateLimitError` includes `retry_after`
- [ ] Successful responses pass through
- [ ] Non-JSON bodies don't crash the middleware
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes

---

### c010 — feat: add base resource and response handling

**Purpose:** Implement `WalmartApi::Resources::Base` — the shared superclass for all API resources (ADR-003). Also implement response wrapping so API responses are accessible as Ruby objects.

**Design decisions:**

- Base resource holds a reference to the Faraday connection
- Provides `get`, `post`, `put`, `delete` helper methods that delegate to the connection
- Response wrapping: `WalmartApi::Response` wraps a hash, providing method-style access (e.g., `response.sku`)
- Nested hashes are recursively wrapped
- Arrays of hashes are wrapped as arrays of Response objects
- Paginated responses: `WalmartApi::PaginatedResponse` extends Response with `next_cursor` and `items` (the list of wrapped elements)

**Files affected:**

| File | Action |
|---|---|
| `lib/walmart_api/resources/base.rb` | Create — Base resource class |
| `lib/walmart_api/response.rb` | Create — Response wrapper |
| `lib/walmart_api/paginated_response.rb` | Create — PaginatedResponse for list endpoints |
| `lib/walmart_api.rb` | Modify — require new files |

**Tests required:**

- `spec/walmart_api/resources/base_spec.rb`
  - Delegates `get` to the Faraday connection
  - Delegates `post` to the Faraday connection
  - Delegates `put` to the Faraday connection
  - Delegates `delete` to the Faraday connection
  - Passes path and params correctly
- `spec/walmart_api/response_spec.rb`
  - Accesses top-level hash keys as methods
  - Converts camelCase keys to snake_case methods
  - Wraps nested hashes as Response objects
  - Wraps arrays of hashes as arrays of Response objects
  - Returns nil for missing keys
  - Responds to `respond_to_missing?` correctly
  - Exposes the raw hash via `to_h`
- `spec/walmart_api/paginated_response_spec.rb`
  - Exposes `next_cursor` when present in response
  - Returns nil for `next_cursor` when absent
  - Exposes list elements as wrapped Response objects
  - Is Enumerable (supports `each`, `map`, etc.)

**Acceptance criteria:**

- [ ] Base resource provides HTTP method helpers
- [ ] Response wrapper allows method-style access to API data
- [ ] CamelCase keys are accessible as snake_case methods
- [ ] Nested objects are recursively wrapped
- [ ] Paginated response supports cursor-based pagination
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes

---

### c011 — feat: add client

**Purpose:** Implement `WalmartApi::Client` — the main entry point. Builds the Faraday connection with the authentication and error-handling middleware, and exposes resource accessors.

**Design decisions:**

- Accepts optional keyword arguments to override global configuration
- Validates configuration (calls `validate!`) at initialization
- Builds one Faraday connection per client instance
- Lazy-initializes resource instances (`orders`, `inventory`, `items`)
- Resources receive the Faraday connection
- Connection middleware stack order:
  1. `Middleware::Authentication` (request)
  2. `Faraday::Request::Json` (request encoding)
  3. `Middleware::ErrorHandler` (response)
  4. `Faraday::Response::Json` (response parsing)
  5. Default adapter

**Files affected:**

| File | Action |
|---|---|
| `lib/walmart_api/client.rb` | Create — Client class |
| `lib/walmart_api.rb` | Modify — require client |

**Tests required:**

- `spec/walmart_api/client_spec.rb`
  - Initializes with global configuration
  - Initializes with explicit credentials (overrides global)
  - Raises `ConfigurationError` when required credentials are missing
  - Exposes `orders` accessor (returns resource instance)
  - Exposes `inventory` accessor (returns resource instance)
  - Exposes `items` accessor (returns resource instance)
  - Builds Faraday connection with correct base URL
  - Supports multiple clients with independent credentials
  - Lazy-initializes resources (same instance on repeated access)

**Acceptance criteria:**

- [ ] `WalmartApi::Client.new` works with global and explicit configuration
- [ ] Raises `ConfigurationError` early when misconfigured
- [ ] Exposes `orders`, `inventory`, `items` accessors
- [ ] Middleware stack is correctly ordered
- [ ] Multiple clients are independent
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes

---

### c012 — feat: add orders resource

**Purpose:** Implement `WalmartApi::Resources::Orders` — the Orders API resource per the public API design in `docs/api_examples.md`.

**Design decisions:**

- Inherits from `Resources::Base`
- `list` — GET `/v3/orders` with optional filters, returns `PaginatedResponse`
  - Filters: `status`, `created_start_date`, `created_end_date`, `limit`, `next_cursor`, `ship_node_type`
- `find(purchase_order_id)` — GET `/v3/orders/{purchaseOrderId}`, returns `Response`
- Parameter names in the public API use snake_case; they are converted to Walmart's camelCase for the HTTP request
- Response wrapping handles order lines, nested item data, charges, quantities

**Files affected:**

| File | Action |
|---|---|
| `lib/walmart_api/resources/orders.rb` | Create — Orders resource |
| `lib/walmart_api.rb` | Modify — require resources/orders |

**Tests required:**

- `spec/walmart_api/resources/orders_spec.rb`
  - `list` sends GET to `/v3/orders`
  - `list` passes status filter as query parameter
  - `list` passes `created_start_date` as `createdStartDate`
  - `list` passes `created_end_date` as `createdEndDate`
  - `list` passes `limit` parameter
  - `list` passes `next_cursor` parameter
  - `list` passes `ship_node_type` as `shipNodeType`
  - `list` returns a `PaginatedResponse`
  - `list` response includes `next_cursor` for pagination
  - `find` sends GET to `/v3/orders/{purchaseOrderId}`
  - `find` returns a `Response`
  - Response exposes `purchase_order_id`
  - Response exposes `customer_order_id`
  - Response exposes `order_date`
  - Response exposes nested `order_lines`
  - Order line exposes `line_number`, `item`, `charges`, `quantity`, `status`
  - Raises `NotFoundError` for nonexistent order (via error middleware)

**Acceptance criteria:**

- [ ] `client.orders.list` returns paginated orders
- [ ] `client.orders.list(status: "Created")` filters correctly
- [ ] `client.orders.find(id)` returns a single order
- [ ] Snake_case parameters are converted to camelCase
- [ ] Response objects support method-style access as shown in api_examples.md
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes

---

### c013 — feat: add inventory resource

**Purpose:** Implement `WalmartApi::Resources::Inventory` — the Inventory API resource per the public API design.

**Design decisions:**

- Inherits from `Resources::Base`
- `get(sku, ship_node: nil)` — GET `/v3/inventory` with `sku` query param, returns `Response`
- `update(sku, quantity:, ship_node: nil, inventory_available_date: nil)` — PUT `/v3/inventory` with JSON body, returns `Response`
- Request body for update follows Walmart's inventory update schema

**Files affected:**

| File | Action |
|---|---|
| `lib/walmart_api/resources/inventory.rb` | Create — Inventory resource |
| `lib/walmart_api.rb` | Modify — require resources/inventory |

**Tests required:**

- `spec/walmart_api/resources/inventory_spec.rb`
  - `get` sends GET to `/v3/inventory` with `sku` param
  - `get` passes `ship_node` as `shipNode` query param when provided
  - `get` returns a `Response`
  - Response exposes `sku`
  - Response exposes nested `quantity` with `unit` and `amount`
  - `update` sends PUT to `/v3/inventory`
  - `update` sends correct JSON body with SKU and quantity
  - `update` includes `ship_node` in request when provided
  - `update` includes `inventory_available_date` in request when provided
  - `update` returns a `Response`
  - Raises `ValidationError` for invalid quantity (via error middleware)
  - Raises `NotFoundError` for nonexistent SKU (via error middleware)

**Acceptance criteria:**

- [ ] `client.inventory.get("SKU")` returns inventory data
- [ ] `client.inventory.get("SKU", ship_node: "node")` passes ship node
- [ ] `client.inventory.update("SKU", quantity: 150)` updates inventory
- [ ] Update supports optional `ship_node` and `inventory_available_date`
- [ ] Response objects support method-style access
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes

---

### c014 — feat: add items resource

**Purpose:** Implement `WalmartApi::Resources::Items` — the Items API resource per the public API design.

**Design decisions:**

- Inherits from `Resources::Base`
- `list` — GET `/v3/items` with optional filters, returns `PaginatedResponse`
  - Filters: `lifecycle_status`, `published_status`, `limit`, `next_cursor`
- `find(sku)` — GET `/v3/items/{sku}`, returns `Response`
- Parameter names converted from snake_case to camelCase

**Files affected:**

| File | Action |
|---|---|
| `lib/walmart_api/resources/items.rb` | Create — Items resource |
| `lib/walmart_api.rb` | Modify — require resources/items |

**Tests required:**

- `spec/walmart_api/resources/items_spec.rb`
  - `list` sends GET to `/v3/items`
  - `list` passes `lifecycle_status` as `lifecycleStatus`
  - `list` passes `published_status` as `publishedStatus`
  - `list` passes `limit` parameter
  - `list` passes `next_cursor` parameter
  - `list` returns a `PaginatedResponse`
  - `list` response includes `next_cursor` for pagination
  - `find` sends GET to `/v3/items/{sku}`
  - `find` returns a `Response`
  - Response exposes `sku`
  - Response exposes `product_name`
  - Response exposes `product_type`
  - Response exposes nested `price` with `amount` and `currency`
  - Response exposes `published_status`
  - Response exposes `lifecycle_status`
  - Raises `NotFoundError` for nonexistent SKU (via error middleware)

**Acceptance criteria:**

- [ ] `client.items.list` returns paginated items
- [ ] `client.items.list(lifecycle_status: "ACTIVE")` filters correctly
- [ ] `client.items.find("SKU")` returns a single item
- [ ] Snake_case parameters are converted to camelCase
- [ ] Response objects support method-style access as shown in api_examples.md
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes

---

### c015 — build: finalize gemspec and update README

**Purpose:** Final polish. Update the README with real usage examples, ensure the gemspec is complete, and verify the full test suite and linter pass end-to-end.

**Files affected:**

| File | Action |
|---|---|
| `walmart_api.gemspec` | Modify — finalize summary, description, homepage, metadata |
| `README.md` | Modify — add installation instructions, configuration examples, usage examples for orders/inventory/items, error handling examples, link to Walmart docs |
| `lib/walmart_api.rb` | Verify — all requires are present and ordered correctly |

**Tests required:**

- Full suite regression: `bundle exec rspec` (all existing tests)
- `bundle exec rubocop` — zero offenses
- Manual verification: `require "walmart_api"` works from a clean IRB session

**Acceptance criteria:**

- [ ] README includes real usage examples matching the public API
- [ ] Gemspec has no TODO placeholders
- [ ] `gem build walmart_api.gemspec` succeeds
- [ ] Full `bundle exec rspec` passes
- [ ] Full `bundle exec rubocop` passes
- [ ] `require "walmart_api"` loads without errors

---

## Test Fixture Strategy

The following shared test fixtures should be established in c003 and used across all specs:

| Fixture | Location | Purpose |
|---|---|---|
| RSA test key pair | `spec/fixtures/test_private_key.pem` | Used by SignatureGenerator and TokenManager tests |
| Token response JSON | `spec/fixtures/token_response.json` | Stubbed OAuth token endpoint response |
| Order response JSON | `spec/fixtures/orders/single_order.json` | Stubbed single order response |
| Orders list JSON | `spec/fixtures/orders/order_list.json` | Stubbed orders list with pagination |
| Inventory response JSON | `spec/fixtures/inventory/inventory.json` | Stubbed inventory response |
| Item response JSON | `spec/fixtures/items/single_item.json` | Stubbed single item response |
| Items list JSON | `spec/fixtures/items/item_list.json` | Stubbed items list with pagination |
| Error response JSON | `spec/fixtures/errors/error_response.json` | Stubbed API error response body |

Fixture JSON files should be created in the commit where they are first used.

---

## Risk Register

| Risk | Impact | Mitigation |
|---|---|---|
| Walmart API documentation is ambiguous about request signing | Signature generation may not match expected format | Verify against Walmart developer portal; add integration test notes for manual verification |
| Token expiry race condition under high concurrency | Duplicate token requests | Mutex with double-check locking in TokenManager |
| camelCase ↔ snake_case conversion edge cases | Incorrect parameter names in API calls | Explicit parameter mapping in each resource (no generic converter) |
| Response structure varies between Walmart API versions | Response wrapper may miss fields | Response wrapper uses dynamic method access; no hardcoded field list |

---

## Summary

| Metric | Value |
|---|---|
| Total commits | 13 (c003–c015) |
| New Ruby source files | 12 |
| New spec files | 12+ |
| Runtime dependency | Faraday (~> 2.0) |
| Dev dependencies | RSpec, WebMock, VCR, Rubocop |
| Resources delivered | Orders, Inventory, Items |
