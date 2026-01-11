---
title: Migrate My Blog Generator
date: 2026-01-11
tags: [ web ]
---

Restart doing some blogs, and moving my blog site generator from VuePress to Zola.

<!-- more -->

## Restart blogging a bit

最近很突然觉得自己想要重新开始写technical的blogs，想来有几个的原因：

一方面是因为想要给自己留更多的记录。随着年龄的增长，体感上时间过的越来越快了，我发现自己不太能够回溯过去的一年自己到底做了哪些事情。如果有一些记录能帮助我回忆，我觉得会很有帮助。如果这些记录能留存的更久，十年或者二十年，我觉得以后的我也会感激现在留下它们。

另一方面是觉得自己的记忆力在减退，最近碰到一些突然的exception，需要重新设置家里的网络，因为没有办法回忆起很多配置的细节，导致花了
比自己预期更长的时间来理解自己之前的setup。想象到以后还需要做的维护和迭代，记录下自己step by step的work会是值得的。
- *过去几年为家里做了不少有用的数字化，包括设置了非常可靠的fast roaming (基本照搬[
CHEAP WI-FI MESH ALTERNATIVE with fast roaming OpenWrt Wi-Fi Access points](https://www.youtube.com/watch?v=kMgs2XFClaM));
配置了还可以将就的网络for chromecast; DIY了NAS; Build了看起来还行但实际没有用的monitoring;*
![monitoring](home-monitor-example.jpg)
*同时还在持续的reverse engineering家里精装修预装的KNX智能家具*

看上一篇blog的日期还是在2022年2月（这是时隔四年的重启）。github pages帮了我大忙，让旧的blog一直活在互联网上，让我有更多的动力做这次重启。我印象中我应该不止一次，不连续的买过几年的lujc.me的domain，但每次都是一年到期后不想再续，因为觉得域名的使用频率完全划不来我为它支付的价格。

## New feelings on writing

阅读之前自己写的一些内容，结合自己残存的印象，有一些写的内容我当时应该是不理解的(现在也不理解)。如果现在的我来记录，我应该会call out “这是我不懂的内容”。 但无论如何，我还是很感谢自己有写一些东西。能再次了解到几年前的自己在做什么还是非常有趣的。

这次的重新开始，我觉得我会更多的使用中文。因为大部分情况下，中文还是让我能更快的把想的内容写下来。对我来说，更快的写下来，比质量和阅读体验更重要lol。

## Migrate to Zola

其实之前的VuePress based的site generator还很好的被保留在了我的github repo里。我甚至应该投入了很多时间develop其中一部分的前段。但想象到为了build VuePress，我需要去下载node，npm install modules，再可能因为security的原因被要求更新大部分node modules，我就打消了继续使用VuePress的念头（可能还是源于不喜欢node）。介于当下我比较熟悉Rust的ecosystem，使用Zola是一个很合理的选择。Plus，目前看起来它真的很好用，很快，很简单。

有一些小小的遗憾是我觉得我能找到的Zola theme都没有我VuePress based的旧版来的好看。所以我有尝试把旧版blog的HTML download一份放在这个版本的blog里，留给以后的我照着它refresh UI

我尝试了所有的Chrome的“Save As”选项，只有save as “Website，Single File" 能比较完整的保留UI/UX（但somehow 字体丢失了）。但接着碰到的问题是`*.mhtml`是一个archive，我并不能把它packge进Zola project里。所以它被存放在了[static](/old_blog/old_blog.mhtml), 只能for downloading。希望MHTML(MIME encapsulation of aggregate HTML documents)能存活的足够久，让未来我还能预览这个文件。