#!/bin/bash

# Declare device details and path
VENDOR=oneplus
DEVICE=guacamole
DEVICE_PATH=$(pwd)
VENDOR_PATH=${DEVICE_PATH}/../../../vendor
BLOBS_PATH=${VENDOR_PATH}/${VENDOR}/${DEVICE}
SYSTEM_MK=${BLOBS_PATH}/system/${DEVICE}-system.mk
VENDOR_MK=${BLOBS_PATH}/sm8150/${DEVICE}-vendor.mk

# Blobs list
BLOBS_LIST=${DEVICE_PATH}/blobs.txt

# Start adb
echo "Waiting for device to come online"
adb wait-for-device
echo "Device online!"

# Check if adb is running as root
if adb root | grep -q "running as root" ; then
    echo "adb is running as root,proceeding with extraction"
else
    echo "adb is not running as root,aborting!"
    exit
fi

# Wipe existing blobs directory and create necessary files
rm -rf ${VENDOR_PATH}/${VENDOR}
mkdir -p ${BLOBS_PATH}/system ${BLOBS_PATH}/sm8150
echo -ne "PRODUCT_SOONG_NAMESPACES += vendor/${VENDOR}/${DEVICE}/system\n\nPRODUCT_COPY_FILES += " > $SYSTEM_MK
echo -ne "PRODUCT_SOONG_NAMESPACES += vendor/${VENDOR}/${DEVICE}/sm8150\n\nPRODUCT_COPY_FILES += " > $VENDOR_MK
echo -e "soong_namespace {\n}" | tee ${BLOBS_PATH}/system/Android.bp > ${BLOBS_PATH}/sm8150/Android.bp

# arrays to hold list of certain blobs for import
appArray=()
dexArray=()
libArray=()
sysPackArray=()
venPackArray=()

# Classification and then extraction
start_extraction() {
    # Read blobs list line by line
    while read line; do
        # Null check
        if [ ! -z "$line" ] ; then
            # Comments
            if [[ $line == *"#"* ]] ; then
                echo $line
            else
                # Import blob
                if [[ $line == -* ]] ; then
                    line=$(echo $line | sed 's/-//')
                    # Apks, jars, libs
                    if [[ $line == *"apk"* ]] ; then
                        appArray+=($line)
                    elif [[ $line == *"jar"* ]] ; then
                        dexArray+=($line)
                    else
                        if [[ $line == *"lib64"* ]] ; then
                            libArray+=($line)
                        fi
                    fi
                else
                    # Blobs in different input directory
                    if [[ $line == *":"* ]] ; then
                        aline=${line#*:}
                    else
                        aline=$line
                    fi

                    # Classifying blobs
                    if [[ $aline == *"vendor/"* ]] ; then
                        write_to_makefiles $aline vendor
                    elif [[ $aline == *"product/"* ]] ; then
                        write_to_makefiles $aline product
                    else
                        write_to_makefiles $aline system
                    fi
                fi
                # Extract the blob from device
                extract_blob $line
            fi
        fi
    done < $BLOBS_LIST
}

# Extract everything
extract_blob() {
    path=${1%/*}
    # Redirect path to blob
    if [[ $1 == *":"* ]] ; then
        path=${1#*:}
        apath=${1%:*}
        path=${path%/*}
        mkdir -p ${BLOBS_PATH}/${path}
        adb pull $apath ${BLOBS_PATH}/${path}
    elif [[ $1 == *"vendor/"* ]] ; then # vendor blobs
        vpath=${path#*/}
        mkdir -p ${BLOBS_PATH}/sm8150/${vpath}
        adb pull $1 ${BLOBS_PATH}/sm8150/${vpath}
    else # system blobs
        mkdir -p ${BLOBS_PATH}/${path}
        adb pull $1 ${BLOBS_PATH}/${path}
    fi
}

import_lib() {
    for lib in ${libArray[@]}; do
        if [[ $lib == *"vendor/"* ]] ; then
            write_lib_bp $lib sm8150
            venPackArray+=($lib)
        else
            write_lib_bp $lib system
            sysPackArray+=($lib)
        fi
    done
}

import_app() {
    for app in ${appArray[@]}; do
        if [[ $app == *"vendor/"* ]] ; then
            write_app_bp $app sm8150
            venPackArray+=($app)
        else
            write_app_bp $app system
            sysPackArray+=($app)
        fi
    done
}

import_dex() {
    for dex in ${dexArray[@]}; do
        if [[ $dex == *"vendor/"* ]] ; then
            write_dex_bp $dex sm8150
            venPackArray+=($dex)
        else
            write_dex_bp $dex system
            sysPackArray+=($dex)
        fi
    done
}

# Write libs to import to Android.bp
write_lib_bp() {
    name=${1##*/}
    name=${name%.*}
    echo -e "\ncc_prebuilt_library_shared {
    name: \"$name\",
    owner: \"$VENDOR\",
    strip: {\n\t\tnone: true,\n\t}," >> ${BLOBS_PATH}/${2}/Android.bp
    if [[ $1 == *"product/"* ]] ; then
        echo -e "\ttarget: {\n\t\tandroid_arm: {\n\t\t\tsrcs: [\"product/lib/${name}.so\"],\n\t\t},\n\t\tandroid_arm64: {\n\t\t\tsrcs: [\"product/lib64/${name}.so\"],\n\t\t},\n\t}," >> ${BLOBS_PATH}/${2}/Android.bp
    else
        echo -e "\ttarget: {\n\t\tandroid_arm: {\n\t\t\tsrcs: [\"lib/${name}.so\"],\n\t\t},\n\t\tandroid_arm64: {\n\t\t\tsrcs: [\"lib64/${name}.so\"],\n\t\t},\n\t}," >> ${BLOBS_PATH}/${2}/Android.bp
    fi
    echo -e "\tcompile_multilib: \"both\",
    check_elf_files: false,
    prefer: true," >> ${BLOBS_PATH}/${2}/Android.bp

    if [[ $1 == *"product/"* ]] ; then
        echo -e "\tproduct_specific: true,\n}" >> ${BLOBS_PATH}/${2}/Android.bp
    elif [[ $2 == *"system"* ]] ; then
        echo -e "}" >> ${BLOBS_PATH}/${2}/Android.bp
    else
        echo -e "\tsoc_specific: true,\n}" >> ${BLOBS_PATH}/${2}/Android.bp
    fi
}

# Write apps to import to Android.bp
write_app_bp() {
    name=${1##*/}
    name=${name%.*}
    app=${1#*/}
    echo -e "\nandroid_app_import {
    name: \"$name\",
    owner: \"$VENDOR\",
    apk: \"$app\",
    certificate: \"platform\",
    dex_preopt: {\n\t\tenabled: false,\n\t}," >> ${BLOBS_PATH}/${2}/Android.bp

    if [[ $1 == *"priv-app"* ]] ; then
        echo -e "\tprivileged: true," >> ${BLOBS_PATH}/${2}/Android.bp
    fi

    if [[ $1 == *"product/"* ]] ; then
        echo -e "\tproduct_specific: true,\n}" >> ${BLOBS_PATH}/${2}/Android.bp
    elif [[ $2 == *"system"* ]] ; then
        echo -e "}" >> ${BLOBS_PATH}/${2}/Android.bp
    else
        echo -e "\tsoc_specific: true,\n}" >> ${BLOBS_PATH}/${2}/Android.bp
    fi
}

# Write jars to import to Android.bp
write_dex_bp() {
    name=${1##*/}
    name=${name%.*}
    jar=${1#*/}
    echo -e "\ndex_import {
    name: \"$name\",
    owner: \"$VENDOR\",
    jars: [\"$jar\"]," >> ${BLOBS_PATH}/${2}/Android.bp

    if [[ $1 == *"product/"* ]] ; then
        echo -e "\tproduct_specific: true,\n}" >> ${BLOBS_PATH}/${2}/Android.bp
    elif [[ $2 == *"system"* ]] ; then
        echo -e "}" >> ${BLOBS_PATH}/${2}/Android.bp
    else
        echo -e "\tsoc_specific: true,\n}" >> ${BLOBS_PATH}/${2}/Android.bp
    fi
}

# Write rules to copy out blobs
write_to_makefiles() {
    partition=${2^^}
    path=${1#*/}
    if [[ $2 = "vendor" ]] ; then
        echo -ne "\\" >> $VENDOR_MK
        echo -ne "\n\tvendor/${VENDOR}/${DEVICE}/sm8150/${path}:\$(TARGET_COPY_OUT_${partition})/${path} " >> $VENDOR_MK
    elif [[ $2 = "product" ]] ; then
        path=${1#*product/}
        echo -ne "\\" >> $SYSTEM_MK
        echo -ne "\n\tvendor/${VENDOR}/${DEVICE}/${1}:\$(TARGET_COPY_OUT_${partition})/${path} " >> $SYSTEM_MK
    else
        path=${1#*system/}
        echo -ne "\\" >> $SYSTEM_MK
        echo -ne "\n\tvendor/${VENDOR}/${DEVICE}/${1}:\$(TARGET_COPY_OUT_${partition})/${path} " >> $SYSTEM_MK
    fi
}

# Include packages to build
write_packages() {
    echo -ne "\n\nPRODUCT_PACKAGES += " >> $SYSTEM_MK
    echo -ne "\n\nPRODUCT_PACKAGES += " >> $VENDOR_MK
    for package in ${sysPackArray[@]}; do
        package=${package##*/}
        package=${package%.*}
        echo -ne "\\" >> $SYSTEM_MK
        echo -ne "\n\t$package " >> $SYSTEM_MK
    done
    for package in ${venPackArray[@]}; do
        package=${package##*/}
        package=${package%.*}
        echo -ne "\\" >> $VENDOR_MK
        echo -ne "\n\t$package " >> $VENDOR_MK
    done
}

# Everything starts here
start_extraction
import_lib
import_app
import_dex
write_packages
