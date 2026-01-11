---
title: Make a Photo Gallery with Vuepress
lang: en-US
date: 2020-06-07
tags: [ web, TODO ]
---

[Vuepress](https://github.com/vuejs/vuepress) is a simple framework to generate static webpages.
I had that idea to use vuepress to make a static photo gallery for my own website.

<!-- more -->

## Give image path in markdown and no more 

The only design principle is to create a gallery page by providing only image paths.

``` md
...
- ![foo1](foo1.jpg)
- ![foo2](foo2.jpg)
- ![foo3](foo3.jpg)
....
```

You'll have to write a [custom vue component](https://vuepress.vuejs.org/theme/default-theme-config.html#custom-layout-for-specific-pages) where you can put style sheet and scripts to handle layouts and other more functionalities.

Vuepress will parse the markdown and include it into your custom component to do a server side rendering, which outputs a static webpage.

## Vary width grid view with flexbox

A vary-width grid view of elements can be made very easy with [flex-wrap](https://developer.mozilla.org/en-US/docs/Web/CSS/flex-wrap).

Display size of the element along the `flex-direction` is calculated based on `flex-grow` and the actual size of the element (e.g. the image width if `flex-direction: row`).

![flex-wrap-anim](https://i0.wp.com/css-tricks.com/wp-content/uploads/2014/03/flexbox-space-filling.gif)
If elements overflow a row flex container, those that can not fit into the first row will be wrapped to the second row,  so on and so forth.

In the align direction, just hard code the height to be some value, 40vh (40% of the display height) looks good for photos according to some posts I read.

For the markdown example above, it renders

``` html
<ul>
    ...
    <li><img src="foo1.jpg"/></li>
    <li><img src="foo2.jpg"/></li>
    <li><img src="foo3.jpg"/></li>
    ...
</ul>
```

So in the gallery component, style is set as:
``` stylus
ul
    display: flex;
    flex-wrap: wrap;
    list-style-type: none;
    padding: 0;

li
    height: 40vh;
    flex-grow: 1;
    list-style-type: none;

img
    max-height: 100%;
    min-width: 100%;
```

Note that the image is resized in this setup, check out [object-fit](https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit) if you want to keep its aspect ratio.

``` stylus
img
    object-fit: cover;
    max-height: 100%;
    min-width: 100%;
```

For responsive on phone, have the `<li>` to be `width: 100%` which forces one image each row.
``` stylus
@media (max-width: $MQMobile)
    li
      max-height: 55vh;
      width: 100%;

@media (max-width: $MQMobileNarrow)
    li
      max-height: 75vh;
      width: 100%;
```

## Nasty last row

Flexbox has the drawback that it can not perfectly handle `flex-grow` together with responsiveness, at least as far as I know.

For an extreme example, if only one photo is left to the last row, it would be stretched to the row width (default `flex-grow: 1`).

![make-a-photo-gallery-with-vuepress_last-row-stretch](./static/make-a-photo-gallery-with-vuepress_last-row-stretch.jpg)
The [last-child selector](http://localhost:8080/posts/make-a-photo-gallery-with-vuepress.html) can be used to change the last photo's `flex-grow` to `0`, so that it does not stretch.

In my opinion, it does not entirely solve the issue. When resolution changes on other devices, this last photo could be in a row together with other photos. In the example below, there are two photos in the last row, the `flex-grow` difference still causes one photo to stretch.

![make-a-photo-gallery-with-vuepress_last-child-selector.jpg](./static/make-a-photo-gallery-with-vuepress_last-child-selector.jpg)
The takeaway is that it is hard to make it perfect on every device. Tune the order of the photos to till it looks good on one device and forget about others. Not such a big deal, as it is not an issue on very narrow screens (phones) where every row has only one photo.

## Lazy loading

A thumbnail auto generation is hard to fit into the vuepress infrastructure.
Using original photos in the gallery preview definitely burdens networking and rendering. (Browsers usually re-render when a new image is loaded.)

Lazy loading, which loads images only when they are visible, is natively supported in most browsers.
An `<img/>` with attribute `loading="lazy"` should be lazy loaded.
Using markdown plugin such as [[1]](https://github.com/ruanyf/markdown-it-image-lazy-loading) easily converts your markdown images to lazy loaded.

However, there is something about lazy loading with Chrome according to [[2]](https://stackoverflow.com/questions/57753240/native-lazy-loading-loading-lazy-not-working-even-with-flags-enabled), which I also reproduced and verified.
Chrome (version 83.0.4103.97) is kinda aggressive about loading.
It loads image far ahead of your visible window, which is a bad thing for webpage with all photos.
Firefox does not have this issue (or feature).

Note that images initially have no width. Therefore, images are in the same flex row before they get loaded. 

![make-a-photo-gallery-with-vuepress_initial-one-row.jpg](./static/make-a-photo-gallery-with-vuepress_initial-one-row.jpg)
So even with lazy loading, more than necessary images are loaded in the first place (Think about when images are loaded, they wrap around and push the content below into invisible regions).

To make it better, one possible approach is to make the image container (`<li>` in the context) reactive.
Provides it with a hard coded `width` in server side rendering, then use a js based lazy loading and set a callback to flip the `width` to `auto` after the image is loaded.

TODO: Alter `src` to `data-src` and do lazy loading manually with [lozad](https://github.com/ApoorvSaxena/lozad.js/).

## Photo viewer

TODO: Add a photo viewer with [v-viewer](https://github.com/mirari/v-viewer).
Should be straightforward, just inject a click event for each `<img>` in `mounted()`.


## Reference
- [https://css-tricks.com/filling-space-last-row-flexbox/](https://css-tricks.com/filling-space-last-row-flexbox/)
- [https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Flexible_Box_Layout/Mastering_Wrapping_of_Flex_Items](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Flexible_Box_Layout/Mastering_Wrapping_of_Flex_Items)
- [https://css-tricks.com/adaptive-photo-layout-with-flexbox/](https://css-tricks.com/adaptive-photo-layout-with-flexbox/)
