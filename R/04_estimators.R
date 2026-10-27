# 04_estimators.R: three DiD estimators on one simulated panel
# Each estimator (in functions.R) takes the panel and returns c(est = , se = ).
source(here::here("R", "00_setup.R"))
source(here::here("R", "functions.R"))
set.seed(seed)

# No predictions were written for this script (exploratory project).

# Same panel as 03_dgp_panel.R (same seed, same call)
panel <- simulate_panel(n_markets, n_periods, cohorts, cohort_p, tau_g,
                        sigma_alpha, sigma_u, rho_u, trend)
att_true <- panel |> filter(treated) |> summarise(att = mean(tau)) |> pull(att)

results <- bind_rows(
  twfe_lm    = as_tibble_row(est_twfe_lm(panel)),
  twfe_feols = as_tibble_row(est_twfe_feols(panel)),
  cs         = as_tibble_row(est_cs(panel)),
  .id = "estimator"
) |>
  mutate(truth = att_true, error = est - truth)

results

# Test of understanding: lm and feols must give the same point estimate
all.equal(est_twfe_lm(panel)[["est"]], est_twfe_feols(panel)[["est"]])
