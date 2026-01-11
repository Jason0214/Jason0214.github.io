---
title: Graphics and System Readings
lang: en-US
date: 2021-02-28
---

Blogs and news read during Feb. 2021 that I found interesting.
<!-- more -->

Disclaimer: Opinions on my own and please judge the credibility by yourself.

[[toc]]

### The complexity that lives in the GUI
[https://blog.royalsloth.eu/posts/the-complexity-that-lives-in-the-gui/](https://blog.royalsloth.eu/posts/the-complexity-that-lives-in-the-gui/) -  December 01, 2021

> Classes are a great building blocks for the GUI, because they let you divide the complexity into smaller parts each containing just the internal state of one little component ... if you are organizing the stuff in box A you don’t care about the mess that resides in box B.

> For a while this strategy of “mess in other boxes is not my problem” works, but soon enough you hit the next challenge. ... Connect the boxes ... Lift the state up ... Introduce a message bus... It goes without saying, that none of the presented options are without problems.

> Connect the boxes: ... It turns out, for small components this strategy works quite well. As usual, it’s often the wrong thing to do when your project grows large and contains hundreds of such inter class communication paths. Not to mention how injecting hundreds of components is tedious, error prone and ugly to look at.

> Lift the state up: ... handling this accidental complexity is by lifting the state up and storing the state of your component into another box that is usually called the model ... Model View Controller (MVC) gang rejoice ...
though you improved the situation a little bit, you still have a huge model that is full of weird edge cases... The more modern GUI frameworks usually arm you with some kind of data binding abstraction, which allows to easily propagate data changes from one model to another via the so called one way, two way data binding ... you realize that it would be really useful if you could attach a change listener that would trigger and perform an action on every change of the state object ... Clicking on buttons will start triggering events which will modify the state in the model that will in turn start triggering event listeners causing your GUI to flash like a christmas tree ...

> Message bus: ... just spamming messages back and forth causes a lot of performance problems ... Why filter out all the irrelevant messages and waste CPU cycles, when you can subscribe to a specific channel that receives only the messages on the topic you are interested in? ... But, it’s so easy to throw yet another message into the void.

> There is also another way of making GUIs called Immediate Mode that is commonly used for drawing user interfaces in games ... Immediate Mode GUIs somehow never reached the critical mass and you are probably not going to find it outside of the games industry.

A good discussion on the complexity in developing GUI, especiall in the unavoidable cross component communication. Three commonly used design pattern are discussed here. 1) creates ad-hoc links works; but it does not scale 2)  MVC design can scale, still the data bindings (intra component links) can get very complex 3) Message bus (i.e. publish/subscribe) is a good abstraction, but it either waste cycles on filtering irrelevant message or being error prone on finding the right subscriber. 
From my own experience, I have the same feeling as the author that immediate mode GUI like ImGui has fewer issues.


### Cameras and Lenses
[https://ciechanow.ski/cameras-and-lenses/](https://ciechanow.ski/cameras-and-lenses/)

Long article but relaxing to read.
It has good animations emebed in the text that you can tweak the camera/lens parameters and check how they affect the image.
New knowledge for me are
1) the Bayer filter in demosaicing.
2) The cosine-fourth-power law for objects has an angle to the focal axis (Hope it gives some introduction on how real world cameras compensate for this effect, but it does not.)
3) The need for a convex thick lens, because parallel glass may "shift" the ray.
4) Spherical aberration that appears to be fuzzy focus points because of the imperfection of lens, which can be solved by [aspheric lens](https://en.wikipedia.org/wiki/Aspheric_lens)
5) Chromatic aberration that caused by color spectrum having different focus points, which can be solved with [achromatic lens](https://en.wikipedia.org/wiki/Achromatic_lens)

### sRGB gamut clipping 
[https://bottosson.github.io/posts/gamutclipping/](https://bottosson.github.io/posts/gamutclipping/)

Gamut clipping is a technique to display HDR content on SDR color space.
It does some  transformation for out of gamut colors in a perceptual color space.

In the article the author compares different gamut editing methods, linear/nonlinear.
The delivered quality seems to be good, but I am wondering what is an advantage over tone mapping?
(Also I am not sure how does the author get the "unprocessed" HDR image showing on the page?) 

### Wine on Wayland: An exciting first update
[https://www.collabora.com/news-and-blog/news-and-events/wayland-on-wine-an-exciting-first-update.html](https://www.collabora.com/news-and-blog/news-and-events/wayland-on-wine-an-exciting-first-update.html)

> Copy/paste support works well in both directions (native Wayland apps <=> Wine apps) with many common formats already supported. Drag and drop works in the direction of native Wayland apps to Wine apps for many common formats ... 

Progress on Wayland driver of Wine. Wine on Wayland is very interesting as it may bring lots of GPU heavy games onto Wayland.
While previously, games running on Wayland needs to go through XWayland.
Being able to get rid of X, it might be an opportunity for us to see how Wayland are capable of running games, like performance wise.

### Explanation of the Linux-Kernel Memory Consistency Model
[https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/tools/memory-model/Documentation/explanation.txt](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/tools/memory-model/Documentation/explanation.txt)

Best explanation of various memory models, cache coherence, etc that I ever read.
It lies in the Linux kernel (no surprise actually).
LKMM supports some sort of formal verification, see [Calibrating your fear of big bad optimizing compilers](https://lwn.net/Articles/799218/) .

### A one-bit processor explained: reverse-engineering the vintage MC14500B
[https://www.righto.com/2021/02/a-one-bit-processor-explained-reverse.html](https://www.righto.com/2021/02/a-one-bit-processor-explained-reverse.html)
> ... CMOS (complementary MOS) circuitry uses two types of transistors, NMOS and PMOS, working together ...

Some introduction on CMOS transistor, which refers to two types of transistors, namely PMOS and NMOS, working together.
The 1-bit processor MC14500B has circuits on the die that are so simple that can be visually tell how logical gates, inverters, Flip-flop are composed with transistors.
