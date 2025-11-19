#!/usr/bin/env python3
from setuptools import setup, find_packages

setup(
    name='linux-voice-assistant-wrapper',
    version='1.0.0',
    description='Wrapper for linux-voice-assistant with LED event support',
    author='Miguel Fuertes',
    author_email='hkfuertes@gmail.com',
    url='https://github.com/hkfuertes/voice-assistant-satellite-buildroot',
    packages=find_packages(),
    python_requires='>=3.7',
    install_requires=[
        'spidev',
        'gpiozero',
    ],
    entry_points={
        'console_scripts': [
            'voice-wrapper=wrapper:main',
        ],
    },
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.13',
    ],
)
