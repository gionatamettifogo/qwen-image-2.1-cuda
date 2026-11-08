# Qwen Image 2.1 on DGX Spark

A headless, SSH-operated local image-generation service for NVIDIA DGX Spark (GB10, CUDA compute capability 12.1). The container compiles upstream stable-diffusion.cpp with CUDA for `sm_121` and fails health checks if the CUDA GPU is unavailable.

The diffusion transformer uses the INT8 ConvRot Qwen Image 2.1 checkpoint, with a BF16 VAE and a Q4_K_M Qwen3-VL 8B GGUF text/vision encoder. The API runs locally and accepts prompts with up to ten reference images.

## Start and stop

    ./start.sh
    ./stop.sh

The API binds to `127.0.0.1:8188`. Reach it over SSH from another computer with:

    ssh -N -L 8188:127.0.0.1:8188 sparky

Then call `http://127.0.0.1:8188/generate`. The first generation downloads approximately 14 GB of model weights into `models/`.

## Smoke tests

    python3 tests/generate_examples.py

This generates a text-only image and an image using two reference assets. Set `TEST_SIZE` or `TEST_STEPS` to change the default 512×512, eight-step smoke runs.

## Timing

Each request is recorded in `logs/timings.jsonl`; the full native CLI output is saved as `logs/<request-id>.log`. `generation_seconds` covers local model loading and inference, excluding initial model downloads and uploads.
