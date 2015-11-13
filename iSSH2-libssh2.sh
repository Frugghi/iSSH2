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

set -e

source ./iSSH2-functions

mkdir -p "$LIBSSHDIR"

LIBSSH_TAR="libssh2-$LIBSSH_VERSION.tar.gz"

downloadFile "http://www.libssh2.org/download/$LIBSSH_TAR" "$LIBSSHDIR/$LIBSSH_TAR"

LIBSSHSRC="$LIBSSHDIR/src/"
mkdir -p "$LIBSSHSRC"

set +e
echo "Extracting $LIBSSH_TAR"
tar -zxkf "$LIBSSHDIR/$LIBSSH_TAR" -C "$LIBSSHDIR/src" --strip-components 1 2>&-
set -e

echo "Building Libssh2 $LIBSSH_VERSION:"

for ARCH in $ARCHS
do
	if [ "$ARCH" == "i386" -o "$ARCH" == "x86_64" ];
	then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi

	OPENSSLDIR="$BASEPATH/openssl/"
	LIBSSH2DIR="$LIBSSHDIR/$PLATFORM$SDK_VERSION-$ARCH"
	LIPO_SSH2="$LIPO_SSH2 $LIBSSH2DIR/lib/libssh2.a"

	(
	if [ -f "$LIBSSH2DIR/lib/libssh2.a" ];
	then
		echo "libssh2.a for $ARCH already exists."
		exit 0
	fi

	rm -rf "$LIBSSH2DIR"
	cp -R "$LIBSSHSRC"  "$LIBSSH2DIR"
	cd "$LIBSSH2DIR"

	LOG="$LIBSSH2DIR/build-libssh2.log"
	touch $LOG

	if [ "$ARCH" == "arm64" ];
	then
		HOST="aarch64-apple-darwin"
	else
		HOST="$ARCH-apple-darwin"
	fi

	export DEVROOT="$DEVELOPER/Platforms/$PLATFORM.platform/Developer"
	export SDKROOT="$DEVROOT/SDKs/$PLATFORM$SDK_VERSION.sdk"
	export CC="$CLANG"
	export CPP="$CLANG -E"
	export CFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IPHONEOS_MINVERSION -fembed-bitcode"
	export CPPFLAGS="-arch $ARCH -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IPHONEOS_MINVERSION"

	./Configure --host=$HOST --prefix="$LIBSSH2DIR" --with-openssl --with-libssl-prefix="$OPENSSLDIR" --disable-shared --enable-static  >> "$LOG" 2>&1

	make >> "$LOG" 2>&1
	make install >> "$LOG" 2>&1

	echo "- $PLATFORM $ARCH done!"
	)&
done

wait

lipoFatLibrary "$LIPO_SSH2" "$BASEPATH/libssh2/lib/libssh2.a"

importHeaders "$LIBSSHSRC/include/" "$BASEPATH/libssh2/include"

echo "Building done."
