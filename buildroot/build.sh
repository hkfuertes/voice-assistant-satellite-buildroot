# Build del contenedor (solo primera vez)
docker-compose build

# Entrar en el contenedor
docker compose run --rm buildroot

# Dentro del contenedor:
make raspberrypizero2w_defconfig

# Añadir paquetes que quieras
make menuconfig
# O editar .config directamente:
# echo 'BR2_PACKAGE_IWD=y' >> .config
# echo 'BR2_PACKAGE_OPENSSH=y' >> .config
# make olddefconfig

# Compilar
make
