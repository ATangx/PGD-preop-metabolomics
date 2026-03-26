# Dockerfile for Reproducible R Environment
# For maximum reproducibility across different systems
# R version 4.5.1 (2025-06-13)

FROM rocker/r-ver:4.5.1

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
# Based on requirements from R/Utilities/Helpers/check_system_dependencies.R
RUN apt-get update && apt-get install -y \
    # Core build tools
    build-essential \
    gfortran \
    cmake \
    # Required system tools (from check_system_dependencies.R)
    ghostscript \
    pandoc \
    imagemagick \
    # XML and networking
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libgit2-dev \
    # Graphics and fonts
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libcairo2-dev \
    libxt-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    # Liberation fonts (Arial-compatible, required for XeLaTeX \setmainfont{Arial} in script 08)
    fonts-liberation \
    fonts-liberation2 \
    # LaTeX/PDF generation dependencies
    wget \
    perl \
    # HDF5 for bioinformatics (MSnbase, xcms)
    libhdf5-dev \
    libnetcdf-dev \
    # Additional dependencies for Bioconductor packages
    libfftw3-dev \
    libgsl-dev \
    libgmp-dev \
    libglpk-dev \
    # GraphViz for network plots
    graphviz \
    libgraphviz-dev \
    # Additional system dependencies identified by renv
    gdal-bin \
    git \
    libgdal-dev \
    libmagick++-dev \
    # TeX Live for PDF/XeLaTeX generation (replaces TinyTeX network installer)
    # Needed by supporting_info.Rmd and cover_page.Rmd which use xelatex + fontspec
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-latex-extra \
    lmodern \
    && rm -rf /var/lib/apt/lists/*

# Install real Arial fonts (copied from macOS into the repo fonts/ directory)
# This ensures cairo_pdf, systemfonts, and XeLaTeX all find genuine Arial
COPY fonts/ /usr/share/fonts/truetype/arial/
RUN fc-cache -fv

# Set up renv for exact package restoration
RUN Rscript -e "install.packages('renv', repos='https://cloud.r-project.org')"

# Copy project files
WORKDIR /analysis
COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

# Copy remaining project files before restore (needed for renv to scan dependencies)
COPY DESCRIPTION .
COPY R/ R/
COPY All_Run/ All_Run/
COPY Databases/ Databases/
COPY Outputs/ Outputs/
COPY ["Supporting Information/", "Supporting Information/"]

# Restore R packages from renv.lock (this captures exact versions from laptop)
RUN Rscript -e "renv::restore()"

# Verify renv status
RUN Rscript -e "renv::status()"

# Default command runs the full pipeline
CMD ["Rscript", "All_Run/run.R"]