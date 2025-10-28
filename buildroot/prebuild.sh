#!/bin/sh

docker run --rm --platform linux/arm64 \
  -v $(pwd)/external/package/wyoming-openwakeword/files:/wheels \
  python:3.13-slim \
  pip3 wheel --no-deps -w /wheels pyopen-wakeword

docker run --rm --platform linux/arm64 \
  -v $(pwd)/external/package/wyoming-microwakeword/files:/output \
  python:3.13-slim \
  bash -c "
    apt-get update && apt-get install -y build-essential cmake && \
    pip3 install pymicro-wakeword && \
    cd /usr/local/lib/python3.13/site-packages && \
    tar czf /output/pymicro-complete.tar.gz pymicro_* micro_*
  "

make -p $(pwd)/external/package/linux-voice-assistant/files
cp $(pwd)/external/package/wyoming-microwakeword/files/pymicro-complete.tar.gz \
   $(pwd)/external/package/linux-voice-assistant/files/