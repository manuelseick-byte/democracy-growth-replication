# Replication and Extension of *Democracy Does Cause Growth*

**Sophia Bagley · Sara Ledesma Robina · Manuel Seick**  
Barcelona School of Economics — Political Economy Final Project, 2026

This repository contains the code and project materials for our replication and extension of Acemoglu, Naidu, Restrepo, and Robinson (2019), *Democracy Does Cause Growth*.

## Project overview

We replicate the eight main-text tables and six figures of the original paper using Stata. The replication covers fixed-effects estimates, system GMM, semiparametric estimators, instrumental-variable specifications based on regional democratization waves, and heterogeneous-effects specifications.

We then extend the analysis in two directions:

1. **Initial-income heterogeneity** — estimating the democracy–growth relationship across five initial-income quintiles; and
2. **Democracy and market reforms** — examining whether the estimated growth effect of democratization varies with market-reform intensity and across the Cold War / post-Cold War periods.

## Repository structure

```text
.
├── README.md
├── CITATION.cff
├── .gitignore
├── code/
│   ├── 00_setup.do
│   ├── replication/
│   └── extensions/
│       ├── 01_market_reforms.R
│       └── 02_income_heterogeneity.do
├── data/
│   └── README.md
├── results/
└── paper/
    └── Bagley_LedesmaRobina_Seick_Democracy_Does_Cause_Growth_Replication.pdf
```

## Replication code

The `code/replication/` folder follows the main tables and figures in the original article:

- `01_summary_statistics.do` — summary statistics
- `02_table2_main_effects.do` — baseline effects of democracy on GDP per capita
- `03_table3_growth_rates.do` — growth-rate specifications
- `04_table4_controls.do` — robustness to additional controls
- `05_table5_semiparametric.do` — semiparametric estimators
- `06_table6_iv.do` — IV estimates using regional democratization waves
- `07_table7_mechanisms.do` — potential mechanisms
- `08_table8_heterogeneity_corrected.do` — heterogeneous-effects specifications and corrections
- `09_figure1.do` to `12_figure6.do` — main figures
- `13_unit_root_tests.do` — supplementary unit-root checks

## Extensions

### Democracy and market reforms

`code/extensions/01_market_reforms.R` studies whether the estimated effect of democracy varies with market-reform intensity. It uses two-way fixed effects with four lags of GDP per capita, democracy–market-reform interactions, Cold War / post-Cold War subsamples, and a marginal-effect figure.

### Initial-income heterogeneity

`code/extensions/02_income_heterogeneity.do` estimates the baseline democracy–growth relationship separately across five initial-income quintiles.

## Replication adjustments

During the replication, we identified implementation issues affecting selected specifications. In particular, the Table 8 code required corrections to the construction/scaling of the schooling interaction and its instrument. Parts of the spatial-lag implementation used in the IV analysis were also adapted for compatibility with newer Stata versions.

These adjustments are documented in the corresponding scripts and in the accompanying project paper.

## Data

The original replication dataset is not redistributed here.

The scripts expect:

```text
data/DDCGdata_final.dta
```

See [`data/README.md`](data/README.md) for source information and instructions.

## Running the code

From the repository root, run:

```stata
do "code/00_setup.do"
```

Then run the desired replication script.

The market-reforms extension can be run separately in R:

```r
source("code/extensions/01_market_reforms.R")
```

Some IV, minimum-distance, and bootstrap routines can take substantially longer than the baseline specifications.

## Reproducibility

This repository contains the code used for the project and is organised as a research archive. The original replication dataset is obtained from the authors' official replication materials and is not redistributed here.

The public folder structure was cleaned for documentation and portfolio use and has not been rerun end-to-end after the organisational changes.

## Software

- **Stata 19** — main replication and income-heterogeneity extension
- **R 4.5.2** — market-reforms extension

The R extension principally uses `haven`, `plm`, `lmtest`, `sandwich`, `tidyverse`, and `ggplot2`.

## Paper

The accompanying final paper is available in [`paper/`](paper/).

## Citation and attribution

This is a student replication and extension project by Sophia Bagley, Sara Ledesma Robina, and Manuel Seick.

The underlying study, data, and substantial parts of the replication design originate from:

> Acemoglu, D., Naidu, S., Restrepo, P., & Robinson, J. A. (2019). *Democracy Does Cause Growth*. Journal of Political Economy, 127(1).

Please cite the original article and its official replication materials when using those components.

No open-source license is asserted for third-party material adapted from the original replication package.
