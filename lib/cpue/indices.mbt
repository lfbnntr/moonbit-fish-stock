/// CPUE abundance indices and trend analysis for fishery stock assessment.

///|
/// Compute an abundance index from CPUE and a catchability coefficient q.
/// Abundance = CPUE / q, where q is the proportion of stock captured per unit effort.
pub fn compute_abundance_index(
  cpue_values : Array[Double],
  calibration_q : Double,
) -> Array[@types.AbundanceIndex] raise @types.ErrorType {
  if cpue_values.length() == 0 {
    raise @types.ErrorType::InsufficientData("Empty CPUE array")
  }
  if calibration_q <= 0.0 || calibration_q > 1.0 {
    raise @types.ErrorType::InvalidParameter(
      "Catchability coefficient q must be in (0, 1]",
    )
  }
  let n = cpue_values.length()
  let result : Array[@types.AbundanceIndex] = []
  let m = @math.mean(cpue_values)
  let mut sum_sq = 0.0
  for i = 0; i < n; i = i + 1 {
    let d = cpue_values[i] - m
    sum_sq = sum_sq + d * d
  }
  let se = if n > 1 {
    @math.sqrt_approx(sum_sq / (n.to_double() - 1.0)) /
    @math.sqrt_approx(n.to_double())
  } else {
    0.0
  }
  let se_abundance = se / calibration_q
  for i = 0; i < n; i = i + 1 {
    let abundance = cpue_values[i] / calibration_q
    let idx : @types.AbundanceIndex = {
      year: i,
      cpue: cpue_values[i],
      abundance,
      lower_ci: abundance - 1.96 * se_abundance,
      upper_ci: abundance + 1.96 * se_abundance,
    }
    result.push(idx)
  }
  result
}

///|
/// Compare nominal (raw) vs standardized CPUE series.
/// Returns a comparison struct with correlation and mean bias.
pub fn nominal_vs_standardized(
  nominal : Array[Double],
  standardized : Array[Double],
) -> @types.CpueComparison raise @types.ErrorType {
  let n = nominal.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData("Empty arrays")
  }
  if n != standardized.length() {
    raise @types.ErrorType::InvalidParameter(
      "Nominal and standardized arrays must have the same length",
    )
  }
  let mean_n = @math.mean(nominal)
  let mean_s = @math.mean(standardized)
  let mut cov = 0.0
  let mut var_n = 0.0
  let mut var_s = 0.0
  for i = 0; i < n; i = i + 1 {
    let dn = nominal[i] - mean_n
    let ds = standardized[i] - mean_s
    cov = cov + dn * ds
    var_n = var_n + dn * dn
    var_s = var_s + ds * ds
  }
  let denom = @math.sqrt_approx(var_n * var_s)
  let correlation = if denom > 0.0 { cov / denom } else { 0.0 }
  let mut bias_sum = 0.0
  for i = 0; i < n; i = i + 1 {
    bias_sum = bias_sum + (nominal[i] - standardized[i])
  }
  let bias = bias_sum / n.to_double()
  { nominal, standardized, correlation, bias }
}

///|
/// Analyze the trend in a CPUE series.
/// Fits a linear regression (y = intercept + slope * t) and returns trend statistics.
pub fn cpue_trend_analysis(
  series : Array[Double],
) -> @types.TrendResult raise @types.ErrorType {
  let n = series.length()
  if n < 2 {
    raise @types.ErrorType::InsufficientData(
      "Need at least 2 data points for trend analysis",
    )
  }
  let t_arr : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    t_arr.push(i.to_double())
  }
  let (slope, intercept, r_squared) = @math.linear_regression(t_arr, series)
  let trend_direction = if slope > 0.001 {
    "increasing"
  } else if slope < -0.001 {
    "decreasing"
  } else {
    "stable"
  }
  { slope, intercept, r_squared, trend_direction }
}

///|
/// Test for hyperstability or hyperdepletion in CPUE.
/// Fits log(CPUE) = a + beta * log(Biomass).
/// beta < 1 indicates hyperstability; beta > 1 indicates hyperdepletion.
pub fn hyperstability_test(
  cpue : Array[Double],
  biomass : Array[Double],
) -> @types.TrendResult raise @types.ErrorType {
  let n = cpue.length()
  if n < 2 {
    raise @types.ErrorType::InsufficientData(
      "Need at least 2 data points for hyperstability test",
    )
  }
  if n != biomass.length() {
    raise @types.ErrorType::InvalidParameter(
      "CPUE and biomass arrays must have the same length",
    )
  }
  let log_cpue : Array[Double] = []
  let log_biomass : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    if cpue[i] <= 0.0 || biomass[i] <= 0.0 {
      raise @types.ErrorType::InvalidParameter(
        "CPUE and biomass must be positive for log transformation",
      )
    }
    log_cpue.push(@math.ln_approx(cpue[i]))
    log_biomass.push(@math.ln_approx(biomass[i]))
  }
  let (slope, intercept, r_squared) = @math.linear_regression(
    log_biomass, log_cpue,
  )
  let trend_direction = if slope < 0.95 {
    "hyperstable"
  } else if slope > 1.05 {
    "hyperdepleted"
  } else {
    "proportional"
  }
  { slope, intercept, r_squared, trend_direction }
}
