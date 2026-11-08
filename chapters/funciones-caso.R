################################################################################
# Funciones compartidas por los capítulos del caso de estudio
# Modelos No Paramétricos y de Regresión · ¿Cómo se fija la tasa de una hipoteca?
#
# Datos: Freddie Mac Single-Family Loan-Level Dataset, archivo de muestra 2024
# (50,000 hipotecas originadas en 2024). Los datos NO se incluyen en el repositorio:
# los términos de Freddie Mac permiten publicar resultados, pero no los datos.
# Descárgalos (registro gratuito) y define la variable de entorno FREDDIE_DIR con la
# carpeta que contiene sample_orig_2024.txt (por defecto: ~/Downloads/freddie).
#
# Regla de este repositorio: ningún capítulo imprime registros individuales; solo
# resúmenes, modelos y gráficas agregadas.
################################################################################

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(ggplot2)
})
theme_set(theme_minimal(base_size = 12))
AZUL <- "#1a73e8"; ROJO <- "#d93025"; GRIS <- "#80868b"

# Nombres de las 31 columnas del archivo de originación, en orden (layout de Freddie Mac)
COLUMNAS <- c("fico", "first_payment", "ftb", "maturity", "msa", "mi", "units", "occ", "cltv",
              "dti", "upb", "ltv", "rate", "channel", "ppm", "amortization", "state", "ptype",
              "zip3", "loan_id", "purpose", "term", "nb", "seller", "super_conforming",
              "pre_harp", "program", "harp", "valuation", "io", "vantage")

archivo_2024 <- function(carpeta = Sys.getenv("FREDDIE_DIR", "~/Downloads/freddie")) {
  carpeta <- path.expand(carpeta)
  f <- list.files(carpeta, pattern = "^sample_orig_2024\\.txt$", recursive = TRUE, full.names = TRUE)
  if (length(f) == 0) stop("No encuentro sample_orig_2024.txt en ", carpeta, ". Ver README.")
  f[1]
}

# Hipotecas a 30 años con primer pago entre marzo de 2024 y febrero de 2025 (12 meses completos)
leer_hipotecas <- function(carpeta = Sys.getenv("FREDDIE_DIR", "~/Downloads/freddie")) {
  read_delim(archivo_2024(carpeta), delim = "|", col_names = COLUMNAS,
             col_types = cols(.default = "c"), progress = FALSE) |>
    transmute(
      tasa = as.numeric(rate),
      fico = na_if(as.integer(fico), 9999L),
      ltv = na_if(as.numeric(ltv), 999),
      cltv = na_if(as.numeric(cltv), 999),
      dti = na_if(as.numeric(dti), 999),
      monto = as.numeric(upb),
      plazo = as.integer(term),
      mes = first_payment,
      canal = factor(channel, c("R", "B", "C"), c("Banco directo", "Bróker", "Corresponsal")),
      proposito = factor(purpose, c("P", "N", "C"), c("Compra", "Refinanciamiento", "Refinanciamiento con retiro")),
      ocupacion = factor(occ, c("P", "S", "I"), c("Vivienda propia", "Segunda vivienda", "Inversión")),
      primer_comprador = ftb == "Y",
      seguro_hipotecario = as.numeric(mi) > 0,
      acreditados = as.integer(nb),
      unidades = as.integer(units)
    ) |>
    filter(plazo == 360, mes >= "202403", mes <= "202502") |>
    tidyr::drop_na(tasa, fico, ltv, dti, canal, proposito, ocupacion) |>
    mutate(mes = factor(mes))
}

# Bandas de FICO y LTV como las de las tablas de precio de la industria
banda_fico <- function(x) cut(x, c(300, 640, 660, 680, 700, 720, 740, 760, 780, 851), right = FALSE,
                              labels = c("<640", "640–659", "660–679", "680–699", "700–719", "720–739", "740–759", "760–779", "780+"))
banda_ltv <- function(x) cut(x, c(0, 60, 70, 75, 80, 85, 90, 95, 200),
                             labels = c("≤60", "60–70", "70–75", "75–80", "80–85", "85–90", "90–95", ">95"))

# Pago mensual de una hipoteca (tasa anual en %, n pagos mensuales)
pago_mensual <- function(monto, tasa, n = 360) {
  r <- tasa / 100 / 12
  monto * r / (1 - (1 + r)^(-n))
}

# Efecto en pesos/dólares: cuánto cambia el pago mensual por "pb" puntos base sobre una tasa base
costo_pb <- function(pb, monto = 300000, tasa = 6.6) {
  c(por_mes = pago_mensual(monto, tasa + pb / 100) - pago_mensual(monto, tasa),
    en_30_anios = 360 * (pago_mensual(monto, tasa + pb / 100) - pago_mensual(monto, tasa)))
}
