// ============================================================
// Virtual Population Analysis (VPA) / Catch-at-Age Cohort Analysis
// ============================================================

///|
/// VPA Cohort Analysis result structure.
pub(all) struct VPAResult {
  num_ages : Int
  num_years : Int
  population_matrix : Array[Array[Double]] // N[age][year]
  fishing_mortality : Array[Array[Double]] // F[age][year]
  spawning_biomass : Array[Double] // SSB[year]
} derive(Eq)

///|
pub fn VPAResult::new(
  num_ages : Int,
  num_years : Int,
  population_matrix : Array[Array[Double]],
  fishing_mortality : Array[Array[Double]],
  spawning_biomass : Array[Double],
) -> VPAResult {
  {
    num_ages,
    num_years,
    population_matrix,
    fishing_mortality,
    spawning_biomass,
  }
}

///|
/// Baranov Catch Equation solver using Newton's iteration.
/// Given C, N, M, find F such that C = (F / (F + M)) * N * (1 - exp(-(F + M))).
pub fn solve_baranov_f(
  catch_val : Double,
  n_val : Double,
  m_val : Double,
) -> Double {
  if catch_val <= 0.0 || n_val <= 0.0 {
    return 0.0
  }
  let mut f_guess = catch_val / n_val
  for _iter = 0; _iter < 15; _iter = _iter + 1 {
    let z = f_guess + m_val
    let exp_neg_z = @math.exp_approx(-z)
    let pred_c = f_guess / z * n_val * (1.0 - exp_neg_z)
    let diff = pred_c - catch_val
    if @math.abs_double(diff) < 1.0e-6 {
      break
    }
    // Derivative dC/dF approximation
    let deriv = n_val / z * (1.0 - exp_neg_z) -
      f_guess * n_val / (z * z) * (1.0 - exp_neg_z) +
      f_guess * n_val / z * exp_neg_z
    let deriv_safe = if @math.abs_double(deriv) < 1.0e-8 {
      1.0e-8
    } else {
      deriv
    }
    f_guess = f_guess - diff / deriv_safe
    if f_guess < 0.0 {
      f_guess = 0.001
    }
  }
  f_guess
}

///|
/// Perform Pope's Cohort Analysis (analytical approximation to VPA).
/// N_{a, t} = N_{a+1, t+1} * exp(M) + C_{a, t} * exp(M / 2)
pub fn popes_cohort_analysis(
  catch_matrix : Array[Array[Double]], // catch[age][year]
  terminal_f : Double,
  natural_mortality : Double,
  weight_at_age : Array[Double],
  maturity_at_age : Array[Double],
) -> VPAResult raise @types.ErrorType {
  let num_ages = catch_matrix.length()
  if num_ages == 0 {
    raise @types.ErrorType::InsufficientData("Empty catch matrix")
  }
  let num_years = catch_matrix[0].length()
  let m = natural_mortality
  let exp_m = @math.exp_approx(m)
  let exp_half_m = @math.exp_approx(m / 2.0)

  // Initialize N and F matrices
  let n_matrix : Array[Array[Double]] = []
  let f_matrix : Array[Array[Double]] = []
  for a = 0; a < num_ages; a = a + 1 {
    let row_n : Array[Double] = []
    let row_f : Array[Double] = []
    for y = 0; y < num_years; y = y + 1 {
      row_n.push(0.0)
      row_f.push(0.0)
    }
    n_matrix.push(row_n)
    f_matrix.push(row_f)
  }

  // Set terminal year population for each age
  let last_yr = num_years - 1
  let z_term = terminal_f + m
  for a = 0; a < num_ages; a = a + 1 {
    let c = catch_matrix[a][last_yr]
    if z_term > 0.0 {
      n_matrix[a][last_yr] = c *
        z_term /
        (terminal_f * (1.0 - @math.exp_approx(-z_term)))
    } else {
      n_matrix[a][last_yr] = c
    }
    f_matrix[a][last_yr] = terminal_f
  }

  // Backwards calculation for cohort analysis
  for y = num_years - 2; y >= 0; y = y - 1 {
    for a = num_ages - 2; a >= 0; a = a - 1 {
      let c = catch_matrix[a][y]
      let n_next = n_matrix[a + 1][y + 1]
      let n_curr = n_next * exp_m + c * exp_half_m
      n_matrix[a][y] = n_curr
      let f_est = solve_baranov_f(c, n_curr, m)
      f_matrix[a][y] = f_est
    }
  }

  // Compute Spawning Stock Biomass (SSB) per year
  let ssb : Array[Double] = []
  for y = 0; y < num_years; y = y + 1 {
    let mut year_ssb = 0.0
    for a = 0; a < num_ages; a = a + 1 {
      let w = if a < weight_at_age.length() { weight_at_age[a] } else { 1.0 }
      let mat = if a < maturity_at_age.length() {
        maturity_at_age[a]
      } else {
        1.0
      }
      year_ssb = year_ssb + n_matrix[a][y] * w * mat
    }
    ssb.push(year_ssb)
  }

  VPAResult::new(num_ages, num_years, n_matrix, f_matrix, ssb)
}
