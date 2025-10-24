## Install drivers
``` shell
echo "dtoverlay=wm8960-soundcard" >> /boot/firmware/config.txt
sudo reboot
```
## Install docker
```shell
curl -fsSL https://get.docker.com -o install-docker.sh
sudo sh install-docker.sh
sudo systemctl enable docker
sudo usermod -aG docker $USER
```
## Start Wyoming Satellite
```shell
git clone https://github.com/hkfuertes/assist_pi && cd assist_pi
docker compose up -d
```
_Still figuring this out..._
