---
title: Graphics and System Readings
lang: en-US
date: 2020-09-22
tags: [ graphics, system ]

---

Blogs and news read in Sept. 2020 that I found interesting. Summaries updated in Feb. 2021.
<!-- more -->
Disclaimer: Opinions on my own and please judge the credibility by yourself.

[[toc]]

----

### The Stack Monoid
([https://raphlinus.github.io/gpu/2020/09/05/stack-monoid.html](https://raphlinus.github.io/gpu/2020/09/05/stack-monoid.html))

> This post is a writeup of a new idea, but with a caution, no implementation... if it holds up, I think it’s an exciting line of research on how to port sequential algorithms to GPU.

> For this post, I’m going to pose an even more simplified version of the problem: for each open bracket, record the index of the parent in the parse tree, and for each close bracket, the index of the corresponding open bracket...

> Can it be parallelized? It’s challenging to see how, as there are dependencies on previous state... Maybe we can do something.... So let’s turn this sequential program into a monoid... 


In this article, the author brings up the idea that monoid could be an universal way to turn a sequential algorithm to a parallel one which, then, is able to take more advantage of modern hardwares.

[Monoid](https://en.wikipedia.org/wiki/Monoid_(category_theory)) is a term frequently appearing in functional programming language. In my understanding (which may not be accurate), Monoid is a class that (1) Has an identity value; (2) Has closure property, result of computation on two Monoid is still a Monoid; (3) Is commutative, changing the computation order of a sequence of Monoid won't affect the result;

The author gives an example about converting the brackets matching algorithm with stack into a monoid sequence. The monoid is the pair `[ numof_pops, elements_to_push ]`. Refer to the full article for its monoid properties and its correctness. With the commutative property of monoid, the monoid sequence can be partitioned and running in parallel.

Besides the discussion on how approachable of using a monoid to partition, the author also talks about difficulties. The difficulty for the matching brackets is how to partition efficiently so that partitions have regular memory consumption. For other sequential algorithms, coming up with a monoid might not be that easy. But anyway, in my opinion, the idea is of using monoid is very generic. It could be helpful when you need to do some parallel computation but has no direction to start with.

----

### Separate Interface and Implementation in C++
([https://accu.org/journals/overload/13/66/griffiths_269/#GOF95](https://accu.org/journals/overload/13/66/griffiths_269/#GOF95))
### Pimpl and Compilation Firewall
([https://herbsutter.com/gotw/_100/](https://herbsutter.com/gotw/_100/))
> C++’s build model is based on textual inclusion...
 
> To reduce these compilation dependencies, a common technique is to use an opaque pointer to hide some of the implementation details
> First, system builds run faster because using a Pimpl can eliminate extra #includes... Second, it localizes the build impact of code changes because the parts of a class that reside in the Pimpl can be freely changed – that is, members can be freely added or removed – without recompiling client code...
 
These two articles talk about a design pattern in C++. "Compilation Firewalls", "handle/body", "Pimpl Idiom" and "Cheshire Cat", they all refer to the same thing that separates the interface and implementation of a class into two classes.
 
Because C++ include is based on textual content, private data and functions actually are not hidden from clients classes. They still get included and create dependencies. Move some or all (, which depending on approaches, ) private implementation to another class helps to resolve the issue, because then clients classes only need to include the interface class.
 
The two article both discussed what members should be put into the implementation class. The conclusion is **put all private nonvirtual members into impl**. Refer to the full articles for explanations. Other choices may require 1) adding delegations in the interface class to call functions in implementation class and/or 2) a back pointer in implementation class to access interface methods.
 
Separating interface and implementation when necessary has the benefits in 1) reducing building time and 2) faster incremental building. Besides, the reference of implementation in interface also creates another level of abstraction, where multiple different implementations of one interface or share implementation between multiple interfaces can be implemented easily.

---

### There Are No Zero-cost Abstractions
([https://youtu.be/rHIkrotSwcc?t=1091](https://youtu.be/rHIkrotSwcc?t=1091))
> C++ is often described as providing zero-cost abstractions. Libraries offer up facilities documented as such. And of course, users read all of these advertisements and believe that the abstractions they are using are truly zero-cost.
 
> Sadly, there is no truth in advertising here, and there are no zero-cost abstractions...
 
This is a talk given at CppConference 2019 about costs when we do abstraction. The presenter gives three examples about the cost that could be easily looked over.
 
The first example is about an incremental feature rollout in Google's protocol buffers C++ codegen. The team made great efforts on cutting down runtime cost but it actually traded with a huge build time cost.
 
The second story is the runtime cost of `unique_ptr`. This is a very interesting one, as most people do not expect smart pointers to come with unignorable cost. The presenter shows the disassembly of calling an external function and passing the ownership of a `unique_ptr<int>` to the function, i.e. `baz(std::move(int_unique_ptr);`. Compared with passing the `int` use C pointer, using smart pointer generates additional instructions, which, by another look, are expensive memory load instructions on critical paths.
- If the callee has signature `void baz(std::unique_ptr<int> && int_unique_ptr)` which passes the pointer by reference, there are two additional memory loads generated because of the two indirection (one reference and one pointer) to the integer.
- If the callee has signature `void baz(std::unique_ptr<int> int_unique_ptr)` which passses the pointer by value, there are still instruction to push the `unique_ptr<int>` to stack and then load from stack after `baz(...)` returns. The stack push and pop can not be elided, because after `baz(...)` call, accessing `int_unique_ptr` is needed in `unique_ptr<int>`'s destruction. This behavior is defined by C++ ABI and `std::move` semantics and can not be changed.
 
The third story is about the maintenance cost of converting a block of code into more readable functions. I suppose this is a deja vu experience for most people. A block of code is hard to review and read, but a number of functions need you to jump around in the editor to read.
 
As the title says "there are no zero-cost abstraction". Everything is tradeoff. Keep this in mind when doing any refactoring.
