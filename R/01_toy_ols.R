# 01_toy_ols.R: bias and variance of OLS, toy Monte Carlo
source(here::here("R", "00_setup.R"))
set.seed(seed)

simulate_one_ols <- function(n, beta0, beta1, sigma) {
  x   <- rnorm(n)
  eps <- rnorm(n, mean = 0, sd = sigma)
  y   <- beta0 + beta1 * x + eps
  coef(lm(y ~ x))[["x"]]
}

estimates <- replicate(n_reps, simulate_one_ols(n_obs, beta0, beta1, sigma))

bias      <- mean(estimates) - beta1
emp_sd    <- sd(estimates)
rmse      <- sqrt(mean((estimates - beta1)^2))
mcse_bias <- emp_sd / sqrt(n_reps)

tibble(bias, mcse_bias, emp_sd, rmse)

