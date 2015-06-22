# iSSH2

iSSH2 is a bash script for compiling Libssh2 (and OpenSSL) for iOS and iPhone Simulator.

The current version supports armv7, armv7s, arm64, i386, x86_64 architectures.

- Libssh2: [Website](http://www.libssh2.org) | [Documentation](http://www.libssh2.org/docs.html) | [Changelog](http://www.libssh2.org/changes.html)
- OpenSSL: [Website](http://www.openssl.org) | [Documentation](http://www.openssl.org/docs/) | [Changelog](http://www.openssl.org/news/)

## Requirements

- Xcode
- Xcode Command Line Tools
- iOS SDK

#### Optional Requirements

- git (required for automatically detection of latest version of Libssh2/OpenSSL)

## Tested with

- Xcode: 6.3.2
- iOS SDK: 8.3
- Libssh2: 1.6.0
- OpenSSL: 1.0.2c
- Architectures: armv7, armv7s, arm64, i386, x86_64

## How to use

1. Download the script
2. Run `iSSH2.sh` in Terminal
3. Take a cup of coffee while waiting

## Script help

```
Usage: iSSH2.sh [options]

This script download and build OpenSSL and Libssh2 libraries.

Options:
  -a, --archs=[ARCHS]              build for [ARCHS] architectures
                                   default is i386 x86_64 armv7 armv7s arm64
  -i, --iphoneos-min-version=VERS  set iPhoneOS minimum version to VERS;
                                   default is 6.0
  -s, --sdk-version=VERS           use SDK version VERS
  -l, --libssh2=VERS               download and build Libssh2 version VERS
  -o, --openssl=VERS               download and build OpenSSL version VERS
      --build-only-openssl         build OpenSSL and skip Libssh2
  -h, --help                       display this help and exit
```

## License

Copyright (c) 2015 Tommaso Madonia. All rights reserved.

```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
