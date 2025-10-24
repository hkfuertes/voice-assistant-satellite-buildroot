## Install respeaker drivers
Current Trixie kernel for PI is 6.12:
``` shell
  hkfuertes@AssistPi:~ $ uname -a
  Linux AssistPi 6.12.47+rpt-rpi-v8 #1 SMP PREEMPT Debian 1:6.12.47-1+rpt1 (2025-09-16) aarch64 GNU/Linux
```
So we need the drivers for that, thankfully (@HinTak) is maintaining the drivers:
```shell
sudo apt install -y git
git clone -b v6.12 https://github.com/HinTak/seeed-voicecard
cd seeed-voicecard
sudo ./install.sh
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
