################################################################################
#
# host-python-pybind11
#
################################################################################

HOST_PYTHON_PYBIND11_VERSION = 2.13.6
HOST_PYTHON_PYBIND11_SOURCE = pybind11-$(HOST_PYTHON_PYBIND11_VERSION).tar.gz
HOST_PYTHON_PYBIND11_SITE = https://files.pythonhosted.org/packages/source/p/pybind11
HOST_PYTHON_PYBIND11_SETUP_TYPE = setuptools
HOST_PYTHON_PYBIND11_LICENSE = BSD-3-Clause
HOST_PYTHON_PYBIND11_LICENSE_FILES = LICENSE

$(eval $(host-python-package))
