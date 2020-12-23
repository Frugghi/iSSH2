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
    >&2 echo "Build failed, cleaning up temporary files..."
    rm -rf "$LIBSSLDIR/src/" "$LIBSSLDIR/tmp/" "$LIBSSHDIR/src/" "$LIBSSHDIR/tmp/"
  else
    >&2 echo "Build failed, temporary files location: $TEMPPATH"
  fi
  exit 1
}

cleanupAll () {
  if $1; then
    echo "Cleaning up temporary files..."
    rm -rf "$TEMPPATH"
  else
    echo "Temporary files location: $TEMPPATH"
  fi
}

getLibssh2Version () {
  if type git >/dev/null 2>&1; then
    LIBSSH_VERSION=`git ls-remote --tags https://github.com/libssh2/libssh2.git | egrep "libssh2-[0-9]+(\.[0-9])*[a-zA-Z]?$" | cut -f 2 -d - | sort -t . -r | head -n 1`
    LIBSSH_AUTO=true
  else
    >&2 echo "Install git to automatically get the latest Libssh2 version or use the --libssh2 argument"
    >&2 echo
    >&2 echo "Try '$SCRIPTNAME --help' for more information."
    exit 2
  fi
}

getOpensslVersion () {
  if type git >/dev/null 2>&1; then
    LIBSSL_VERSION=`git ls-remote --tags git://git.openssl.org/openssl.git | egrep "OpenSSL(_[0-9])+[a-zA-Z]?$" | cut -f 2,3,4 -d _ | sort -t _ -r | head -n 1 | tr _ .`
    LIBSSL_AUTO=true
  else
    >&2 echo "Install git to automatically get the latest OpenSSL version or use the --openssl argument"
    >&2 echo
    >&2 echo "Try '$SCRIPTNAME --help' for more information."
    exit 2
  fi
}

getBuildSetting () {
  echo "${1}" | grep -i "^\s*${2}\s*=\s*" | cut -d= -f2 | xargs echo -n
}

version () {
  printf "%02d%02d%02d" ${1//./ }
}

usageHelp () {
  echo
  echo "Usage: $SCRIPTNAME.sh [options]"
  echo
  echo "This script download and build OpenSSL and Libssh2 libraries."
  echo
  echo "Options:"
  echo "  -a, --archs=[ARCHS]       build for [ARCHS] architectures"
  echo "  -p, --platform=PLATFORM   build for PLATFORM platform"
  echo "  -v, --min-version=VERS    set platform minimum version to VERS"
  echo "  -s, --sdk-version=VERS    use SDK version VERS"
  echo "  -l, --libssh2=VERS        download and build Libssh2 version VERS"
  echo "  -o, --openssl=VERS        download and build OpenSSL version VERS"
  echo "  -x, --xcodeproj=PATH      get info from the project (requires TARGET)"
  echo "  -t, --target=TARGET       get info from the target (requires XCODEPROJ)"
  echo "      --build-only-openssl  build OpenSSL and skip Libssh2"
  echo "      --no-clean            do not clean build folder"
  echo "      --no-bitcode          don't embed bitcode"
  echo "  -h, --help                display this help and exit"
  echo
  echo "Valid platforms: iphoneos, macosx, appletvos, watchos"
  echo
  echo "Xcodeproj and target or platform and min version must be set."
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

BUILD_OSX=false
BUILD_SSL=true
BUILD_SSH=true
CLEAN_BUILD=true

XCODE_PROJECT=
TARGET_NAME=

while getopts 'a:p:l:o:v:s:x:t:h-' OPTION ; do
  case "$OPTION" in
    a) ARCHS="$OPTARG" ;;
    p) SDK_PLATFORM="$OPTARG" ;;
    v) MIN_VERSION="$OPTARG" ;;
    s) SDK_VERSION="$OPTARG" ;;
    l) LIBSSH_VERSION="$OPTARG" ;;
    o) LIBSSL_VERSION="$OPTARG" ;;
    x) XCODE_PROJECT="$OPTARG" ;;
    t) TARGET_NAME="$OPTARG" ;;
    h) usageHelp ;;
    -) eval FULL_OPTION="\$$OPTIND"
       OPTARG=$(echo $FULL_OPTION | cut -d'=' -f2)
       OPTION=$(echo $FULL_OPTION | cut -d'=' -f1)
       case "$OPTION" in
         --archs) ARCHS="$OPTARG" ;;
         --platform) SDK_PLATFORM="$OPTARG" ;;
         --openssl) LIBSSL_VERSION="$OPTARG" ;;
         --libssh2) LIBSSH_VERSION="$OPTARG" ;;
         --sdk-version) SDK_VERSION="$OPTARG" ;;
         --min-version) MIN_VERSION="$OPTARG" ;;
         --xcodeproj) XCODE_PROJECT="$OPTARG" ;;
         --target) TARGET_NAME="$OPTARG" ;;
         --build-only-openssl) BUILD_SSH=false ;;
         --only-print-env) BUILD_SSL=false; BUILD_SSH=false ;;
         --osx) BUILD_OSX=true ;;
         --no-bitcode) EMBED_BITCODE="" ;;
         --no-clean) CLEAN_BUILD=false ;;
         --help) usageHelp ;;
         * ) echo "$SCRIPTNAME: Invalid option '$FULL_OPTION'"
             echo "Run '$SCRIPTNAME --help' for more information."
             exit 1 ;;
       esac
       shift
      ;;
    \?) echo "$SCRIPTNAME: Invalid option -- $OPTION"
        echo "Run '$SCRIPTNAME --help' for more information."
        exit 1 ;;
  esac
  shift $((OPTIND - 1))
  OPTIND=1
done

echo "Initializing..."

XCODE_VERSION=`xcodebuild -version | grep Xcode | cut -d' ' -f2`

if [[ ! -z "$XCODE_PROJECT" ]] && [[ ! -z "$TARGET_NAME" ]]; then
  BUILD_SETTINGS=`xcodebuild -project "$XCODE_PROJECT" -target "$TARGET_NAME" -showBuildSettings`
  SDK_PLATFORM=`getBuildSetting "$BUILD_SETTINGS" "PLATFORM_NAME"`
  MIN_VERSION=`getBuildSetting "$BUILD_SETTINGS" "${SDK_PLATFORM}_DEPLOYMENT_TARGET"`
  TARGET_ARCHS=`getBuildSetting "$BUILD_SETTINGS" "VALID_ARCHS"`
fi

if [[ -z "$SDK_PLATFORM" ]]; then
  >&2 echo "$SCRIPTNAME: Platform must be specified."
  >&2 echo "Specify --platform=PLATFORM or --xcodeproj=PATH and --target=TARGET"
  >&2 echo
  >&2 echo "Run '$SCRIPTNAME --help' for more information."
  exit 1
fi

if [[ -z "$MIN_VERSION" ]]; then
  >&2 echo "$SCRIPTNAME: Minimum platform version must be specified."
  >&2 echo "Specify --min-version=VERS or --xcodeproj=PATH and --target=TARGET"
  >&2 echo
  >&2 echo "Run '$SCRIPTNAME --help' for more information."
  exit 1
fi

if [[  "$SDK_PLATFORM" == "macosx" ]] || [[ "$SDK_PLATFORM" == "iphoneos" ]] || [[ "$SDK_PLATFORM" == "appletvos" ]] || [[ "$SDK_PLATFORM" == "watchos" ]]; then
  if [[ -z "$ARCHS" ]]; then
    ARCHS="$TARGET_ARCHS"

    if [[ "$SDK_PLATFORM" == "macosx" ]]; then
      if [[ -z "$ARCHS" ]]; then
        ARCHS="x86_64"

        if [[ $(version "$XCODE_VERSION") < $(version "10.0") ]]; then
          ARCHS="$ARCHS i386"
        fi
      fi
    elif [[ "$SDK_PLATFORM" == "iphoneos" ]]; then
      if [[ -z "$ARCHS" ]]; then
        ARCHS="arm64"

        if [[ $(version "$XCODE_VERSION") == $(version "10.1") ]] || [[ $(version "$XCODE_VERSION") > $(version "10.1") ]]; then
          ARCHS="$ARCHS arm64e"
        fi

        if [[ $(version "$MIN_VERSION") < $(version "10.0") ]]; then
          ARCHS="$ARCHS armv7 armv7s"
        fi
        if [[ $(version "$XCODE_VERSION") -ge $(version "12.0") ]]; then
          ARCHS="$ARCHS arm64"
        fi
      fi

      ARCHS="$ARCHS x86_64"

      if [[ $(version "$MIN_VERSION") < $(version "10.0") ]]; then
        ARCHS="$ARCHS i386"
      fi
    elif [[ "$SDK_PLATFORM" == "appletvos" ]]; then
      ARCHS="$ARCHS arm64 x86_64"
    elif [[ "$SDK_PLATFORM" == "watchos" ]]; then
      ARCHS="$ARCHS i386 armv7k"

      if [[ $(version "$XCODE_VERSION") == $(version "10.0") ]] || [[ $(version "$XCODE_VERSION") > $(version "10.0") ]]; then
        ARCHS="$ARCHS arm64_32"
      fi
    fi
  fi
else
  >&2 echo "$SCRIPTNAME: Unknown platform '$SDK_PLATFORM'"
  >&2 echo "Run '$SCRIPTNAME --help' for more information."
  exit 1
fi

ARCHS="$(echo "$ARCHS" | tr ' ' '\n' | sort -u | tr '\n' ' ')"

LIBSSH_AUTO=false
if [[ -z "$LIBSSH_VERSION" ]]; then
  getLibssh2Version
fi

LIBSSL_AUTO=false
if [[ -z "$LIBSSL_VERSION" ]]; then
  getOpensslVersion
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

echo "Xcode version: $XCODE_VERSION (Automatically detected)"
echo "Architectures: $ARCHS"
echo "Platform: $SDK_PLATFORM"
echo "Platform min version: $MIN_VERSION"
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
