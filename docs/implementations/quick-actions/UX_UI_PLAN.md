# Quick Actions UX/UI Plan

Plan for a StoryPad home-screen quick actions customization experience. This is UX/UI planning only; platform shortcut registration, persistence, paid entitlement checks, and navigation behavior can be implemented in later phases.

## Product Goal

Let users choose the actions that appear when they long-press the StoryPad app icon from their phone home screen, so common journaling flows can start without first opening the full app.

## User Value

- Start a new story faster.
- Capture time-sensitive memories with photo or voice entry.
- Open frequently used templates directly.
- Jump into a meaningful tag, such as Travel, Family, Health, or Gratitude.
- Understand what will appear on the phone home screen before saving changes.

## Scope

### In Scope For UX/UI

- Customization screen layout.
- Native-looking quick action preview.
- Enabled action list with remove and reorder affordances.
- Available action picker grouped by category.
- Template selection through the existing Templates view opened as a picker sheet.
- Free vs paid visual treatment for template and tag actions.
- Empty, full-limit, locked, and no-content states.
- Copy, icon, and hierarchy recommendations.

### Out Of Scope For This Plan

- Native iOS/Android shortcut API wiring.
- Data model and persistence.
- Subscription purchase flow implementation.
- Actual story, photo, voice, template, or tag routing.
- Analytics implementation.

## Naming

Recommended user-facing title: **Home Quick Actions**

Recommended route/view name for later implementation: `HomeQuickActionsView`

Recommended folder for later implementation: `lib/views/home_quick_actions/`

Rationale: "Home Quick Actions" is clearer than "Quick Actions" because it explains where the actions live. It also avoids making the screen feel like a generic in-app shortcut manager.

## Action Types

| Type     | Example Label    | Availability       | Expected Result Later                              |
| -------- | ---------------- | ------------------ | -------------------------------------------------- |
| Default  | New Story        | Free               | Opens editor for a blank story                     |
| Default  | Take Photo       | Free               | Opens photo capture/import flow                    |
| Default  | Record Voice     | Free               | Opens voice recording flow                         |
| Template | Daily Reflection | Paid customization | Opens editor from selected template                |
| Template | Travel Log       | Paid customization | Opens editor from selected gallery/custom template |
| Tag      | Gratitude        | Paid customization | Opens the tag detail/story list view               |

## Platform Constraints

- Device support varies; design for a configurable limit between 5 and 10 actions.
- The UI should show the current limit as capacity, for example `3 of 5 used`.
- Default actions should remain available for all users.
- Template and tag shortcut customization should show as paid when unavailable.
- iOS and Android preview styling should feel native, but the customization screen itself should remain consistent with StoryPad.

## Core Screen Structure

All concepts should contain these functional regions:

1. Native Preview
   - App icon anchored visually like a phone home-screen item.
   - Shortcut menu layered above or beside the icon, matching platform direction.
   - Uses platform-like typography: Android can reference Google Sans; iOS can use a Google Font with similar proportions to San Francisco if needed.
   - Shows the enabled action order exactly as the platform would expose it.

2. Enabled Actions
   - Shows current active shortcuts in order.
   - Supports remove.
   - Later phase can add drag reorder.
   - Shows capacity and full-limit state.

3. Available Actions
   - Grouped by Default Actions, Templates, and Tags.
   - Each row has icon, label, short supporting text when helpful, and add/locked state.
   - Templates should not be listed inline; use a single template picker row that opens the existing Templates view in a sheet.
   - Paid-only categories use a subtle lock treatment and upgrade affordance.

4. Footer / Save Behavior
   - For UX-only prototype, a sticky `Done` or `Save` button can be shown.
   - Later implementation should decide between instant apply and explicit save based on native shortcut API behavior.

## Design Concept 1: Preview-First Studio

### Layout

A vertically scrolling page with a large native preview at the top, followed by enabled actions, then available action categories.

```
Home Quick Actions
[capacity: 3 of 5 used]

┌─────────────────────────────┐
│ Native Preview              │
│   shortcut menu             │
│        StoryPad icon        │
└─────────────────────────────┘

Enabled Actions
[New Story]      [remove]
[Take Photo]     [remove]
[Record Voice]   [remove]

Add Actions
[New Story]        [add]
[Take Photo]       [add]
[Record Voice]     [add]
[Choose Template]  [lock/add]
[Tags]
```

### Visual Style

- Calm, preview-led, and familiar.
- Preview uses a soft phone-home-screen surface rather than a decorative card-heavy page.
- Enabled rows are compact list tiles.
- Category headers are quiet and scannable.
- Paid content uses a lock icon, disabled add button, and small upgrade text.

### Strengths

- Easiest concept for users to understand immediately.
- Makes the native outcome visible before the configuration details.
- Works well for first release because the mental model is simple.
- Scales naturally to Android/iOS preview switching.

### Risks

- The available action list can become long when users have many tags.
- Needs good search or filtering in a later phase if the tag list grows.

### Best For

Initial release and broad user comprehension.

## Design Concept 2: Two-Pane Builder

### Layout

A builder-style layout. On compact phones it stacks; on tablets or wider devices it becomes split-view.

```
Home Quick Actions

┌───────────────────┬───────────────────┐
│ Enabled Actions   │ Preview           │
│ 3 of 5 used       │ native menu       │
│                   │ app icon          │
│ [New Story]       │                   │
│ [Take Photo]      │                   │
│ [Record Voice]    │                   │
├───────────────────┴───────────────────┤
│ Add Actions                            │
│ Default | Templates | Tags             │
└───────────────────────────────────────┘
```

### Visual Style

- Productivity-tool feel: dense, organized, and efficient.
- Enabled list feels like a queue or stack that users are building.
- Preview is persistent, especially on larger screens.
- Available actions use tabs or segmented controls instead of large sections.

### Strengths

- Strong for power users who want to compare enabled items and add options quickly.
- Makes capacity management obvious.
- Tablet and desktop layouts can feel especially polished.

### Risks

- More complex to implement responsively.
- Can feel busier than StoryPad needs for a small settings feature.
- Preview may become too small on narrow phones unless carefully stacked.

### Best For

Users with many templates/tags, or a later phase when shortcut customization becomes more advanced.

## Design Concept 3: Guided Category Picker

### Layout

A step-like flow within a single screen. The top summarizes enabled actions; the main area focuses on one action category at a time.

```
Home Quick Actions
[Native Preview]

Your Actions: New Story, Take Photo, Record Voice

What would you like to add?
[Default] [Templates] [Tags]

Selected category content
[Daily Reflection] [add]
[Gratitude]        [locked]
```

### Visual Style

- Friendly, editorial, and lighter than the builder concept.
- Uses segmented controls for category switching.
- Category content can be more curated, with recommended templates/tags first.
- Locked paid items can be grouped behind a clear upgrade prompt instead of disabled row after disabled row.

### Strengths

- Keeps the screen from becoming visually overwhelming.
- Gives space to explain paid customization without clutter.
- Makes empty states more graceful, especially when no tags or templates exist.

### Risks

- Users may need extra taps to browse all available options.
- Enabled action management is less prominent than in the other concepts.

### Best For

A softer settings experience where discovery and upgrade messaging matter more than speed.

## Recommended Direction

Use **Concept 1: Preview-First Studio**.

It best matches the feature's core promise: "This is what will appear from your phone home screen." It is straightforward for all users, supports the requested preview/list/category structure, and is the lowest-risk foundation for a first UX/UI pass.

Keep the first version minimal: default actions are listed directly, templates open the existing Templates view in a picker sheet, and tags can remain a compact section. Borrow from Concept 2 later for larger screens, where the preview can remain sticky beside the action list.

## Recommended Screen Detail

### App Bar

- Title: `Home Quick Actions`
- Optional trailing reset action in later phase.
- Back navigation follows existing platform behavior.

### Capacity Row

- Text: `3 of 5 actions enabled`
- Progress indicator can be subtle, such as a thin linear bar.
- When full: `Action limit reached` with add buttons disabled.

### Preview

Preview should render the same enabled labels and order as the list below.

iOS preview traits:

- Rounded translucent menu surface.
- App icon below the menu.
- Compact rows with icon leading and label.
- Slight blur/tint effect if feasible later.

Android preview traits:

- App icon with menu bubble anchored above.
- Google Sans-style typography.
- Material-like list surface and elevation.
- Icons left aligned with action labels.

### Enabled Actions Section

Each enabled row:

- Leading icon using `SpIcons` in later implementation.
- Main label.
- Optional supporting label for template/tag source, such as `Template` or `Tag`.
- Remove icon button.
- Drag handle can be introduced when reorder is implemented.

Empty state:

- Title: `No quick actions yet`
- Body: `Add the actions you want to start from your phone home screen.`
- Primary suggestion: add `New Story`.

Full state:

- Add buttons disabled.
- Capacity row changes to `5 of 5 actions enabled`.
- Short helper text: `Remove an action before adding another.`

### Available Actions Section

Default Actions:

- `New Story`: start a blank story.
- `Take Photo`: capture a memory with a photo.
- `Record Voice`: capture a voice note.
- Free, always visible unless already enabled.

Templates:

- Show one row: `Choose Template`.
- Tapping it opens the existing Templates view in a sheet.
- Add a `pickMode` boolean to the templates route/view parameters so the same Templates view can behave as a selector.
- In pick mode, tapping a custom template or gallery template returns the selected template to Home Quick Actions instead of opening the normal template story creation flow.
- The returned value should preserve whether it is a gallery template or a custom template.
- Paid customization.
- Template picker is never empty because gallery templates are available even when the user has no custom templates.
- For free users, the `Choose Template` row can be visible but locked.

Tags:

- Shows user's existing tags.
- Paid customization.
- Empty state: `No tags yet`.
- Tag rows should use tag color/swatch if the app already supports tag colors.

### Locked Paid Treatment

Keep it calm and transparent:

- Lock icon on paid rows.
- Add button label changes to `Upgrade` or uses a lock icon depending on existing app style.
- Short section note: `Templates and tags are part of quick action customization.`
- Avoid blocking the entire screen; free actions remain usable.

## Interaction Model

- Tap add on an available action to move it into Enabled Actions if capacity allows.
- Tap `Choose Template` to open the Templates view as a picker sheet when the user has access and capacity is available.
- In template pick mode, selecting a gallery or custom template closes the sheet and adds that template action to Enabled Actions.
- Tap remove on an enabled action to return it to available actions.
- If the same action is already enabled, hide it from available actions or show it as selected/disabled.
- Template and tag actions should include enough label context to avoid duplicates.
- Reorder can be deferred, but the UI should leave room for it.
- Save behavior can be explicit for the first design: changes appear in preview immediately, then persist on `Save`.

## Accessibility

- All icon-only controls need semantic labels.
- Remove buttons should announce the item, for example `Remove New Story`.
- Locked rows should be readable by screen readers as locked or requiring upgrade.
- Preview is decorative if it duplicates enabled actions; mark carefully later to avoid repeated screen reader noise.
- Maintain sufficient color contrast in locked and disabled states.
- Support dynamic text without row overlap.

## Visual Guardrails

- Use `SpIcons` for later implementation; do not use `Icons.*` or `CupertinoIcons.*` directly.
- Use the term `widgets` in implementation docs and code discussions.
- Keep list rows compact and readable; this is a settings tool, not a landing page.
- Avoid nested cards. Use sections, list tiles, and a single preview surface.
- Reuse the existing Templates view for template browsing; do not recreate template browsing UI inside Home Quick Actions.
- Keep preview dimensions stable so changing action labels does not shift the whole layout.
- Use platform-specific preview styling only inside the preview area; the surrounding settings screen should stay StoryPad-native.

## Suggested Icons For Later Implementation

| Action       | Suggested `SpIcons` Direction |
| ------------ | ----------------------------- |
| New Story    | edit/create                   |
| Take Photo   | photo/camera                  |
| Record Voice | microphone                    |
| Template     | document/template             |
| Tag          | tag                           |
| Remove       | close/delete                  |
| Locked       | lock                          |

If a needed icon is missing, add it to `SpIcons` following `docs/ui/icons.md`.

## Future Implementation Phases

| Phase | Focus            | Outcome                                                                                            |
| ----- | ---------------- | -------------------------------------------------------------------------------------------------- |
| 1     | UX/UI prototype  | Static Concept 1 screen with preview, enabled list, default rows, template picker row, tag section |
| 2     | Local state      | Add/remove/reorder interactions and template picker sheet without platform shortcut registration   |
| 3     | Data model       | Persist configured quick action definitions                                                        |
| 4     | Platform adapter | Register shortcuts on iOS/Android with platform limits                                             |
| 5     | Routing          | Open story/template/tag flows from launched quick action                                           |
| 6     | Monetization     | Connect paid entitlement and upgrade flow                                                          |

## Open Questions

- Should changes apply instantly or only after tapping Save?
- Should default quick actions be removable, or should at least one default action always remain?
- Should shortcut order match list order exactly on both iOS and Android?
- What is the final minimum supported action limit per platform?
- What exact result object should the Templates picker sheet return for gallery vs custom templates?
- Should tag quick actions open the tag story list directly or open a filtered home timeline?

## Success Criteria

- Users can understand the feature from the preview without reading instructions.
- Free users can configure default actions without feeling blocked.
- Paid template/tag customization is visible, desirable, and clearly marked.
- The screen remains usable with zero custom templates, zero tags, and a full action list.
- Template browsing stays consistent by reusing the existing Templates view in picker mode.
- The design can evolve into real platform shortcut registration without changing the core UX.
