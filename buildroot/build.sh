docker-compose run --rm buildroot
cp /repo/diffconfig .config
make raspberrypi_3_zero2w_64_defconfig
make olddefconfig
make menuconfig  # Si quieres cambiar algo
make savedefconfig BR2_DEFCONFIG=$(BR2_EXTERNAL_CUSTOM_PACKAGES_PATH)/configs/raspberrypi_3_zero2w_64_defconfig
make

cp output/images/sdcard.img /repo/


# --------------------- #
sudo modprobe cdc_acm
arecord -V mono -f cd /dev/null

