---
layout: default
parent: Developer Articles
title: Sharing Experience
---

# Sharing my open-source diary app with 80k+ downloads: 5 years of learning & mindset changes

Hi everyone, today I want to introduce my open-source diary app with 80k+ downloads & share my experience in learning & making the app for the last 5 years.

I started learning Flutter about 5 years ago. I built this open-source app called StoryPad for the purpose of learning. The app accidentally got a lot of downloads but I was really bad at maintaining my own code at that time. With poor reviews and my younger mindset, I gave up easily. I created a new app called Spooky just to replace it (How silly I am).

After a while, StoryPad still gains downloads & Spooky downloads is still lower than StoryPad despite more advances & having more features. With all the reviews I got, I realize that users don't want that advance for a diary app, they want simple things.

In the past few months, I shifted my focus to rebuilding StoryPad from scratch, prioritizing maintainability. Rewriting is not a good thing but migrating a 4 years old app is even harder.

For new codebase, I don't want to feel bad looking at my own code a year later or rewrite it again. Here's my plan to keep maintainability high:

\- Use as few packages as possible, so upgrading Flutter is faster & no longer much pain as I don't have to wait for a few packages to update to be compatible with new Flutter version.

\- Only integrate something when it's truly needed. E.g. the app doesn’t need deeplink yet, so I don't have to integrate Navigator 2.0 or even packages like auto_route or go_router that make it so easy to do it yet. I just need to design my code a little bit for easier to pass params, log analytics view & have other custom push logic:

    StoryDetailsRoute(id: 1).push(context);
    StoryDetailsRoute(id: 1).pushReplacement(context);

\- Stick with Provider state management. Other state management is powerful, but Provider remains simple & aligns well with Flutter's approach to handling state. It helps keep the codebase clean and easy to maintain. In addition to provider, I also use stateful widgets & organize the app's states into three categories: App State, View State & Widget State (similar to FlutterFlow).

There are other solutions that I do such as structuring the folder and managing Flutter, Java, Ruby version, etc which I wrote inside the repo itself.

It’s not perfect, but I’m eager to hear your feedback and continue improving the app. Check it out here:

[https://github.com/theachoem/storypad](https://github.com/theachoem/storypad)

Please give repo a star if you like it! 😊

<blockquote class="reddit-embed-bq" style="height:316px" data-embed-height="316"><a href="https://www.reddit.com/r/FlutterDev/comments/1j1zd48/sharing_my_opensource_diary_app_with_80k/">Sharing my open-source diary app with 80k+ downloads: 5 years of learning &amp; mindset changes</a><br> by<a href="https://www.reddit.com/user/Basic-Actuator7263/">u/Basic-Actuator7263</a> in<a href="https://www.reddit.com/r/FlutterDev/">FlutterDev</a></blockquote><script async="" src="https://embed.reddit.com/widgets.js" charset="UTF-8"></script>

<style> iframe { margin: 0px !important; } </style>
