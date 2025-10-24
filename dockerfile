FROM python:slim
RUN apt update && apt install -y alsa-utils caps && rm -rf /var/lib/apt/lists/*
ADD https://github.com/rhasspy/wyoming-satellite.git#13bb0249310391bb7b7f6e109ddcc0d7d76223c1 /app/
WORKDIR /app
RUN script/setup
EXPOSE 10700/tcp
ENTRYPOINT ["/app/script/run"]
