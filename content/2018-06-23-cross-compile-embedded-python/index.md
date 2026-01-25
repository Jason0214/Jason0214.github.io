---
title: Cross Compile Embedded Python
lang: en-US
date: 2018-06-23
tags: [ embedded system ]

---

A Brief guide on how to cross compile a python embedded C program onto a linux based embedded device.

<!-- more -->

## Save effort by using python library

Python is somewhat a glue language, it can be easily embedded to almost all the popular languages.
(***here 'embedded' means calling python runtime inside other languages***)

Making use of python can save a lot of effort.
Here I want to take advantage of python's http lib to handle complex web requests in my C application.

## Use python on embedded devices

Not every embedded device can easily run python.
While there are some powerfully and popular embedded devices, **Raspberry Pi** and **Beagle Bone** , which are able to run an entire linux system.
It is fairly straightforward to run python on those devices.

## Cross compile python embedded C program on Beagle Bone Green

Here I use an example of Beagle Bone Green which has an ARM architecture and official Debian operating system support.

When cross compiling on host, python libraries and headers on your device need to be accessible.
Here are some useful tools that can help to locate the libraries:
- [pkg-config](https://linux.die.net/man/1/pkg-config): run `pkg-config --libs --cflags  python3` to find all the header files.
- [ldd](http://man7.org/linux/man-pages/man1/ldd.1.html): run `ldd /usr/bin/python3.4` to find static and shared libs.
- [readelf](https://linux.die.net/man/1/readelf) print out symbols in a .so file.


Use my BBG device as an example:
- python header files are located `/usr/include/python3.4m/*` and `/usr/include/arm-linux-gnueabihf/python3.4m/`
- python libs are at `/usr/lib/python3.4/config-3.4m-arm-linux-gnueabihf/libpython3.4*`, `/lib/arm-linux-gnueabihf/libz.so.1` and `/lib/arm-linux-gnueabihf/libexpat.so.1`.

I used an NFS directory to share the libs and headers to host. (following commands assume it set up at `/mnt/remote/`)
``` bash
cp -r /usr/include/python3.4m/* /mnt/remote/python3.4/include
mkdir /mnt/remote/python3.4/include/arm-linux-gnueabihf/
cp -r /usr/include/arm-linux-gnueabihf/python3.4m /mnt/remote/python3.4/include/arm-linux-gnueabihf/

cp /usr/lib/python3.4/config-3.4m-arm-linux-gnueabihf/libpython3.4* /mnt/remote/python3.4/lib/
cp /lib/arm-linux-gnueabihf/libz.so.1  /mnt/remote/python3.4/lib/libz.so
cp /lib/arm-linux-gnueabihf/libexpat.so.1  /mnt/remote/python3.4/lib/libexpat.so
```

Set compiler flags:
``` Makefile
...
# ~/foo/public is the NFS entry on the host
IFLAGS=-I$(HOME)/foo/public/python3.4/include
LFLAGS=-L$(HOME)/foo/public/python3.4/lib
...
```

## Use pip packages
Note that embedded python interpret does not load pip package path by default.
You need to call `PySys_SetPath()` to manually setup the paths of the python modules you want to access.
``` c
#define  PY_PACKAGE_PATH L"/usr/local/lib/python3.4/dist-packages"

wchar_t* wc_default_path = Py_GetPath();
size_t full_path_len = wcslen(wc_default_path) + 1 + wcslen(PY_PACKAGE_PATH) + 1;
wchar_t* wc_whole_path = (wchar_t*)malloc(sizeof(wchar_t) * full_path_len);
wcscpy(wc_whole_path, wc_default_path);
wcscat(wc_whole_path, L":");
wcscat(wc_whole_path, PY_PACKAGE_PATH);

PySys_SetPath(wc_whole_path)
```

## Be Aware of GIL
Most of the python implementation has a GIL, which can be quite annoying when you are using multi-threads.
Here is a [thread](https://stackoverflow.com/questions/15470367/pyeval-initthreads-in-python-3-how-when-to-call-it-the-saga-continues-ad-naus/15471525#15471525) that may help.

## Reference
- [https://stackoverflow.com/questions/48703423/cython-compile-a-standalone-static-executable](https://stackoverflow.com/questions/48703423/cython-compile-a-standalone-static-executable)
- [https://stackoverflow.com/questions/34732/how-do-i-list-the-symbols-in-a-so-file](https://stackoverflow.com/questions/34732/how-do-i-list-the-symbols-in-a-so-file)
- [https://stackoverflow.com/questions/15470367/pyeval-initthreads-in-python-3-how-when-to-call-it-the-saga-continues-ad-naus/15471525#15471525](https://stackoverflow.com/questions/15470367/pyeval-initthreads-in-python-3-how-when-to-call-it-the-saga-continues-ad-naus/15471525#15471525)
