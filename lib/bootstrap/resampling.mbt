// ============================================================
// Bootstrap Resampling and Uncertainty Analysis
// ============================================================

///|
/// Perform non-parametric residual bootstrap on CPUE observations.
/// Creates B resampled CPUE series by adding randomly resampled residuals to predicted CPUE.
pub fn residual_bootstrap_cpue(
  model_result : @types.ModelResult,
  n_bootstraps : Int,
  prng : @math.PRNG,
) -> Array[Array[Double]] raise @types.ErrorType {
  if n_bootstraps <= 0 {
    raise @types.ErrorType::InvalidParameter("n_bootstraps must be positive")
  }
  let pred = model_result.predicted_cpue
  let res = model_result.residuals
  let n = pred.length()
  if n == 0 || res.length() != n {
    raise @types.ErrorType::InsufficientData(
      "Model result has empty or mismatched series",
    )
  }
  let resampled_series_list : Array[Array[Double]] = []
  for _b = 0; _b < n_bootstraps; _b = _b + 1 {
    let resampled_res = prng.sample_with_replacement(res, n)
    let new_cpue : Array[Double] = []
    for i = 0; i < n; i = i + 1 {
      let val = pred[i] + resampled_res[i]
      let val_safe = if val < 1.0e-6 { 1.0e-6 } else { val }
      new_cpue.push(val_safe)
    }
    resampled_series_list.push(new_cpue)
  }
  resampled_series_list
}

///|
/// Compute summary statistics (mean, median, SE, CIs) for a set of bootstrap samples.
pub fn analyze_bootstrap_samples(
  samples : Array[Double],
  alpha : Double,
) -> @types.BootstrapResult raise @types.ErrorType {
  let n = samples.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData("Empty bootstrap samples array")
  }
  if alpha <= 0.0 || alpha >= 1.0 {
    raise @types.ErrorType::OutOfRange("Alpha must be in (0, 1)")
  }
  let sorted_samples : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    sorted_samples.push(samples[i])
  }
  // Sort samples
  for i = 0; i < n - 1; i = i + 1 {
    for j = 0; j < n - i - 1; j = j + 1 {
      if sorted_samples[j] > sorted_samples[j + 1] {
        let tmp = sorted_samples[j]
        sorted_samples[j] = sorted_samples[j + 1]
        sorted_samples[j + 1] = tmp
      }
    }
  }
  let point_est = @math.mean(sorted_samples)
  let std_err = @math.std_dev(sorted_samples)

  let lower_idx = (alpha / 2.0 * n.to_double()).to_int()
  let upper_idx = ((1.0 - alpha / 2.0) * n.to_double()).to_int()
  let l_safe = if lower_idx < 0 {
    0
  } else if lower_idx >= n {
    n - 1
  } else {
    lower_idx
  }
  let u_safe = if upper_idx < 0 {
    0
  } else if upper_idx >= n {
    n - 1
  } else {
    upper_idx
  }

  let ci_lower = sorted_samples[l_safe]
  let ci_upper = sorted_samples[u_safe]

  @types.BootstrapResult::new(point_est, ci_lower, ci_upper, std_err, samples)
}
