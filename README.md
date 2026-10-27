**Simulated data, illustration only.** No result here is a fact about any real merger.

# merger-did-montecarlo: staggered merger retrospectives, TWFE vs robust DiD

Personal R project to learn Monte Carlo simulation. It asks, on simulated market-by-period panels where mergers happen at different dates, how a two-way fixed effects (TWFE) difference-in-differences estimator compares with the Callaway and Sant'Anna (2021) estimator: bias, RMSE, coverage of the 95% interval, size, and the Monte Carlo error of each measure.

This is an exploratory learning project, not a pre-registered study. Two scripts (`02`, `03`) carry a prediction written before running; the main grid does not, because I had no specific expectations.

**Status: in progress.** The note `report/note.qmd` reads every number from the simulation output; none is typed by hand.

## Structure
| File | Content |
|---|---|
| `R/00_setup.R` | packages and all parameters |
| `R/functions.R` | DGP, estimators, simulation engine, performance measures |
| `R/01_toy_ols.R` | toy: bias and variance of OLS |
| `R/02_toy_omitted.R` | toy: omitted variable bias, short vs long regression |
| `R/03_dgp_panel.R` | the staggered-merger panel: checks on one draw |
| `R/04_estimators.R` | TWFE (lm and fixest) and Callaway-Sant'Anna on one panel |
| `R/05_engine.R` | the Monte Carlo grid (slow); writes `output/tables/` |
| `R/06_figures.R` | figures in `output/figures/` |
| `R/07_animation.R` | animated GIF of the error distribution building up (needs `gganimate`, `gifski`) |
| `report/note.qmd` | the note, with limits |

## Reproduce
```r
install.packages(c("tidyverse", "here", "fixest", "did", "gganimate", "gifski"))
```
Open `merger-did-montecarlo.Rproj`, then run the scripts in order. `05_engine.R` is the slow one: check it with `n_reps_grid <- 20` in `00_setup.R` first. Then run `06_figures.R` and `07_animation.R`, and render the note with `quarto render report/note.qmd`. Seeds are fixed, so the results are reproducible.

## Reading
Morris, White and Crowther (2019), *Using simulation studies to evaluate statistical methods*; Kiviet (2012), *Monte Carlo Simulation for Econometricians*; Goodman-Bacon (2021), *Difference-in-differences with variation in treatment timing*; Callaway and Sant'Anna (2021), *Difference-in-differences with multiple time periods*.
