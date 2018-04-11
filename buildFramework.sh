#!/bin/sh

PROJECT_NAME='ZXLUpload'
TARGET_NAME="ZXLUpload"
SRCROOT='.'

# Sets the target folders and the final framework product.
FMK_NAME='ZXLUpload'

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
INSTALL_DIR=${SRCROOT}/Products/${FMK_NAME}.framework

# Working dir will be deleted after the framework creation.
WRK_DIR=./build
DEVICE_DIR=${WRK_DIR}/Release-iphoneos/${FMK_NAME}.framework
SIMULATOR_DIR=${WRK_DIR}/Release-iphonesimulator/${FMK_NAME}.framework

# -configuration ${CONFIGURATION}
# Clean and Building both architectures.
# xcodebuild -configuration "Release" -target "${FMK_NAME}" -sdk iphoneos clean build
# xcodebuild -configuration "Release" -target "${FMK_NAME}" -sdk iphonesimulator clean build
xcodebuild -configuration Release -project "${PROJECT_NAME}.xcodeproj" -scheme "${TARGET_NAME}" -sdk iphoneos clean archive SYMROOT="${WRK_DIR}"
xcodebuild -configuration Release -project "${PROJECT_NAME}.xcodeproj" -scheme "${TARGET_NAME}" -sdk iphonesimulator clean build SYMROOT="${WRK_DIR}"

# Cleaning the oldest.
if [ -d "${INSTALL_DIR}" ]
then
    rm -rf "${INSTALL_DIR}"
fi

mkdir -p ${SRCROOT}/Products

cp -LR "${DEVICE_DIR}" "${INSTALL_DIR}"

# Uses the Lipo Tool to merge both binary files (i386 + armv6/armv7) into one Universal final product.
lipo -create "${DEVICE_DIR}/${FMK_NAME}" "${SIMULATOR_DIR}/${FMK_NAME}" -output "${INSTALL_DIR}/${FMK_NAME}"

rm -r "${WRK_DIR}"

if [ -d "${INSTALL_DIR}/_CodeSignature" ]
then
    rm -rf "${INSTALL_DIR}/_CodeSignature"
fi

if [ -f "${INSTALL_DIR}/Info.plist" ]
then
    rm "${INSTALL_DIR}/Info.plist"
fi

