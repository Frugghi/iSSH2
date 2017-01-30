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

export SCRIPTNAME="iSSH2"

#Functions

cleanupFail () {
  if $1; then
    echo "Build failed, cleaning up temporary files..."
    rm -rf "$LIBSSLDIR/src/" "$LIBSSLDIR/tmp/" "$LIBSSHDIR/src/" "$LIBSSHDIR/tmp/"
    exit 1
  fi
}

cleanupAll () {
  if $1; then
    echo "Cleaning up temporary files..."
    rm -rf "$TEMPPATH"
  fi
}

getLibssh2Version () {
  if type git >/dev/null 2>&1; then
    LIBSSH_VERSION=`git ls-remote --tags https://github.com/libssh2/libssh2.git | egrep "libssh2-[0-9]+(\.[0-9])*[a-zA-Z]?$" | cut -f 2 -d - | sort -t . -r | head -n 1`
    LIBSSH_AUTO=true
  else
    echo "Install git to automatically get the latest Libssh2 version or use the --libssh2 argument"
    echo "Try '$SCRIPTNAME --help' for more information."
    exit 2
  fi
}

getOpensslVersion () {
  if type git >/dev/null 2>&1; then
    LIBSSL_VERSION=`git ls-remote --tags git://git.openssl.org/openssl.git | egrep "OpenSSL(_[0-9])+[a-zA-Z]?$" | cut -f 2,3,4 -d _ | egrep "^(0|1_0)" | sort -t _ -r | head -n 1 | tr _ .`
    LIBSSL_AUTO=true
  else
    echo "Install git to automatically get the latest OpenSSL version or use the --openssl argument"
    echo "Try '$SCRIPTNAME --help' for more information."
    exit 2
  fi
}

usageHelp () {
  echo
  echo "Usage: $SCRIPTNAME.sh [options]"
  echo
  echo "This script download and build OpenSSL and Libssh2 libraries."
  echo
  echo "Options:"
  echo "  -a, --archs=[ARCHS]       build for [ARCHS] architectures"
  echo "  -v, --min-version=VERS    set iPhone or Mac OS minimum version to VERS"
  echo "  -s, --sdk-version=VERS    use SDK version VERS"
  echo "  -l, --libssh2=VERS        download and build Libssh2 version VERS"
  echo "  -o, --openssl=VERS        download and build OpenSSL version VERS"
  echo "      --build-only-openssl  build OpenSSL and skip Libssh2"
  echo "      --no-clean            do not clean build folder"
  echo "      --osx                 build only for OSX"
  echo "      --no-bitcode          don't embed bitcode"
  echo "  -h, --help                display this help and exit"
  echo
  exit 1
}

#Config

export SDK_VERSION=
export LIBSSH_VERSION=
export LIBSSL_VERSION=
export MIN_VERSION=
export ARCHS=
export SDK_PLATFORM=
export EMBED_BITCODE="-fembed-bitcode"

OSX_ARCHS="i386 x86_64"
IOS_ARCHS="armv7 armv7s arm64"

BUILD_OSX=false
BUILD_SSL=true
BUILD_SSH=true
CLEAN_BUILD=true

while getopts ':a:l:o:v:s:h-' OPTION ; do
  case "$OPTION" in
    a) ARCHS="$OPTARG" ;;
    v) MIN_VERSION="$OPTARG" ;;
    s) SDK_VERSION="$OPTARG" ;;
    l) LIBSSH_VERSION="$OPTARG" ;;
    o) LIBSSL_VERSION="$OPTARG" ;;
    h) usageHelp ;;
    -) [[ $OPTIND -ge 1 ]] && optind=$(expr $OPTIND - 1 ) || optind=$OPTIND
         eval FULL_OPTION="\$$optind"
         OPTARG=$(echo $FULL_OPTION | cut -d'=' -f2)
         OPTION=$(echo $FULL_OPTION | cut -d'=' -f1)
         case "$OPTION" in
             --archs) ARCHS="$OPTARG" ;;
             --openssl) LIBSSL_VERSION="$OPTARG" ;;
             --libssh2) LIBSSH_VERSION="$OPTARG" ;;
             --sdk-version) SDK_VERSION="$OPTARG" ;;
             --min-version) MIN_VERSION="$OPTARG" ;;
             --build-only-openssl) BUILD_SSH=false ;;
             --only-print-env) BUILD_SSL=false; BUILD_SSH=false ;;
             --osx) BUILD_OSX=true ;;
             --no-bitcode) EMBED_BITCODE="" ;;
             --no-clean) CLEAN_BUILD=false ;;
             --help) usageHelp ;;
             * ) echo "$SCRIPTNAME: Invalid option '$FULL_OPTION'"
                  echo "Try '$SCRIPTNAME --help' for more information."
                  exit 1 ;;
         esac
       OPTIND=1
       shift
      ;;
    \?) echo "$SCRIPTNAME: Invalid option -- $OPTION"
        echo "Try '$SCRIPTNAME --help' for more information."
        exit 1 ;;
  esac
done

echo "Initializing..."

if [[ -z "$MIN_VERSION" ]]; then
  if [[ $BUILD_OSX == true ]]; then
    MIN_VERSION="10.10"
  else
    MIN_VERSION="8.0"
  fi
fi

if [[ -z "$ARCHS" ]]; then
  if [[ $BUILD_OSX == true ]]; then
    ARCHS="$OSX_ARCHS"
  else
    ARCHS="$IOS_ARCHS $OSX_ARCHS"
  fi
fi

LIBSSH_AUTO=false
if [[ -z "$LIBSSH_VERSION" ]]; then
  getLibssh2Version
fi

LIBSSL_AUTO=false
if [[ -z "$LIBSSL_VERSION" ]]; then
  getOpensslVersion
fi

if [[ $BUILD_OSX == true ]]; then
  SDK_PLATFORM="macosx"
else
  SDK_PLATFORM="iphoneos"
fi

SDK_AUTO=false
if [[ -z "$SDK_VERSION" ]]; then
   SDK_VERSION=`xcrun --sdk $SDK_PLATFORM --show-sdk-version`
   SDK_AUTO=true
fi

export BUILD_THREADS=$(sysctl hw.ncpu | awk '{print $2}')

export CLANG=`xcrun --find clang`
export GCC=`xcrun --find gcc`
export DEVELOPER=`xcode-select --print-path`

export BASEPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export TEMPPATH="$TMPDIR$SCRIPTNAME"
export LIBSSLDIR="$TEMPPATH/openssl-$LIBSSL_VERSION"
export LIBSSHDIR="$TEMPPATH/libssh2-$LIBSSH_VERSION"

#Env

echo
if [[ $LIBSSH_AUTO == true ]]; then
  echo "Libssh2 version: $LIBSSH_VERSION (Automatically detected)"
else
  echo "Libssh2 version: $LIBSSH_VERSION"
fi

if [[ $LIBSSL_AUTO == true ]]; then
  echo "OpenSSL version: $LIBSSL_VERSION (Automatically detected)"
else
  echo "OpenSSL version: $LIBSSL_VERSION"
fi

if [[ $SDK_AUTO == true ]]; then
  echo "SDK version: $SDK_VERSION (Automatically detected)"
else
  echo "SDK version: $SDK_VERSION"
fi

echo "Architectures: $ARCHS"
echo "OS min version: $MIN_VERSION"
echo

#Build

set -e

if [[ $BUILD_SSL == true ]]; then
  "$BASEPATH/iSSH2-openssl.sh" || cleanupFail $CLEAN_BUILD
fi

if [[ $BUILD_SSH == true ]]; then
  "$BASEPATH/iSSH2-libssh2.sh" || cleanupFail $CLEAN_BUILD
fi

if [[ $BUILD_SSL == true ]] || [[ $BUILD_SSH == true ]]; then
  cleanupAll $CLEAN_BUILD
fi
