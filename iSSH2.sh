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
	echo "Build failed, cleaning up temporary files..."
	rm -rf "${LIBSSLDIR}/src/" "${LIBSSLDIR}/tmp/" "${LIBSSHDIR}/src/" "${LIBSSHDIR}/tmp/"
	exit 1
}

cleanupAll () {
	echo "Cleaning up temporary files..."
	rm -rf "${TEMPPATH}"
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
		LIBSSL_VERSION=`git ls-remote --tags git://git.openssl.org/openssl.git | egrep "OpenSSL(_[0-9])+[a-zA-Z]?$" | cut -f 2,3,4 -d _ | sort -t _ -r | head -n 1 | tr _ . `
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
	echo "  -a, --archs=[ARCHS]              build for [ARCHS] architectures;"
	echo "                                   default is $ARCHS"
	echo "  -i, --iphoneos-min-version=VERS  set iPhoneOS minimum version to VERS;"
	echo "                                   default is $IPHONEOS_MINVERSION"
	echo "  -s, --sdk-version=VERS           use SDK version VERS"
	echo "  -l, --libssh2=VERS               download and build Libssh2 version VERS"
	echo "  -o, --openssl=VERS               download and build OpenSSL version VERS"
	echo "      --build-only-openssl         build OpenSSL and skip Libssh2"
	echo "  -h, --help                       display this help and exit"
	echo
	exit 1
}

#Config

export SDK_VERSION=
export LIBSSH_VERSION=
export LIBSSL_VERSION=
export IPHONEOS_MINVERSION="6.0"
export ARCHS="i386 x86_64 armv7 armv7s arm64"

BUILD_SSL=true
BUILD_SSH=true

while getopts ':a:i:l:o:s:h-' OPTION ; do
  case "$OPTION" in
    a  ) ARCHS="$OPTARG" ;;
    i  ) IPHONEOS_MINVERSION="$OPTARG" ;;
    s  ) SDK_VERSION="$OPTARG" ;;
    l  ) LIBSSH_VERSION="$OPTARG" ;;
    o  ) LIBSSL_VERSION="$OPTARG" ;;
    h  ) usageHelp ;;
    -  ) [ $OPTIND -ge 1 ] && optind=$(expr $OPTIND - 1 ) || optind=$OPTIND
         eval OPTION="\$$optind"
         OPTARG=$(echo $OPTION | cut -d'=' -f2)
         OPTION=$(echo $OPTION | cut -d'=' -f1)
         case $OPTION in
             --archs   ) ARCHS="$OPTARG"          ;;
             --openssl ) LIBSSL_VERSION="$OPTARG" ;;
             --libssh2 ) LIBSSH_VERSION="$OPTARG" ;;
             --sdk-version ) SDK_VERSION="$OPTARG" ;;
             --iphoneos-min-version) IPHONEOS_MINVERSION="$OPTARG" ;;
             --build-only-openssl) BUILD_SSH=false ;;
             --only-print-env)     BUILD_SSL=false; BUILD_SSH=false ;;
             --help    ) usageHelp ;; 
             * )  echo "$SCRIPTNAME: Invalid option '$OPTION'" 
             	  echo "Try '$SCRIPTNAME --help' for more information."
             	  exit 1 ;;
         esac
       OPTIND=1
       shift
      ;;
    \?  ) echo "$SCRIPTNAME: Invalid option -- $OPTION"
    	  echo "Try '$SCRIPTNAME --help' for more information."
    	  exit 1 ;;
  esac
done

echo "Initializing..."

LIBSSH_AUTO=false
if [ -z "$LIBSSH_VERSION" ]; then
	getLibssh2Version
fi

LIBSSL_AUTO=false
if [ -z "$LIBSSL_VERSION" ]; then
	getOpensslVersion
fi

SDK_AUTO=false
if [ -z "$SDK_VERSION" ]; then
 	SDK_VERSION=`xcrun --sdk iphoneos --show-sdk-version`
 	SDK_AUTO=true
fi

export CLANG=`xcrun --find clang`
export DEVELOPER=`xcode-select --print-path`

export BASEPATH="${PWD}"
export TEMPPATH="/tmp/$SCRIPTNAME" 
export LIBSSLDIR="${TEMPPATH}/openssl-${LIBSSL_VERSION}"
export LIBSSHDIR="${TEMPPATH}/libssh2-${LIBSSH_VERSION}"

#Env

echo
if $LIBSSH_AUTO; then
	echo "Libssh2 version: $LIBSSH_VERSION (Automatically detected)"
else
	echo "Libssh2 version: $LIBSSH_VERSION"
fi

if $LIBSSL_AUTO; then
	echo "OpenSSL version: $LIBSSL_VERSION (Automatically detected)"
else
	echo "OpenSSL version: $LIBSSL_VERSION"
fi

if $SDK_AUTO; then
	echo "SDK version: $SDK_VERSION (Automatically detected)"
else
	echo "SDK version: $SDK_VERSION"
fi

echo "Architectures: $ARCHS"
echo "iPhoneOS Min Version: $IPHONEOS_MINVERSION"
echo

#Build

set -e

if $BUILD_SSL; then
	./iSSH2-openssl.sh || cleanupFail
fi

if $BUILD_SSH; then
	./iSSH2-libssh2.sh || cleanupFail
fi

if $BUILD_SSL || $BUILD_SSH; then
	cleanupAll
fi