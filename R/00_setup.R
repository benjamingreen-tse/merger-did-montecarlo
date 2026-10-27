# 00_setup.R: packages and parameters, all in one place. Simulates nothing.
# Every script calls set.seed(seed) itself, right after source()-ing this file.

library(tidyverse)
library(here)
library(fixest)
library(did)

seed <- 123

# --- Step 1: toy OLS ---------------------------------------------------------
n_obs  <- 1000    # sample size
n_reps <- 10000   # Monte Carlo replications
beta0  <- 1       # true intercept
beta1  <- 2       # true slope (the estimand)
sigma  <- 1       # sd of the error

# --- Step 1b: omitted variable -----------------------------------------------
gamma <- 1.5      # effect of the omitted variable z on y
rho   <- 0.5      # corr(x, z)

# --- Step 2: staggered-merger panel (DGP) --------------------------------------
n_markets   <- 100
n_periods   <- 20
cohorts     <- c(6, 10, 14)      # merger dates (period)
cohort_p    <- c(0.2, 0.2, 0.2)  # shares; the remaining 40% are never treated
tau_g       <- c(3, 2, 1)        # true effect by cohort
sigma_alpha <- 1                 # sd of market fixed effects
sigma_u     <- 1                 # sd of the AR(1) error (of the process, not the innovation)
rho_u       <- 0.5               # AR(1) persistence of the error
trend       <- 0.1               # slope of the common time trend (lambda_t = trend * t)

# --- Step 4: simulation grid ---------------------------------------------------
# Three effect scenarios: heterogeneous (the default above), homogeneous (same ATT
# whatever the cohort weights) and null (no effect: the rejection rate is the size).
tau_scenarios  <- list(
  heterogeneous = tau_g,
  homogeneous   = c(2, 2, 2),
  null          = c(0, 0, 0)
)
grid_n_markets <- c(50, 100)   # panel size
grid_rho_u     <- c(0, 0.5)    # error persistence: 0 = independent errors
n_reps_grid    <- 500          # replications per scenario (test with 20 first)
z_crit         <- 1.96         # normal critical value for 95% intervals and tests
