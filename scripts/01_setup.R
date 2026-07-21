# Project setup and dependency configuration.
# Purpose: Load packages and define shared project paths.

user_library <- Sys.getenv("R_LIBS_USER")

if (user_library == "") {
  user_library <- file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library", paste(R.version$major, R.version$minor, sep = "."))
}

dir.create(user_library, recursive = TRUE, showWarnings = FALSE)
.libPaths(unique(c(user_library, .libPaths())))

options(timeout = 300)

required_packages <- c(
  "dplyr",
  "tidyr",
  "readr",
  "stringr",
  "ggplot2",
  "lubridate",
  "janitor",
  "scales",
  "zoo"
)
missing_packages <- required_packages[!required_packages %in% rownames(installed.packages())]

if (length(missing_packages) > 0) {
  install.packages(
    missing_packages,
    lib = user_library,
    repos = "https://cloud.r-project.org",
    type = "binary"
  )
}

invisible(lapply(required_packages, library, character.only = TRUE))

raw_data_dir <- "data/raw"
processed_data_dir <- "data/processed"
figure_dir <- "output/figures"
table_dir <- "output/tables"

dir.create(processed_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

theme_set(
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      plot.subtitle = element_text(color = "gray35"),
      panel.grid.minor = element_blank()
    )
)

message("Setup complete.")
