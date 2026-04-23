FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ghdl \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    make \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir --break-system-packages -r /tmp/requirements.txt

CMD ["make", "cocotb-test"]
