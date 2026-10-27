# functions.R: DGP, estimators and simulation engine.
# Only defines functions: sourcing this file draws no random number and prints
# nothing. Needs the packages loaded by 00_setup.R.

# --- DGP -----------------------------------------------------------------------
# y_it = alpha_i + lambda_t + tau_it + u_it, staggered merger dates, AR(1) errors.
simulate_panel <- function(n_markets, n_periods, cohorts, cohort_p, tau_g,
                           sigma_alpha, sigma_u, rho_u, trend) {
  # one row per market: drawn ONCE, then joined to every period
  markets <- tibble(
    market = 1:n_markets,
    cohort = sample(c(cohorts, NA_real_), n_markets, replace = TRUE,
                    prob = c(cohort_p, 1 - sum(cohort_p))),  # NA = never merged
    alpha  = rnorm(n_markets, mean = 0, sd = sigma_alpha)
  )
  # one row per period: common trend
  periods <- tibble(period = 1:n_periods, lambda = trend * period)

  # u: stationary AR(1) with variance sigma_u^2 (innovation sd = sigma_u*sqrt(1-rho^2)).
  # Rows are ordered market by market, so one column per market, stacked, matches.
  u_all <- as.vector(replicate(
    n_markets,
    as.numeric(arima.sim(model = list(ar = rho_u), n = n_periods,
                         sd = sigma_u * sqrt(1 - rho_u^2)))
  ))

  expand_grid(market = 1:n_markets, period = 1:n_periods) |>
    left_join(markets, by = "market") |>
    left_join(periods, by = "period") |>
    mutate(
      treated = !is.na(cohort) & period >= cohort,
      tau = case_when(
        treated ~ tau_g[match(cohort, cohorts)],
        TRUE    ~ 0
      ),
      u = u_all,
      y = alpha + lambda + tau + u
    ) |>
    select(market, period, cohort, treated, tau, y, u)
}

# --- Estimators: each takes the panel and returns c(est = , se = ) ---------------
# 1. TWFE by hand: treatment dummy plus market and period dummies (classical se)
est_twfe_lm <- function(panel) {
  dat <- mutate(panel, d = as.integer(treated))
  fit <- lm(y ~ d + factor(market) + factor(period), data = dat)
  c(est = coef(fit)[["d"]],
    se  = summary(fit)$coefficients["d", "Std. Error"])
}

# 2. Same TWFE with fixest: fixed effects absorbed. vcov = "iid" gives the
#    classical se, vcov = ~market the se clustered by market.
est_twfe_feols <- function(panel, vcov = ~market) {
  dat <- mutate(panel, d = as.integer(treated))
  fit <- feols(y ~ d | market + period, data = dat, vcov = vcov)
  c(est = coef(fit)[["d"]], se = se(fit)[["d"]])
}

# 3. Callaway and Sant'Anna: ATT(g, t) against never-treated, then aggregated.
#    did codes never-treated as cohort 0 (not NA); done here, not in the DGP.
est_cs <- function(panel) {
  dat <- panel |>
    mutate(g = if_else(is.na(cohort), 0, cohort)) |>
    as.data.frame()
  gt <- att_gt(yname = "y", tname = "period", idname = "market", gname = "g",
               data = dat, control_group = "nevertreated",
               bstrap = FALSE, cband = FALSE)     # analytic se: bootstrap is slow
  agg <- aggte(gt, type = "simple")
  c(est = agg$overall.att, se = agg$overall.se)
}

# --- Engine --------------------------------------------------------------------
# All estimators on one panel. If did fails on a draw, that row is NA (counted).
est_all <- function(panel) {
  est_cs_safe <- function(panel) {
    tryCatch(suppressWarnings(est_cs(panel)),
             error = function(e) c(est = NA_real_, se = NA_real_))
  }
  rows <- list(
    twfe_iid     = est_twfe_feols(panel, vcov = "iid"),
    twfe_cluster = est_twfe_feols(panel, vcov = ~market),
    cs           = est_cs_safe(panel)
  )
  bind_rows(map(rows, as_tibble_row), .id = "estimator")
}

# One replication: simulate a panel, estimate, attach the truth of THAT panel
# (mean of tau over its treated market-periods).
run_one <- function(n_markets, n_periods, cohorts, cohort_p, tau_g,
                    sigma_alpha, sigma_u, rho_u, trend) {
  panel <- simulate_panel(n_markets, n_periods, cohorts, cohort_p, tau_g,
                          sigma_alpha, sigma_u, rho_u, trend)
  est_all(panel) |>
    mutate(truth = mean(panel$tau[panel$treated]))
}

# All replications of all scenarios. `scenarios` has columns scenario, effects,
# n_markets, rho_u and the list-column tau_g.
run_grid <- function(scenarios, n_reps, n_periods, cohorts, cohort_p,
                     sigma_alpha, sigma_u, trend) {
  out <- vector("list", nrow(scenarios))
  for (i in seq_len(nrow(scenarios))) {
    sc <- scenarios[i, ]
    message("scenario ", sc$scenario, " of ", nrow(scenarios), ": ", sc$effects,
            ", n_markets = ", sc$n_markets, ", rho_u = ", sc$rho_u)
    out[[i]] <- map(seq_len(n_reps), \(r) {
      run_one(sc$n_markets, n_periods, cohorts, cohort_p, sc$tau_g[[1]],
              sigma_alpha, sigma_u, sc$rho_u, trend) |>
        mutate(rep = r)
    }) |>
      list_rbind() |>
      mutate(scenario = sc$scenario, effects = sc$effects,
             n_markets = sc$n_markets, rho_u = sc$rho_u)
  }
  list_rbind(out)
}

# Performance measures (Morris, White and Crowther 2019) per scenario and estimator.
# coverage: share of 95% intervals containing the truth (1 - coverage = size of the
# test of the true value). reject_zero: share rejecting ATT = 0 (size when the true
# effect is 0, power otherwise). mcse_*: Monte Carlo error of the measure above.
performance_summary <- function(draws, z = 1.96) {
  draws |>
    mutate(err      = est - truth,
           covered  = abs(err) <= z * se,
           rejects0 = abs(est) > z * se) |>
    group_by(scenario, effects, n_markets, rho_u, estimator) |>
    summarise(
      n_ok        = sum(!is.na(est)),
      n_fail      = sum(is.na(est)),
      bias        = mean(err, na.rm = TRUE),
      mcse_bias   = sd(err, na.rm = TRUE) / sqrt(n_ok),
      emp_sd      = sd(est, na.rm = TRUE),
      mean_se     = mean(se, na.rm = TRUE),
      rmse        = sqrt(mean(err^2, na.rm = TRUE)),
      coverage    = mean(covered, na.rm = TRUE),
      mcse_cov    = sqrt(coverage * (1 - coverage) / n_ok),
      reject_zero = mean(rejects0, na.rm = TRUE),
      .groups = "drop"
    )
}
