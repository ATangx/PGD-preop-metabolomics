# Recipient Plasma Metabolomics as a Predictor of Heart Transplant Severe Primary Graft Dysfunction

## 📖 Citation

This code is associated with the analysis presented in the following manuscript:
> Preston et al. (2025). Recipient Plasma Metabolomics as a Predictor of Heart Transplant Severe Primary Graft Dysfunction. *American Journal of Transplantation*.

## 🚀 Quick Start for Reproduction

**⚠️ Data Availability Notice**: 
- **No data files** (raw data, processed feature tables, or clinical metadata) are included in this repository
- **All instructions below assume you have obtained data files or are using your own data**
- **To reproduce this analysis**: Contact the senior author (Joshua L. Chan, joshua.chan@emory.edu) or first author (Joshua D. Preston, joshua.preston@emory.edu) to obtain the data files—this is the easiest and recommended approach
- **Public data access**: Raw metabolomics data and untargeted feature tables will be available after embargo (October 31, 2026) through the NIH Common Fund's National Metabolomics Data Repository (NMDR) website, Metabolomics Workbench (Project ID PR002742; Study ID ST004328; DOI: http://dx.doi.org/10.21228/M87549)
- **To run analyses with your own data or provided data files**: Update file paths in `All_Run/config_dynamic.yaml` to match your system

### Option 1: Using Docker (Recommended for Exact Reproducibility)

**Prerequisites**: 
- Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
- (Optional) Create free [Docker Hub](https://hub.docker.com) account

#### Method A: Pull Pre-built Image (Fastest - Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/jdpreston30/PGD-preop-metabolomics.git
cd PGD-preop-metabolomics

# 2. Pull the pre-built Docker image (~5-10 minutes)
docker pull jdpreston30/pgd-preop-metabolomics:latest

# 3. Run the complete analysis pipeline
docker run -v $(pwd):/analysis jdpreston30/pgd-preop-metabolomics:latest


# Windows users: Replace $(pwd) with:
# - CMD: docker run -v %cd%:/analysis jdpreston30/pgd-preop-metabolomics:latest
# - PowerShell: docker run -v ${PWD}:/analysis jdpreston30/pgd-preop-metabolomics:latest
```

#### Method B: Build Image Locally

```bash
# 1. Clone the repository
git clone https://github.com/jdpreston30/PGD-preop-metabolomics.git
cd PGD-preop-metabolomics

# 2. Build the Docker image from Dockerfile (~30-45 minutes)
docker build -t pgd-metabolomics .

# 3. Run the complete analysis pipeline
docker run -v $(pwd):/analysis pgd-metabolomics

# Windows users: Replace $(pwd) with:
# - CMD: docker run -v %cd%:/analysis pgd-metabolomics
# - PowerShell: docker run -v ${PWD}:/analysis pgd-metabolomics
```

All outputs (figures, tables, pathway results) will be saved to your local workspace.

#### Testing the Container

To verify the Docker image was built correctly before running the full analysis:

```bash
# Quick verification (< 1 minute)
docker run --rm pgd-metabolomics Rscript -e "packageVersion('xcms'); packageVersion('mixOmics')"
```

This should display package versions. If it succeeds, the container is ready for the full analysis.

#### Troubleshooting

**Build fails or is very slow**: 
- This is normal for the first build (30-45 minutes) due to compiling complex packages like xcms
- If build is interrupted, run `docker build` again - it will resume from where it stopped

**"No space left on device" error**:
- The final image is ~3-5 GB
- Check available disk space: `docker system df`
- Clean up old images: `docker image prune`

**Container runs but produces no output**:
- Check the Outputs directory exists and is writable
- Verify the mount path: `ls Outputs/`

### Option 2: Manual Installation (Without Docker)

**Prerequisites**: 
- R >= 4.5.1
- Git (to clone repository)

**Note**: This project uses `renv` for package management to ensure reproducibility. The `renv.lock` file contains exact versions of all packages used in the manuscript.

```r
# 1. Clone the repository
# (from terminal)
git clone https://github.com/jdpreston30/PGD-preop-metabolomics.git
cd PGD-preop-metabolomics

# 2. Start R in the project directory
# (renv automatically activates via .Rprofile)

# 3. Restore all packages at exact versions (first time only, ~10-20 minutes)
renv::restore()

# 4. Check system dependencies
source("R/Utilities/Helpers/check_system_dependencies.R")
check_system_dependencies()

# 5. Run the complete analysis pipeline
source("All_Run/run.R")
```

**What happens during `renv::restore()`**:
- Installs 246 R packages at exact versions from `renv.lock`
- Installs CRAN packages (e.g., ggplot2, dplyr, broom, conflicted)
- Installs Bioconductor 3.21 packages (e.g., xcms, mixOmics, CAMERA)
- Installs GitHub packages (TernTablesR, MetaboAnalystR)
- Creates isolated project library (doesn't affect your system R packages)
- Only needed once per computer; subsequent runs use installed packages
- Packages are automatically loaded from `DESCRIPTION` file during pipeline execution

## 📁 Project Structure

```
├── DESCRIPTION                 # R package dependencies (CRAN, Bioconductor, GitHub)
├── Dockerfile                  # Docker container for reproducible environment
├── renv.lock                   # Exact package versions for reproducibility
├── session_info.txt            # Timestamped session and package information
├── All_Run/                    # Pipeline execution
│   ├── config_dynamic.yaml     # Analysis configuration (update paths for your system)
│   └── run.R                   # Main pipeline execution script
├── R/                          # Analysis code
│   ├── Scripts/                # Analysis workflow scripts (00a-09)
│   ├── Utilities/              # Custom analysis functions
│   │   ├── Analysis/           # Statistical and pathway analysis
│   │   ├── Helpers/            # Helper functions
│   │   ├── Preprocessing/      # Data preprocessing functions
│   │   └── Visualization/      # Plotting functions
│   └── raw_process/            # Raw data processing (not part of main pipeline)
├── Databases/                  # Reference databases/metabolite libraries
├── Outputs/                    # Generated results
│   ├── Figures/                # Publication figures (PDF, EPS, PNG)
│   ├── Tables/                 # Tables (Clinical Data)
│   └── mummichog/              # Pathway enrichment results
└── Supporting Information/     # Supplementary materials and methods
```

## 🔬 Analysis Workflow

The complete pipeline executes in sequence:

1. **00a-00d**: Environment setup, clinical metadata, feature tables
2. **01**: Clustering analysis
3. **02**: Pathway enrichment (mummichog analysis)
4. **03**: Annotated bar plots
5. **04**: Assignment of plots
6. **05**: Render final figures
7. **06**: Generate tables of clinical data
8. **07**: Results mentioned in manuscript but not in figures/tables
9. **08**: Supporting information document creation
10. **09**: Session information (documents final package versions)

## 💻 System Requirements

### Computational Requirements
- **R**: Version 4.5.1 or higher
- **Platform**: Developed on macOS but should work well on Windows or Linux
- **Note**: Standard modern computer sufficient; no special hardware required

### System Dependencies
- **Ghostscript**: PDF to EPS conversion
- **Pandoc**: R Markdown rendering
- **ImageMagick**: Image processing
- **TinyTeX/LaTeX**: PDF generation

*Note: All system dependencies are automatically installed in the Docker container. For manual installation, run `check_system_dependencies()` for platform-specific instructions.*

## 📦 Package Dependencies

All R package dependencies are specified in `DESCRIPTION`. Key packages include:

### CRAN Packages
- **Data manipulation**: tidyverse (dplyr, tidyr, purrr, readr, etc.)
- **Visualization**: ggplot2, ggraph, patchwork, Cairo, magick
- **Statistical modeling**: mixOmics, caret, randomForest, e1071
- **Reporting**: rmarkdown, knitr, officer, flextable

### Bioconductor Packages (Bioconductor 3.21)
- **MetaboAnalystR dependencies**: xcms, CAMERA, MSnbase
- **Pathway analysis**: fgsea, globaltest, GlobalAncova
- **Network analysis**: RBGL
- **Data structures**: BiocParallel, multtest

### GitHub Packages
- `jdpreston30/TernTablesR`: Epidemiologic statistics and tables
- `xia-lab/MetaboAnalystR`: Metabolomics analysis and pathway enrichment

*See `DESCRIPTION` file for complete list of all dependencies.*

## 🔄 Reproducibility Features

This project implements best practices for computational reproducibility:

- ✅ **Version Control**: Complete analysis code on GitHub
- ✅ **Package Management**: `renv` with `renv.lock` pinning all 246 packages to exact versions
- ✅ **Dependency Declaration**: All dependencies specified in `DESCRIPTION` with automatic loading
- ✅ **Containerization**: Docker image (R 4.5.1, Bioconductor 3.21) available at `jdpreston30/pgd-preop-metabolomics:latest`
- ✅ **Conflict Resolution**: `conflicted` package ensures predictable function behavior
- ✅ **Docker Hub Distribution**: Pre-built image available at [jdpreston30/pgd-preop-metabolomics](https://hub.docker.com/r/jdpreston30/pgd-preop-metabolomics)
- ✅ **Configuration-Driven**: All parameters in `config_dynamic.yaml`
- ✅ **System Dependency Checking**: Automated validation via `check_system_dependencies()`
- ✅ **Documentation**: Comprehensive function documentation and workflow comments
- ✅ **Session Info**: Timestamped session information in `session_info.txt` documents exact package versions

## 📧 Contact

**First Author & Repository Maintainer**: Joshua D. Preston
- **Email**: joshua.preston@emory.edu  
- **ORCID**: [0000-0001-9834-3017](https://orcid.org/0000-0001-9834-3017)  
- **Institution**: Department of Surgery, Emory University School of Medicine

**Senior & Corresponding Author**: Joshua L. Chan
- **Email**: joshua.chan@emory.edu  
- **ORCID**: [0000-0001-7220-561X](https://orcid.org/0000-0001-7220-561X)  
- **Institution**: Department of Surgery, Emory University School of Medicine

---

**Repository**: https://github.com/jdpreston30/PGD-preop-metabolomics  
**Docker Hub**: https://hub.docker.com/r/jdpreston30/pgd-preop-metabolomics  
**Zenodo Archive**: https://doi.org/10.5281/zenodo.17875844 (archived December 10, 2025)
