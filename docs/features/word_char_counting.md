# Word & Character Counting

Accurate counting of words and characters in story pages, showing users only the content they actually wrote—excluding formatting and structural elements.

## How It Works

### Process Flow

1. **Convert Quill Delta to Markdown** → `QuillDeltaToPlainTextService`
   - Transforms rich text Delta JSON into markdown-formatted plain text
   - Preserves text content while adding markdown syntax

2. **Filter Structural Elements** → `MarkdownContentFilterService`
   - Removes markdown formatting and decorative elements
   - Extracts only actual written content

3. **Calculate Counts** → `GenerateBodyPlainTextService`
   - Counts characters in filtered text
   - Counts words by splitting on whitespace

### What Gets Filtered Out

Content **NOT** counted (formatting/structure):

- ❌ Checkboxes: `- [ ]` or `⏹️` (unchecked only)
- ❌ Bullet markers: `- `, `* `, `•`
- ❌ List numbering: `1. `, `a. `, `i.`
- ❌ Markdown syntax: `**bold**`, `*italic*`, `~~strike~~`, `` `code` ``
- ❌ Links: `[text](url)` → keeps "text", removes URL
- ❌ Images: `![alt](url)` → removed entirely
- ❌ Headers: `## Title` → keeps "Title"
- ❌ Blockquotes: `> ` prefix
- ❌ Code blocks: ` ``` ` markers
- ❌ Horizontal rules: `---`, `***`, `___`
- ❌ Indentation: leading tabs
- ❌ Blank/empty lines: Lines that become empty after filtering are removed
- ❌ Embedded widgets: `\uFFFC` placeholder

Content **COUNTED** (actual writing):

- ✅ Plain text
- ✅ Text from links (without URL)
- ✅ Header text (without `#` markers)
- ✅ Checked checkbox content (keeps the text)
- ✅ Code content (without `` ` `` markers)

## Examples

### Example 1: Simple Formatting

**What you write:**

```
Today I felt **really happy** and *excited* about my project!
```

**Markdown generated:**

```
Today I felt **really happy** and *excited* about my project!
```

**After filtering:**

```
Today I felt really happy and excited about my project!
```

**Count:** 52 characters, 10 words

---

### Example 2: Task List

**What you write:**

- ☐ Buy groceries
- ☑ Finish report
- ☐ Call mom

**Markdown generated:**

```
- [ ] Buy groceries
- [x] Finish report
- [ ] Call mom
```

**After filtering:**

```
Buy groceries
Finish report
Call mom
```

**Count:** 35 characters, 6 words

- Note: Checkbox markers (`- [ ]`, `- [x]`) not counted
- Only the actual task text counts

---

### Example 3: Mixed Content

**What you write:**

```
# My Day

I visited [the museum](https://example.com) and saw:
- Ancient artifacts
- Modern art
- Historical documents

The guide said: "This is `priceless`"
```

**Markdown generated:**

```
# My Day

I visited [the museum](https://example.com) and saw:
- Ancient artifacts
- Modern art
- Historical documents

The guide said: "This is `priceless`"
```

**After filtering:**

```
My Day
I visited the museum and saw:
Ancient artifacts
Modern art
Historical documents
The guide said: "This is priceless"
```

**Count:** 124 characters, 22 words

- Header `#` removed
- Link URL removed, kept "the museum"
- Bullet markers removed
- Inline code backticks removed

---

### Example 4: Writing Goals

If you want to write a 500-word journal entry:

**Before filtering (raw markdown):**

```markdown
## Morning Reflection

Today started with:

- [ ] Meditation ✓
- [ ] Exercise

I felt **amazing** because...
```

= 78 characters with formatting

**After filtering (what counts):**

```
Morning Reflection
Today started with:
Meditation ✓
Exercise
I felt amazing because...
```

= 77 characters, 12 words counted

This shows you've written 12 words toward your 500-word goal, not including any formatting overhead.

---

### Example 5: Blank Lines

**What you write:**

```
Just realize we got first payment from Google

It is actually sent since last month, but I didn't noticed 🤗

Sent to my girl 25$ as well, she help building our tiktok & reddit.
```

**After filtering:**

```
Just realize we got first payment from Google
It is actually sent since last month, but I didn't noticed 🤗
Sent to my girl 25$ as well, she help building our tiktok & reddit.
```

**Count:** 197 characters, 46 words

- Blank lines between paragraphs are **not counted** (they're spacing/layout)
- Only actual text content counts
- Emoji (🤗) counts as a character since it's expressive content

## Technical Implementation

### Key Services

```dart
// 1. Convert Delta to markdown text
final plainText = QuillDeltaToPlainTextService.call(
  deltaOps,
  markdown: true,
  includeMarkdownEmbeds: false,
);

// 2. Filter out formatting
final filteredText = MarkdownContentFilterService.call(plainText);

// 3. Count
final characterCount = filteredText.length;
final wordCount = filteredText
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .length;
```

### Location

- **Services**: `lib/core/services/`
  - `quill_delta_to_plain_text_service.dart`
  - `markdown_content_filter_service.dart`
  - `generate_body_plain_text_service.dart`
- **Tests**: `test/core/services/`
  - 100+ test cases ensuring accuracy

## Why Filter?

Users expect to see the **amount they've written**, not formatting overhead:

- Writing `**Hello**` should count as 5 chars ("Hello"), not 9
- A checklist with 5 items should count as the text content, not include `- [ ]` markers
- Bullet points are layout, not content

This gives writers an accurate sense of their actual writing output.
