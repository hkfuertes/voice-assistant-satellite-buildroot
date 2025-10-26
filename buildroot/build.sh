docker-compose run --rm buildroot
cp /repo/diffconfig .config
make raspberrypizero2w_64_defconfig
make olddefconfig
make menuconfig  # Si quieres cambiar algo
make savedefconfig BR2_DEFCONFIG=/repo/diffconfig
make