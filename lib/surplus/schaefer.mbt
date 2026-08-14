// ============================================================
// Schaefer Surplus Production Model
// Dynamics: B_{t+1} = B_t + r * B_t * (1 - B_t / K) - C_t
// Reference points: MSY = rK/4, B_msy = K/2, F_msy = r/2, E_msy = r/(2q)
// ============================================================

///|
/// Simulate biomass dynamics over time given initial biomass, catches, and parameters.
pub fn schaefer_biomass_dynamics(
  b_init : Double,
  catches : Array[Double],
  params : @types.ModelParams,
) -> Array[Double] raise @types.ErrorType {
  let n = catches.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData(
      "Empty catch array for biomass simulation",
    )
  }
  @types.validate_model_params(params)
  let biomass : Array[Double] = []
  biomass.push(b_init)
  let mut b_current = b_init
  for i = 0; i < n; i = i + 1 {
    let growth = params.r * b_current * (1.0 - b_current / params.k)
    let c = catches[i]
    let b_next = b_current + growth - c
    let b_clamped = if b_next < 1.0e-6 { 1.0e-6 } else { b_next }
    biomass.push(b_clamped)
    b_current = b_clamped
  }
  biomass
}

///|
/// Compute predicted CPUE values: CPUE_pred_t = q * B_t.
pub fn schaefer_predicted_cpue(
  biomass : Array[Double],
  q : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  let n = biomass.length()
  for i = 0; i < n; i = i + 1 {
    result.push(q * biomass[i])
  }
  result
}

///|
/// Calculate equilibrium yield for a given effort E.
/// Yield_eq = q * E * K * (1 - q * E / r)
pub fn schaefer_equilibrium_yield(
  effort : Double,
  params : @types.ModelParams,
) -> Double {
  let f = params.q * effort
  if f >= params.r {
    0.0
  } else {
    f * params.k * (1.0 - f / params.r)
  }
}

///|
/// Compute Sum of Squared Errors (SSE) between observed and predicted CPUE.
pub fn schaefer_sse(
  observed : Array[Double],
  predicted : Array[Double],
) -> Double raise @types.ErrorType {
  @types.validate_same_length(observed, predicted, "observed", "predicted")
  let n = observed.length()
  let mut sse = 0.0
  for i = 0; i < n; i = i + 1 {
    let diff = observed[i] - predicted[i]
    sse = sse + diff * diff
  }
  sse
}

///|
/// Compute Maximum Sustainable Yield (MSY) for Schaefer model.
pub fn schaefer_msy(params : @types.ModelParams) -> Double {
  params.r * params.k / 4.0
}

///|
/// Compute B_MSY for Schaefer model.
pub fn schaefer_bmsy(params : @types.ModelParams) -> Double {
  params.k / 2.0
}

///|
/// Compute F_MSY for Schaefer model.
pub fn schaefer_fmsy(params : @types.ModelParams) -> Double {
  params.r / 2.0
}

///|
/// Compute Effort at MSY (E_MSY).
pub fn schaefer_emsy(params : @types.ModelParams) -> Double {
  if params.q > 0.0 {
    params.r / (2.0 * params.q)
  } else {
    0.0
  }
}

///|
/// Compute Maximum Economic Yield (MEY) considering cost per unit effort c and price per unit catch p.
/// MEY occurs where marginal revenue equals marginal cost.
pub fn schaefer_mey(
  params : @types.ModelParams,
  price_per_unit_catch : Double,
  cost_per_unit_effort : Double,
) -> Double {
  if price_per_unit_catch <= 0.0 || params.q <= 0.0 {
    return 0.0
  }
  let e_mey = params.r /
    (2.0 * params.q) *
    (1.0 - cost_per_unit_effort / (price_per_unit_catch * params.q * params.k))
  let e_clamped = if e_mey < 0.0 { 0.0 } else { e_mey }
  schaefer_equilibrium_yield(e_clamped, params)
}

///|
/// Fit Schaefer model to a StockSeries using grid search parameter estimation.
pub fn fit_schaefer(
  series : @types.StockSeries,
  r_grid : Array[Double],
  k_grid : Array[Double],
  q_grid : Array[Double],
) -> @types.ModelResult raise @types.ErrorType {
  @types.validate_stock_series(series)
  let observed_cpue = series.cpue_data
  let catches = series.catch_data
  let n = series.years.length()

  let mut best_sse = 1.0e308
  let mut best_params = @types.ModelParams::schaefer(0.5, 1000.0, 0.001)
  let mut best_biomass : Array[Double] = []
  let mut best_pred_cpue : Array[Double] = []

  for i = 0; i < r_grid.length(); i = i + 1 {
    let r = r_grid[i]
    for j = 0; j < k_grid.length(); j = j + 1 {
      let k = k_grid[j]
      for m = 0; m < q_grid.length(); m = m + 1 {
        let q = q_grid[m]
        let p = @types.ModelParams::schaefer(r, k, q)
        let bio = schaefer_biomass_dynamics(k, catches, p) catch { _ => [] }
        if bio.length() == n + 1 {
          let pred = schaefer_predicted_cpue(bio, q)
          // Trim pred to length n
          let pred_trimmed : Array[Double] = []
          for idx = 0; idx < n; idx = idx + 1 {
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
  for idx = 0; idx < n; idx = idx + 1 {
    if idx < best_pred_cpue.length() {
      residuals.push(observed_cpue[idx] - best_pred_cpue[idx])
    } else {
      residuals.push(0.0)
    }
  }

  let n_params = 3.0
  let n_obs = n.to_double()
  let sse_safe = if best_sse < 1.0e-10 { 1.0e-10 } else { best_sse }
  let aic = n_obs * @math.ln_approx(sse_safe / n_obs) + 2.0 * n_params
  let bic = n_obs * @math.ln_approx(sse_safe / n_obs) +
    n_params * @math.ln_approx(n_obs)

  @types.ModelResult::new(
    best_params, best_biomass, best_pred_cpue, residuals, best_sse, aic, bic,
  )
}
