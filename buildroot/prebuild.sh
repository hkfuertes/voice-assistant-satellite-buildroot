#!/bin/sh

docker run --rm --platform linux/arm64 \
  -v $(pwd)/external/package/wyoming-openwakeword/files:/wheels \
  python:3.13-slim \
  pip3 wheel --no-deps -w /wheels pyopen-wakeword

# Instala TODO en un contenedor ARM64 y empaqueta el directorio completo
docker run --rm --platform linux/arm64 \
  -v $(pwd)/external/package/wyoming-microwakeword/files:/output \
  python:3.13-slim \
  bash -c "
    apt-get update && apt-get install -y build-essential cmake && \
    pip3 install pymicro-wakeword && \
    cd /usr/local/lib/python3.13/site-packages && \
    tar czf /output/pymicro-complete.tar.gz pymicro_* micro_*
  "
