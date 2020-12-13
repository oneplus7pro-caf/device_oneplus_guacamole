# config.mk
#
# Product-specific compile-time definitions.
#

DEVICE_PATH := device/oneplus/guacamole

#Generate DTBO image
BOARD_KERNEL_SEPARATED_DTBO := true

BOARD_BUILD_SYSTEM_ROOT_IMAGE := true
TARGET_NO_RECOVERY := true
BOARD_USES_RECOVERY_AS_BOOT := true

BOARD_SYSTEMSDK_VERSIONS:=$(SHIPPING_API_LEVEL)

TARGET_BOARD_PLATFORM := msmnile
TARGET_BOOTLOADER_BOARD_NAME := msmnile

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a76

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a76

BOARD_SECCOMP_POLICY := $(DEVICE_PATH)/seccomp

TARGET_NO_BOOTLOADER := true
TARGET_USES_UEFI := true
TARGET_NO_KERNEL := false

USE_OPENGL_RENDERER := true

#Disable appended dtb
TARGET_KERNEL_APPEND_DTB := false

# Set Header version for bootimage
#Enable dtb in boot image and Set Header version
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_BOOTIMG_HEADER_VERSION := 2

BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOTIMG_HEADER_VERSION)

# Defines for enabling A/B builds
AB_OTA_UPDATER := true

AB_OTA_PARTITIONS ?= \
	boot \
	dtbo \
	odm \
	system \
 	vendor \
	vbmeta

BOARD_USES_METADATA_PARTITION := true

#Enable split vendor image
ENABLE_VENDOR_IMAGE := true
ifeq ($(ENABLE_VENDOR_IMAGE), true)
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery_vendor_variant.fstab
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
else
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
endif

BOARD_PREBUILT_DTBOIMAGE := out/target/product/guacamole/prebuilt_dtbo.img

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
BOARD_ODMIMAGE_PARTITION_SIZE := 104857600
BOARD_VENDORIMAGE_PARTITION_SIZE := 1073741824
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3640655872
BOARD_USERDATAIMAGE_PARTITION_SIZE := 243561607168
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)

#----------------------------------------------------------------------
# Compile Linux Kernel
#----------------------------------------------------------------------

KERNEL_DEFCONFIG := guacamole-perf_defconfig

BOARD_VENDOR_KERNEL_MODULES := \
    $(KERNEL_MODULES_OUT)/audio_apr.ko \
    $(KERNEL_MODULES_OUT)/audio_wglink.ko \
    $(KERNEL_MODULES_OUT)/audio_q6_pdr.ko \
    $(KERNEL_MODULES_OUT)/audio_q6_notifier.ko \
    $(KERNEL_MODULES_OUT)/audio_adsp_loader.ko \
    $(KERNEL_MODULES_OUT)/audio_q6.ko \
    $(KERNEL_MODULES_OUT)/audio_usf.ko \
    $(KERNEL_MODULES_OUT)/audio_pinctrl_wcd.ko \
    $(KERNEL_MODULES_OUT)/audio_swr.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd_core.ko \
    $(KERNEL_MODULES_OUT)/audio_swr_ctrl.ko \
    $(KERNEL_MODULES_OUT)/audio_wsa881x.ko \
    $(KERNEL_MODULES_OUT)/audio_platform.ko \
    $(KERNEL_MODULES_OUT)/audio_hdmi.ko \
    $(KERNEL_MODULES_OUT)/audio_stub.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd9xxx.ko \
    $(KERNEL_MODULES_OUT)/audio_mbhc.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd934x.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd9360.ko \
    $(KERNEL_MODULES_OUT)/audio_wcd_spi.ko \
    $(KERNEL_MODULES_OUT)/audio_native.ko \
    $(KERNEL_MODULES_OUT)/audio_machine_msmnile.ko \
    $(KERNEL_MODULES_OUT)/wil6210.ko \
    $(KERNEL_MODULES_OUT)/msm_11ad_proxy.ko \
    $(KERNEL_MODULES_OUT)/mpq-adapter.ko \
    $(KERNEL_MODULES_OUT)/mpq-dmx-hw-plugin.ko \
    $(KERNEL_MODULES_OUT)/tspp.ko \

# install lkdtm only for userdebug and eng build variants
ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
    ifeq (,$(findstring perf_defconfig, $(KERNEL_DEFCONFIG)))
        BOARD_VENDOR_KERNEL_MODULES += $(KERNEL_MODULES_OUT)/lkdtm.ko
    endif
endif

BOARD_DO_NOT_STRIP_VENDOR_MODULES := true
TARGET_USES_ION := true
TARGET_USES_NEW_ION_API :=true
TARGET_USES_QCOM_BSP := false
BOARD_KERNEL_CMDLINE := console=ttyMSM0,115200n8 earlycon=msm_geni_serial,0xa90000 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 loop.max_part=7 androidboot.usbcontroller=a600000.dwc3
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
BOARD_EGL_CFG := $(DEVICE_PATH)/egl.cfg

BOARD_KERNEL_BASE        := 0x00000000
BOARD_KERNEL_PAGESIZE    := 4096
BOARD_KERNEL_TAGS_OFFSET := 0x01E00000
BOARD_RAMDISK_OFFSET     := 0x02000000

TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_CROSS_COMPILE_PREFIX := $(PWD)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
TARGET_KERNEL_CROSS_COMPILE_ARM32_PREFIX := $(PWD)/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-

TARGET_USES_UNCOMPRESSED_KERNEL := false

MAX_EGL_CACHE_KEY_SIZE := 12*1024
MAX_EGL_CACHE_SIZE := 2048*1024

#File system for ODM
TARGET_COPY_OUT_ODM := odm
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := ext4

BOARD_USES_GENERIC_AUDIO := true
TARGET_NO_RPC := true

TARGET_PLATFORM_DEVICE_BASE := /devices/soc.0/
TARGET_INIT_VENDOR_LIB := libinit_msm

TARGET_COMPILE_WITH_MSM_KERNEL := true

#Enable PD locater/notifier
TARGET_PD_SERVICE_ENABLED := true

#Enable peripheral manager
TARGET_PER_MGR_ENABLED := true

# Enable dex pre-opt to speed up initial boot
ifeq ($(HOST_OS),linux)
    ifeq ($(WITH_DEXPREOPT),)
      WITH_DEXPREOPT := true
      WITH_DEXPREOPT_PIC := true
      ifneq ($(TARGET_BUILD_VARIANT),user)
        # Retain classes.dex in APK's for non-user builds
        DEX_PREOPT_DEFAULT := nostripping
      endif
    endif
endif

TARGET_USES_GRALLOC1 := true

# Enable sensor multi HAL
USE_SENSOR_MULTI_HAL := true

#Do not add non-hlos files to ota packages
ADD_RADIO_FILES := false

#Enable INTERACTION_BOOST
TARGET_USES_INTERACTION_BOOST := true

#Enable DRM plugins 64 bit compilation
TARGET_ENABLE_MEDIADRM_64 := true

#----------------------------------------------------------------------
# wlan specific
#----------------------------------------------------------------------
ifeq ($(strip $(BOARD_HAS_QCOM_WLAN)),true)
include device/qcom/wlan/msmnile/BoardConfigWlan.mk
endif

ifeq ($(ENABLE_VENDOR_IMAGE), false)
  $(error "Vendor Image is mandatory !!")
endif

BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_PREBUILT_ELF_FILES := true

BUILD_BROKEN_NINJA_USES_ENV_VARS := SDCLANG_AE_CONFIG SDCLANG_CONFIG SDCLANG_SA_ENABLED SDCLANG_CONFIG_AOSP
BUILD_BROKEN_NINJA_USES_ENV_VARS += TEMPORARY_DISABLE_PATH_RESTRICTIONS
BUILD_BROKEN_NINJA_USES_ENV_VARS += RTIC_MPGEN
BUILD_BROKEN_PREBUILT_ELF_FILES := true
BUILD_BROKEN_USES_BUILD_HOST_SHARED_LIBRARY := true
BUILD_BROKEN_USES_BUILD_HOST_STATIC_LIBRARY := true
BUILD_BROKEN_USES_BUILD_HOST_EXECUTABLE := true
BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true

#Enable VNDK Compliance
BOARD_VNDK_VERSION:=current
Q_BU_DISABLE_MODULE := true


#################################################################################
# This is the End of BoardConfig.mk file.
# Now, Pickup other split Board.mk files:
#################################################################################
# TODO: Relocate the system Board.mk files pickup into qssi lunch, once it is up.
-include vendor/qcom/defs/board-defs/system/*.mk
-include vendor/qcom/defs/board-defs/vendor/*.mk
#################################################################################

include device/qcom/sepolicy_vndr/SEPolicy.mk
