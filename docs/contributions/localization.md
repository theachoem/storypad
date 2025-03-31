---
layout: default
parent: Contribution
title: Localization
contributors:
  - name: "I'm Acoustic"
    image: "https://lh3.googleusercontent.com/a-/ALV-UjX9zmgpk7EMLTS1AQHLrkAP3W1ocR0rWqMs6qtbm6q8biYfxMs=s100-c"
    languages:
      - km
  - name: "Seavleng Hong"
    image: "https://lh3.googleusercontent.com/a-/ALV-UjX9pKrVd7eP4oaT0tarwNEZCTKVaS0YLqnzXI9GqcO3wa3Rbz0usQ=s100-c"
    languages:
      - km
  - name: "iljinjung"
    image: "https://avatars.githubusercontent.com/u/72493043?v=4"
    reference: https://github.com/theachoem/storypad/pull/349
    languages:
      - ko-KR
---

# Localization

Our app currently supports the following languages, with translations provided by Google Translate:

> Arabic, German, English, Spanish (Latin America), Spanish (Spain), French, Hindi, Indonesian, Italian, Japanese, Khmer, Korean, Polish, Portuguese, Thai, Vietnamese & Chinese (Simplified).

If your language is not listed, or you spot any translation glitches, feel free to suggest improvements in our Google Sheet below:

[Google Sheet](https://docs.google.com/spreadsheets/d/1XcohOqNzrkMJnAmAuJssa0Rc7wftjfN2rrxb4GgcE9c/edit?usp=sharing){: .btn .btn-green }

## How Can I Help?

1. Open the Google Sheet linked above.
2. Find your language and suggest improvements, corrections, or better translations.
3. If you see any translation errors or feel a translation can be better, add your suggestions!
4. We’ll review the updates and apply them in the app with the next release.

## Contributors

Thank you for helping us make StoryPad better for users around the world!

<div>
  {% for contributor in page.contributors %}
    {% if contributor.reference %}
      <a href="{{ contributor.reference }}">
        <img style="width: 48px;" src="{{ contributor.image }}" alt="{{ contributor.name }}" />
      </a>
    {% else %}
      <img style="width: 48px;" src="{{ contributor.image }}" alt="{{ contributor.name }}" />
    {% endif %}
  {% endfor %}
</div>
