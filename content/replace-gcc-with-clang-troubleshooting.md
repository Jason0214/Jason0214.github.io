---
title: Replace gcc with clang Troubleshooting
lang: en-US
date: 2020-06-20
tags: [ toolchain ]
---

I was rebuilding [Interval-Based-Reclamation](https://github.com/roghnin/Interval-Based-Reclamation) with `clang` to adapt it to a microbenchmark for garbage collection with coroutine (`clang` has a better coroutine implementation). I made several mistakes which took me a long time to figure out. The mistakes are silly, while the investigation is kinda fun and worth sharing.

<!-- more -->

## Set libc++ in linker flags

The first mistake I made is that I forget to put `-stdlib=libc++` in `LD_FLAGS`.
Therefore I got a bunch of undefined reference error:
```
/usr/bin/../lib64/gcc/x86_64-pc-linux-gnu/10.1.0/../../../../include/c++/10.1.0/bits/basic_string.tcc:219: undefined reference to `std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_create(unsigned long&, unsigned long)'
/usr/bin/ld: ./ext/parharness/libparharness.a(Recorder.o): in function `void std::__cxx11::list<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, std::allocator<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > > >::_M_insert<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&>(std::_List_iterator<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > >, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&)':
...
```

[Interval-Based-Reclamation](https://github.com/roghnin/Interval-Based-Reclamation/blob/master/Makefile) uses Makefile.
It separates the compiler flags for source compiling and object linking into `CXX_FLAGS` and `LD_FLAGS` respectively,
which I failed to notice in the first place.
You will need `-stdlib=libc++` in `CXX_FLAGS` to find headers and in `LD_FLAGS` to find the shared libraries.

Actually there is no error information when you link an object using the `clang` command.
I realize the mistake I made only when I turn on compiler verbose mode.
``` bash
$ make CXX="clang++ -v" 2>&1 | grep stdc++
```
I got the log where I saw `-lstdc++` in the output of `ld` call made by `clang`
```
 "/usr/bin/ld" -pie --eh-frame-hdr -m elf_x86_64 -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o bin/release/main /usr/bin/../lib64/gcc/x86_64-pc-linux-gnu/10.1.0/../../../../lib64/Scrt1.o /usr/bin/../lib64/gcc/x86_64-pc-linux-gnu/10.1.0/../../../../lib64/crti.o /usr/bin/../lib64/gcc/x86_64-pc-linux-gnu/10.1.0/crtbeginS.o -L./ext/parharness -L/usr/bin/../lib64/gcc/x86_64-pc-linux-gnu/10.1.0 -L/usr/bin/../lib64/gcc/x86_64-pc-linux-gnu/10.1.0/../../../../lib64 -L/usr/bin/../lib64 -L/lib/../lib64 -L/usr/lib/../lib64 -L/usr/bin/../lib64/gcc/x86_64-pc-linux-gnu/10.1.0/../../.. -L/usr/bin/../lib -L/lib -L/usr/lib obj/release/src/CustomTests.o obj/release/src/rideables/BonsaiTreeRange.o obj/release/src/rideables/BonsaiTree.o obj/release/src/coroutine.o obj/release/src/main.o -lparharness -lhwloc -lpthread -lm -lrt -lstdc++ -lm -lgcc_s -lgcc -lc -lgcc_s -lgcc /usr/bin/../lib64/gcc/x86_64-pc-linux-gnu/10.1.0/crtendS.o /usr/bin/../lib64/gcc/x86_64-pc-linux-gnu/10.1.0/../../../../lib64/crtn.o
```

## Verify libc++ is visible to linker
After the fix of putting `-stdlib=libc++` to link flags, the linking issue persists.
Therefore, I made further checkups to veiryf libc++ is correctly installed.

``` bash
$ ldconfig -p | grep libc++
```
got
```
	libc++abi.so.1 (libc6,x86-64) => /usr/lib/libc++abi.so.1
	libc++abi.so (libc6,x86-64) => /usr/lib/libc++abi.so
	libc++.so.1 (libc6,x86-64) => /usr/lib/libc++.so.1
```
which is fine.

## Manually link libc++abi on Arch
Lot of threads on the web report linking issues building some C++ libraries on Arch Linux because of missing `libc++abi`.
For example, https://github.com/google/filament/issues/16.

In my case, the missing symbols seem to come from `libc++` (e.g. std::basic_string), not from `libc++abi`.
Anyway I tried put 
``` Makefile
LD_FLAGS += -lc++abi
```
in linking, it does not solve the issue as expected.


## Use lld to link shared libraries
I suspect that the GNU `ld` may have some issues in finding `libc++`, so I switched to LLVM `lld`.
Setup linking flags following [using-lld](https://lld.llvm.org/#using-lld)
``` Makefile
LD_FLAGS += -fuse-ld=lld
```

`lld` works surprisingly well. It noticeably increases linking speed and generates error messages that are far more readable.

```
ld.lld: error: undefined symbol: std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_assign(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&)
>>> referenced by basic_string.h:1366 (/usr/include/c++/10.1.0/bits/basic_string.h:1366)
>>>               TestConfig.o:(GlobalTestConfig::parseCommandLine(int, char**)) in archive ./ext/parharness/libparharness.a
>>> referenced by basic_string.h:1366 (/usr/include/c++/10.1.0/bits/basic_string.h:1366)
>>>               TestConfig.o:(GlobalTestConfig::parseCommandLine(int, char**)) in archive ./ext/parharness/libparharness.a
>>> referenced by basic_string.h:1366 (/usr/include/c++/10.1.0/bits/basic_string.h:1366)
>>>               TestConfig.o:(GlobalTestConfig::setEnv(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >)) in archive ./ext/parharness/libparharness.a
>>> referenced by basic_string.h:1366 (/usr/include/c++/10.1.0/bits/basic_string.h:1366)
>>>               Recorder.o:(Recorder::reportThreadInfo(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, int)) in archive ./ext/parharness/libparharness.a
>>> referenced by basic_string.h:1366 (/usr/include/c++/10.1.0/bits/basic_string.h:1366)
>>>               Recorder.o:(Recorder::reportGlobalInfo(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >)) in archive ./ext/parharness/libparharness.a
```

The errors all point to `./ext/parharness/libparharness.a` which is built from a submodule of [Interval-Based-Reclamation](https://github.com/roghnin/Interval-Based-Reclamation/tree/master/ext/parharness).

## Check symbols in objects
I further checks the symbols in each `.o` objects that are archived to `libparharness.a`.
I realize that `nm` is quite handy to check symbols, easier to use than `objdump`.
Specify `-g` to only display external symbols and `-C` to display a human readable symbol name. 

In `TestConfig.o`, an object from `libparharness.a`.
``` bash
$ nm -gC TestConfig.o  | grep getEnv
```
got 
```
0000000000002d30 T GlobalTestConfig::getEnv(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >)
```

In `main.o`
```
$ nm -gC main.o | grep getEnv
```
got 
```
                 U GlobalTestConfig::getEnv(std::__1::basic_string<char,std::__1::char_traits<char>, std::__1::allocator<char> >)
```

a namespace mismatch between `std::__1::` and `std::__cxx11`.
`std::__1::` is the default namespace for `libc++` with C++11 plus.
While `std::__cxx11` is the default namespace for `stdlibc++`.

I finally noticed that I made a typo in toggling `libc++` in `libparharness.a` where I put `-std=libc++` instead of `-stdlib=libc++`.

## Reference
- [https://stackoverflow.com/questions/38441490/how-to-check-if-libc-is-installed](https://stackoverflow.com/questions/38441490/how-to-check-if-libc-is-installed)
- [https://stackoverflow.com/questions/3880924/how-to-view-symbols-in-object-files](https://stackoverflow.com/questions/3880924/how-to-view-symbols-in-object-files)
- [https://stackoverflow.com/questions/29293394/where-does-the-1-symbol-come-from-when-using-llvms-libc](https://stackoverflow.com/questions/29293394/where-does-the-1-symbol-come-from-when-using-llvms-libc)


