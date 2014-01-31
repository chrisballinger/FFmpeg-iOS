#!/bin/bash
#  Builds rtmpdump for all three current iPhone targets: iPhoneSimulator-i386,
#  iPhoneOS-armv7, iPhoneOS-armv7s.
#
#  rtmpdump modifications by Chris Ballinger
#  Copyright 2014 Chris Ballinger <chris@openwatch.net>
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
#  Choose your rtmpdump version and your currently-installed iOS SDK version:
#
VERSION="2.3"
SDKVERSION="7.0"
MINIOSVERSION="6.0"

#
#
###########################################################################
#
# Don't change anything under this line!
#
###########################################################################


# by default, we won't build for debugging purposes
if [ "${DEBUG}" == "true" ]; then
    echo "Compiling for debugging ..."
    DEBUG_CFLAGS="-O0 -fno-inline -g"
    DEBUG_LDFLAGS=""
    DEBUG_CONFIG_ARGS=""
else
    DEBUG_CFLAGS="-g"
    DEBUG_LDFLAGS=""
    DEBUG_CONFIG_ARGS=""
fi

# no need to change this since xcode build will only compile in the
# necessary bits from the libraries we create
ARCHS="i386 x86_64 armv7 armv7s arm64"

DEVELOPER=`xcode-select -print-path`

cd "`dirname \"$0\"`"
REPOROOT=$(pwd)

# where we'll end up storing things in the end
OUTPUTDIR="${REPOROOT}/dependencies"
mkdir -p ${OUTPUTDIR}/include
mkdir -p ${OUTPUTDIR}/lib
mkdir -p ${OUTPUTDIR}/bin


BUILDDIR="${REPOROOT}/build"

# where we will keep our sources and build from
SRCDIR="${BUILDDIR}/src"
mkdir -p $SRCDIR
# where we will store intermediary builds
INTERDIR="${BUILDDIR}/built"
mkdir -p $INTERDIR

########################################

cd $SRCDIR

# Exit the script if an error happens
set -e

if [ ! -e "${SRCDIR}/rtmpdump-${VERSION}.tgz" ]; then
    echo "Downloading rtmpdump-${VERSION}.tgz"
    curl -LO http://rtmpdump.mplayerhq.hu/download/rtmpdump-${VERSION}.tgz
else
    echo "Using rtmpdump-${VERSION}.tgz"
fi

tar zxf rtmpdump-${VERSION}.tgz -C $SRCDIR
cd "${SRCDIR}/rtmpdump-${VERSION}/librtmp"

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

for ARCH in ${ARCHS}
do
    if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
        PLATFORM="iPhoneSimulator"
        EXTRA_CONFIG=""
        EXTRA_CFLAGS="-arch ${ARCH} -miphoneos-version-min=${MINIOSVERSION} ${DEBUG_CFLAGS}"
        EXTRA_LDFLAGS="-miphoneos-version-min=${MINIOSVERSION} ${DEBUG_LDFLAGS}"
    else
        PLATFORM="iPhoneOS"
        EXTRA_CONFIG=""
        EXTRA_CFLAGS="-w -arch ${ARCH} -miphoneos-version-min=${MINIOSVERSION}"
        EXTRA_LDFLAGS="-miphoneos-version-min=${MINIOSVERSION}"
    fi

    OUTPUT_DIR="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
    if [ ! -d "$OUTPUT_DIR" ]; then
        mkdir -p ${OUTPUT_DIR}

        # Build the application and install it to the fake SDK intermediary dir
        # we have set up. Make sure to clean up afterward because we will re-use
        # this source tree to cross-compile other targets.
        export XCFLAGS="-fPIE ${EXTRA_CFLAGS} -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk"
        export INC="-I${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk"
        make prefix=\"${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk\" SYS=darwin SHARED= install
        make clean
    fi
done

########################################

echo "Build library..."

# These are the libs that comprise rtmpdump.
OUTPUT_LIBS="librtmp.a"
for OUTPUT_LIB in ${OUTPUT_LIBS}; do
    INPUT_LIBS=""
    for ARCH in ${ARCHS}; do
        if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
            PLATFORM="iPhoneSimulator"
        else
            PLATFORM="iPhoneOS"
        fi
        INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/${OUTPUT_LIB}"
        if [ -e $INPUT_ARCH_LIB ]; then
            INPUT_LIBS="${INPUT_LIBS} -arch ${ARCH} ${INPUT_ARCH_LIB}"
        fi
    done
    # Combine the three architectures into a universal library.
    if [ -n "$INPUT_LIBS"  ]; then
        xcrun -sdk iphoneos lipo -create $INPUT_LIBS \
        -output "${OUTPUTDIR}/lib/${OUTPUT_LIB}"
    else
        echo "$OUTPUT_LIB does not exist, skipping (are the dependencies installed?)"
    fi
done

for ARCH in ${ARCHS}; do
    if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
        PLATFORM="iPhoneSimulator"
    else
        PLATFORM="iPhoneOS"
    fi
    cp -R ${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/* ${OUTPUTDIR}/include/
    if [ $? == "0" ]; then
        # We only need to copy the headers over once. (So break out of forloop
        # once we get first success.)
        break
    fi
done

####################

echo "Building done."
echo "Cleaning up..."
rm -fr ${INTERDIR}
rm -fr "${SRCDIR}/rtmpdump-${VERSION}"
echo "Done."
