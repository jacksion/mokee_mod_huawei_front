#!/bin/bash

cd `dirname $0`
SRCDIR=`pwd`

CM_MOD=$SRCDIR/../cm101_mod_huawei_front
BT_PORT=$SRCDIR/../bluez_port
DEVICE=$SRCDIR/../android_device_huawei
VENDOR=$SRCDIR/../android_vendor_huawei

# arg check
DSTDIR=$1
if [ -z "$DSTDIR" ]
then
    echo "Usage: $0 <cm 10.1 dir>"
    exit 1
fi

# checkout projects if required
if [ ! -d $DEVICE ]
then
    echo "Checking out android_device_huawei"
    (cd ..;git clone https://github.com/f3n9/android_device_huawei.git)
fi

if [ ! -d $VENDOR ]
then
    echo "Checking out android_vendor_huawei"
    (cd ..;git clone https://github.com/f3n9/android_vendor_huawei.git)
fi

if [ ! -d $BT_PORT ]
then
    echo "Checking out bluez_port"
    (cd ..;git clone https://github.com/f3n9/bluez_port.git)
fi

if [ ! -d $CM_MOD ]
then
    echo "Checking out cm101_mod_huawei_front"
    (cd ..;git clone https://github.com/f3n9/cm101_mod_huawei_front.git)
fi




# build/core/pathmap.mk: patch
echo "[build/core] Patch pathmap.mk"
cat $BT_PORT/patches/build_core.patch | patch -d $DSTDIR/build/core -p0 -N -r - -s


# external/bluetooth: 1. remove bluedroid
#                     2. copy bluez, glib and hcidump
echo "[external/bluetooth] removing mk files from bluedroid"
rm -f $DSTDIR/external/bluetooth/bluedroid/Android.mk
rm -f $DSTDIR/external/bluetooth/bluedroid/audio_a2dp_hw/Android.mk
echo "[external/bluetooth] adding bluez, glib and hcidump"
cp -r $BT_PORT/external/bluetooth/* $DSTDIR/external/bluetooth/

# packages/apps: 1. replace Bluetooth; 
#                2. patch Phone
echo "[packages/apps] removing Bluetooth"
rm -rf $DSTDIR/packages/apps/Bluetooth
echo "[packages/apps] adding Bluetooth"
cp -r $BT_PORT/packages/apps/Bluetooth $DSTDIR/packages/apps/

echo "[packages/apps] patching Phone"
cat $BT_PORT/patches/Phone_all2.patch | patch -d $DSTDIR/packages/apps/Phone -p1 -N -r - -s

# patch frameworks/base
echo "[frameworks/base] applying patch frameworks_base_all2.patch"
cat $BT_PORT/patches/frameworks_base_all2.patch | patch -d $DSTDIR/frameworks/base -p1 -N -r - -s


# copy and patch device
echo ""
echo "Copying device files"
mkdir -p $DSTDIR/device/huawei 2>/dev/null
rm -rf $DSTDIR/device/huawei/front 2>/dev/null
cp -r $DEVICE/front $DSTDIR/device/huawei/
cat $SRCDIR/patches/cm2mokee_device_huawei_front.patch | patch -d $DSTDIR/device/huawei/front  -p2 -N -r - -s

# copy vendor
echo ""
echo "Copying vendor files"
mkdir -p $DSTDIR/vendor/huawei
rm -rf $DSTDIR/vendor/huawei/front 2>/dev/null
cp -r $VENDOR/front $DSTDIR/vendor/huawei/

# AudioRecord patch
echo ""
echo "Applying AudioRecord patch"
cat $CM_MOD/patches/AudioRecord.patch | patch -d $DSTDIR/frameworks/av/ -p1 -N -r - -s

# Adding caller geo info database
echo "Adding CallerGeoInfo data"
cp $CM_MOD/patches/geoloc/86_zh $DSTDIR/external/libphonenumber/java/src/com/android/i18n/phonenumbers/geocoding/data/86_zh
cp $CM_MOD/patches/geoloc/PhoneNumberMetadataProto_CN $DSTDIR/external/libphonenumber/java/src/com/android/i18n/phonenumbers/data/PhoneNumberMetadataProto_CN

# EMUI Gallery/Camera patch
echo ""
echo "Applying EMUI Gallery/Camera patch"
cat $CM_MOD/patches/EMUI_Gallery2.patch | patch -d $DSTDIR/frameworks/base -p1 -N -r - -s

echo "Done"
