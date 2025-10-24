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

## LED Service
_... and this ..._

Example event services for the ReSpeaker 2Mic and 4Mic HATs are included in `wyoming-satellite/examples` that will change the LED color depending on the satellite state. The example below is for the 2Mic HAT, using `2mic_service.py`.  If you're using the 4Mic HAT, use `4mic_service.py` instead as the LEDs and GPIO pins are slightly different.

Install it from your home directory:

```sh
cd wyoming-satellite/examples
python3 -m venv --system-site-packages .venv
.venv/bin/pip3 install --upgrade pip
.venv/bin/pip3 install --upgrade wheel setuptools
.venv/bin/pip3 install 'wyoming==1.5.2'
```

In case you use a ReSpeaker USB 4mic array v2.0, additionally install pixel-ring:

```sh
.venv/bin/pip3 install 'pixel-ring'
```


The `--system-site-packages` argument is used to access the pre-installed `gpiozero` and `spidev` Python packages. If these are **not already installed** in your system, run:

```sh
sudo apt-get install python3-spidev python3-gpiozero
```

Test the service with:

```sh
.venv/bin/python3 2mic_service.py --help
```

Create a systemd service for it:

``` sh
sudo systemctl edit --force --full 2mic_leds.service
```

Paste in the following template, and change both `/home/pi` and the `script/run` arguments to match your set up:

```text
[Unit]
Description=2Mic LEDs

[Service]
Type=simple
ExecStart=/home/pi/wyoming-satellite/examples/.venv/bin/python3 2mic_service.py --uri 'tcp://127.0.0.1:10500'
WorkingDirectory=/home/pi/wyoming-satellite/examples
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
```

Save the file and exit your editor.
