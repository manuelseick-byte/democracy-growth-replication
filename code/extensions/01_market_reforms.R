# ============================================================
# EXTENSION: Democracy × Market Reforms
# Does the growth effect of democracy depend on market reforms?
# Paper: Acemoglu et al. (2019) "Democracy Does Cause Growth"
# ============================================================

# --- 0. PACKAGES --------------------------------------------
# Install if needed:
# install.packages(c("haven","plm","lmtest","sandwich","tidyverse","knitr","kableExtra"))

library(haven)
library(plm)
library(lmtest)
library(sandwich)
library(tidyverse)

# --- 1. LOAD DATA -------------------------------------------
# Expected repository structure:
# data/DDCGdata_final.dta

df <- read_dta("data/DDCGdata_final.dta")

# Quick check
cat("Rows:", nrow(df), " | Cols:", ncol(df), "\n")
cat("Years:", min(df$year, na.rm = TRUE), "-", max(df$year, na.rm = TRUE), "\n")
cat("Countries:", length(unique(df$wbcode2)), "\n")


# --- 2. PREPARE DATA ----------------------------------------

df <- df %>%
  arrange(wbcode2, year) %>%
  group_by(wbcode2) %>%
  mutate(
    # Lags of log GDP per capita (y is already log GDP × 100 in the paper)
    y_l1 = lag(y, 1),
    y_l2 = lag(y, 2),
    y_l3 = lag(y, 3),
    y_l4 = lag(y, 4),

    # Interaction: democracy × market reforms index
    dem_x_mref = dem * marketref,

    # Post-1990 dummy (Cold War cutoff, for robustness)
    post1990 = as.numeric(year >= 1990),
    dem_x_post1990 = dem * post1990
  ) %>%
  ungroup()


# --- 3. HELPER FUNCTIONS ------------------------------------

# Compute clustered standard errors (by country = wbcode2)
clse <- function(model, cluster_var) {
  vcov_cl <- vcovHC(model, type = "HC1", cluster = "group")
  coeftest(model, vcov = vcov_cl)
}

# Compute long-run effect of democracy and effect after 25 years
# Formula from the paper: LR = beta / (1 - sum_of_lag_coefs)
# Effect after T years computed by simulating the impulse response
long_run_effects <- function(model) {
  coefs <- coef(model)

  # Get democracy coefficient
  beta <- coefs["dem"]

  # Get lag coefficients (however many are in the model)
  lag_names <- names(coefs)[grepl("^y_l", names(coefs))]
  rho <- sum(coefs[lag_names], na.rm = TRUE)

  # Long-run effect
  LR <- beta / (1 - rho)

  # Effect after 25 years: impulse response sum
  # y_t = beta + rho1*y_{t-1} + rho2*y_{t-2} + ...
  # Simulate: set dem=1 at t=1, track impulse
  n_lags <- length(lag_names)
  lag_coefs <- coefs[lag_names]

  impulse <- numeric(30)
  impulse[1] <- beta
  for (t in 2:30) {
    contrib <- 0
    for (k in 1:min(n_lags, t - 1)) {
      contrib <- contrib + lag_coefs[k] * impulse[t - k]
    }
    impulse[t] <- contrib
  }
  eff_25 <- sum(impulse[1:25])

  return(list(LR = LR, eff25 = eff_25, persistence = rho, beta = beta))
}


# --- 4. PANEL DATA OBJECT -----------------------------------
pdf <- pdata.frame(df, index = c("wbcode2", "year"))


# --- 5. MAIN EXTENSION: Democracy × Market Reforms ----------
# Spec mirrors Table 8 of the original paper (4 lags, two-way FE)
# We add: (a) interaction term, (b) marketref as control

cat("\n\n=== ESTIMATING MODELS ===\n")

# Model 1: Baseline (replication, col 3 of Table 2)
m_base <- plm(y ~ dem + y_l1 + y_l2 + y_l3 + y_l4,
              data = pdf, model = "within", effect = "twoways")

# Model 2: Add market reforms as control only
m_mref_ctrl <- plm(y ~ dem + marketref + y_l1 + y_l2 + y_l3 + y_l4,
                   data = pdf, model = "within", effect = "twoways")

# Model 3: Add interaction dem × marketref
m_mref_int <- plm(y ~ dem + dem_x_mref + marketref + y_l1 + y_l2 + y_l3 + y_l4,
                  data = pdf, model = "within", effect = "twoways")

# Model 4: Interaction without marketref as separate control
# (checks robustness)
m_mref_int2 <- plm(y ~ dem + dem_x_mref + y_l1 + y_l2 + y_l3 + y_l4,
                   data = pdf, model = "within", effect = "twoways")

cat("Done.\n")


# --- 6. CLUSTERED STANDARD ERRORS ---------------------------
se_base      <- clse(m_base, "wbcode2")
se_mref_ctrl <- clse(m_mref_ctrl, "wbcode2")
se_mref_int  <- clse(m_mref_int, "wbcode2")
se_mref_int2 <- clse(m_mref_int2, "wbcode2")


# --- 7. LONG-RUN EFFECTS ------------------------------------
lr_base      <- long_run_effects(m_base)
lr_mref_ctrl <- long_run_effects(m_mref_ctrl)
lr_mref_int  <- long_run_effects(m_mref_int)
lr_mref_int2 <- long_run_effects(m_mref_int2)

cat("\n=== LONG-RUN EFFECTS ===\n")
cat(sprintf("Baseline       — Democracy coef: %.3f | LR: %.3f | Eff25: %.3f | Persist: %.3f\n",
            lr_base$beta, lr_base$LR, lr_base$eff25, lr_base$persistence))
cat(sprintf("+ mref control — Democracy coef: %.3f | LR: %.3f | Eff25: %.3f | Persist: %.3f\n",
            lr_mref_ctrl$beta, lr_mref_ctrl$LR, lr_mref_ctrl$eff25, lr_mref_ctrl$persistence))
cat(sprintf("+ interaction  — Democracy coef: %.3f | LR: %.3f | Eff25: %.3f | Persist: %.3f\n",
            lr_mref_int$beta, lr_mref_int$LR, lr_mref_int$eff25, lr_mref_int$persistence))


# --- 8. PRINT RESULTS TABLE ---------------------------------
cat("\n\n=== TABLE: Extension — Democracy × Market Reforms (Within/FE) ===\n")
cat("(Coefficients multiplied by 100 as in original paper)\n\n")

print_row <- function(label, models_se, coef_name) {
  vals <- sapply(models_se, function(m) {
    if (coef_name %in% rownames(m)) {
      sprintf("%.3f (%.3f)", m[coef_name, "Estimate"], m[coef_name, "Std. Error"])
    } else {
      "—"
    }
  })
  cat(sprintf("%-35s %s\n", label, paste(vals, collapse = "   ")))
}

models_se <- list(se_base, se_mref_ctrl, se_mref_int, se_mref_int2)
col_labels <- c("(1) Baseline", "(2) +marketref", "(3) +interaction", "(4) No ctrl")

cat(sprintf("%-35s %s\n", "", paste(col_labels, collapse = "   ")))
cat(strrep("-", 100), "\n")
print_row("Democracy",             models_se, "dem")
print_row("Dem × Market Reforms", models_se, "dem_x_mref")
print_row("Market Reforms",        models_se, "marketref")
cat(strrep("-", 100), "\n")

# Long-run effects
lr_list <- list(lr_base, lr_mref_ctrl, lr_mref_int, lr_mref_int2)
lrs <- sapply(lr_list, function(x) sprintf("%.3f", x$LR))
e25 <- sapply(lr_list, function(x) sprintf("%.3f", x$eff25))
per <- sapply(lr_list, function(x) sprintf("%.3f", x$persistence))
obs <- sapply(list(m_base, m_mref_ctrl, m_mref_int, m_mref_int2), function(m) nobs(m))

cat(sprintf("%-35s %s\n", "Long-run effect of democracy", paste(lrs, collapse = "   ")))
cat(sprintf("%-35s %s\n", "Effect after 25 years",        paste(e25, collapse = "   ")))
cat(sprintf("%-35s %s\n", "Persistence of GDP process",   paste(per, collapse = "   ")))
cat(sprintf("%-35s %s\n", "Observations",                 paste(obs, collapse = "   ")))
cat(strrep("-", 100), "\n")


# --- 9. ROBUSTNESS: COLD WAR SUBSAMPLES ---------------------
# Filter on df (before pdata.frame), not on pdf
cat("\n\n=== ROBUSTNESS: Cold War vs Post-Cold War ===\n")

df_cw  <- df %>% filter(year < 1990)
df_pcw <- df %>% filter(year >= 1990)

pdf_cw  <- pdata.frame(df_cw,  index = c("wbcode2", "year"))
pdf_pcw <- pdata.frame(df_pcw, index = c("wbcode2", "year"))

m_cw <- plm(y ~ dem + y_l1 + y_l2 + y_l3 + y_l4,
            data = pdf_cw, model = "within", effect = "twoways")

m_pcw <- plm(y ~ dem + y_l1 + y_l2 + y_l3 + y_l4,
             data = pdf_pcw, model = "within", effect = "twoways")

se_cw  <- clse(m_cw, "wbcode2")
se_pcw <- clse(m_pcw, "wbcode2")

lr_cw  <- long_run_effects(m_cw)
lr_pcw <- long_run_effects(m_pcw)

cat(sprintf("Cold War (1960-1989):      dem = %.3f (%.3f) | LR = %.3f | Eff25 = %.3f | N = %d\n",
            se_cw["dem", "Estimate"], se_cw["dem", "Std. Error"],
            lr_cw$LR, lr_cw$eff25, nobs(m_cw)))

cat(sprintf("Post-Cold War (1990-2010): dem = %.3f (%.3f) | LR = %.3f | Eff25 = %.3f | N = %d\n",
            se_pcw["dem", "Estimate"], se_pcw["dem", "Std. Error"],
            lr_pcw$LR, lr_pcw$eff25, nobs(m_pcw)))


# --- 10. FIGURE: Marginal Effect of Democracy by Market Reform Level ---
cat("\n\n=== GENERATING FIGURE ===\n")

beta_dem <- coef(m_mref_int)["dem"]
beta_int <- coef(m_mref_int)["dem_x_mref"]
vcov_m   <- vcovHC(m_mref_int, type = "HC1", cluster = "group")

mref_range <- seq(0, 100, by = 1)
me <- beta_dem + beta_int * mref_range

se_me <- sqrt(
  vcov_m["dem", "dem"] +
    mref_range^2 * vcov_m["dem_x_mref", "dem_x_mref"] +
    2 * mref_range * vcov_m["dem", "dem_x_mref"]
)

fig_df <- data.frame(
  marketref = mref_range,
  me        = me,
  ci_lo     = me - 1.96 * se_me,
  ci_hi     = me + 1.96 * se_me
)

mref_hist <- df %>%
  filter(!is.na(marketref)) %>%
  pull(marketref)

p <- ggplot(fig_df, aes(x = marketref, y = me)) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi),
              alpha = 0.2, fill = "steelblue") +
  geom_line(color = "steelblue", linewidth = 1.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  geom_rug(
    data = data.frame(x = mref_hist),
    aes(x = x),
    inherit.aes = FALSE,
    alpha = 0.15,
    sides = "b"
  ) +
  labs(
    title    = "Marginal Effect of Democracy on Log GDP per Capita",
    subtitle = "By level of Market Reforms Index",
    x        = "Market Reforms Index (0-100)",
    y        = "Marginal Effect of Democracy\n(log GDP per capita x 100)",
    caption  = "Shaded area: 95% confidence interval. Rug: distribution of market reform values."
  ) +
  theme_bw(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

# Ensure output directory exists
dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)

ggsave(
  "results/figures/extension_figure_marginal_effect.pdf",
  plot = p,
  width = 8,
  height = 5
)

ggsave(
  "results/figures/extension_figure_marginal_effect.png",
  plot = p,
  width = 8,
  height = 5,
  dpi = 300
)

cat("Figure saved to results/figures/\n")
