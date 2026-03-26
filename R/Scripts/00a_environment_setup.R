#* 0a: Environment Setup
#' Package management is handled by renv for reproducibility.
#' All required packages and their exact versions are specified in renv.lock.
#' 
#' The renv environment is verified and restored (if needed) by restore_renv.R
#' which is sourced at the beginning of run.R.

#+ 0a.1: Load conflicted and set ALL preferences BEFORE loading other packages
library(conflicted)
# Set all conflict preferences to prevent warnings during package loading
conflicts_prefer(purrr::map)
conflicts_prefer(dplyr::filter)
conflicts_prefer(dplyr::summarize)
conflicts_prefer(dplyr::select)
conflicts_prefer(dplyr::first)
conflicts_prefer(dplyr::mutate)
conflicts_prefer(dplyr::arrange)
conflicts_prefer(dplyr::summarise)
conflicts_prefer(dplyr::count)
conflicts_prefer(dplyr::rename)
conflicts_prefer(ggplot2::margin)
conflicts_prefer(stats::chisq.test)
conflicts_prefer(stats::fisher.test)
conflicts_prefer(jsonlite::fromJSON)
conflicts_prefer(readxl::read_xlsx)
conflicts_prefer(raster::intersect)
conflicts_prefer(igraph::compose)
conflicts_prefer(flextable::align)
conflicts_prefer(base::setdiff)
conflicts_prefer(base::as.factor)
conflicts_prefer(base::unique)
conflicts_prefer(base::as.data.frame)
#+ 0a.2: Load all packages from DESCRIPTION file
source("R/Utilities/Helpers/load_packages_from_description.R")
load_packages_from_description()
#+ 0a.3: Load GitHub Packages explicitly for renv detection
library(TernTablesR)
library(MetaboAnalystR)
#+ 0a.4: Check system dependencies
source("R/Utilities/Helpers/check_system_dependencies.R")
check_system_dependencies()
#+ 0a.5: Register Arial in R's PostScript/PDF font database (always required)
# grid::draw_label() and cowplot use grid.Call(C_textBounds) which looks up fonts
# in grDevices::pdfFonts(), NOT in systemfonts. This must always be registered
# regardless of whether the TTF file is physically present on the system.
tryCatch({
  grDevices::pdfFonts(Arial = grDevices::pdfFonts()[["Helvetica"]])
  grDevices::postscriptFonts(Arial = grDevices::postscriptFonts()[["Helvetica"]])
  message("Arial registered in PDF/PostScript font database")
}, error = function(e) {
  message("Could not register Arial in PDF font database: ", e$message)
})
# If Arial TTF is not physically present, also register a substitute via systemfonts
# (covers ragg/PNG rendering on plain Linux without the bundled fonts/)
if (!any(systemfonts::system_fonts()$family == "Arial")) {
  message("Arial TTF not found - registering Liberation Sans as Arial substitute for PNG rendering")
  tryCatch({
    systemfonts::register_font(
      name = "Arial",
      plain = systemfonts::system_fonts()$path[systemfonts::system_fonts()$family == "Liberation Sans" & systemfonts::system_fonts()$style == "Regular"][1],
      bold = systemfonts::system_fonts()$path[systemfonts::system_fonts()$family == "Liberation Sans" & systemfonts::system_fonts()$style == "Bold"][1],
      italic = systemfonts::system_fonts()$path[systemfonts::system_fonts()$family == "Liberation Sans" & systemfonts::system_fonts()$style == "Italic"][1],
      bolditalic = systemfonts::system_fonts()$path[systemfonts::system_fonts()$family == "Liberation Sans" & systemfonts::system_fonts()$style == "Bold Italic"][1]
    )
    message("Liberation Sans registered as Arial substitute for PNG rendering")
  }, error = function(e) {
    message("Could not register font substitute: ", e$message)
  })
}