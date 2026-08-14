// ============================================================
// Stock-Recruitment Models (Beverton-Holt, Ricker, Deriso-Schnute)
// ============================================================

///|
/// Stock-recruitment model parameters.
pub(all) struct RecruitmentParams {
  a : Double // density-independent parameter (initial slope)
  b : Double // density-dependent parameter
  steepness : Double // steepness h (0.2 to 1.0)
  r0 : Double // virgin recruitment
  s0 : Double // virgin spawning biomass
} derive(Eq)

///|
pub fn RecruitmentParams::beverton_holt(
  a : Double,
  b : Double,
) -> RecruitmentParams {
  { a, b, steepness: 0.7, r0: 1000.0, s0: 5000.0 }
}

///|
pub fn RecruitmentParams::ricker(a : Double, b : Double) -> RecruitmentParams {
  { a, b, steepness: 0.7, r0: 1000.0, s0: 5000.0 }
}

///|
/// Compute recruitment R from spawning biomass S using Beverton-Holt model.
/// R = (a * S) / (1.0 + b * S)
pub fn beverton_holt_recruitment(
  spawning_biomass : Double,
  params : RecruitmentParams,
) -> Double raise @types.ErrorType {
  if spawning_biomass < 0.0 {
    raise @types.ErrorType::InvalidParameter(
      "Spawning biomass must be non-negative",
    )
  }
  let denom = 1.0 + params.b * spawning_biomass
  if denom <= 0.0 {
    0.0
  } else {
    params.a * spawning_biomass / denom
  }
}

///|
/// Compute recruitment R from spawning biomass S using Beverton-Holt with steepness h.
/// R = (4 * h * R0 * S) / (S0 * (1 - h) + S * (5 * h - 1))
pub fn beverton_holt_steepness(
  spawning_biomass : Double,
  h : Double,
  r0 : Double,
  s0 : Double,
) -> Double raise @types.ErrorType {
  if h < 0.2 || h > 1.0 {
    raise @types.ErrorType::OutOfRange("Steepness h must be in [0.2, 1.0]")
  }
  let num = 4.0 * h * r0 * spawning_biomass
  let denom = s0 * (1.0 - h) + spawning_biomass * (5.0 * h - 1.0)
  if denom <= 0.0 {
    0.0
  } else {
    num / denom
  }
}

///|
/// Compute recruitment R using Ricker model.
/// R = a * S * exp(-b * S)
pub fn ricker_recruitment(
  spawning_biomass : Double,
  params : RecruitmentParams,
) -> Double raise @types.ErrorType {
  if spawning_biomass < 0.0 {
    raise @types.ErrorType::InvalidParameter(
      "Spawning biomass must be non-negative",
    )
  }
  let exponent = -params.b * spawning_biomass
  params.a * spawning_biomass * @math.exp_approx(exponent)
}

///|
/// Compute peak spawning biomass for Ricker model: S_max = 1 / b.
pub fn ricker_peak_spawning_biomass(params : RecruitmentParams) -> Double {
  if params.b > 0.0 {
    1.0 / params.b
  } else {
    0.0
  }
}

///|
/// Compute peak recruitment for Ricker model: R_max = a / (b * e).
pub fn ricker_peak_recruitment(params : RecruitmentParams) -> Double {
  if params.b > 0.0 {
    params.a / (params.b * @math.e)
  } else {
    0.0
  }
}

///|
/// Deriso-Schnute generalized stock-recruitment model.
/// R = a * S * (1 - b * c * S)^{1 / c}
pub fn deriso_schnute_recruitment(
  spawning_biomass : Double,
  a : Double,
  b : Double,
  c : Double,
) -> Double raise @types.ErrorType {
  if spawning_biomass < 0.0 {
    raise @types.ErrorType::InvalidParameter(
      "Spawning biomass must be non-negative",
    )
  }
  let inner = 1.0 - b * c * spawning_biomass
  if inner <= 0.0 {
    0.0
  } else {
    let factor = @math.pow_double(inner, 1.0 / c)
    a * spawning_biomass * factor
  }
}
