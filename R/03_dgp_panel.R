# 03_dgp_panel.R: staggered-merger panel, checks on one simulated draw
source(here::here("R", "00_setup.R"))
source(here::here("R", "functions.R"))   # simulate_panel() lives there
set.seed(seed)

# Prediction (written before running)
# True ATT = mean of tau over treated market-periods. A market of cohort g is
# treated for (n_periods - g + 1) periods, so each cohort is weighted by
# share * exposure:
#   ATT = sum(p_g * (T - g + 1) * tau_g) / sum(p_g * (T - g + 1))
# With the setup values: (3*0.2*15 + 2*0.2*11 + 1*0.2*7) / (0.2*(15+11+7)) = 14.8 / 6.6, about 2.24

panel <- simulate_panel(n_markets, n_periods, cohorts, cohort_p, tau_g,
                        sigma_alpha, sigma_u, rho_u, trend)

# Checks
count(distinct(panel, market, cohort), cohort)       # cohort sizes
nrow(filter(panel, treated, period < cohort))         # must be 0
anyNA(panel$y)                                        # must be FALSE
panel |>                                              # should be near rho_u
  group_by(market) |> mutate(u_lag = lag(u)) |> ungroup() |>
  summarise(cor_u = cor(u, u_lag, use = "complete.obs"))
panel |> filter(treated) |> summarise(att = mean(tau))   # compare to the prediction
