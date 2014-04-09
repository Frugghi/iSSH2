#!/bin/sh
                                   #########
#################################### iSSH2 #####################################
#                                  #########                                   #
# Copyright (c) 2013 Tommaso Madonia. All rights reserved.                     #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to deal#
# in the Software without restriction, including without limitation the rights #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell    #
# copies of the Software, and to permit persons to whom the Software is        #
# furnished to do so, subject to the following conditions:                     #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,#
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN    #
# THE SOFTWARE.                                                                #
################################################################################

                               #################
################################ Configuration #################################
#                              #################                               #
 LIBSSL_VERSION="1.0.1g"
 LIBSSH_VERSION="1.4.3"
################################################################################

echo "Initializing..."

export LIBSSL_VERSION
export LIBSSH_VERSION

export IPHONEOS_MINVERSION="6.0"
export ARCHS="i386 x86_64 armv7 armv7s arm64"

export BASEPATH="${PWD}"
export LIBSSLDIR="${BASEPATH}/tmp/openssl-${LIBSSL_VERSION}"
export LIBSSHDIR="${BASEPATH}/tmp/libssh2-${LIBSSH_VERSION}"

export SDK_VERSION=`xcrun --sdk iphoneos --show-sdk-version`
export CLANG=`xcrun --find clang`
export DEVELOPER=`xcode-select --print-path`

set -e

./iSSH2-openssl.sh
./iSSH2-libssh2.sh