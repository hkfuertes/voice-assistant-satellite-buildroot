################################################################################
#
# python-aioesphomeapi
#
################################################################################

PYTHON_AIOESPHOMEAPI_VERSION = 42.7.0
PYTHON_AIOESPHOMEAPI_SITE = $(call github,esphome,aioesphomeapi,v$(PYTHON_AIOESPHOMEAPI_VERSION))
PYTHON_AIOESPHOMEAPI_LICENSE = MIT
PYTHON_AIOESPHOMEAPI_LICENSE_FILES = LICENSE
PYTHON_AIOESPHOMEAPI_SETUP_TYPE = setuptools
PYTHON_AIOESPHOMEAPI_DEPENDENCIES = python3 \
	python-protobuf \
	python-zeroconf \
	python-cryptography \
	python-aiohappyeyeballs \
	python-async-interrupt \
	python-chacha20poly1305-reuseable \
	python-noiseprotocol \
	host-protobuf \
	python-tzlocal

# Regenerate protobuf files with correct version
define PYTHON_AIOESPHOMEAPI_REGENERATE_PROTOBUF
	cd $(@D)/aioesphomeapi && \
		$(HOST_DIR)/bin/protoc --python_out=. --proto_path=. api_options.proto && \
		$(HOST_DIR)/bin/protoc --python_out=. --proto_path=. api.proto
	sed -i 's/^import api_options_pb2/from . import api_options_pb2/' \
		$(@D)/aioesphomeapi/api_pb2.py
	rm -f $(@D)/aioesphomeapi/*_pb2.pyi
endef

PYTHON_AIOESPHOMEAPI_POST_PATCH_HOOKS += PYTHON_AIOESPHOMEAPI_REGENERATE_PROTOBUF

$(eval $(python-package))
