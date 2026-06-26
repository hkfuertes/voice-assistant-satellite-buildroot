.PHONY: build image lva-wm8960 shell clean-container clean-output-cache

IMAGE := vas-buildroot-2026
DL_VOLUME := vas-buildroot-dl
OUTPUT_VOLUME := vas-buildroot-output-2026
DEFCONFIG := lva_wm8960hat_pi_3_02w_defconfig
ARTIFACT := lva-wm8960hat-pi.img.xz

build: lva-wm8960

image:
	docker build --platform linux/amd64 -t $(IMAGE) buildroot

lva-wm8960: image
	docker volume create $(DL_VOLUME) >/dev/null
	docker volume create $(OUTPUT_VOLUME) >/dev/null
	docker run --rm --platform linux/amd64 --user root \
		-v $(DL_VOLUME):/home/builder/buildroot/dl \
		-v $(OUTPUT_VOLUME):/home/builder/buildroot/out \
		$(IMAGE) chown -R builder:builder /home/builder/buildroot/dl /home/builder/buildroot/out
	docker run --rm --platform linux/amd64 --name vas-buildroot-lva \
		-v $(DL_VOLUME):/home/builder/buildroot/dl \
		-v $(OUTPUT_VOLUME):/home/builder/buildroot/out \
		-v "$(CURDIR)/buildroot:/repo" \
		-e BR2_EXTERNAL=/repo/external \
		$(IMAGE) bash -lc 'set -o pipefail; rm -f out/build/wifi-autoconfig-*/.stamp_* 2>/dev/null || true; make O=out $(DEFCONFIG) && make O=out -j$$(nproc) && cp -f out/images/sdcard.img.xz /repo/$(ARTIFACT)'

shell: image
	docker volume create $(DL_VOLUME) >/dev/null
	docker volume create $(OUTPUT_VOLUME) >/dev/null
	docker run --rm --platform linux/amd64 \
		-v $(DL_VOLUME):/home/builder/buildroot/dl \
		-v $(OUTPUT_VOLUME):/home/builder/buildroot/out \
		-v "$(CURDIR)/buildroot:/repo" \
		-e BR2_EXTERNAL=/repo/external \
		$(IMAGE) bash

clean-container:
	docker rm -f vas-buildroot-lva 2>/dev/null || true

clean-output-cache:
	docker volume rm -f $(OUTPUT_VOLUME)
