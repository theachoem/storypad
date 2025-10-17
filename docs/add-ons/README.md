# Add-ons

StoryPad offers optional add-ons to enhance your writing experience while keeping the app sustainable.

## Philosophy

StoryPad doesn't run ads. We don't sell your data. We don't have a subscription model. These add-ons are our way of keeping the app sustainable while giving you tools that genuinely enhance your experience.

## Available Add-ons

- **[Relaxing Sounds](./relaxing-sounds.md)** — Set the mood before you write or read. — **$0.99**
- **[Templates](./templates.md)** — Create your own daily writing templates. — **$0.99**
- **[Period Calendar](./period-calendar.md)** — Track your period and create related story entries. — **$0.99**

## Pricing Model

Each add-on is available as a one-time purchase. No subscriptions, no recurring fees.

## Technical Implementation

### In-App Purchase System

- Uses **RevenueCat** for cross-platform purchase management
- Product identifiers defined in `lib/core/types/app_product.dart`
- Purchase provider: `lib/providers/in_app_purchase_provider.dart`
- Privacy-focused: Only hashed email identifiers are stored, never your actual email

### Add-on Management

- Main view: `lib/views/add_ons/add_ons_view.dart`
- View model: `lib/views/add_ons/add_ons_view_model.dart`
- Add-on object model: `lib/core/objects/add_on_object.dart`

### Reward System

Users can unlock add-ons temporarily or permanently through reward codes:

- Share story to social media → Get 1 FREE add-on
- Share relax sound mix to social media → Get 1 FREE add-on

## Related Files

```
lib/
├── core/
│   ├── objects/
│   │   └── add_on_object.dart
│   └── types/
│       └── app_product.dart
├── providers/
│   └── in_app_purchase_provider.dart
└── views/
    └── add_ons/
        ├── add_ons_view.dart
        ├── add_ons_view_model.dart
        └── show/
            ├── show_add_on_view.dart
            └── show_add_on_view_model.dart
```
