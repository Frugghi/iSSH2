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

set -e

mkdir -p "${LIBSSHDIR}"

if [ ! -f "${LIBSSHDIR}/libssh2-${LIBSSH_VERSION}.tar.gz" ];
then
	echo "Downloading libssh2-${LIBSSH_VERSION}.tar.gz"
	curl --progress-bar "http://www.libssh2.org/download/libssh2-${LIBSSH_VERSION}.tar.gz" > "${LIBSSHDIR}/libssh2-${LIBSSH_VERSION}.tar.gz"
else
	echo "libssh2-${LIBSSH_VERSION}.tar.gz already exists"
fi

mkdir -p "${LIBSSHDIR}/src/"

set +e
echo "Extracting libssh2-${LIBSSH_VERSION}.tar.gz"
tar -zxkf "${LIBSSHDIR}/libssh2-${LIBSSH_VERSION}.tar.gz" -C "${LIBSSHDIR}/src" --strip-components 1 2>&-
set -e

echo "Building Libssh2 ${LIBSSH_VERSION}:"

for ARCH in ${ARCHS}
do
	if [ "${ARCH}" == "i386" -o "${ARCH}" == "x86_64" ];
	then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"	
	fi

	if [ "${ARCH}" == "arm64" ];
	then
		HOST="aarch64-apple-darwin"
	else
		HOST="${ARCH}-apple-darwin"
	fi

	OPENSSLDIR="${LIBSSLDIR}/${PLATFORM}${SDK_VERSION}-${ARCH}"
	LIBSSH2DIR="${LIBSSHDIR}/${PLATFORM}${SDK_VERSION}-${ARCH}"
	
	LIPO_SSH2="${LIPO_SSH2} ${LIBSSH2DIR}/lib/libssh2.a"

	echo "Building for ${PLATFORM} ${ARCH}, please wait..."

	if [ -f "${LIBSSH2DIR}/lib/libssh2.a" ];
	then
		echo "libssh2.a for ${ARCH} already exists."
		continue
	fi

	rm -rf "${LIBSSHDIR}/tmp/"
	mkdir -p "${LIBSSHDIR}/tmp/"
	cp -R "${LIBSSHDIR}/src/" "${LIBSSHDIR}/tmp/"
	
	cd "${LIBSSHDIR}/tmp/"

	rm -rf "${LIBSSH2DIR}"
	mkdir -p "${LIBSSH2DIR}"

	LOG="${LIBSSH2DIR}/build-libssh2.log"

	export DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDK_VERSION}.sdk"
	export CC="${CLANG}"
	export CPP="${CLANG} -E"
	export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -miphoneos-version-min=${IPHONEOS_MINVERSION}"
	export CPPFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -miphoneos-version-min=${IPHONEOS_MINVERSION}"

	./Configure --host=${HOST} --prefix="${LIBSSH2DIR}" --with-openssl --with-libssl-prefix="${OPENSSLDIR}" --disable-shared --enable-static  >> "${LOG}" 2>&1

	make >> "${LOG}" 2>&1
	make install >> "${LOG}" 2>&1
	make clean >> "${LOG}" 2>&1
	
	echo "Building done."
done

echo "Building fat library..."
rm -rf "${BASEPATH}/libssh2/lib/"
mkdir -p "${BASEPATH}/libssh2/lib/"
lipo -create ${LIPO_SSH2} -output "${BASEPATH}/libssh2/lib/libssh2.a"

echo "Copying headers..."
rm -rf "${BASEPATH}/libssh2/include/"
mkdir -p "${BASEPATH}/libssh2/include/"
cp -RL "${LIBSSHDIR}/src/include/" "${BASEPATH}/libssh2/include/"

echo "Building done."