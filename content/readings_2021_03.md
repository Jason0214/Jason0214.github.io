---
title: Graphics and System Readings
lang: en-US
date: 2021-03-07
---

Blogs and news read during March 2021 that I found interesting.
<!-- more -->

Disclaimer: Opinions on my own and please judge the credibility by yourself.

[[toc]]

### Proton Has Enabled 7000 Windows Games To Run On Linux
[https://boilingsteam.com/7000-windows-games-working-on-linux-with-proton/](https://boilingsteam.com/7000-windows-games-working-on-linux-with-proton/)  - March 05, 2021

>  for every Windows game out there, there’s a coin flip chance that it will work just as well on Linux ... Note that when a game does not run well with vanilla Proton, there’s always a non-negligible chance that Proton GE may fare better at running it.

### LLVM meets Code Property Graphs 
[https://blog.llvm.org/posts/2021-02-23-llvm-meets-code-property-graphs/](https://blog.llvm.org/posts/2021-02-23-llvm-meets-code-property-graphs/)

> The code property graph (CPG) is a data structure designed to mine large codebases for instances of programming patterns via a domain-specific query language ... The core idea of the CPG is that different classic program representations are merged into a property graph, a single data structure that holds information about the program’s syntax, control- and intra-procedural data-flow ... 

> One of the primary interfaces to the code property graphs is a tool called Joern ... This article presents ShiftLeft‘s open-source implementation of llvm2cpg - a standalone tool that brings LLVM Bitcode support to Joern. 

> Joern comes with a data-flow tracker enabling more sophisticated queries, such as “is there a user controlled malloc in the program?”

The data flow tracker that is able to check dynamic allocation in the program seems very interesting. 

### New Vulkan Extensions For Mobile: Maintenance Extensions
[https://community.arm.com/developer/tools-software/graphics/b/blog/posts/vulkan-maintenance-extensions](https://community.arm.com/developer/tools-software/graphics/b/blog/posts/vulkan-maintenance-extensions)

- VK_KHR_uniform_buffer_standard_layout: Some history of std140 and std430 UBO layout and how they are different in alignment. This extension brings std430 UBO layout to Vulkan.
- VK_KHR_separate_depth_stencil_layouts: Depth and stencil are commonly being packed together. It leads to inconvenience in scenarios where depth buffer and stencil buffer are used in different pipeline stages. This extension supports an explicit decoupling of depth and stencil buffer.
- VK_KHR_imageless_framebuffer: Extension supports creating VkFramebuffer without specifying attachments, delaying attachment binding to command recording time. It saves applications from keeping a mapping between framebuffers and attachments. In my understanding, now framebuffer and renderpass can be one-one mapped in most cases.

### New Game Changing Vulkan Extensions For Mobile: Buffer Device Address
[https://community.arm.com/developer/tools-software/graphics/b/blog/posts/vulkan-buffer-device-address](https://community.arm.com/developer/tools-software/graphics/b/blog/posts/vulkan-buffer-device-address)

> ... none of the competing graphics APIs support.
Extensions that support getting the GPU virtual address of a buffer. With the extension, it is possible for a shader to read/write a buffer without binding its descriptors. Though not sure if there is any practical case to do it that way.  Maybe some debugging tools can utilize it?
The extension also comes with a feature called `bufferDeviceAddressCaptureReplay`. Looks like using the extension could break capture replay tools. Not intuitive to me how it breaks, is that because applications may have different code paths for different returned virtual addresses?

### New Game Changing Vulkan Extensions For Mobile: Descriptor Indexing
[https://community.arm.com/developer/tools-software/graphics/b/blog/posts/vulkan-descriptor-indexing](https://community.arm.com/developer/tools-software/graphics/b/blog/posts/vulkan-descriptor-indexing)

VK_EXT_descriptor_indexing brings update-after-bin support for descriptors. In my understanding, it is similar to the concept of a dynamic uniform buffer that you create a big chunk of memory but only use portions of it in each draw call.  However, this extension does it to the descriptors of the uniform buffer, not the uniform buffer itself.

### Moving The Machinery to Bindless
[https://ourmachinery.com/post/moving-the-machinery-to-bindless/](https://ourmachinery.com/post/moving-the-machinery-to-bindless/)

Using VK_EXT_descriptor_indexing in practice. It creates a maxminal number of descriptor set bindings beforehand and then allocate and free descriptors dynamically in each command draw.
It uses a linked list to track the free slots of descriptors in the big descriptor set bindings.

### OpenGL on DirectX: Conformance & upstreaming of the D3D12 driver
[https://www.collabora.com/news-and-blog/news-and-events/opengl-directx-conformance-upstreaming-d3d12.html](https://www.collabora.com/news-and-blog/news-and-events/opengl-directx-conformance-upstreaming-d3d12.html)
> ... have recently passed the OpenGL 3.3 conformance tests,

> ... The D3D12 driver was upstreamed in Mesa in Merge-Request 7477, and the OpenCL compiler followed in Merge-Request 7565. 

> Next step, WSL support!


### Headless Native Backend and Virtual Monitors
[https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1698](https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1698)

> Ability to run the native backend on top of only a render node (i.e. no mode setting) and without evdev (a.k.a. "headless")
> Ability to create virtual monitors via command line arguments, primarily for debugging purposes
> Ability to create virtual monitors PipeWire streams via a new org.gnome.Mutter.ScreenCast.Session.RecordVirtual D-Bus method
> ... another way for the headless mode to run under: surfaceless EGL context. This should make it possible to run headlessly without a render node too.

Mutter has merged a change to support running on render node only (through Wayland) as well as without render node through EGL surfaceless. Looks like now it is possible to recording gnome-shell from start to end very easily.

### Apple M1 Microarchitecture Research
[https://dougallj.github.io/applecpu/firestorm.html](https://dougallj.github.io/applecpu/firestorm.html)
> Certain instructions are able to issue as one uop if they appear consecutively in the instruction stream.

Apple M1 has instruction fusion.

### Full Wayland Setup on Arch Linux
[https://www.fosskers.ca/en/blog/wayland](https://www.fosskers.ca/en/blog/wayland)

> The about:support page in Firefox has a field titled Window Protocol that tells us which protocol it is running through ... Set the MOZ_ENABLE_WAYLAND environment variable to 1.

> Chromium's conversion is a bit simpler. In /home/you/.config/chromium-flags.conf, add the following lines:
--enable-features=UseOzonePlatform
--ozone-platform=wayland

> Steam and Gaming ... set -x SDL_VIDEODRIVER 'wayland' ...

Configurations for Firefox, Chromium and Steam games to run on top of native Wayland.

### Makes Continuous Profiling Possible
[https://github.com/pyroscope-io](https://github.com/pyroscope-io)

Looks like a `perf top` for python and with a nice UI. Would be happy to try it out.

### What Are Some “10x” Software Product Innovations You Have Experienced?
[https://news.ycombinator.com/item?id=26477507](https://news.ycombinator.com/item?id=26477507)

Some examples mentioned are: sing Google for search in 2000, Google Maps in 2004, MS Window Media Player's,  SQLite library, C++ STL in late 1990s, VMware in 2000s, Google Chrome in 2008, etc.
All of them are before from decades or even before.

### MATch: Differentiable Material Graphs for Procedural Material Capture
[http://match.csail.mit.edu](http://match.csail.mit.edu/)
[https://users.cg.tuwien.ac.at/zsolnai/gfx/photorealistic-material-editing/](https://users.cg.tuwien.ac.at/zsolnai/gfx/photorealistic-material-editing/)
> MATch, a method to automatically convert photographs of material samples into production-grade procedural material models
> a new library DiffMat that provides differentiable building blocks for constructing procedural materials, which can be used to automatically translate large-scale procedural models, with hundreds to thousands of node parameters, into differentiable node graphs.

One of few applications of machine learning that really convinces me ML is the future.
I have played with material editting using the Cycles Engine in Blender.
I know how hard it is for a non-artist to use node graph to create realistic material.
IMO, "MATch" is a revolutionary techique to this field.
Get the node graph of texture in a photo is an end to end experience, with no requiring of knowledge on "node" or "material". Amazing!
The limitation is that user still need to select a "base texture". Understandable, because noise patterns are not differentiable. And it does not hurt since choose a "noise node" is the easy part in the material creation pipeline.

### Plan 9 from Bell Labs in Cyberspace!
[https://www.bell-labs.com/institute/blog/plan-9-bell-labs-cyberspace/](https://www.bell-labs.com/institute/blog/plan-9-bell-labs-cyberspace/)
> what many don’t know is the team that created UNIX also developed another operating system in the 1980s ...  The system in question is the Plan 9 OS from Bell Labs,  ... This OS may not be as famous as UNIX, but it has been highly influential in its own ways, spearheading several concepts that are cornerstones of distributed computing systems today.

> The OS is structured as a collection of loosely coupled services, which may be hosted on different machines. Another key concept in its design is that of a per-process name space: services can be mapped on to local names fixed by convention, so that programs using those services need not change if the current services are replaced by others providing the same functionality.

sidebar: The Plan 9 file system protocol, a.k.a 9p, is used in popular softwares such as WSL, QEMU.

### Expert to Expert: Rich Hickey and Brian Beckman - Inside Clojure
[https://channel9.msdn.com/Shows/Going+Deep/Expert-to-Expert-Rich-Hickey-and-Brian-Beckman-Inside-Clojure](https://channel9.msdn.com/Shows/Going+Deep/Expert-to-Expert-Rich-Hickey-and-Brian-Beckman-Inside-Clojure)

Amazing talk. Especially the internal design part in the last half.
Interestingly, the design of immutable data structures in Clojure (or maybe it is a general design for LISP) looks very similar to how git works. The git commit (variable) is a tree of snapshots (values) and make a new commit (create new value from the old) preserve the time complexity.

### Auto HDR Preview for PC Available Today
[https://devblogs.microsoft.com/directx/auto-hdr-preview-for-pc-available-today/](https://devblogs.microsoft.com/directx/auto-hdr-preview-for-pc-available-today/)

### How to reconstruct an image if you see only a few pixels
[https://towardsdatascience.com/how-to-reconstruct-an-image-if-you-see-only-a-few-pixels-e3899d038bf9#4218-42d96b4589ee](https://towardsdatascience.com/how-to-reconstruct-an-image-if-you-see-only-a-few-pixels-e3899d038bf9#4218-42d96b4589ee)

> Image-space is vast, incredibly vast, and yet so small. Think about it for a second. You can create 18 446 744 073 709 551 616 different images by considering a grid as small as 8 by 8 black and white pixels. Yet, among these 18 quintillion images, very few make sense for human beings. Most images basically look like QR codes. Those making sense to human beings belongs to what we could call the set of natural images. 

Minimizing energy on pixel space and frequency space can recover the whole image when only 10% of its pixels is known.

### Mesa Developers Discuss The Possibility Of Rust Graphics Driver Code
[https://www.phoronix.com/scan.php?page=news_item&px=AMD-Hiring-Radeon-Rust](https://www.phoronix.com/scan.php?page=news_item&px=AMD-Hiring-Radeon-Rust)
[https://www.phoronix.com/scan.php?page=news_item&px=Mesa-Rust-2020-Discussion](https://www.phoronix.com/scan.php?page=news_item&px=Mesa-Rust-2020-Discussion)

Rust are being brought up in graphics community. It is Alyssa again.

### NVIDIA Proposes Mesa Patches To Support Alternative GBM Back-Ends
[https://www.phoronix.com/scan.php?page=news_item&px=NVIDIA-GBM-Mesa-Backend-Alt](https://www.phoronix.com/scan.php?page=news_item&px=NVIDIA-GBM-Mesa-Backend-Alt)
[https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/9902](https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/9902)

Finally Nvidia is turning to GBM. And it will be another backend insteand of DRI.
