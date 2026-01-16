#!/bin/bash
#  Builds libopus for iOS as an XCFramework supporting:
#  - iOS Device (arm64)
#  - iOS Simulator (arm64 for Apple Silicon, x86_64 for Intel)
#
#  Copyright 2012 Mike Tigas <mike@tig.as>
#
#  Based on work by Felix Schulze on 16.12.10.
#  Copyright 2010 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Choose your libopus version and your currently-installed iOS SDK version:
#
VERSION="1.5.2"
SDKVERSION="26.0"
MINIOSVERSION="16.0"

###########################################################################
#
# Don't change anything under this line!
#
###########################################################################

# by default, we won't build for debugging purposes
if [ "${DEBUG}" == "true" ]; then
    echo "Compiling for debugging ..."
    OPT_CFLAGS="-O0 -fno-inline -g"
    OPT_LDFLAGS=""
    OPT_CONFIG_ARGS="--enable-assertions --disable-asm"
else
    OPT_CFLAGS="-O3 -ffast-math -g"
    OPT_LDFLAGS=""
    OPT_CONFIG_ARGS=""
fi

# Architectures to build
# Device: arm64
# Simulator: arm64 (Apple Silicon) + x86_64 (Intel)
DEVICE_ARCHS="arm64"
SIM_ARCHS="arm64 x86_64"

DEVELOPER=`xcode-select -print-path`

cd "`dirname \"$0\"`"
REPOROOT=$(pwd)

# Where we'll end up storing things in the end
OUTPUTDIR="${REPOROOT}/dependencies"
mkdir -p ${OUTPUTDIR}/include
mkdir -p ${OUTPUTDIR}/lib

# Use /tmp for building to avoid permission issues
BUILDDIR="/tmp/opus-ios-build-$$"
mkdir -p ${BUILDDIR}

# where we will keep our sources and build from.
SRCDIR="${BUILDDIR}/src"
mkdir -p $SRCDIR
# where we will store intermediary builds
INTERDIR="${BUILDDIR}/built"
mkdir -p $INTERDIR

echo "Build directory: ${BUILDDIR}"

########################################

cd $SRCDIR

# Exit the script if an error happens
set -e

# Check if tarball exists in repo, otherwise download
TARBALL="${REPOROOT}/build/src/opus-${VERSION}.tar.gz"
if [ -e "${TARBALL}" ]; then
    echo "Using existing opus-${VERSION}.tar.gz from build/src/"
    cp "${TARBALL}" "${SRCDIR}/"
elif [ ! -e "${SRCDIR}/opus-${VERSION}.tar.gz" ]; then
    echo "Downloading opus-${VERSION}.tar.gz"
    curl -LO http://downloads.xiph.org/releases/opus/opus-${VERSION}.tar.gz
fi
echo "Using opus-${VERSION}.tar.gz"

tar zxf opus-${VERSION}.tar.gz -C $SRCDIR
cd "${SRCDIR}/opus-${VERSION}"

set +e # don't bail out of bash script if ccache doesn't exist
CCACHE=`which ccache`
if [ $? == "0" ]; then
    echo "Building with ccache: $CCACHE"
    CCACHE="${CCACHE} "
else
    echo "Building without ccache"
    CCACHE=""
fi
set -e # back to regular "bail out on error" mode

export ORIGINALPATH=$PATH

########################################
# Build for iOS Device (arm64)
########################################
echo "========================================"
echo "Building for iOS Device..."
echo "========================================"

for ARCH in ${DEVICE_ARCHS}
do
    echo "Building Device arch: ${ARCH}"
    PLATFORM="iPhoneOS"
    EXTRA_CFLAGS="-arch ${ARCH} -target ${ARCH}-apple-ios${MINIOSVERSION}"
    EXTRA_CONFIG="--host=arm-apple-darwin"

    mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

    ./configure --enable-float-approx --disable-shared --disable-asm --enable-static --with-pic --disable-extra-programs --disable-doc ${EXTRA_CONFIG} \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
    LDFLAGS="$LDFLAGS ${OPT_LDFLAGS} -fPIE -miphoneos-version-min=${MINIOSVERSION} -L${OUTPUTDIR}/lib" \
    CFLAGS="$CFLAGS ${EXTRA_CFLAGS} ${OPT_CFLAGS} -fPIE -miphoneos-version-min=${MINIOSVERSION} -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" \

    make -j4
    make install
    make clean
done

########################################
# Build for iOS Simulator (arm64 + x86_64)
########################################
echo "========================================"
echo "Building for iOS Simulator..."
echo "========================================"

for ARCH in ${SIM_ARCHS}
do
    echo "Building Simulator arch: ${ARCH}"
    PLATFORM="iPhoneSimulator"
    
    if [ "${ARCH}" == "arm64" ]; then
        # Apple Silicon simulator
        EXTRA_CFLAGS="-arch ${ARCH} -target ${ARCH}-apple-ios${MINIOSVERSION}-simulator"
        EXTRA_CONFIG="--host=arm-apple-darwin"
    else
        # Intel simulator
        EXTRA_CFLAGS="-arch ${ARCH} -target ${ARCH}-apple-ios${MINIOSVERSION}-simulator"
        EXTRA_CONFIG="--host=x86_64-apple-darwin"
    fi

    mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

    ./configure --enable-float-approx --disable-shared --disable-asm --enable-static --with-pic --disable-extra-programs --disable-doc ${EXTRA_CONFIG} \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
    LDFLAGS="$LDFLAGS ${OPT_LDFLAGS} -fPIE -mios-simulator-version-min=${MINIOSVERSION} -L${OUTPUTDIR}/lib" \
    CFLAGS="$CFLAGS ${EXTRA_CFLAGS} ${OPT_CFLAGS} -fPIE -mios-simulator-version-min=${MINIOSVERSION} -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" \

    make -j4
    make install
    make clean
done

########################################
echo "Creating framework from static libraries..."
########################################

# Create device framework
echo "Creating iOS Device framework..."
DEVICE_FRAMEWORK_DIR="${INTERDIR}/frameworks/device/opus.framework"
mkdir -p "${DEVICE_FRAMEWORK_DIR}/Headers"

# Create device static lib
lipo -create "${INTERDIR}/iPhoneOS${SDKVERSION}-arm64.sdk/lib/libopus.a" \
    -output "${DEVICE_FRAMEWORK_DIR}/opus"

# Copy headers
cp -R ${INTERDIR}/iPhoneOS${SDKVERSION}-arm64.sdk/include/opus/* "${DEVICE_FRAMEWORK_DIR}/Headers/"

# Create module map
mkdir -p "${DEVICE_FRAMEWORK_DIR}/Modules"
cat > "${DEVICE_FRAMEWORK_DIR}/Modules/module.modulemap" << EOF
framework module opus {
  umbrella header "opus.h"
  export *
  module * { export * }
}
EOF

# Create Info.plist
cat > "${DEVICE_FRAMEWORK_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>opus</string>
    <key>CFBundleIdentifier</key>
    <string>org.opus-codec.opus</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>opus</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>${MINIOSVERSION}</string>
</dict>
</plist>
EOF

# Create simulator framework with combined architectures
echo "Creating iOS Simulator framework..."
SIM_FRAMEWORK_DIR="${INTERDIR}/frameworks/simulator/opus.framework"
mkdir -p "${SIM_FRAMEWORK_DIR}/Headers"
mkdir -p "${SIM_FRAMEWORK_DIR}/Modules"

# Combine simulator architectures
lipo -create \
    "${INTERDIR}/iPhoneSimulator${SDKVERSION}-arm64.sdk/lib/libopus.a" \
    "${INTERDIR}/iPhoneSimulator${SDKVERSION}-x86_64.sdk/lib/libopus.a" \
    -output "${SIM_FRAMEWORK_DIR}/opus"

# Copy headers and module map
cp -R ${INTERDIR}/iPhoneSimulator${SDKVERSION}-arm64.sdk/include/opus/* "${SIM_FRAMEWORK_DIR}/Headers/"
cp "${DEVICE_FRAMEWORK_DIR}/Modules/module.modulemap" "${SIM_FRAMEWORK_DIR}/Modules/"
cp "${DEVICE_FRAMEWORK_DIR}/Info.plist" "${SIM_FRAMEWORK_DIR}/"

echo "Device framework architectures:"
lipo -info "${DEVICE_FRAMEWORK_DIR}/opus"

echo "Simulator framework architectures:"
lipo -info "${SIM_FRAMEWORK_DIR}/opus"

########################################
echo "Creating XCFramework..."
########################################

# Remove old XCFramework if exists
rm -rf "${OUTPUTDIR}/opus.xcframework"

# Create XCFramework from frameworks
xcodebuild -create-xcframework \
    -framework "${DEVICE_FRAMEWORK_DIR}" \
    -framework "${SIM_FRAMEWORK_DIR}" \
    -output "${OUTPUTDIR}/opus.xcframework"

echo "XCFramework created at: ${OUTPUTDIR}/opus.xcframework"

# Also update headers in dependencies/include
cp -R ${INTERDIR}/iPhoneOS${SDKVERSION}-arm64.sdk/include/* ${OUTPUTDIR}/include/

########################################
echo "Verifying XCFramework..."
########################################

echo "XCFramework contents:"
ls -la "${OUTPUTDIR}/opus.xcframework/"

echo ""
echo "Device library info:"
lipo -info "${OUTPUTDIR}/opus.xcframework/ios-arm64/libopus.a" 2>/dev/null || echo "(check ios-arm64 directory)"

echo ""
echo "Simulator library info:"
lipo -info "${OUTPUTDIR}/opus.xcframework/ios-arm64_x86_64-simulator/libopus.a" 2>/dev/null || echo "(check simulator directory)"

####################

echo ""
echo "Building done."
echo "Cleaning up..."
rm -rf ${BUILDDIR}
echo "Done."

echo ""
echo "========================================"
echo "Build Summary:"
echo "========================================"
echo "XCFramework: ${OUTPUTDIR}/opus.xcframework"
echo "Headers:     ${OUTPUTDIR}/include/opus/"
echo ""
echo "Supported architectures:"
echo "  - iOS Device: arm64"
echo "  - iOS Simulator: arm64 (Apple Silicon) + x86_64 (Intel)"
echo ""
echo "Use this XCFramework with CocoaPods or SPM."
echo "========================================"
