// ============================================================
// Environmental Covariates Processing
// ============================================================

///|
/// Environmental time series record.
pub(all) struct EnvSeries {
  years : Array[Int]
  values : Array[Double]
  name : String
} derive(Eq)

///|
pub fn EnvSeries::new(
  years : Array[Int],
  values : Array[Double],
  name : String,
) -> EnvSeries raise @types.ErrorType {
  @types.validate_same_length(years, values, "years", "values")
  { years, values, name }
}

///|
/// Compute standardized environmental anomaly: (x_t - mean) / std_dev.
pub fn compute_anomalies(
  series : EnvSeries,
) -> Array[Double] raise @types.ErrorType {
  let n = series.values.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData("Empty environmental series")
  }
  let m = @math.mean(series.values)
  let sd = @math.std_dev(series.values)
  let sd_safe = if sd == 0.0 { 1.0 } else { sd }
  let anomalies : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    anomalies.push((series.values[i] - m) / sd_safe)
  }
  anomalies
}

///|
/// Compute 3-year running mean of environmental index.
pub fn moving_average_env(
  series : EnvSeries,
  window : Int,
) -> Array[Double] raise @types.ErrorType {
  let n = series.values.length()
  if window <= 0 || window > n {
    raise @types.ErrorType::InvalidParameter("Invalid moving average window")
  }
  let result : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    let start = if i - window + 1 < 0 { 0 } else { i - window + 1 }
    let mut sum = 0.0
    let mut count = 0
    for k = start; k <= i; k = k + 1 {
      sum = sum + series.values[k]
      count = count + 1
    }
    result.push(sum / count.to_double())
  }
  result
}

///|
/// Compute cross-correlation between environmental series and CPUE at specified lag.
pub fn cross_correlation_lag(
  env : EnvSeries,
  cpue : Array[Double],
  lag : Int,
) -> Double raise @types.ErrorType {
  let n_env = env.values.length()
  let n_cpue = cpue.length()
  let n = @math.min_double(n_env.to_double(), n_cpue.to_double()).to_int()
  if n < 5 {
    raise @types.ErrorType::InsufficientData(
      "Insufficient data length for cross-correlation",
    )
  }
  let env_sub : Array[Double] = []
  let cpue_sub : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    let env_idx = i - lag
    if env_idx >= 0 && env_idx < n_env {
      env_sub.push(env.values[env_idx])
      cpue_sub.push(cpue[i])
    }
  }
  if env_sub.length() < 3 {
    return 0.0
  }
  let m_env = @math.mean(env_sub)
  let m_cpue = @math.mean(cpue_sub)
  let mut cov = 0.0
  let mut v_env = 0.0
  let mut v_cpue = 0.0
  let k_len = env_sub.length()
  for i = 0; i < k_len; i = i + 1 {
    let de = env_sub[i] - m_env
    let dc = cpue_sub[i] - m_cpue
    cov = cov + de * dc
    v_env = v_env + de * de
    v_cpue = v_cpue + dc * dc
  }
  let denom = @math.sqrt_approx(v_env * v_cpue)
  if denom == 0.0 {
    0.0
  } else {
    cov / denom
  }
}
