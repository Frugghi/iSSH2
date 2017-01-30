#!/bin/bash
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

source "$BASEPATH/iSSH2-commons"

set -e

mkdir -p "$LIBSSLDIR"

LIBSSL_TAR="openssl-$LIBSSL_VERSION.tar.gz"

downloadFile "https://www.openssl.org/source/$LIBSSL_TAR" "$LIBSSLDIR/$LIBSSL_TAR"

LIBSSLSRC="$LIBSSLDIR/src/"
mkdir -p "$LIBSSLSRC"

set +e
echo "Extracting $LIBSSL_TAR"
tar -zxkf "$LIBSSLDIR/$LIBSSL_TAR" -C "$LIBSSLSRC" --strip-components 1 2>&-
set -e

echo "Building OpenSSL $LIBSSL_VERSION, please wait..."

for ARCH in $ARCHS
do
  if [[ "$SDK_PLATFORM" == "macosx" ]]; then
    PLATFORM="MacOSX"
    CONF="no-shared"
  else
    CONF="no-asm no-hw no-shared"
    if [[ "$ARCH" == "i386" ]] || [[ "$ARCH" == "x86_64" ]]; then
      PLATFORM="iPhoneSimulator"
    else
      PLATFORM="iPhoneOS"
    fi
  fi

  OPENSSLDIR="$LIBSSLDIR/$PLATFORM$SDK_VERSION-$ARCH"
  LIPO_LIBSSL="$LIPO_LIBSSL $OPENSSLDIR/libssl.a"
  LIPO_LIBCRYPTO="$LIPO_LIBCRYPTO $OPENSSLDIR/libcrypto.a"

  if [[ -f "$OPENSSLDIR/libssl.a" ]] && [[ -f "$OPENSSLDIR/libcrypto.a" ]]; then
    echo "libssl.a and libcrypto.a for $ARCH already exist."
  else
    rm -rf "$OPENSSLDIR"
    cp -R "$LIBSSLSRC"  "$OPENSSLDIR"
    cd "$OPENSSLDIR"

    LOG="$OPENSSLDIR/build-openssl.log"
    touch $LOG

    if [[ "$SDK_PLATFORM" == "macosx" ]]; then
      if [[ "$ARCH" == "x86_64" ]]; then
        HOST="darwin64-x86_64-cc"
      else
        HOST="darwin-$ARCH-cc"
      fi
    else
      if [[ "${ARCH}" == *64 ]]; then
        HOST="BSD-generic64"
        CONF="$CONF enable-ec_nistp_64_gcc_128"
      else
        HOST="BSD-generic32"
      fi
    fi

    if [[ "$PLATFORM" == "iPhoneOS" ]]; then
      sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "$OPENSSLDIR/crypto/ui/ui_openssl.c"
    fi

    export DEVROOT="$DEVELOPER/Platforms/$PLATFORM.platform/Developer"
    export SDKROOT="$DEVROOT/SDKs/$PLATFORM$SDK_VERSION.sdk"
    export CC="$CLANG -arch $ARCH"

    CONF="$CONF -m$SDK_PLATFORM-version-min=$MIN_VERSION $EMBED_BITCODE"

    ./Configure $HOST $CONF >> "$LOG" 2>&1

    #sed -ie "s!^CFLAG=!CFLAG=-isysroot $SDKROOT !" "Makefile"
    export CFLAG="-isysroot $SDKROOT"

    make depend >> "$LOG" 2>&1
    make -j "$BUILD_THREADS" build_libs >> "$LOG" 2>&1

    echo "- $PLATFORM $ARCH done!"
  fi
done

lipoFatLibrary "$LIPO_LIBSSL" "$BASEPATH/openssl/lib/libssl.a"
lipoFatLibrary "$LIPO_LIBCRYPTO" "$BASEPATH/openssl/lib/libcrypto.a"

importHeaders "$OPENSSLDIR/include/" "$BASEPATH/openssl/include"

echo "Building done."
