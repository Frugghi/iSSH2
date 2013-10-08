#!/bin/sh

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

LIPO_SSH2="lipo -create"

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
	cd "${BASEPATH}"
done

echo "Building fat library..."
rm -rf "${BASEPATH}/libssh2/lib/"
mkdir -p "${BASEPATH}/libssh2/lib/"
eval "${LIPO_SSH2} -output ${BASEPATH}/libssh2/lib/libssh2.a"

echo "Copying headers..."
rm -rf "${BASEPATH}/libssh2/include/"
mkdir -p "${BASEPATH}/libssh2/include/"
cp -RL "${LIBSSHDIR}/src/include/" "${BASEPATH}/libssh2/include/"

echo "Cleaning up..."
rm -rf "${LIBSSHDIR}/src/"
rm -rf "${LIBSSHDIR}/tmp/"

echo "Building done."