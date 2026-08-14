// ============================================================
// Climate-Linked Surplus Production Models
// ============================================================

///|
/// Climate-linked surplus production model parameters.
pub(all) struct ClimateModelParams {
  r0 : Double // base growth rate
  k0 : Double // base carrying capacity
  q : Double // catchability
  gamma : Double // environmental response coefficient
} derive(Eq)

///|
pub fn ClimateModelParams::new(
  r0 : Double,
  k0 : Double,
  q : Double,
  gamma : Double,
) -> ClimateModelParams {
  { r0, k0, q, gamma }
}

///|
/// Simulate biomass dynamics under climate-varying carrying capacity K(t) = K0 * exp(gamma * E_t).
pub fn climate_schaefer_biomass(
  b_init : Double,
  catches : Array[Double],
  env_anomalies : Array[Double],
  params : ClimateModelParams,
) -> Array[Double] raise @types.ErrorType {
  let n = catches.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData("Empty catch array")
  }
  @types.validate_same_length(
    catches, env_anomalies, "catches", "env_anomalies",
  )
  let biomass : Array[Double] = []
  biomass.push(b_init)
  let mut b_current = b_init
  for t = 0; t < n; t = t + 1 {
    let env_factor = @math.exp_approx(params.gamma * env_anomalies[t])
    let k_t = params.k0 * env_factor
    let k_safe = if k_t < 1.0 { 1.0 } else { k_t }
    let growth = params.r0 * b_current * (1.0 - b_current / k_safe)
    let c = catches[t]
    let b_next = b_current + growth - c
    let b_clamped = if b_next < 1.0e-6 { 1.0e-6 } else { b_next }
    biomass.push(b_clamped)
    b_current = b_clamped
  }
  biomass
}

///|
/// Compute dynamic MSY(t) under climate forcing.
/// MSY(t) = r0 * K(t) / 4
pub fn climate_dynamic_msy(
  env_anomaly : Double,
  params : ClimateModelParams,
) -> Double {
  let k_t = params.k0 * @math.exp_approx(params.gamma * env_anomaly)
  params.r0 * k_t / 4.0
}
