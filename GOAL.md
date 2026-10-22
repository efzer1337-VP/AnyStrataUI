# GOAL.md — PolyStrata with Strata UI

## North star

Create **one fully functional Windows desktop application that looks and feels like the original Strata, runs models using PolyStrata's supported inference engines, and can discover, evaluate, download, and launch compatible models from Hugging Face — including uncensored and abliterated fine-tunes.**

**Product formula:** `Original Strata UI/UX + PolyStrata inference + Hugging Face model browser + hardware-aware model management`.

This is a real local inference product, **not** a screenshot clone, a web mockup, or two applications loosely bundled together.

## Upstream projects

- **Strata** — https://github.com/Niko1221/Strata — primary source of UI, interaction design, and the existing hardware-aware recommendation flow.
- **PolyStrata** — https://github.com/VecSzn/PolyStrata — primary source of expanded engine/model support and runtime functionality.

PolyStrata documents its reuse of the Strata engine for Qwen3.8-Flash-Next, plus separate engines for other model families. Its custom GGUF workflows should be reused where supported. Exact capabilities are contingent on the chosen upstream revisions and actual verification.

## Intended user experience

1. Open a single Strata-looking Windows app.
2. See the familiar **Recommended** list, including quantizations, memory estimates, and download sizes.
3. Optionally open **Hugging Face Search** in the same interface.
4. Search by name/author/repository/URL, or filter for **Uncensored / Abliterated**, GGUF, architecture, quantization, and compatibility.
5. Open a model to see its description, real files, quantizations, shards, size, license, model family, and supported engine(s).
6. See hardware-aware estimates for selected quantization and context: VRAM, RAM, KV cache, and any genuinely supported SSD/disk assistance.
7. Download required files with progress, safe recovery, and integrity checks.
8. Load a supported model using the correct PolyStrata engine without leaving the app.
9. Chat with streaming output, monitor performance, change settings, and unload/switch models.

Discoverability **does not imply** compatibility: unsupported models are shown honestly, never falsely marked runnable.

## Product pillars

### 1. Authentic Strata interface

Preserve as closely as technically and legally feasible:
- Dark visual language, main layout, typography, icons, components, navigation, and interactions.
- Existing chat, monitoring, settings, and model-management experiences.
- Hardware-aware **Recommended** groups and their expandable model variants.
- Original responsiveness and usability.

New features must look native to Strata; do not redesign the product into a generic model launcher.

### 2. PolyStrata inference foundation

- Retain PolyStrata's verified model families and inference engines, including its Strata-backed path where applicable.
- Support engine selection/routing, start/stop, model switching, streaming, and error reporting.
- Preserve supported local APIs (such as OpenAI-/Anthropic-compatible endpoints) without inventing missing functionality.
- Reuse existing custom GGUF validation/loading mechanisms instead of duplicating code.

### 3. Hugging Face model discovery

- Search all public/searchable HF models, not a fixed curated list.
- First-class optional `Uncensored / Abliterated` filter using terms and metadata such as `uncensored`, `abliterated`, `heretic`, `dolphin`, `unfiltered`, and `no-refusal`.
- Explicitly distinguish verified model metadata from heuristics; model naming alone is insufficient proof.
- Browse GGUF files and quantizations; handle sharded models and repositories with multiple files.
- Respect authentication, model licenses, and gated repository access.

### 4. Smart model suitability

- Detect actual computer resources at runtime.
- Estimate model weights, VRAM/RAM residence, KV cache, context, buffers, and margin.
- Show meaningful categories: **Excellent fit / Good fit / Limited / Not recommended / Unsupported / Unknown**.
- Identify the appropriate engine and why a quantization should or should not run.
- Offer preference-based recommendations (coding, general chat, speed, memory efficiency, large context, uncensored).
- No invented compatibility data, benchmarks, or guaranteed context sizes.

### 5. Reliable model lifecycle

- Search → inspect → choose GGUF → validate → download → register → load → chat → unload.
- Resumable/recoverable downloads where feasible, disk-space checks, required shards, and integrity verification when metadata permits.
- Import existing local GGUF files without unnecessary duplication or deletion.
- Keep UI responsive during model downloads and initialization.
- Respect user data and protect API/HF credentials.

## Primary development target

- Windows 11
- NVIDIA RTX 4080, 16 GB VRAM
- AMD Ryzen 9 5950X
- 32 GB system RAM
- SSD storage (capacity detected dynamically)

This target informs testing and default recommendations; the implementation should detect other supported machines rather than hardcode this profile.

## MVP — must work first

1. Single runnable desktop application with original Strata-style chat, models, and settings screens.
2. Stable PolyStrata-backed model selection, loading, unloading, and streaming inference on Windows.
3. Original curated recommendations retained.
4. Hugging Face text search with uncensored/abliterated filter and usable model details.
5. Real GGUF listing, file size, quantization, shard, and compatibility identification.
6. Download and local registration of a supported model.
7. Basic hardware-aware RAM/VRAM suitability estimate with uncertainty labels.
8. Clear errors, safe storage paths, and no destructive changes to existing model files.

## Later milestones

- Advanced model ranking and broader model-family discovery.
- Detailed live performance/KV-cache monitoring where backend metrics allow.
- More precise context-dependent memory estimation.
- Advanced GPU offloading, batch, and KV-cache controls only for engines that implement them.
- Improved background download recovery and local cache management.
- Polished Windows installer/portable distribution and automated compatibility regression tests.

## Explicit non-goals

- Supporting every arbitrary GGUF architecture or quantization.
- Training or fine-tuning models inside the app.
- Guaranteeing that any model tagged `uncensored` is actually uncensored.
- Bypassing gated Hugging Face access or ignoring licenses.
- Promising all models will work on 16 GB VRAM or a 256K context.
- Rewriting functioning inference engines purely for stylistic reasons.
- Replacing the original Strata UI with an unrelated design.
- Building a cloud-hosted inference service.

## Definition of done

The project reaches its main goal when a user can:

1. Launch **one** Windows application that closely matches Strata's original interface.
2. Find a model from Strata's recommendations **or** from Hugging Face (including uncensored searches).
3. Inspect real GGUF quantizations, memory estimates, support status, and download size.
4. Download or import a model safely.
5. Load it through the appropriate functioning PolyStrata engine.
6. Generate a real streamed chat response.
7. Observe meaningful status/monitoring, change supported settings, and switch or unload the model.
8. Repeat this workflow after restarting the app without losing configuration.

Success requires **actual Windows builds and runtime tests**. A build alone does not prove GPU inference; an attractive UI alone does not satisfy the goal.

## Delivery artifacts

- Working source tree with preserved upstream licenses/attribution.
- `AGENTS.md` and `GOAL.md` kept current as implementation evolves.
- Reproducible build instructions and Windows packaging where feasible.
- Tested workflows, known model/engine compatibility, and test results.
- Explicit remaining issues and limitations.

## Decision rule

If there is a conflict, **preserve working inference and model compatibility first**, preserve original Strata UI fidelity second, and add new functionality with the smallest reliable integration surface. Validate architectural assumptions against real code and ask for user approval for major tradeoffs.
