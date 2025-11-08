# Product Deals Strategy

**Version:** 1.0  
**Last Updated:** November 2025  
**Status:** Active

## Overview

Instead of bundling add-ons together, StoryPad uses **promotional deals** on individual add-ons. This approach allows unlimited scalability as your add-on catalog grows, while maintaining the simplicity and user-friendly positioning.

## Why Deals Instead of Bundles?

### Problem with Bundles

- **Hard to scale:** Adding the 5th add-on makes bundle pricing confusing
  - Do you lower bundle price? Users feel nickeled-and-dimed
  - Do you keep it the same? New customers feel cheated vs. old prices
  - Do you increase it? People see a "worse deal" over time
- **Forces all-in purchases:** Customers must buy features they don't want
- **Reduces flexibility:** Harder to adjust pricing strategy later

### Why Deals Work Better

✅ **Infinitely scalable** – Add 10 more add-ons, no pricing confusion  
✅ **Individual choice** – Each customer pays only for what they want  
✅ **Flexible promotions** – Can run sales on specific add-ons anytime  
✅ **Aligns with brand** – Minimalist approach: "only what you need"  
✅ **Easy to explain** – "$1.99 each, currently 30% off Voice Journal"  
✅ **Data-driven** – Track which add-ons sell best at different discounts

## Technical Implementation

### How Deals Work

Deals are managed via **Firebase Remote Config** and applied dynamically:

```dart
// ProductDealObject handles the discount logic
final discountedPrice = storeProduct.price;
final convertedToOriginalPrice = discountedPrice / (1 - discountPercentage / 100);

// Display shows both prices:
// "Pay $1.39" (discounted)
// "Was $1.99" (strikethrough original)
// "30% OFF" (badge)
```

### Remote Config Structure

Deals are stored in Remote Config as JSON:

```json
{
  "deals": [
    {
      "product": "voice_journal",
      "discount_percentage": 30,
      "start_date": "2024-11-01T00:00:00Z",
      "end_date": "2024-11-30T23:59:59Z"
    },
    {
      "product": "templates",
      "discount_percentage": 40,
      "start_date": "2024-12-01T00:00:00Z",
      "end_date": "2024-12-31T23:59:59Z"
    }
  ]
}
```

### Key Features

| Feature               | Details                                                             |
| --------------------- | ------------------------------------------------------------------- |
| **Timezone handling** | Dates convert to local time automatically                           |
| **Active check**      | Only deals where `now` is between `start_date` and `end_date` apply |
| **Multiple deals**    | Can run simultaneous deals on different add-ons                     |
| **No deals period**   | If no deals are active, prices show full $1.99                      |
| **Real-time updates** | Remote Config syncs without app restart                             |

## Usage Examples

### Example 1: Black Friday Campaign

```json
{
  "deals": [
    {
      "product": "voice_journal",
      "discount_percentage": 50,
      "start_date": "2024-11-29T00:00:00Z",
      "end_date": "2024-12-02T23:59:59Z"
    },
    {
      "product": "templates",
      "discount_percentage": 50,
      "start_date": "2024-11-29T00:00:00Z",
      "end_date": "2024-12-02T23:59:59Z"
    },
    {
      "product": "relax_sounds",
      "discount_percentage": 50,
      "start_date": "2024-11-29T00:00:00Z",
      "end_date": "2024-12-02T23:59:59Z"
    }
  ]
}
```

### Example 2: Staggered Seasonal Deals

```json
{
  "deals": [
    {
      "product": "voice_journal",
      "discount_percentage": 25,
      "start_date": "2024-11-01T00:00:00Z",
      "end_date": "2024-11-15T23:59:59Z"
    },
    {
      "product": "templates",
      "discount_percentage": 25,
      "start_date": "2024-11-16T00:00:00Z",
      "end_date": "2024-11-30T23:59:59Z"
    },
    {
      "product": "relax_sounds",
      "discount_percentage": 25,
      "start_date": "2024-12-01T00:00:00Z",
      "end_date": "2024-12-15T23:59:59Z"
    }
  ]
}
```

## Guidelines for Running Deals

### Best Practices

1. **Frequency** – Monthly or quarterly promotional windows work best
2. **Duration** – 1-2 week promotions drive urgency without annoying users
3. **Discount % ** – 20-50% range feels right (not too aggressive, not wimpy)
4. **Rotation** – Rotate which add-ons are on sale to boost different products
5. **Staggering** – Avoid putting all add-ons on sale simultaneously (except mega events)

### What NOT to Do

❌ Running deals back-to-back (trains users to wait for discounts)  
❌ Deep discounts every week (devalues your products)  
❌ No deals ever (misses revenue opportunity)  
❌ Unclear deal end dates (users lose urgency to buy)

## Scalability Math

### With 4 Add-ons

- Base revenue: 4 × $1.99 = $7.96 per customer (if all purchased)
- With deals: Rotate which ones are on sale, drive sequential purchases

### With 10 Add-ons (future)

- Base revenue: 10 × $1.99 = $19.90 per customer (theoretical max)
- **No pricing chaos** – Still just "$1.99 each, [X] is currently 30% off"
- Deal rotation becomes more powerful with more options

### With Bundles (anti-pattern)

- 4 add-ons: Bundle at $4.99 (saves user $2.97) ❌ Confusing math
- 10 add-ons: Bundle at $9.99? (saves user $9.91) ❌ Impossible to price fairly
- Each new add-on breaks old bundle pricing ❌ Not scalable

## Implementation Details

### Files Involved

- **`lib/core/objects/product_deal_object.dart`** – Core deal logic
  - Parses Remote Config JSON
  - Calculates display prices
  - Checks if deal is active
- **`lib/views/add_ons/add_ons_view_model.dart`** – UI integration

  - Fetches active deals
  - Displays discount badges ("30% OFF")
  - Shows both original and discounted prices

- **`lib/core/services/remote_config/remote_config_service.dart`** – Remote Config integration
  - Manages `productDeals` parameter
  - Syncs deals on app startup

### How to Run a Deal

1. Open Firebase Console → Remote Config
2. Update `productDeals` JSON parameter (above structure)
3. Set `start_date` and `end_date` for timezone-aware scheduling
4. Publish changes (app fetches on next startup)

## Metrics to Track

- **Conversion rate per add-on** (with vs. without discount)
- **Average discount % that drives purchases** (A/B test 20% vs. 30% vs. 50%)
- **Seasonal trends** (which add-ons sell best when)
- **Deal fatigue** (do frequent deals reduce full-price purchases?)

## Future Enhancements

- **A/B testing deals** – Run different discounts for different user segments
- **AI-driven pricing** – Adjust discounts based on user cohorts
- **Time-based pricing** – Different deals for users in different time zones
- **Limited quantity deals** – "Only 50 copies available" for scarcity pricing
