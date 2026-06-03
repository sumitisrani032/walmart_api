# ADR-003: Resource Architecture

Status: Accepted

## Context

The Walmart Marketplace API contains multiple business domains.

## Decision

Resources should be organized by domain.

Examples:

* Orders
* Inventory
* Items
* Returns
* Feeds

Usage:

```ruby
client.orders.list
client.inventory.get(sku)
client.items.find(item_id)
```

Each resource inherits from a shared base resource.

## Consequences

Positive:

* Consistent API
* Easier discoverability
* Shared request logic

Negative:

* Additional abstraction layer
