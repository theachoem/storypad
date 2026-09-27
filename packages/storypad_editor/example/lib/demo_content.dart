/// A demo story exercising every block, format and demo embed, as stored (canonical Markdown).
const demoMarkdown = '''
# A day at the lake

We left early. The water was **still**, the air *cold*, and someone had written <u>"welcome"</u> in the sand. <span style="color:#1e88e5ff">Blue</span> skies, <mark style="background-color:#fff59dff">bright</mark> sun.

<div style="text-align:center">

Photos from the morning

</div>

<sp-album data-size="max"><img src="images/lake-1.jpg"><img src="images/lake-2.jpg"><video controls src="videos/lake-3.mp4"></video></sp-album>

<audio controls src="audio/birds.m4a"></audio>

## Things to remember

- Sunscreen
    - The good one
1. Leave by 7
1. Take the long road
- [x] Pack lunch
- [ ] Call grandma
    - [ ] Ask about the recipe

> The best days are the ones you don't plan.

```
lake_temperature = 14 // °C
```

<time datetime="2024-06-15T00:00:00.000">2024-06-15T00:00:00.000</time>

---

Written on the way home.''';
