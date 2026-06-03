# Public API Design

This document defines the ideal public API for the walmart_api gem.

It covers v0.1.0 scope: Orders, Inventory, and Items.

These are usage examples only. No implementation code.

---

## Configuration

### Global Configuration

```ruby
WalmartApi.configure do |config|
  config.client_id = ENV.fetch("WALMART_CLIENT_ID")
  config.client_secret = ENV.fetch("WALMART_CLIENT_SECRET")
  config.private_key_path = "config/walmart_private_key.pem"
end
```

### Private Key As String

```ruby
WalmartApi.configure do |config|
  config.client_id = ENV.fetch("WALMART_CLIENT_ID")
  config.client_secret = ENV.fetch("WALMART_CLIENT_SECRET")
  config.private_key = ENV.fetch("WALMART_PRIVATE_KEY")
end
```

### Environment Override

```ruby
WalmartApi.configure do |config|
  config.client_id = ENV.fetch("WALMART_CLIENT_ID")
  config.client_secret = ENV.fetch("WALMART_CLIENT_SECRET")
  config.private_key_path = "config/walmart_private_key.pem"
  config.environment = :sandbox
end
```

Production is the default environment.

### Channel Type

```ruby
WalmartApi.configure do |config|
  config.client_id = ENV.fetch("WALMART_CLIENT_ID")
  config.client_secret = ENV.fetch("WALMART_CLIENT_SECRET")
  config.private_key_path = "config/walmart_private_key.pem"
  config.channel_type = ENV.fetch("WALMART_CHANNEL_TYPE")
end
```

---

## Client Initialization

### Using Global Configuration

```ruby
client = WalmartApi::Client.new
```

### Using Explicit Credentials

```ruby
client = WalmartApi::Client.new(
  client_id: ENV.fetch("WALMART_CLIENT_ID"),
  client_secret: ENV.fetch("WALMART_CLIENT_SECRET"),
  private_key_path: "config/walmart_private_key.pem"
)
```

Explicit credentials override global configuration.

This supports multiple seller accounts in the same process.

### Multiple Clients

```ruby
seller_a = WalmartApi::Client.new(
  client_id: ENV.fetch("SELLER_A_CLIENT_ID"),
  client_secret: ENV.fetch("SELLER_A_CLIENT_SECRET"),
  private_key_path: "config/seller_a_key.pem"
)

seller_b = WalmartApi::Client.new(
  client_id: ENV.fetch("SELLER_B_CLIENT_ID"),
  client_secret: ENV.fetch("SELLER_B_CLIENT_SECRET"),
  private_key_path: "config/seller_b_key.pem"
)
```

Each client manages its own authentication tokens independently.

---

## Orders

Corresponds to Walmart Marketplace Orders API.

### List Orders

```ruby
orders = client.orders.list
```

### List Orders With Filters

```ruby
orders = client.orders.list(
  status: "Created",
  created_start_date: "2025-01-01T00:00:00.000Z",
  limit: 50
)
```

```ruby
orders = client.orders.list(
  status: "Acknowledged",
  created_start_date: "2025-06-01T00:00:00.000Z",
  created_end_date: "2025-06-07T23:59:59.000Z"
)
```

```ruby
orders = client.orders.list(
  status: "Shipped",
  ship_node_type: "SellerFulfilled"
)
```

### Pagination

```ruby
page = client.orders.list(limit: 20)

while page.next_cursor
  page = client.orders.list(limit: 20, next_cursor: page.next_cursor)
end
```

### Get A Single Order

```ruby
order = client.orders.find("2577374099943")
```

### Access Order Fields

```ruby
order = client.orders.find("2577374099943")

order.purchase_order_id
order.customer_order_id
order.customer_email_id
order.order_date
order.estimated_delivery_date
order.estimated_ship_date
order.order_lines
```

### Access Order Lines

```ruby
order = client.orders.find("2577374099943")

order.order_lines.each do |line|
  line.line_number
  line.item.product_name
  line.item.sku
  line.charges
  line.quantity.unit_of_measurement
  line.quantity.amount
  line.status
  line.status_date
end
```

---

## Inventory

Corresponds to Walmart Marketplace Inventory API.

### Get Inventory For A SKU

```ruby
inventory = client.inventory.get("SKU-1234")
```

### Get Inventory With Ship Node

```ruby
inventory = client.inventory.get("SKU-1234", ship_node: "node_123")
```

### Access Inventory Fields

```ruby
inventory = client.inventory.get("SKU-1234")

inventory.sku
inventory.quantity.unit
inventory.quantity.amount
```

### Update Inventory

```ruby
client.inventory.update("SKU-1234", quantity: 150)
```

### Update Inventory With Ship Node

```ruby
client.inventory.update("SKU-1234", quantity: 150, ship_node: "node_123")
```

### Update Inventory With Available Date

```ruby
client.inventory.update(
  "SKU-1234",
  quantity: 75,
  inventory_available_date: "2025-07-15T00:00:00.000Z"
)
```

---

## Items

Corresponds to Walmart Marketplace Items API.

### List Items

```ruby
items = client.items.list
```

### List Items With Filters

```ruby
items = client.items.list(
  lifecycle_status: "ACTIVE",
  limit: 20
)
```

```ruby
items = client.items.list(
  published_status: "PUBLISHED",
  limit: 50
)
```

### Pagination

```ruby
page = client.items.list(limit: 20)

while page.next_cursor
  page = client.items.list(limit: 20, next_cursor: page.next_cursor)
end
```

### Get A Single Item

```ruby
item = client.items.find("SKU-1234")
```

### Access Item Fields

```ruby
item = client.items.find("SKU-1234")

item.sku
item.product_name
item.product_type
item.price.amount
item.price.currency
item.published_status
item.lifecycle_status
```

---

## Error Handling

### Catch All API Errors

```ruby
begin
  order = client.orders.find("2577374099943")
rescue WalmartApi::ApiError => e
  e.status
  e.correlation_id
  e.body
  e.message
end
```

All domain exceptions inherit from WalmartApi::ApiError.

### Authentication Errors

```ruby
begin
  orders = client.orders.list
rescue WalmartApi::AuthenticationError => e
  log_error("Authentication failed", correlation_id: e.correlation_id)
end
```

Raised when credentials are invalid or the OAuth token cannot be obtained.

HTTP status: 401.

### Authorization Errors

```ruby
begin
  orders = client.orders.list
rescue WalmartApi::AuthorizationError => e
  log_error("Insufficient permissions", correlation_id: e.correlation_id)
end
```

Raised when the authenticated seller lacks permission for the requested resource.

HTTP status: 403.

### Rate Limit Errors

```ruby
begin
  orders = client.orders.list
rescue WalmartApi::RateLimitError => e
  e.retry_after
  sleep(e.retry_after)
  retry
end
```

Raised when Walmart throttles the request.

HTTP status: 429.

### Validation Errors

```ruby
begin
  client.inventory.update("SKU-1234", quantity: -5)
rescue WalmartApi::ValidationError => e
  e.status
  e.body
  e.message
end
```

Raised when the request contains invalid data.

HTTP status: 400.

### Server Errors

```ruby
begin
  order = client.orders.find("2577374099943")
rescue WalmartApi::ServerError => e
  log_error("Walmart API unavailable", correlation_id: e.correlation_id)
end
```

Raised when Walmart returns a 5xx response.

HTTP status: 500, 502, 503, 504.

### Not Found Errors

```ruby
begin
  order = client.orders.find("nonexistent_id")
rescue WalmartApi::NotFoundError => e
  e.status
  e.correlation_id
end
```

Raised when the requested resource does not exist.

HTTP status: 404.

### Granular Error Handling

```ruby
begin
  order = client.orders.find("2577374099943")
rescue WalmartApi::AuthenticationError
  reauthenticate_and_retry
rescue WalmartApi::RateLimitError => e
  sleep(e.retry_after)
  retry
rescue WalmartApi::NotFoundError
  nil
rescue WalmartApi::ServerError
  notify_oncall_team
rescue WalmartApi::ApiError => e
  log_error("Unexpected API error", status: e.status, correlation_id: e.correlation_id)
end
```

### Error Attributes

Every exception exposes:

```ruby
rescue WalmartApi::ApiError => e
  e.status           # HTTP status code (Integer)
  e.correlation_id   # Walmart correlation ID (String)
  e.body             # Parsed response body (Hash)
  e.message          # Human-readable error message (String)
end
```

RateLimitError additionally exposes:

```ruby
rescue WalmartApi::RateLimitError => e
  e.retry_after      # Seconds to wait before retrying (Integer)
end
```

---

## Exception Hierarchy

```
WalmartApi::Error
  WalmartApi::ConfigurationError
  WalmartApi::ApiError
    WalmartApi::AuthenticationError   (401)
    WalmartApi::AuthorizationError    (403)
    WalmartApi::NotFoundError         (404)
    WalmartApi::ValidationError       (400)
    WalmartApi::RateLimitError        (429)
    WalmartApi::ServerError           (5xx)
```

WalmartApi::Error is the root. It catches everything from this gem.

WalmartApi::ConfigurationError is raised before any HTTP call when required configuration is missing.

WalmartApi::ApiError is the base for all HTTP-related errors.

---

## Configuration Errors

```ruby
begin
  client = WalmartApi::Client.new
rescue WalmartApi::ConfigurationError => e
  e.message  # "client_id is required"
end
```

Raised at client initialization when required credentials are missing.

---

## Rails Integration

### Initializer

```ruby
# config/initializers/walmart_api.rb

WalmartApi.configure do |config|
  config.client_id = Rails.application.credentials.dig(:walmart, :client_id)
  config.client_secret = Rails.application.credentials.dig(:walmart, :client_secret)
  config.private_key_path = Rails.root.join("config", "walmart_private_key.pem")
end
```

### Usage In A Controller

```ruby
client = WalmartApi::Client.new
orders = client.orders.list(status: "Created", limit: 10)
```

### Usage In A Service Object

```ruby
class OrderSyncService
  def initialize
    @client = WalmartApi::Client.new
  end

  def sync_recent_orders
    @client.orders.list(
      status: "Created",
      created_start_date: 24.hours.ago.iso8601
    )
  end
end
```
