Pod::Spec.new do |s|
  s.name              = 'Libssh2-iOS'
  s.version           = '1.6.0'
  s.summary           = 'Libssh2 is a client-side C library implementing the SSH2 protocol.'
  s.description       = <<-DESC
                        Libssh2 is a project providing a lean C library implementing the SSH2 protocol for embedding specific SSH capabilities into other tools. It has a stable, well-documented API for working on the client side with the different SSH subsystems: Session, Userauth, Channel, SFTP, and Public Key. The API can be set to either blocking or non-blocking.
                        DESC
  s.homepage          = 'https://github.com/libssh2/libssh2'
  s.documentation_url = 'http://www.libssh2.org/docs.html'
  s.author            = { 'Sara Golemon' => 'sarag@libssh2.org',
                          'Mikhail Gusarov' => 'dottedmag@dottedmag.net',
                          'Eli Fant' => 'elifantu@mail.ru',
                          'The Written Word, Inc.' => 'info@thewrittenword.com',
                          'Daniel Stenberg' => 'daniel@haxx.se',
                          'Simon Josefsson' => 'simon@josefsson.org' }
  s.source            = { :git => 'https://github.com/libssh2/libssh2.git',
                          :tag => 'libssh2-' + s.version.to_s }
  s.license	          = { :type => 'BSD 3-Clause', :file => 'COPYING' }

  s.module_name     = 'Libssh2'
  s.module_map      = 'module.modulemap'
  s.default_subspec = 'Framework'

  s.platform            = :ios, '7.0'
  s.requires_arc        = false
  s.public_header_files = 'include/*.h'
  s.preserve_paths      = 'libssh2.a', 'libssl.a', 'libcrypto.a'
  s.libraries           = 'z'

  s.subspec 'Static' do |static|
    static.source_files        = 'include/*.h'
    static.vendored_libraries  = 'libssh2.a', 'libssl.a', 'libcrypto.a'
  end

  s.subspec 'Framework' do |framework|
    framework.source_files = 'include/*.h'
    framework.xcconfig     = { 'SWIFT_INCLUDE_PATHS'  => '$(PODS_ROOT)/Libssh2-iOS',
                               'LIBRARY_SEARCH_PATHS' => '$(PODS_ROOT)/Libssh2-iOS' }
  end

  s.prepare_command = <<-CMD
    ARCHS="i386 x86_64 armv7 armv7s arm64"

    BASEPATH="${PWD}"
    BUILDDIR="${TMPDIR}Libssh2"
    SRCDIR="${BUILDDIR}/openssl"

    SDK_VERSION=`xcrun --sdk iphoneos --show-sdk-version`
    CLANG=`xcrun --find clang`
    DEVELOPER=`xcode-select --print-path`

    rm -rf "${BUILDDIR}"
    mkdir -p "${SRCDIR}"
    cd "${BUILDDIR}"

    git clone "https://github.com/openssl/openssl.git"
    cd "${SRCDIR}"
    OPENSSLVERSION=`git tag -l | egrep "OpenSSL(_[0-9])+[a-zA-Z]?$" | sort -r | head -1`
    git checkout $OPENSSLVERSION
    echo $OPENSSLVERSION > "${BUILDDIR}/openssl-version.txt"

    for ARCH in ${ARCHS}
    do
      if [ "${ARCH}" == "i386" -o "${ARCH}" == "x86_64" ];
      then
        PLATFORM="iPhoneSimulator"
      else
        sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "${SRCDIR}/crypto/ui/ui_openssl.c"
        PLATFORM="iPhoneOS"
      fi

      CONF="no-asm"

      if [ "${ARCH}" == "arm64" -o "${ARCH}" == "x86_64" ];
      then
        HOST="BSD-generic64"
        CONF="${CONF} enable-ec_nistp_64_gcc_128"
      else
        HOST="BSD-generic32"
      fi

      OPENSSLDIR="${BUILDDIR}/${PLATFORM}${SDK_VERSION}-${ARCH}"

      LIPO_LIBSSL="${LIPO_LIBSSL} ${OPENSSLDIR}/lib/libssl.a"
      LIPO_LIBCRYPTO="${LIPO_LIBCRYPTO} ${OPENSSLDIR}/lib/libcrypto.a"

      rm -rf "${OPENSSLDIR}"
      mkdir -p "${OPENSSLDIR}"

      LOG="${OPENSSLDIR}/build-openssl.log"

      export DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
      export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDK_VERSION}.sdk"
      export CC="${CLANG}"

      ./Configure ${HOST} ${CONF} --openssldir="${OPENSSLDIR}" > "${LOG}" 2>&1

      sed -ie "s!^CFLAG=!CFLAG=-isysroot ${SDKROOT} -arch ${ARCH} -mios-version-min=7.0 !" "Makefile"

      make all install_sw >> "${LOG}" 2>&1
      make clean >> "${LOG}" 2>&1
    done

    SRCDIR="${BUILDDIR}/src"

    mkdir -p "${SRCDIR}"
    cp -R "${BASEPATH}/." "${SRCDIR}"
    cd "${SRCDIR}"

    ./buildconf

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

      LIBSSH2DIR="${BUILDDIR}/${PLATFORM}${SDK_VERSION}-${ARCH}"

      LIPO_SSH2="${LIPO_SSH2} ${LIBSSH2DIR}/lib/libssh2.a"

      mkdir -p "${LIBSSH2DIR}"

      LOG="${LIBSSH2DIR}/build-libssh2.log"

      export DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
      export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDK_VERSION}.sdk"
      export CC="${CLANG}"
      export CPP="${CLANG} -E"
      export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -miphoneos-version-min=7.0"
      export CPPFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -miphoneos-version-min=7.0"

      ./configure --host=${HOST} --prefix="${LIBSSH2DIR}" --with-openssl --with-libssl-prefix="${LIBSSH2DIR}" --disable-shared --enable-static  >> "${LOG}" 2>&1

      make >> "${LOG}" 2>&1
      make install >> "${LOG}" 2>&1
      make clean >> "${LOG}" 2>&1
    done

    rm -f "${BASEPATH}/libssh2.a"
    rm -f "${BASEPATH}/libssl.a"
    rm -f "${BASEPATH}/libcrypto.a"
    lipo -create ${LIPO_SSH2}      -output "${BASEPATH}/libssh2.a"
    lipo -create ${LIPO_LIBSSL}    -output "${BASEPATH}/libssl.a"
    lipo -create ${LIPO_LIBCRYPTO} -output "${BASEPATH}/libcrypto.a"

    cd "${BASEPATH}"
    rm -rf "${BUILDDIR}"

    MODULE="module.modulemap"

    echo "module Libssh2 {" > $MODULE
    for HEADER in include/*.h; do
        echo "    header \\"${HEADER}\\"" >> $MODULE
    done
    echo -e "\n    link \\"ssl\\"\n    link \\"crypto\\"\n    link \\"ssh2\\"\n\n    export *\n}" >> $MODULE
  CMD

end
