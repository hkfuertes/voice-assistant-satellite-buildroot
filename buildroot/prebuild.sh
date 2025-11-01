#!/bin/sh

docker run --rm --platform linux/arm64 \
  -v $(pwd)/external/package/wyoming-openwakeword/files:/wheels \
  python:3.13-slim \
  pip3 wheel --no-deps -w /wheels pyopen-wakeword
