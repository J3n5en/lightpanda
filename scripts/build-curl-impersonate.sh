#!/bin/bash
# Build curl-impersonate static libraries for lightpanda integration.
# Usage: ./scripts/build-curl-impersonate.sh [curl-impersonate-source-dir]
#
# Prerequisites: cmake, ninja, autoconf, automake, libtool, go
# On Ubuntu/Debian: apt install cmake ninja-build autoconf automake libtool golang-go
# On macOS: brew install cmake ninja autoconf automake

set -euo pipefail

CI_SRC="${1:-../curl-impersonate}"
DEST="$(pwd)/.curl-impersonate"
JOBS="${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

if [ ! -d "$CI_SRC/patches" ]; then
    echo "Error: curl-impersonate source not found at $CI_SRC"
    echo "Usage: $0 [path-to-curl-impersonate-source]"
    exit 1
fi

CI_SRC="$(cd "$CI_SRC" && pwd)"
echo "Building curl-impersonate from: $CI_SRC"
echo "Output: $DEST"
echo "Jobs: $JOBS"

BORING_SSL_COMMIT=673e61fc215b178a90c0e67858bbf162c8158993
CURL_VERSION=curl-8_15_0
WORKDIR="$CI_SRC"

cd "$WORKDIR"

# --- zlib ---
echo "=== Building zlib ==="
if [ ! -f zlib-1.3.1/installed/lib/libz.a ]; then
    [ -f zlib-1.3.1.tar.gz ] || curl -L "https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz" -o zlib-1.3.1.tar.gz
    [ -d zlib-1.3.1 ] || tar xf zlib-1.3.1.tar.gz
    cd zlib-1.3.1
    ./configure --prefix="$(pwd)/installed" --static
    make -j"$JOBS"
    make install
    cd ..
fi

# --- zstd ---
echo "=== Building zstd ==="
if [ ! -f zstd-1.5.6/installed/lib/libzstd.a ]; then
    [ -f zstd-1.5.6.tar.gz ] || curl -L "https://github.com/facebook/zstd/releases/download/v1.5.6/zstd-1.5.6.tar.gz" -o zstd-1.5.6.tar.gz
    [ -d zstd-1.5.6 ] || tar xf zstd-1.5.6.tar.gz
    cd zstd-1.5.6
    make -C lib BUILD_SHARED=0 BUILD_STATIC=1 -j"$JOBS" libzstd.a
    mkdir -p installed/lib installed/include
    cp lib/libzstd.a installed/lib/
    cp lib/*.h installed/include/
    cd ..
fi

# --- brotli ---
echo "=== Building brotli ==="
if [ ! -f brotli-1.2.0/out/installed/lib/libbrotlicommon.a ]; then
    [ -f brotli-1.2.0.tar.gz ] || curl -L "https://github.com/google/brotli/archive/refs/tags/v1.2.0.tar.gz" -o brotli-1.2.0.tar.gz
    [ -d brotli-1.2.0 ] || tar xf brotli-1.2.0.tar.gz
    cd brotli-1.2.0
    [ -f .patched ] || { patch -p1 < "$CI_SRC/patches/brotli.patch" && touch .patched; }
    mkdir -p out && cd out
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=./installed -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=OFF -DBROTLI_DISABLE_TESTS=ON -DBROTLI_BUILD_TOOLS=OFF ..
    cmake --build . --config Release --target install --parallel "$JOBS"
    cd ../..
fi

# --- BoringSSL (patched) ---
echo "=== Building BoringSSL ==="
if [ ! -f "boringssl-${BORING_SSL_COMMIT}/lib/libssl.a" ]; then
    [ -f "boringssl-${BORING_SSL_COMMIT}.zip" ] || \
        curl -L "https://github.com/google/boringssl/archive/${BORING_SSL_COMMIT}.zip" -o "boringssl-${BORING_SSL_COMMIT}.zip"
    [ -d "boringssl-${BORING_SSL_COMMIT}" ] || unzip -q -o "boringssl-${BORING_SSL_COMMIT}.zip"
    cd "boringssl-${BORING_SSL_COMMIT}"
    [ -f .patched ] || { patch -p1 < "$CI_SRC/patches/boringssl.patch" && touch .patched; }
    mkdir -p build && cd build
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=on \
        -DCMAKE_C_FLAGS="-Wno-unknown-warning-option -Wno-stringop-overflow -Wno-array-bounds -Wno-macro-redefined" \
        -DCMAKE_CXX_FLAGS="-Wno-macro-redefined" -GNinja ..
    ninja -j"$JOBS" crypto ssl
    cd ..
    mkdir -p lib
    cp build/libssl.a build/libcrypto.a lib/
    cd ..
fi

# --- nghttp2 ---
echo "=== Building nghttp2 ==="
if [ ! -f nghttp2-1.63.0/installed/lib/libnghttp2.a ]; then
    [ -f nghttp2-1.63.0.tar.bz2 ] || curl -L "https://github.com/nghttp2/nghttp2/releases/download/v1.63.0/nghttp2-1.63.0.tar.bz2" -o nghttp2-1.63.0.tar.bz2
    [ -d nghttp2-1.63.0 ] || tar -xf nghttp2-1.63.0.tar.bz2
    cd nghttp2-1.63.0
    ./configure --prefix="$(pwd)/installed" --with-pic --enable-lib-only --disable-shared
    make -j"$JOBS"
    make install
    cd ..
fi

# --- curl (patched) ---
echo "=== Building curl-impersonate ==="
if [ ! -f "${CURL_VERSION}/lib/.libs/libcurl-impersonate.a" ]; then
    [ -f "${CURL_VERSION}.tar.gz" ] || curl -L "https://github.com/curl/curl/archive/${CURL_VERSION}.tar.gz" -o "${CURL_VERSION}.tar.gz"
    if [ ! -f "${CURL_VERSION}/.patched" ]; then
        rm -rf "${CURL_VERSION}"
        tar -xf "${CURL_VERSION}.tar.gz"
        mv "curl-${CURL_VERSION}" "${CURL_VERSION}"
        cd "${CURL_VERSION}"
        patch -p1 < "$CI_SRC/patches/curl.patch"
        autoreconf -fi
        touch .patched
        cd ..
    fi
    cd "${CURL_VERSION}"

    # Detect OS for configure flags
    OS="$(uname -s)"
    IDN_FLAGS=""
    ADD_LIBS="-pthread -lstdc++"
    case "$OS" in
        Darwin)
            IDN_FLAGS="--with-apple-idn --without-libidn2"
            ADD_LIBS="-pthread -lc++"
            ;;
        Linux)
            IDN_FLAGS="--without-libidn2"
            ;;
    esac

    ./configure \
        --prefix=/usr/local \
        --with-brotli="$WORKDIR/brotli-1.2.0/out/installed" \
        --with-nghttp2="$WORKDIR/nghttp2-1.63.0/installed" \
        --with-openssl="$WORKDIR/boringssl-${BORING_SSL_COMMIT}" \
        --with-zlib="$WORKDIR/zlib-1.3.1/installed" \
        --with-zstd="$WORKDIR/zstd-1.5.6/installed" \
        $IDN_FLAGS \
        --without-librtmp --without-libpsl \
        --disable-ldap --disable-ldaps \
        --enable-websockets --enable-ipv6 \
        --enable-ech --enable-ssls-export \
        --enable-static --disable-shared \
        USE_CURL_SSLKEYLOGFILE=true \
        LIBS="$ADD_LIBS"
    make -j"$JOBS"
    cd ..
fi

# --- Collect outputs ---
echo "=== Collecting libraries ==="
mkdir -p "$DEST/lib" "$DEST/include"

cp "${CURL_VERSION}/lib/.libs/libcurl-impersonate.a" "$DEST/lib/"
cp -R "${CURL_VERSION}/include/curl" "$DEST/include/"
cp "boringssl-${BORING_SSL_COMMIT}/lib/libssl.a" "$DEST/lib/"
cp "boringssl-${BORING_SSL_COMMIT}/lib/libcrypto.a" "$DEST/lib/"
cp -R "boringssl-${BORING_SSL_COMMIT}/include/openssl" "$DEST/include/"
cp nghttp2-1.63.0/installed/lib/libnghttp2.a "$DEST/lib/"
cp brotli-1.2.0/out/installed/lib/libbrotli*.a "$DEST/lib/"
cp zlib-1.3.1/installed/lib/libz.a "$DEST/lib/"
cp zstd-1.5.6/installed/lib/libzstd.a "$DEST/lib/"

echo ""
echo "=== Done ==="
echo "Libraries installed to: $DEST"
ls -lh "$DEST/lib/"
echo ""
echo "Build lightpanda with:"
echo "  zig build -Doptimize=ReleaseFast -Dcurl_impersonate_path=.curl-impersonate ..."
