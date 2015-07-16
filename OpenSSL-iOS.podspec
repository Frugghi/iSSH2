Pod::Spec.new do |s|
  s.name              = 'OpenSSL-iOS'
  s.version           = '1.0.204'
  s.summary           = 'OpenSSL is an SSL/TLS and Crypto toolkit.'
  s.description       = <<-DESC
                        The OpenSSL Project is a collaborative effort to develop a robust, commercial-grade, full-featured, and Open Source toolkit implementing the Secure Sockets Layer (SSL v2/v3) and Transport Layer Security (TLS) protocols as well as a full-strength general purpose cryptography library.
                        DESC
  s.homepage          = 'https://github.com/openssl/openssl'
  s.documentation_url = 'https://www.openssl.org/docs/'
  s.author            = { 'The OpenSSL Project' => 'openssl-dev@openssl.org' }
  s.source            = { :git => 'https://github.com/Frugghi/openssl.git', :tag => s.version.to_s }
  s.license	          = { :type => 'OpenSSL (OpenSSL/SSLeay)', :file => 'LICENSE' }

  s.module_name     = 'OpenSSL'
  s.module_map      = 'module.modulemap'
  s.default_subspec = 'Framework'

  s.platform            = :ios, '7.0'
  s.requires_arc        = false
  s.header_dir          = 'openssl'
  s.public_header_files = 'openssl/*.h'
  s.preserve_paths      = 'libcrypto.a', 'libssl.a'

  s.subspec 'Static' do |static|
    static.source_files        = 'openssl/*.h'
    static.vendored_libraries  = 'libcrypto.a', 'libssl.a'
  end

  s.subspec 'Framework' do |framework|
    framework.source_files = 'openssl/*.h'
    framework.xcconfig     = { 'SWIFT_INCLUDE_PATHS'  => '$(PODS_ROOT)/OpenSSL-iOS',
                               'LIBRARY_SEARCH_PATHS' => '$(PODS_ROOT)/OpenSSL-iOS' }
  end

  s.prepare_command = <<-CMD
    ARCHS="i386 x86_64 armv7 armv7s arm64"

    BASEPATH="${PWD}"
    BUILDDIR="${TMPDIR}OpenSSL"
    SRCDIR="${BUILDDIR}/src"

    SDK_VERSION=`xcrun --sdk iphoneos --show-sdk-version`
    CLANG=`xcrun --find clang`
    DEVELOPER=`xcode-select --print-path`

    rm -rf "${BUILDDIR}"
    mkdir -p "${SRCDIR}"
    cp -R "${BASEPATH}/." "${SRCDIR}"
    cd "${SRCDIR}"

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

      LOG="${OPENSSLDIR}/build.log"

      export DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
      export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDK_VERSION}.sdk"
      export CC="${CLANG}"

      ./Configure ${HOST} ${CONF} --openssldir="${OPENSSLDIR}" > "${LOG}" 2>&1

      sed -ie "s!^CFLAG=!CFLAG=-isysroot ${SDKROOT} -arch ${ARCH} -mios-version-min=7.0 !" "Makefile"

      make all install_sw >> "${LOG}" 2>&1
      make clean >> "${LOG}" 2>&1
    done

    rm -f "${BASEPATH}/libssl.a"
    rm -f "${BASEPATH}/libcrypto.a"
    lipo -create ${LIPO_LIBSSL}    -output "${BASEPATH}/libssl.a"
    lipo -create ${LIPO_LIBCRYPTO} -output "${BASEPATH}/libcrypto.a"

    cp -RL "${SRCDIR}/include/." "${BASEPATH}/"

    cd "${BASEPATH}"
    rm -rf "${BUILDDIR}"

    MODULE="module.modulemap"
    BEFORE_HEADERS="rc2.h rc4.h"
    AFTER_HEADERS="dtls1.h"
    EXCLUDE_HEADERS="${BEFORE_HEADERS} ${AFTER_HEADERS}"

    function print_submodule {
        echo -e "    explicit module $(basename $1 | cut -d"." -f1) {\n        header \\"$1\\"\n    }\n"
    }

    echo "module OpenSSL {" > $MODULE

    for HEADER in openssl/*.h; do
        if [[ $BEFORE_HEADERS =~ $(basename $HEADER) ]]; then
          print_submodule $HEADER >> $MODULE
        fi
    done

    for HEADER in openssl/*.h; do
        if [[ ! $EXCLUDE_HEADERS =~ $(basename $HEADER) ]]; then
          print_submodule $HEADER >> $MODULE
        fi
    done

    for HEADER in openssl/*.h; do
        if [[ $AFTER_HEADERS =~ $(basename $HEADER) ]]; then
          print_submodule $HEADER >> $MODULE
        fi
    done

    echo -e "    link \\"ssl\\"\n    link \\"crypto\\"\n}" >> $MODULE
  CMD

end
