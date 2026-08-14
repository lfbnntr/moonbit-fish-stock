// ============================================================
// Fox Exponential Surplus Production Model
// Growth rate: g(B) = r * B * ln(K / B)
// Reference points: MSY = r * K / e, B_MSY = K / e, F_MSY = r
// ============================================================

///|
/// Simulate biomass dynamics using Fox model.
pub fn fox_biomass_dynamics(
  b_init : Double,
  catches : Array[Double],
  params : @types.ModelParams,
) -> Array[Double] raise @types.ErrorType {
  let n_data = catches.length()
  if n_data == 0 {
    raise @types.ErrorType::InsufficientData("Empty catch array for Fox model")
  }
  @types.validate_model_params(params)
  let biomass : Array[Double] = []
  biomass.push(b_init)
  let mut b_current = b_init
  for i = 0; i < n_data; i = i + 1 {
    let ratio = if b_current <= 0.0 { 1.0e-6 } else { params.k / b_current }
    let log_ratio = @math.ln_approx(ratio)
    let growth = params.r * b_current * log_ratio
    let c = catches[i]
    let b_next = b_current + growth - c
    let b_clamped = if b_next < 1.0e-6 { 1.0e-6 } else { b_next }
    biomass.push(b_clamped)
    b_current = b_clamped
  }
  biomass
}

///|
/// Compute Maximum Sustainable Yield (MSY) for Fox model.
/// MSY = r * K / e
pub fn fox_msy(params : @types.ModelParams) -> Double {
  params.r * params.k / @math.e
}

///|
/// Compute B_MSY for Fox model.
/// B_MSY = K / e
pub fn fox_bmsy(params : @types.ModelParams) -> Double {
  params.k / @math.e
}

///|
/// Compute F_MSY for Fox model.
/// F_MSY = r
pub fn fox_fmsy(params : @types.ModelParams) -> Double {
  params.r
}

///|
/// Calculate equilibrium yield for Fox model at effort E.
pub fn fox_equilibrium_yield(
  effort : Double,
  params : @types.ModelParams,
) -> Double {
  let f = params.q * effort
  if f >= params.r {
    0.0
  } else {
    let b_eq = params.k * @math.exp_approx(-f / params.r)
    f * b_eq
  }
}

///|
/// Fit Fox model to a StockSeries.
pub fn fit_fox(
  series : @types.StockSeries,
  r_grid : Array[Double],
  k_grid : Array[Double],
  q_grid : Array[Double],
) -> @types.ModelResult raise @types.ErrorType {
  @types.validate_stock_series(series)
  let observed_cpue = series.cpue_data
  let catches = series.catch_data
  let n_len = series.years.length()

  let mut best_sse = 1.0e308
  let mut best_params = @types.ModelParams::fox(0.5, 1000.0, 0.001)
  let mut best_biomass : Array[Double] = []
  let mut best_pred_cpue : Array[Double] = []

  for i = 0; i < r_grid.length(); i = i + 1 {
    let r = r_grid[i]
    for j = 0; j < k_grid.length(); j = j + 1 {
      let k = k_grid[j]
      for m = 0; m < q_grid.length(); m = m + 1 {
        let q = q_grid[m]
        let p = @types.ModelParams::fox(r, k, q)
        let bio = fox_biomass_dynamics(k, catches, p) catch { _ => [] }
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

  let n_params = 3.0
  let n_obs = n_len.to_double()
  let sse_safe = if best_sse < 1.0e-10 { 1.0e-10 } else { best_sse }
  let aic = n_obs * @math.ln_approx(sse_safe / n_obs) + 2.0 * n_params
  let bic = n_obs * @math.ln_approx(sse_safe / n_obs) +
    n_params * @math.ln_approx(n_obs)

  @types.ModelResult::new(
    best_params, best_biomass, best_pred_cpue, residuals, best_sse, aic, bic,
  )
}
