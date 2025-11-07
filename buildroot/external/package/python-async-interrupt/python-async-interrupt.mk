PYTHON_ASYNC_INTERRUPT_VERSION = 1.2.1
PYTHON_ASYNC_INTERRUPT_SOURCE = async_interrupt-$(PYTHON_ASYNC_INTERRUPT_VERSION).tar.gz
PYTHON_ASYNC_INTERRUPT_SITE = https://files.pythonhosted.org/packages/source/a/async_interrupt
PYTHON_ASYNC_INTERRUPT_LICENSE = Apache-2.0
PYTHON_ASYNC_INTERRUPT_SETUP_TYPE = setuptools
$(eval $(python-package))
