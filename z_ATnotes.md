# Troubleshooting Notes: PGD Preop Metabolomics Pipeline
**Ailin Tang — March 16, 2026**

---

## Background

This project contains a metabolomics analysis pipeline originally written and run by Josh on his own machine. The goal was to reproduce all outputs (figures, tables, supporting information PDF) from scratch on my Mac (Apple Silicon / ARM64). This document summarizes everything that was tried, what failed, what worked, and why.

---

## Phase 1: Docker Approach

### Why Docker?

Docker was the intended reproducibility mechanism — Josh packaged the R environment and all dependencies into a Docker image so others could run the pipeline without worrying about system setup. In theory: pull image, run container, get outputs.

### What Happened

#### Initial Build Issues
- Docker image builds were slow and sometimes appeared to hang.
- The root cause: Docker on Mac (Apple Silicon) emulates x86_64 via Rosetta, which is slow, and memory limits are set conservatively.

#### Environment Conflicts
- The Docker image was built on Josh's Linux machine (Ubuntu). His environment had system libraries (Cairo, fonts, etc.) pre-installed or available in ways that didn't map cleanly to the container environment I was building.
- Font issues: Arial was not available inside the container. R scripts required Arial for PDF rendering via the `Cairo` graphics device and PostScript font registration. Attempted fix: copied Arial `.ttf` files from Mac into `fonts/`, updated the Dockerfile to install them via `fc-cache`, and improved font registration in `00a_environment_setup.R` and `vis_tools.R`.
- Cairo library conflicts: the `Cairo` R package failed to find `cairo.h` inside the container at various points.

#### Memory / RAM Limitations (The Core Problem)
- Script 05 (`05_render_figures.R`) renders all figures to high-resolution PDFs and consistently crashed with **exit code 137** — the Linux OOM (out-of-memory) killer.
- Docker on Mac is limited to a share of the Mac's RAM (default ~8 GB for Docker Desktop). Script 05 is memory-intensive (high-DPI PDF rendering via Cairo).
- Attempted mitigation: reduced PDF rendering DPI from 1200 → 300 in `05_render_figures.R`. This helped but did not fully resolve the issue.
- It's likely that even the earlier environment/font conflicts were masking an underlying memory problem — once those were partially resolved, the OOM kill became the clear bottleneck.

#### Summary of Docker Fixes Attempted
| Issue | Fix Attempted | Result |
|---|---|---|
| Arial fonts missing | Copied `.ttf` files, updated Dockerfile | Partial fix |
| Cairo library not found | Installed in Dockerfile | Partial fix |
| Script 05 OOM kill (exit 137) | Reduced DPI to 300 | Still failing |
| Font registration in R | Updated `00a_environment_setup.R`, `vis_tools.R` | Improved but not resolved |
| Config paths | Updated `config_dynamic.yaml` + `load_dynamic_config.R` for Docker vs native auto-detection | Working |

### Conclusion on Docker

Too many compounding conflicts — environment, fonts, memory — that were difficult to disentangle inside the container. Decided to try running natively on Mac instead.

---

## Phase 2: Native Mac Approach

### Strategy

Run the pipeline directly in R on the Mac, using `renv::restore()` to install all R packages from the lockfile. This required installing missing system libraries via Homebrew as compilation errors surfaced.

### System Library Installations (Homebrew)

Each library was installed as a compilation error appeared during `renv::restore()`:

| Library | Error it resolved |
|---|---|
| `pkg-config` (`pkgconf`) | All compiled R packages need it to find system libs |
| `cairo` | `Cairo` R package — `cairo.h` not found |
| `gettext` | `data.table` — `libintl.h` not found |
| **gfortran 14.2 (CRAN official pkg)** | `igraph` — Fortran compiler not found at `/opt/gfortran/` |
| `harfbuzz`, `fribidi` | `textshaping` — `hb-ft.h` not found |
| `jpeg-turbo`, `libtiff`, `webp` | `ragg` — `tiffio.h` not found |
| `imagemagick` | `magick` R package |
| `libgit2`, `libssh2` | `gert` R package |
| `poppler`, `gdal`, `proj`, `geos`, `glpk` | `pdftools`, spatial packages |

**Important note on gfortran:** The CRAN-distributed R for macOS ARM64 expects gfortran at `/opt/gfortran/bin/gfortran` (the official CRAN toolchain). Homebrew's `gcc` installs gfortran at `/opt/homebrew/bin/gfortran` — a different path. Simply symlinking wasn't enough because `igraph`'s linker step also looked for `emutls_w` and other libraries in `/opt/gfortran/lib/`. The fix was to download and install the **official CRAN gfortran-14.2-universal.pkg** from `https://mac.r-project.org/tools/`, which installs everything to the expected `/opt/gfortran/` path.

### `~/.R/Makevars` Configuration

Created `~/.R/Makevars` to help R's compiler find Homebrew-installed headers and libraries during compilation:

```makefile
CPPFLAGS=-I/opt/homebrew/include -I/opt/homebrew/Cellar/gettext/1.0/include
LDFLAGS=-L/opt/homebrew/lib -L/opt/homebrew/Cellar/gettext/1.0/lib -lintl
PKG_CONFIG_PATH=/opt/homebrew/lib/pkgconfig:/opt/homebrew/Cellar/cairo/1.18.4/lib/pkgconfig
```

### renv::restore() Outcome

After all system libraries were installed, `renv::restore()` completed successfully. Final `renv::status()` showed only 6 packages listed as "not used" (not "not installed") — these were installed and loadable, just not detected by renv's static analysis:
- `MetaboAnalystR`, `qs`, `RApiSerialize`, `RcppParallel`, `stringfish`, `TernTablesR`

All critical packages confirmed loading: `Cairo`, `igraph`, `data.table`, `textshaping`, `ragg`, `magick`, `ggplot2`, `dplyr`, `MetaboAnalystR` ✅

### Pipeline Execution

Ran `Rscript All_Run/run.R` natively. Scripts 00–08 completed without issues.

**Script 09 (Supporting Information PDF)** failed initially:
- Error: `File 'pdfpages.sty' not found`
- Cause: TinyTeX was on the 2025 release; the remote TeX Live repository had moved to 2026, blocking package installs.
- Fix: `tinytex::reinstall_tinytex(repository = "illinois")` upgraded to TinyTeX 2026, after which all LaTeX packages were available.
- Then rendered the Rmd directly: `rmarkdown::render('Supporting Information/supporting_info.Rmd')` ✅

### Final Outputs — All Successfully Generated

| Output | Location | Status |
|---|---|---|
| `fig1.pdf`, `fig2.pdf`, `fig3.pdf` | `Outputs/Figures/Final/PDF/` | ✅ Generated |
| `fig1.eps`, `fig2.eps`, `fig3.eps` | `Outputs/Figures/Final/EPS/` | ✅ Generated |
| `T1.docx`, `T2.docx`, `T3.docx` | `Outputs/Tables/` | ✅ Generated |
| Raw PNGs (fig1, fig2c, fig2d, S1, S2) | `Outputs/Figures/Raw/` | ✅ Generated |
| `supporting_info.pdf` (3.9 MB) | `Supporting Information/` | ✅ Generated |

---

## Do You Even Need Docker for Reproducibility?

**Short answer: No.** Docker is one way to achieve reproducibility, but not the only way — and for an R analysis like this, arguably not the best way.

This pipeline already has the right tool built in: **`renv`**. The `renv.lock` file snapshots every R package at its exact version. Any collaborator can:

1. Clone/download the project
2. Install system libraries (Homebrew on Mac, `apt` on Linux — a one-time step, now documented below)
3. Run `renv::restore()` to get the exact R environment
4. Run `Rscript All_Run/run.R`

The only thing `renv` *doesn't* capture is the system-level libraries (Cairo, gfortran, harfbuzz, etc.) — because those live outside R. But that gap is easy to close with a simple install list in the README, which is exactly what this notes document now provides.

**The tradeoff vs. Docker:**

| | Docker | Native + renv |
|---|---|---|
| Setup steps for user | Few (just `docker run`) | More (install system libs) |
| Troubleshooting when it breaks | Hard — errors are buried in container layers | Easy — errors are direct and Googleable |
| Memory limits | Artificially capped (especially on Mac) | Full system RAM available |
| Cross-platform | Good in theory, painful on Apple Silicon | Requires per-OS install instructions |
| Portability | High | High (with good documentation) |
| Long-term maintenance | Image can go stale, rebuild is slow | Lockfile is lightweight and easy to update |

So yes — native + `renv` + a documented system dependency list is a perfectly valid and often *more* practical reproducibility strategy, especially for academic analyses shared between a small number of collaborators. It's more transparent, easier to debug, and doesn't hit hidden resource walls.

---

## Docker vs. Native: Personal Takeaway

> *"Docker is really efficient and easy to run in the sense where it requires way less steps for the user and has everything in one place — but in the long run it results in a lot of hidden conflicts when running on different machines and is way more difficult to pinpoint and troubleshoot compared to locally running everything."*

This experience really illustrated the tradeoff:

- **Docker pros:** Single command to run the whole pipeline, no manual dependency management for the end user, portable in principle.
- **Docker cons on Mac (Apple Silicon):** 
  - Memory is capped and shared with the host OS — memory-intensive R scripts hit OOM limits.
  - x86_64 emulation via Rosetta adds overhead and build time.
  - System library conflicts (fonts, Cairo) are harder to debug inside the container.
  - When something goes wrong, it's much harder to know whether the issue is the container, the R environment, the OS emulation layer, or an actual code bug.

- **Native pros:**
  - Error messages are clear and direct — `libintl.h not found` → `brew install gettext`. Simple.
  - Full access to system RAM (no artificial cap).
  - Package manager (Homebrew) makes installing system libraries straightforward.
  - Once the environment is set up, iteration is fast.
- **Native cons:** More initial setup steps; environment is specific to this machine and not easily portable to others.

**Bottom line:** For a one-person analysis on your own Mac, native is much smoother. Docker makes more sense for deployment on servers or sharing with users who shouldn't have to think about R environments at all — but it requires the original developer to build and test the image on the same architecture as the target machine.

---

## Key Commands Reference

```bash
# Install system libraries (Homebrew)
brew install pkg-config cairo gettext gcc harfbuzz fribidi \
  jpeg-turbo libtiff webp imagemagick libgit2 libssh2 \
  poppler gdal proj geos glpk udunits

# Install official CRAN gfortran (required for igraph etc.)
# Download from: https://mac.r-project.org/tools/gfortran-14.2-universal.pkg
sudo installer -pkg /tmp/gfortran-14.2-universal.pkg -target /

# Create ~/.R/Makevars for compiler paths
mkdir -p ~/.R
# (add CPPFLAGS, LDFLAGS, PKG_CONFIG_PATH — see above)

# Restore R environment
cd /path/to/project
PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig" Rscript -e "renv::restore(prompt = FALSE)"

# Upgrade TinyTeX (if on old release)
Rscript -e "tinytex::reinstall_tinytex(repository = 'illinois')"

# Run full pipeline
Rscript All_Run/run.R

# Render Supporting Information manually if needed
Rscript -e "rmarkdown::render('Supporting Information/supporting_info.Rmd', output_dir='Supporting Information')"
```
