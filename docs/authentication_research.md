# Walmart Marketplace Authentication Research

Status: Complete

Research conducted: 2026-06-04

---

## Sources

| Source | URL |
|---|---|
| Developer Portal | https://developer.walmart.com/ |
| Marketplace Docs | https://developer.walmart.com/us-marketplace/docs |
| Authentication Guide | https://developer.walmart.com/us-marketplace/docs/authentication |
| Get An Access Token | https://developer.walmart.com/us-marketplace/docs/get-an-access-token |
| Token API Reference | https://developer.walmart.com/us-marketplace/reference/tokenapi |
| OAuth 2.0 Authorization | https://developer.walmart.com/us-marketplace/docs/oauth-20-authorization |
| Sandbox Testing | https://developer.walmart.com/us-marketplace/docs/test-marketplace-apis |
| Dynamic Sandbox | https://developer.walmart.com/us-marketplace/docs/dynamic-sandbox |
| Sandbox Throttling | https://developer.walmart.com/us-marketplace/docs/sandbox-throttling-limits |
| Orders API Reference | https://developer.walmart.com/us-marketplace/reference/getallorders |
| Inventory API Reference | https://developer.walmart.com/us-marketplace/reference/getinventory |
| Items API Reference | https://developer.walmart.com/us-marketplace/reference/getanitem |

---

## OAuth 2.0 Flow

Walmart Marketplace uses OAuth 2.0 for authentication. All API access requires a valid access token obtained from the token endpoint.

### Token Endpoint

```
POST https://marketplace.walmartapis.com/v3/token
```

### Supported Grant Types

| Grant Type | Use Case |
|---|---|
| `client_credentials` | Direct seller access using Client ID and Client Secret. This is the default and the primary flow for this gem. |
| `authorization_code` | Solution providers acting on behalf of a seller after authorization. Requires `code` and `redirect_uri` parameters. |
| `refresh_token` | Obtaining a new access token using a refresh token. Only applicable to the `authorization_code` flow. |

### Client Credentials Request

This is the flow relevant to v0.1.0.

**Request:**

```
POST https://marketplace.walmartapis.com/v3/token
Authorization: Basic base64(client_id:client_secret)
Content-Type: application/x-www-form-urlencoded
Accept: application/json
WM_QOS.CORRELATION_ID: <unique-identifier>
WM_SVC.NAME: Walmart Marketplace

grant_type=client_credentials
```

**Curl example from Walmart documentation:**

```bash
curl --request POST \
  --url https://marketplace.walmartapis.com/v3/token \
  --header 'Authorization: Basic eW91cl9pZDp5b3VyX3NlY3JldA==' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data 'grant_type=client_credentials'
```

### Token Request Headers

| Header | Required | Description |
|---|---|---|
| `Authorization` | Yes | Basic auth. Value: `Basic base64(client_id:client_secret)` |
| `Content-Type` | Yes | Must be `application/x-www-form-urlencoded` |
| `WM_QOS.CORRELATION_ID` | Yes | Unique identifier for the request |
| `WM_SVC.NAME` | Yes | Service name. Value: `Walmart Marketplace` |
| `WM_PARTNER.ID` | No | Partner ID (solution providers) |
| `WM_CONSUMER.CHANNEL.TYPE` | No | Channel type identifier |
| `Accept` | No | Response format. Defaults to `application/json`. Also supports `application/xml`. |

### Token Response

**HTTP Status:** 200

```json
{
  "access_token": "eyJraWQiOiI1MWY3MjM0Ny0wYWY5LTRhZ.....",
  "token_type": "Bearer",
  "expires_in": 900
}
```

| Field | Type | Description |
|---|---|---|
| `access_token` | String | JWT access token. Use this in subsequent API calls. |
| `token_type` | String | Always `"Bearer"`. |
| `expires_in` | Integer | Token lifetime in seconds. Value: `900` (15 minutes). |
| `refresh_token` | String | Only returned in the `authorization_code` flow. Not returned for `client_credentials`. |

---

## Token Lifecycle

| Property | Value |
|---|---|
| Access token lifetime | 15 minutes (900 seconds) |
| Refresh token lifetime | 1 year (365 days). Only for `authorization_code` flow. |
| Token type | Bearer (JWT) |

### Caching And Refresh Rules

1. Cache the access token after acquisition.
2. Track expiry using the `expires_in` field.
3. Refresh the token before it expires. Recommended: refresh 60 seconds before expiry to avoid edge cases.
4. The `client_credentials` flow does not return a refresh token. To get a new token, repeat the `client_credentials` request.
5. The gem must handle `expires_in` correctly to avoid using expired tokens.

### Thread Safety

Multiple threads may share a client instance. The token manager must:

1. Use a mutex to protect token state.
2. Avoid duplicate token requests under concurrent access.
3. Use double-checked locking: check expiry before and after acquiring the lock.

---

## Required Headers For API Calls

After obtaining an access token, every API request must include the following headers.

### Headers From API Reference Pages

The API reference pages (Orders, Inventory, Items) consistently list these headers:

| Header | Required | Type | Description |
|---|---|---|---|
| `WM_SEC.ACCESS_TOKEN` | Yes | String | The OAuth access token obtained from the token endpoint. |
| `WM_QOS.CORRELATION_ID` | Yes | String | Unique identifier for the request. Used for debugging and tracing. |
| `WM_SVC.NAME` | Yes | String | Service name. Observed value: `Walmart Marketplace`. |
| `WM_CONSUMER.CHANNEL.TYPE` | No | String | Channel type identifier. Set by the developer. |
| `WM_SANDBOX` | No | Enum | Sandbox mode. Value `v2` enables dynamic sandbox. See sandbox section below. |
| `Accept` | No | String | Response format. Default: `application/json`. Also supports `application/xml`. |
| `Content-Type` | Conditional | String | Required for requests with a body (POST, PUT). Value: `application/json`. |

### Header Format Discrepancy

There is a discrepancy in the official documentation:

- **API reference pages** list `WM_SEC.ACCESS_TOKEN` as the header for the access token.
- **Sandbox testing guide** shows `Authorization: Bearer <access_token>` as the header.

Both formats may be accepted. The API reference pages are the more authoritative source for header names. The gem should use `WM_SEC.ACCESS_TOKEN` as the primary format, matching the API reference documentation.

### Correlation ID

- Must be unique per request.
- Format: UUID recommended (e.g., `550e8400-e29b-41d4-a716-446655440000`).
- Returned in error responses for debugging.
- Generate using `SecureRandom.uuid`.

---

## RSA Digital Signature Requirement

### Critical Finding: Current v3 API Does Not Document RSA Signatures

After reviewing all accessible official documentation, no reference was found to:

- `WM_SEC.AUTH_SIGNATURE` header
- `WM_SEC.TIMESTAMP` header
- RSA-SHA256 request signing
- Private key requirements for API requests
- Consumer ID or key version parameters

The OAuth 2.0 authorization documentation explicitly states:

> "This token-based authentication process reduces the number of required headers per API call."

This language suggests the OAuth flow replaced an earlier, more complex signature-based authentication mechanism.

### Historical Context

Earlier versions of the Walmart Marketplace API (pre-v3, before the OAuth 2.0 migration) required RSA-SHA256 digital signatures on every request. This involved:

- A consumer ID issued by Walmart
- A private key generated by the developer
- Signing a concatenation of consumer ID, timestamp, and key version
- Sending the signature in `WM_SEC.AUTH_SIGNATURE`
- Sending the timestamp in `WM_SEC.TIMESTAMP`

### Discrepancy With ADR-002

ADR-002 specifies:

> Walmart Marketplace APIs require:
> * OAuth Access Token
> * RSA Request Signature

And includes `Auth::SignatureGenerator` as a planned component.

The `docs/api_examples.md` file includes `private_key_path` and `private_key` in the configuration examples.

**This conflicts with the current official documentation, which does not mention RSA signatures.**

### Recommendation

Before implementation, this discrepancy must be resolved:

1. **Verify with Walmart**: Confirm whether the current v3 API requires RSA signatures for sellers using `client_credentials`.
2. **Test with live credentials**: Make a request without signature headers. If it succeeds, signatures are not required.
3. **Review ADR-002**: If RSA signatures are confirmed unnecessary, update ADR-002 to remove `SignatureGenerator` and simplify the architecture.
4. **If signatures ARE required**: The documentation may be behind a login wall or in a section not publicly accessible. In this case, preserve ADR-002 as-is and implement signing.

Until confirmed, the implementation plan should treat RSA signatures as a conditional feature. The architecture should support adding them later without breaking changes.

---

## Sandbox vs Production

### Base URLs

| Environment | Base URL |
|---|---|
| Production | `https://marketplace.walmartapis.com` |
| Sandbox | `https://sandbox.walmartapis.com` |

Both environments use the same path structure (e.g., `/v3/orders`, `/v3/token`).

### Sandbox Modes

Walmart provides two sandbox modes, controlled by the `WM_SANDBOX` header:

| Mode | WM_SANDBOX Header | Description |
|---|---|---|
| Static | Absent or null | Returns non-customizable mock datasets. Pre-populated responses. |
| Dynamic | `v2` | Allows custom test data creation. Simulates end-to-end flows. |

### Sandbox Authentication

The sandbox uses the same OAuth flow as production:

- Same token endpoint path: `/v3/token`
- Same client credentials
- Same header requirements
- Full sandbox token URL: `https://sandbox.walmartapis.com/v3/token`

### Sandbox Constraints

| Constraint | Value |
|---|---|
| Feed requests | 30 per hour (Items, Prices, Promotion, Inventory, Lag Time, Returns/Refunds) |
| API calls (dynamic) | 5-50 per hour depending on operation |
| Refund operations | 10 per hour |
| Max test items | 25 (dynamic sandbox) |
| Max test orders | 25 (dynamic sandbox) |
| Fulfillment centers | 1 (dynamic sandbox) |
| Data lifecycle | All sandbox data deleted every 2 days |
| Max file size | Varies: 2 KB to 100 KB per feed type |
| Processing time | Up to 30 minutes per feed request |

### Rate Limit Error

Exceeding sandbox throttling limits returns HTTP 429 Too Many Requests.

### Configuration Impact

The gem needs:

- An `environment` configuration option (`:production` or `:sandbox`)
- Environment determines the base URL
- No special sandbox headers are needed for static sandbox
- Dynamic sandbox requires `WM_SANDBOX: v2` header (consider as a future enhancement, not v0.1.0 scope)

---

## Error Responses From Authentication

### Token Endpoint Errors

| Scenario | Expected HTTP Status | Exception |
|---|---|---|
| Invalid client_id or client_secret | 401 | `AuthenticationError` |
| Missing required headers | 400 | `ValidationError` |
| Rate limited | 429 | `RateLimitError` |
| Walmart server error | 500/502/503/504 | `ServerError` |

### API Call Authentication Errors

| Scenario | Expected HTTP Status | Exception |
|---|---|---|
| Expired access token | 401 | `AuthenticationError` |
| Invalid access token | 401 | `AuthenticationError` |
| Insufficient permissions | 403 | `AuthorizationError` |

---

## Architecture Impact

### Confirmed Requirements

These components are confirmed necessary by official documentation:

| Component | ADR-002 Name | Status |
|---|---|---|
| OAuth token acquisition | `Auth::TokenManager` | Confirmed |
| Token caching with expiry | `Auth::TokenManager` | Confirmed |
| Thread-safe token refresh | `Auth::TokenManager` | Confirmed |
| Authentication header injection | `Middleware::WalmartAuth` | Confirmed |
| Correlation ID generation | `Middleware::WalmartAuth` | Confirmed |

### Unconfirmed Requirements

These components are specified in ADR-002 but not supported by current documentation:

| Component | ADR-002 Name | Status |
|---|---|---|
| RSA request signing | `Auth::SignatureGenerator` | Not found in current docs |
| Private key configuration | `Configuration` | Not found in current docs |

### Implementation Notes

1. **TokenManager** should use a standalone Faraday connection (not the main connection with auth middleware) to avoid circular dependency. The token endpoint uses Basic auth, not the `WM_SEC.ACCESS_TOKEN` header.

2. **Authentication middleware** should inject at minimum:
   - `WM_SEC.ACCESS_TOKEN` (from TokenManager)
   - `WM_QOS.CORRELATION_ID` (generated per request)
   - `WM_SVC.NAME` (configured or defaulted to `Walmart Marketplace`)
   - `WM_CONSUMER.CHANNEL.TYPE` (from configuration, if set)

3. **Configuration** should support:
   - `client_id` (required)
   - `client_secret` (required)
   - `environment` (`:production` or `:sandbox`, default `:production`)
   - `channel_type` (optional)
   - `private_key` / `private_key_path` (defer until RSA requirement is confirmed)

4. **Base URL resolution** is straightforward: environment maps directly to a base URL. No header-based environment switching needed for v0.1.0.

---

## Summary Of Findings

### Confirmed

1. OAuth 2.0 `client_credentials` flow is the authentication mechanism for sellers.
2. Token endpoint: `POST https://marketplace.walmartapis.com/v3/token`.
3. Authorization for token request: `Basic base64(client_id:client_secret)`.
4. Token response includes `access_token`, `token_type`, `expires_in`.
5. Access tokens expire in 15 minutes (900 seconds).
6. Required API headers: `WM_SEC.ACCESS_TOKEN`, `WM_QOS.CORRELATION_ID`, `WM_SVC.NAME`.
7. Optional API header: `WM_CONSUMER.CHANNEL.TYPE`.
8. Sandbox base URL: `https://sandbox.walmartapis.com`.
9. Production base URL: `https://marketplace.walmartapis.com`.
10. Sandbox uses `WM_SANDBOX: v2` header for dynamic mode.
11. Sandbox throttling: 30 requests/hour for feeds, 5-50/hour for other APIs.
12. Rate limit exceeded returns HTTP 429.

### Requires Resolution Before Implementation

1. **RSA digital signature requirement** conflicts between ADR-002 and current official documentation. See detailed analysis above.
2. **Header format for access token**: `WM_SEC.ACCESS_TOKEN` vs `Authorization: Bearer`. API reference pages favor `WM_SEC.ACCESS_TOKEN`.
