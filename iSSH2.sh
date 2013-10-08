#!/bin/sh

#################### Configuration ####################
LIBSSL_VERSION="1.0.1e"
LIBSSH_VERSION="1.4.3"
SDK_VERSION="7.0"
#######################################################

echo "Initializing..."

export LIBSSL_VERSION
export LIBSSH_VERSION
export SDK_VERSION

export IPHONEOS_MINVERSION="6.0"
export ARCHS="i386 x86_64 armv7 armv7s arm64"

export BASEPATH=`pwd`
export LIBSSLDIR="${BASEPATH}/tmp/openssl-${LIBSSL_VERSION}"
export LIBSSHDIR="${BASEPATH}/tmp/libssh2-${LIBSSH_VERSION}"

export CLANG=`xcrun -find clang`
export DEVELOPER=`xcode-select -print-path`

set -e

echo "Building openssl ${LIBSSL_VERSION}:"
./iSSH2-openssl.sh

echo "Building libssh2 ${LIBSSH_VERSION}:"
./iSSH2-libssh2.sh