// ============================================================
// Pella-Tomlinson Generalized Surplus Production Model
// Dynamics: B_{t+1} = B_t + (r / (n - 1)) * B_t * (1 - (B_t / K)^{n-1}) - C_t
// Reduces to Schaefer model when n = 2.0.
// ============================================================

///|
/// Simulate biomass dynamics using Pella-Tomlinson model.
pub fn pella_tomlinson_biomass_dynamics(
  b_init : Double,
  catches : Array[Double],
  params : @types.ModelParams,
) -> Array[Double] raise @types.ErrorType {
  let n_data = catches.length()
  if n_data == 0 {
    raise @types.ErrorType::InsufficientData("Empty catch array")
  }
  @types.validate_model_params(params)
  let shape_n = params.n
  if shape_n <= 1.0 {
    raise @types.ErrorType::InvalidParameter(
      "Pella-Tomlinson shape parameter n must be > 1.0",
    )
  }
  let biomass : Array[Double] = []
  biomass.push(b_init)
  let mut b_current = b_init
  for i = 0; i < n_data; i = i + 1 {
    let ratio = b_current / params.k
    let ratio_pow = @math.pow_double(ratio, shape_n - 1.0)
    let growth = params.r / (shape_n - 1.0) * b_current * (1.0 - ratio_pow)
    let c = catches[i]
    let b_next = b_current + growth - c
    let b_clamped = if b_next < 1.0e-6 { 1.0e-6 } else { b_next }
    biomass.push(b_clamped)
    b_current = b_clamped
  }
  biomass
}

///|
/// Compute Maximum Sustainable Yield (MSY) for Pella-Tomlinson model.
/// MSY = r * K / (n^{n / (n - 1)})
pub fn pella_tomlinson_msy(params : @types.ModelParams) -> Double {
  let n = params.n
  if n <= 1.0 {
    return params.r * params.k / 4.0
  }
  let exponent = n / (n - 1.0)
  let denom = @math.pow_double(n, exponent)
  params.r * params.k / denom
}

///|
/// Compute B_MSY for Pella-Tomlinson model.
/// B_MSY = K * (1 / n)^{1 / (n - 1)}
pub fn pella_tomlinson_bmsy(params : @types.ModelParams) -> Double {
  let n = params.n
  if n <= 1.0 {
    return params.k / 2.0
  }
  let exponent = 1.0 / (n - 1.0)
  params.k * @math.pow_double(1.0 / n, exponent)
}

///|
/// Compute F_MSY for Pella-Tomlinson model.
/// F_MSY = r / n
pub fn pella_tomlinson_fmsy(params : @types.ModelParams) -> Double {
  if params.n > 0.0 {
    params.r / params.n
  } else {
    params.r / 2.0
  }
}

///|
/// Calculate equilibrium yield for Pella-Tomlinson model at effort E.
pub fn pella_tomlinson_equilibrium_yield(
  effort : Double,
  params : @types.ModelParams,
) -> Double {
  let f = params.q * effort
  let n = params.n
  if f >= params.r || n <= 1.0 {
    0.0
  } else {
    let term = 1.0 - f * (n - 1.0) / params.r
    if term <= 0.0 {
      0.0
    } else {
      let b_eq = params.k * @math.pow_double(term, 1.0 / (n - 1.0))
      f * b_eq
    }
  }
}

///|
/// Fit Pella-Tomlinson model to a StockSeries.
pub fn fit_pella_tomlinson(
  series : @types.StockSeries,
  r_grid : Array[Double],
  k_grid : Array[Double],
  q_grid : Array[Double],
  n_shape : Double,
) -> @types.ModelResult raise @types.ErrorType {
  @types.validate_stock_series(series)
  let observed_cpue = series.cpue_data
  let catches = series.catch_data
  let n_len = series.years.length()

  let mut best_sse = 1.0e308
  let mut best_params = @types.ModelParams::pella_tomlinson(
    0.5, 1000.0, 0.001, n_shape,
  )
  let mut best_biomass : Array[Double] = []
  let mut best_pred_cpue : Array[Double] = []

  for i = 0; i < r_grid.length(); i = i + 1 {
    let r = r_grid[i]
    for j = 0; j < k_grid.length(); j = j + 1 {
      let k = k_grid[j]
      for m = 0; m < q_grid.length(); m = m + 1 {
        let q = q_grid[m]
        let p = @types.ModelParams::pella_tomlinson(r, k, q, n_shape)
        let bio = pella_tomlinson_biomass_dynamics(k, catches, p) catch {
          _ => []
        }
        if bio.length() == n_len + 1 {
          let pred = schaefer_predicted_cpue(bio, q)
          let pred_trimmed : Array[Double] = []
          for idx = 0; idx < n_len; idx = idx + 1 {
            pred_trimmed.push(pred[idx])
          }
          let current_sse = schaefer_sse(observed_cpue, pred_trimmed) catch {
            _ => 1.0e308
          }
          if current_sse < best_sse {
            best_sse = current_sse
            best_params = p
            best_biomass = bio
            best_pred_cpue = pred_trimmed
          }
        }
      }
    }
  }

  let residuals : Array[Double] = []
  for idx = 0; idx < n_len; idx = idx + 1 {
    if idx < best_pred_cpue.length() {
      residuals.push(observed_cpue[idx] - best_pred_cpue[idx])
    } else {
      residuals.push(0.0)
    }
  }

  let n_params = 4.0
  let n_obs = n_len.to_double()
  let sse_safe = if best_sse < 1.0e-10 { 1.0e-10 } else { best_sse }
  let aic = n_obs * @math.ln_approx(sse_safe / n_obs) + 2.0 * n_params
  let bic = n_obs * @math.ln_approx(sse_safe / n_obs) +
    n_params * @math.ln_approx(n_obs)

  @types.ModelResult::new(
    best_params, best_biomass, best_pred_cpue, residuals, best_sse, aic, bic,
  )
}
