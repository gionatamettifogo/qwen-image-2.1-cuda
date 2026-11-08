FROM nvidia/cuda:12.9.1-devel-ubuntu24.04 AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential ca-certificates cmake git libcurl4-openssl-dev ninja-build \
    && git clone --recursive --depth 1 https://github.com/leejet/stable-diffusion.cpp.git /tmp/stable-diffusion.cpp \
    && cmake -S /tmp/stable-diffusion.cpp -B /tmp/sd-build -G Ninja \
      -DSD_CUDA=ON -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CUDA_ARCHITECTURES=121 \
      -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    && cmake --build /tmp/sd-build --target sd-cli -j 8 \
    && install -m 0755 /tmp/sd-build/bin/sd-cli /usr/local/bin/sd-cli \
    && rm -rf /tmp/stable-diffusion.cpp /tmp/sd-build /var/lib/apt/lists/*

FROM nvidia/cuda:12.9.1-runtime-ubuntu24.04
ENV PYTHONUNBUFFERED=1 HF_HOME=/models/huggingface HUGGINGFACE_HUB_CACHE=/models/huggingface/hub
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-pip libgomp1 libcurl4 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /usr/local/bin/sd-cli /usr/local/bin/sd-cli
WORKDIR /app
COPY requirements.txt .
RUN python3 -m pip install --break-system-packages --no-cache-dir -r requirements.txt
COPY server.py .
EXPOSE 8188
CMD ["python3", "-m", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8188"]
