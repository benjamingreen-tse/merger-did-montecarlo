# 02_toy_omitted.R: omitted variable bias, short vs long regression
source(here::here("R", "00_setup.R"))
set.seed(seed)

# Predictions (written before running)
# - short regression (y ~ x): bias = gamma * cov(x, z) / var(x)
#   = 1.5 * 0.5 / 1 = 0.75, so beta1_hat should centre on about 2.75
# - long regression (y ~ x + z): bias 0, z is controlled for

simulate_one_omitted <- function(n, beta0, beta1, gamma, rho, sigma) {
  x   <- rnorm(n)
  u   <- rnorm(n)
  z   <- rho * x + sqrt(1 - rho^2) * u   # var(z) = 1, cor(x, z) = rho
  eps <- rnorm(n, mean = 0, sd = sigma)
  y   <- beta0 + beta1 * x + gamma * z + eps
  c(short = coef(lm(y ~ x))[["x"]],
    long  = coef(lm(y ~ x + z))[["x"]])
}

estimates <- replicate(
  n_reps,
  simulate_one_omitted(n_obs, beta0, beta1, gamma, rho, sigma)
)
# estimates is a matrix: 2 rows (short, long) x n_reps columns

performance <- function(est, truth) {
  tibble(
    bias      = mean(est) - truth,
    mcse_bias = sd(est) / sqrt(length(est)),
    emp_sd    = sd(est),
    rmse      = sqrt(mean((est - truth)^2))
  )
}

bind_rows(
  short = performance(estimates["short", ], beta1),
  long  = performance(estimates["long", ],  beta1),
  .id = "model"
)
