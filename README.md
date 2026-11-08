# Qwen Image 2.1 on DGX Spark

A headless, SSH-operated local image-generation service for NVIDIA DGX Spark. The container compiles upstream stable-diffusion.cpp with CUDA for compute capability 12.1 and refuses to start without the NVIDIA GPU.

The diffusion transformer uses the INT8 ConvRot Qwen Image 2.1 checkpoint, with a BF16 VAE and a Q4_K_M Qwen3-VL 8B GGUF text/vision encoder. The API accepts prompts with up to ten reference images.

## Tested systems and acceleration stack

| Host | OS and kernel | GPU and host driver | Container and acceleration |
|---|---|---|---|
| Sparky, this repo | Ubuntu 24.04.5 LTS; Linux 7.0.0-1019-nvidia | NVIDIA GB10, compute capability 12.1; driver 595.99.02. NVIDIA-SMI reports CUDA 13.2 support. | Docker 29.6.2; NVIDIA CUDA 12.9.1 Ubuntu 24.04 image; stable-diffusion.cpp compiled for sm_121. |
| Seratonin, ROCm comparison | Ubuntu 24.04.5 LTS; Linux 7.0.0-38-generic | AMD Radeon 890M, gfx1150, integrated into Ryzen AI 9 HX370. rocm-smi driver report: 7.0.0-38-generic (same as the host kernel release). | Docker 29.8.0; ROCm 7.2.1 PyTorch image on Ubuntu 24.04; HIPBLAS build for gfx1150. |

Seratonin is a Minisforum AI X1 Pro with AMD Ryzen AI 9 HX370 (12 cores / 24 threads, up to 5.1 GHz), Radeon 890M, 96 GB DDR5, and a 2 TB PCIe 4.0 SSD. The ROCm container receives the host GPU through /dev/kfd and /dev/dri. On Sparky, the host driver is newer than the CUDA 12.9.1 runtime in the application container; NVIDIA-SMI's CUDA 13.2 value describes driver compatibility, while the service container uses CUDA 12.9.1.

## Matched test results

Both hosts used the same INT8 ConvRot diffusion checkpoint, BF16 VAE, Q4_K_M text/vision encoder, prompts, reference images, seeds, 768×1024 output size, and 20 steps.

| Test | Sparky, NVIDIA GB10 | Seratonin, Radeon 890M |
|---|---:|---:|
| Unicorn text-to-image, seed 28417 | 32.765 s | 288.438 s |
| Woman-at-harbor with two reference images, seed 73023 | 165.620 s | 566.506 s |

These are local generation times, including per-request model loading, and excluding model download and image upload. The first Spark model download took 198.539 s for approximately 14 GB; subsequent requests used the local cache.

## Example outputs from Sparky

These committed PNGs are the outputs from the two matched tests. The reference-conditioned test uses the portrait and harbor images in tests/assets/.

<table>
  <tr><th>Text prompt · seed 28417 · 32.765 s</th><th>Two reference images · seed 73023 · 165.620 s</th></tr>
  <tr>
    <td><img src="tests/results/unicorn-riding-harley.png" alt="Ivory unicorn riding a black Harley on a mountain road at sunset" width="360"></td>
    <td><img src="tests/results/woman-sailing-at-harbor.png" alt="Woman from the portrait reference preparing a sailboat at the harbor" width="360"></td>
  </tr>
</table>

The sample files are tracked under tests/results/ and arrive with git pull. The exact prompts, seeds, and input images are in tests/generate_examples.py and tests/assets/.

## Run the service

    ./start.sh
    ./stop.sh

The API binds to 127.0.0.1:8188. Reach it over SSH with:

    ssh -N -L 8188:127.0.0.1:8188 sparky

The first generation downloads approximately 14 GB of model weights into models/.

## Reproduce the tests

With the service running:

    python3 tests/generate_examples.py

The script prints the output paths and timings. Fresh PNGs go under outputs/; request timings are appended to logs/timings.jsonl, and native inference logs are saved under logs/. To refresh the committed samples, copy the newly generated matching PNGs into tests/results/ using the names above, then commit the updated images. The test script defaults to 768×1024 and 20 steps; set TEST_WIDTH, TEST_HEIGHT, or TEST_STEPS to change those settings.
