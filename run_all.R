# Reproduce everything. Run from the repository root:  Rscript run_all.R
# Needs the Freddie Mac sample file sample_orig_2024.txt in FREDDIE_DIR (default ~/Downloads/freddie).
# Packages: readr, dplyr, tidyr, ggplot2, knitr, rmarkdown, broom, car, lmtest, sandwich, emmeans, nortest; Quarto for the report.
setwd("chapters")
for (f in sort(list.files(pattern = "^[0-5]-.*[.]Rmd$"))) {
  rmarkdown::render(f, output_dir = "../docs/chapters", envir = new.env(), quiet = TRUE)
}
setwd("..")
system2("quarto", c("render", "index.qmd"))
