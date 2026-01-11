---
title: Coroutine to Hide Cache Miss Optimization (1)
lang: en-US
date: 2021-02-15
tags: [ compiler ]
---

Last year I co-authored the [Corobase](http://www.vldb.org/pvldb/vol14/p431-he.pdf) paper
which was published on PVLDB 2021.
The paper describes the approach to hide data stalls in an in-memory database with [stackless coroutine](https://en.cppreference.com/w/cpp/language/coroutines).
Still, there left several open questions, for example, how to properly inline a coroutine,
which this post may help you to understand. 

<!-- more -->

## Stackless coroutine 
First, what is coroutine? Coroutine was born in the early days of computers, as a sibling of Function.
Function is one-shot subroutine,
while Coroutine can be suspended in the middle to return to the caller and then get resumed some time later.
Stackless coroutine is opposed to stackful coroutine.
They are different implementations of coroutine.

Most of the libraries implement coroutine and fiber (coroutine on thread executors) with stackful coroutine, for example Boost::Coroutine.
Stackful coroutine allocates another stack dedicated to a coroutine context.
The side stack is identical to the process stack,
which uses frame pointer, stack pointer, etc. to manage coroutine call stack.
Stackful coroutine can be easily suspended because all the coroutine's states resides in the coroutine stack
and never interfere with the process stack. 

Stackless coroutine implementation has no side stacks.
Stack frame of a coroutine call lies on the process stack.
This design makes coroutine cheaper to call, suspend and resume than its stackful peer,
where the latter has a larger memory footprint and requires dynamic allocations when stack grows.
However, running coroutine on the process stack makes suspending and resuming not straightforward.
Each time the coroutine get resumed, a new stack frame is pushed to the stack.
But there are runtime states, such as value of local variables that lives across suspendings.
Obviously, the states can not be saved not on the stack,
otherwise they quickly gets overwritten by function calls following coroutine suspending.

The clang(LLVM)'s implementation of stackless coroutine dynamic allocates the memory called coroutine frame
for keeping the states.
Local variables are saved to the coroutine frame on suspending and reloaded back to the process stack on resuming.
Other states like return value and whether suspendable go to the coroutine frame as well.

## Coroutine to hide data stall
The clang's implementation of stackless coroutine has very cheap context switches
(not the same "context-switch" in multi-threading,
here it means suspending from a coroutine and resuming another one).
I am not able to find the exact timing of a context switch,
but it is definitely cheaper than a last level cache-miss
on modern server CPUs (which actually have lower frequency than desktop ones) and latest DRAMs.

The fact leads to the idea about hiding memory stalls with coroutine-alike executions.
Basically, on data loading where cache miss is very likely to happen,
issue a memory prefetch following a coroutine suspend (Note, suspending is unconditionally.
There is no way for any arch to tell by definite whether the data is going to miss).
So that data is getting loaded from memory to cache, in the meantime that data won't be used by CPU at the moment,
and no data stalls.
When the next time, this suspended coroutine gets resumed, hopefully the loading data is already in cache.

As far as I know, the technique started from
[Asynchronous Memory Access Chaining](https://dl.acm.org/doi/10.14778/2856318.2856321#:~:text=This%20work%20introduces%20Asynchronous%20Memory,from%20that%20of%20other%20lookups.)
which manages a state-machine-alike AMAC by hand to do suspending and resuming,
then followed by
[Interleaving with Coroutines: A Practical Approach for Robust Index Joins](http://www.vldb.org/pvldb/vol11/p230-psaropoulos.pdf)
to replace AMAC with stackless coroutine and confirmed its effectiveness on Binary Search,
and then
[Exploiting Coroutines to Attack the “Killer Nanoseconds”](http://www.vldb.org/pvldb/vol11/p1702-jonathan.pdf)
evaluates stackless coroutine on Masstree and BwTree.

[Corobase](http://www.vldb.org/pvldb/vol14/p431-he.pdf) is a follow up work to employ the technique to the whole database.

## Target at usability
[Exploiting Coroutines to Attack the “Killer Nanoseconds”](http://www.vldb.org/pvldb/vol11/p1702-jonathan.pdf)
is a great paper about hiding data stalls on complex indexing data structures such as Masstree,
but unfortunately it is not open sourced to use.

[Corobase](http://www.vldb.org/pvldb/vol14/p431-he.pdf) has no ambition to surpass the performance of
[Exploiting Coroutines to Attack the “Killer Nanoseconds”](http://www.vldb.org/pvldb/vol11/p1702-jonathan.pdf).
Because in whole databases, coroutine not only needs to operate on the indexing Masstree
(for people not familiar, it is a combination of B+Tree and Trie),
but also the value storage, in our case, MVCC
(Multi-version concurrency control, each value is a linked list of different snapshots in different timestamps). 
Complex data structures lead to un-uniform (and larger) memory footprints and less regular cache misses.
That's the reality.

[Corobase](http://www.vldb.org/pvldb/vol14/p431-he.pdf) does not want to be a proof of concept,
others already proved it well.
It wants to be really useful for industry, where a traditional database can make very limited modifications to use the coroutine.

In the [coroutine implementation](https://github.com/sfu-dis/Corobase/blob/81ddcf54a553e6feb6a706580d91574ec53870ab/dbcore/sm-coroutine.h#L517), a normal function can be convert to a coroutine by:
1. Replace return type `T` with `Promise(T)` in function definition.
2. Insert `std::suspend_always` and `prefetch` on a data load that is highly likely to cause cache miss.

We happily rollout this change to our previous non-coroutine database,
However, we found it does not scale well with the level of function calls.
Note, a nested stackless coroutine requires manual management of its call chain,
so that each uncompleted coroutine in the chain gets resumed in the correct order.
Corobase used a double linked list to do it, after comparing performance of stack, circular-array, etc.
We didn't manage to solve the scale problem in the end and falls back to a two-level approach,
which basically needs to "inline" a chain of function calls into a big function by hand.
Read the paper for the details if you are interested.

## Inline Coroutine in LLVM, Possible?

The two-level approach works great on real world workloads with a reasonable amount of throughput improvement.
But it is not so good from the user perspective.
Inlining by hand to two-level, though very easy to do, should definitely be done by the compiler.

Automating inlining coroutine is not trivial.
For functions you can put `inline` attributes to hint the compiler,
there is no way to do the same thing for a coroutine.
Coroutine is not a function from the perspective of LLVM.
In the LLVM optimization passes,
coroutine get splitted to three functions in the name of `xxx.init()`, `xxx.resume()` and `xxx.destroy()`
right before CGSCC (call graph strongly connected components) pass.
In CGSCC, each splitted function may be inlined if they get devirtualized.
Refer to [https://lists.llvm.org/pipermail/llvm-dev/2016-July/102337.html](https://lists.llvm.org/pipermail/llvm-dev/2016-July/102337.html) for the optimization passes design for coroutine.

Why "devirtualized"? Because C++ coroutine is manipulated through `coroutine_handle<promise_type_T>`
or a generic handle `coroutine_handle<void>`.
Resume a coroutine by calling `coroutine_handle<void>.resume()` is an indirect function call.
Virtual function call can not be inlined.
Unfortunately Corobase resumes every coroutine indirectly:
1. direct call [`co_await <expr>`](https://github.com/sfu-dis/Corobase/blob/81ddcf54a553e6feb6a706580d91574ec53870ab/masstree/masstree_get.hh#L64) only reaches [`initial_suspend`](https://github.com/sfu-dis/Corobase/blob/81ddcf54a553e6feb6a706580d91574ec53870ab/dbcore/sm-coroutine.h#L107) without doing any work.
2. in [scheduler](https://github.com/sfu-dis/Corobase/blob/81ddcf54a553e6feb6a706580d91574ec53870ab/benchmarks/ycsb-cs-advance.cc#L76), where schedule the next coroutine resumption, every call is indirect.

Will explain later why `initial_suspend` is necessary and what happens if remove.

## How to improve?

The scheduler part is identical in both nested and two-level.
So if we can make every `co_await <expr>` inlined,
then hopefully nested coroutine calls would have performance close to two-level ones.

The above fact is not that intuitive, more explaining:
A chain of coroutines, whether two-level and nested,
are all executed from `coroutine_handle<void>.resume()` in `scheduler`.
The number of `coroutine_handle<void>.resume()` gets called is same for two-level and nested,
which depends on the added suspending points.
Two-level only eliminites the `co_await <expr>` calls inside each `coroutine_handle<void>.resume()`
(and two-level made the assumption that the linked list can only has two nodes, but I think that is neglectable).

The following text describes some of my ideas and practices to try to inline the `co_await <expr>`.

#### 1) Immediately resume after initial_suspend

`co_await <expr>;` internally is `awaitable_T awaitable_instance = <expr>; co_await awaitable_instance;`
`initial_suspend` happens in `awaitable_instance`'s construction and
`co_await` translates to a `await_suspend()` call on `awaitable_T::awaiter`.

In Corobase, `await_suspend()` does nothing but establish the caller and callee relation,
all the resuming are handled in the scheduler by indirect calls.

I tried to move the first `resume()` textually close to the `awaitable_instance`'s construction,
hoping the compiler is able to devirtualize the resuming call by referring to its local context.

The following lines of code get added in `awaitable_T::awaiter`.
Because of the `initial_suspend`, this resuming should always be a valid call.
``` Diff
// suspended_task_coroutine points to coroutine being co_awaited on
//
// awaiting_coroutine points to the coroutine running co_await
// (i.e. it waits for suspended_task_coroutine to complete first)
template <typename T> struct task<T>::awaiter {
...
  template <typename awaiting_promise_t>
  auto await_suspend(std::experimental::coroutine_handle<awaiting_promise_t> awaiting_coroutine) noexcept {
    suspended_task_coroutine_.promise().set_parent(&(awaiting_coroutine.promise()));
+   suspended_task_coroutine_.resume();
+   // Force coroutine with no suspending points invalid.
+   ASSERT(!suspended_task_coroutine_.done());
-    return suspended_task_coroutine_;
+    return void;
  }
  
  constexpr bool await_ready() const noexcept {
      return false;
  }
...
};
```

I compiled a simplified version of the [sample](https://github.com/sfu-dis/Corobase/blob/81ddcf54a553e6feb6a706580d91574ec53870ab/tests/coroutine/resume_order.cpp)
and checked the generated LLVM IR in `-O3`:
``` LLVM
; demangle to task<void> ChainedCoroCall<5>(int*).resume
define internal fastcc void @_Z15ChainedCoroCallILi5EE4taskIvEPi.resume(%_Z15ChainedCoroCallILi5EE4taskIvEPi.Frame* noalias nonnull align 8 dereferenceable(432) %FramePtr) #0 {
    ...
; demangle to promise_base::set_parent(promise_base*)
_ZN12promise_base10set_parentEPS_.exit.i:         ; preds = %init.ready
    ...
    ; demangle to task<void> ChainedCoroCall<4>(int*).resume
    call fastcc void @_Z15ChainedCoroCallILi4EE4taskIvEPi.resume(%_Z15ChainedCoroCallILi4EE4taskIvEPi.Frame* nonnull %.reload.addr119) #2
    ; demangle to task<void> ChainedCoroCall<4>(int*).Frame
    ; direct call :)
    %18 = bitcast %_Z15ChainedCoroCallILi4EE4taskIvEPi.Frame* %.reload.addr119 to i8**
    %19 = load i8*, i8** %18, align 8
    %20 = icmp eq i8* %19, null
    ...
  
```
Compare to the resuming call in scheduler:
``` LLVM
; demangle to promise_base::get_leaf() const
...
_ZNK12promise_base8get_leafEv.exit:               ; preds = %_ZNK12promise_base8get_leafEv.exit64
  %8 = bitcast i8* %retval.sroa.0.0.copyload.i71 to { i8*, i8* }*
  %9 = getelementptr inbounds { i8*, i8* }, { i8*, i8* }* %8, i32 0, i32 0
  %10 = load i8*, i8** %9, align 8
  %11 = bitcast i8* %10 to void (i8*)*
  ; indirect call :(
  tail call fastcc void %11(i8* nonnull %retval.sroa.0.0.copyload.i71) #2
  ret void
...
```
~~We are getting direct call to `ChainedCoroCall<4>(int*).resume`!~~

(Edit: When `return suspended_task_coroutine_`, the suspended task will be resumed immediately. So there is no new direct call here compared to Corobase)

If we can somehow get some attributes passed into the optimization pass or even tweak the optimizer,
we can definitely inline this.
I will leave the actual inling and performance comparison for the next post.

#### 2) Remove `initial_suspend`

`initial_suspend` exists in the double linked list tracking of coroutine frames to
let the leaf coroutine frame set itself to the root coroutine frame so that
when resuming leaf coroutine can be jumped to with O(1) cost.

Without `initial_suspend`, the callee can spawn another coroutine frame before establish the
"parent" relation with its caller through `co_await`.
That may cause the chain of coroutine frame breaking in the middle when the leaf coroutine frame suspends.

To compensate, either
1) do a full linked list traversal in resuming a chain of coroutine to find the leaf,
which takes O(Num_Of_Level) and obviously does not scale. (Inlining reduces Num_Of_Level to 1? so O(1)?
2) or traverse part of the linked list in `co_await` to update the leaf,
which I don't see the amortized cost but can not be ignored.
3) Get rid of the linked list entirely.
Use a `static thread_local` FIFO to maintain the coroutine frames' dependencies instead.
We have tested this approach before Corobase and it does not perform well.

Still, I removed `initial_suspend` and made changes to the linked list accordingly,
the generated IR in `-O3` for the same sample:
``` LLVM
; demangled to task<void> ChainedCoroCall<5>(int*)
define linkonce_odr void @_Z15ChainedCoroCallILi5EE4taskIvEPi(%class.task* noalias sret align 8 %agg.result, i32* %callLevelCounter) #0 {
    ...
    call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %ref.tmp11) #2
    ; demangled to task<void> ChainedCoroCall<4>(int*)
    ; direct call :)
    call void @_Z15ChainedCoroCallILi4EE4taskIvEPi(%class.task* nonnull sret align 8 %1, i32* nonnull %callLevelCounter)
    ...
    ret void
```
Note `ChainedCoroCall<>.resume()` in the previous trial becomes `ChainedCoroCall<>()`.
Because removing `initial_suspend` causing the actual logic goes to different places in splitting.
But anyway, we get a not inlined direct call again！

Same as above, the performance evaluation will go to another post.

#### 3) Write custom pass to inline coroutine before splitting

Changing the implementation for awaitable is not the only possible way to inline.
LLVM's optimization pass manager has open interfaces allowing it to create custom passes.

Because of the default coroutine optimization pass does splitting,
a good shot to do inlining in a custom pass is to inline before splitting
which basically automates the "inline by hand" in Corobase.

But it leads to the problem that the custom pass would be doing inling in places (outside CGSCC)
that should not do intra function optimization.
You never know what would happen if doing so, therefore I consider this to be "the wrong way".

#### 4) Replace coroutine optimization pass entirely

Does coroutine really need splitting? I guess not necessarily.
Without splitting, coroutine is just a function with some builtin templates that handles
a dynamic memory region and a virtual interface.

I haven't figured out the reason behind the splitting optimization.
But it might be something serving the common usage for stackless coroutine
(Corobase is minority),
such as a multi-threaded event loop to hide IO latency.

A fully rewrite of coroutine optimization passes would cost a lot effort
and very likely never possible to be merged into upstream.
I would not take this path when others are workable.

#### 5) Rust's design

I was told by a friend who did a lot work in Rust
that Rust async, which also uses LLVM stackless coroutine as backend,
exposes a global state machine.

Users get fast context switches without thinking "the chain of coroutine frames".
Same, will look into the design of Rust coroutine in the next post.

# Reference
- [https://llvm.org/devmtg/2016-11/Slides/Nishanov-LLVMCoroutines.pdf](https://llvm.org/devmtg/2016-11/Slides/Nishanov-LLVMCoroutines.pdf)
- [https://reviews.llvm.org/D23234](https://reviews.llvm.org/D23234)
- [https://lists.llvm.org/pipermail/llvm-dev/2016-July/102337.html](https://lists.llvm.org/pipermail/llvm-dev/2016-July/102337.html)
- [https://youtu.be/8C8NnE1Dg4A?t=841](https://youtu.be/8C8NnE1Dg4A?t=841)
- [https://llvm.org/docs/Coroutines.html](https://llvm.org/docs/Coroutines.html)
- [http://www.cs.cornell.edu/~asampson/blog/clangpass.html](http://www.cs.cornell.edu/~asampson/blog/clangpass.html)


