# 07_animation.R: how the Monte Carlo error distribution builds up, replication by replication.
# Reads the simulation output, simulates nothing.
# Needs: install.packages(c("gganimate", "gifski"))
source(here::here("R", "00_setup.R"))
library(gganimate)

draws <- readRDS(here("output", "tables", "sim_draws.rds"))

ref_n   <- max(grid_n_markets)
ref_rho <- rho_u

# Reference scenario: heterogeneous effects, TWFE (clustered) against Callaway-Sant'Anna
ref <- draws |>
  filter(effects == "heterogeneous", n_markets == ref_n, rho_u == ref_rho,
         estimator %in% c("twfe_cluster", "cs"), !is.na(est)) |>
  mutate(err = est - truth)

# One frame per k: the errors of the first k replications only
ks <- seq(20, n_reps_grid, by = 10)
frames <- map(ks, \(k) filter(ref, rep <= k) |> mutate(frame = k)) |>
  list_rbind()

# Running bias at each frame (the black line)
running_bias <- frames |>
  group_by(frame, estimator) |>
  summarise(bias = mean(err), .groups = "drop")

p <- ggplot(frames, aes(x = err, fill = estimator)) +
  geom_histogram(aes(y = after_stat(density)), binwidth = 0.04, alpha = 0.6) +
  geom_vline(xintercept = 0, linetype = "dashed") +                   # the truth
  geom_vline(data = running_bias, aes(xintercept = bias)) +           # running mean
  facet_wrap(~ estimator) +
  coord_cartesian(xlim = c(-0.9, 0.9)) +
  labs(x = "Estimate minus true ATT", y = "Density",
       title = "Replications so far: {current_frame}",
       subtitle = paste0("Heterogeneous effects, n_markets = ", ref_n,
                         ", rho_u = ", ref_rho,
                         ". Dashed: truth. Black: running mean error. Simulated data, illustration only.")) +
  theme_minimal() +
  theme(legend.position = "none") +
  transition_manual(frame)

anim <- animate(p, nframes = length(ks), fps = 8, width = 900, height = 450,
                renderer = gifski_renderer())
anim_save(here("output", "figures", "accumulation.gif"), animation = anim)
