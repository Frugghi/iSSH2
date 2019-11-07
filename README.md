# iSSH2

iSSH2 is a bash script for compiling Libssh2 (and OpenSSL) for iOS, macOS, watchOS and tvOS.

- Libssh2: [Website](http://www.libssh2.org) | [Documentation](http://www.libssh2.org/docs.html) | [Changelog](http://www.libssh2.org/changes.html)
- OpenSSL: [Website](http://www.openssl.org) | [Documentation](http://www.openssl.org/docs/) | [Changelog](http://www.openssl.org/news/)

## Requirements

- Xcode
- Xcode Command Line Tools

#### Optional Requirements

- git (required for automatically detection of latest version of Libssh2/OpenSSL)

## Tested with

- Xcode: 11.2
- iOS SDK: 13.2
- Libssh2: 1.9.0
- OpenSSL: 1.1.1d
- Architectures: arm64 arm64e x86_64

## How to use

1. Download the script
2. Run `iSSH2.sh` passing `--platform=PLATFORM --min-version=VERS` or `--xcodeproj=PATH --target=TARGET` as options (for example: `./iSSH2.sh --platform=iphoneos --min-version=8.0`)
3. Take a cup of coffee while waiting

## Script help

```
Usage: iSSH2.sh [options]

This script download and build OpenSSL and Libssh2 libraries.

Options:
  -a, --archs=[ARCHS]       build for [ARCHS] architectures
  -p, --platform=PLATFORM   build for PLATFORM platform
  -v, --min-version=VERS    set platform minimum version to VERS
  -s, --sdk-version=VERS    use SDK version VERS
  -l, --libssh2=VERS        download and build Libssh2 version VERS
  -o, --openssl=VERS        download and build OpenSSL version VERS
  -x, --xcodeproj=PATH      get info from the project (requires TARGET)
  -t, --target=TARGET       get info from the target (requires XCODEPROJ)
      --build-only-openssl  build OpenSSL and skip Libssh2
      --no-clean            do not clean build folder
      --no-bitcode          don't embed bitcode
  -h, --help                display this help and exit

Valid platforms: iphoneos, macosx, appletvos, watchos

Xcodeproj and target or platform and min version must be set.
```

## License

Copyright (c) 2016 Tommaso Madonia. All rights reserved.

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
