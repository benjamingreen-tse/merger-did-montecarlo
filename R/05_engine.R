# 05_engine.R: the Monte Carlo grid (scenarios x replications x estimators).
# SLOW. First set n_reps_grid <- 20 in 00_setup.R to check that it runs, then
# put 500 back. Same seed, same results.
source(here::here("R", "00_setup.R"))
source(here::here("R", "functions.R"))
set.seed(seed)

# No predictions were written for the grid (exploratory project).

scenarios <- expand_grid(
  effects   = names(tau_scenarios),
  n_markets = grid_n_markets,
  rho_u     = grid_rho_u
) |>
  mutate(scenario = row_number(),
         tau_g    = unname(tau_scenarios[effects]))

t0 <- Sys.time()
draws <- run_grid(scenarios, n_reps_grid, n_periods, cohorts, cohort_p,
                  sigma_alpha, sigma_u, trend)
message("elapsed: ", format(round(Sys.time() - t0, 1)))

perf <- performance_summary(draws, z_crit)

saveRDS(draws, here("output", "tables", "sim_draws.rds"))
write_csv(perf, here("output", "tables", "performance.csv"))

perf
