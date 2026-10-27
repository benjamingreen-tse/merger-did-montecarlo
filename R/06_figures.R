# 06_figures.R: figures from the simulation output (reads, never simulates)
source(here::here("R", "00_setup.R"))

draws <- readRDS(here("output", "tables", "sim_draws.rds"))
perf  <- read_csv(here("output", "tables", "performance.csv"), show_col_types = FALSE)

ref_n   <- max(grid_n_markets)   # reference scenario for the distribution plot
ref_rho <- rho_u

# Figure 1: distribution of the error (estimate minus the truth of that panel)
fig_err <- draws |>
  filter(n_markets == ref_n, rho_u == ref_rho, effects != "null",
         estimator %in% c("twfe_cluster", "cs"), !is.na(est)) |>
  ggplot(aes(x = est - truth, fill = estimator)) +
  geom_density(alpha = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  facet_wrap(~ effects) +
  labs(x = "Estimate minus true ATT", y = "Density", fill = NULL,
       title = "Sampling distribution of the error",
       subtitle = paste0("n_markets = ", ref_n, ", rho_u = ", ref_rho,
                         ". Simulated data, illustration only.")) +
  theme_minimal()

# Figure 2: bias with its Monte Carlo interval
fig_bias <- perf |>
  filter(estimator != "twfe_iid") |>
  ggplot(aes(x = estimator, y = bias, colour = estimator)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_pointrange(aes(ymin = bias - z_crit * mcse_bias,
                      ymax = bias + z_crit * mcse_bias)) +
  facet_grid(rows = vars(effects), cols = vars(n_markets, rho_u),
             labeller = label_both) +
  labs(x = NULL, y = "Bias (bars: +/- 1.96 Monte Carlo errors)",
       title = "Bias by scenario. Simulated data, illustration only.") +
  theme_minimal() +
  theme(legend.position = "none")

# Figure 3: coverage of the 95% interval, against the nominal level
fig_cov <- perf |>
  ggplot(aes(x = estimator, y = coverage, colour = estimator)) +
  geom_hline(yintercept = 0.95, linetype = "dashed") +
  geom_pointrange(aes(ymin = coverage - z_crit * mcse_cov,
                      ymax = coverage + z_crit * mcse_cov)) +
  facet_grid(rows = vars(effects), cols = vars(n_markets, rho_u),
             labeller = label_both) +
  coord_cartesian(ylim = c(0, 1)) +
  labs(x = NULL, y = "Coverage (bars: +/- 1.96 Monte Carlo errors)",
       title = "Coverage of the 95% interval. Simulated data, illustration only.") +
  theme_minimal() +
  theme(legend.position = "none", axis.text.x = element_text(angle = 30, hjust = 1))

ggsave(here("output", "figures", "error_distribution.png"), fig_err,  width = 8, height = 4.5, dpi = 150)
ggsave(here("output", "figures", "bias.png"),               fig_bias, width = 9, height = 6,   dpi = 150)
ggsave(here("output", "figures", "coverage.png"),           fig_cov,  width = 9, height = 6,   dpi = 150)
