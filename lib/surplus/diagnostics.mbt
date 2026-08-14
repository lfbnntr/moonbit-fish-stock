// ============================================================
// Model Diagnostics for Surplus Production Models
// ============================================================

///|
/// Diagnostic summary structure.
pub(all) struct ModelDiagnostics {
  durbin_watson : Double
  runs_p_value : Double
  is_autocorrelated : Bool
  mean_residual : Double
  std_residual : Double
} derive(Eq)

///|
pub fn ModelDiagnostics::new(
  durbin_watson : Double,
  runs_p_value : Double,
  is_autocorrelated : Bool,
  mean_residual : Double,
  std_residual : Double,
) -> ModelDiagnostics {
  {
    durbin_watson,
    runs_p_value,
    is_autocorrelated,
    mean_residual,
    std_residual,
  }
}

///|
/// Compute Durbin-Watson statistic for residual autocorrelation.
/// DW = sum_{t=2}^n (e_t - e_{t-1})^2 / sum_{t=1}^n e_t^2
/// DW near 2 => no autocorrelation. DW < 1.5 => positive autocorrelation.
pub fn durbin_watson_stat(residuals : Array[Double]) -> Double {
  let n = residuals.length()
  if n < 2 {
    return 2.0
  }
  let mut num = 0.0
  let mut den = residuals[0] * residuals[0]
  for t = 1; t < n; t = t + 1 {
    let diff = residuals[t] - residuals[t - 1]
    num = num + diff * diff
    den = den + residuals[t] * residuals[t]
  }
  if den == 0.0 {
    2.0
  } else {
    num / den
  }
}

///|
/// Perform a Runs Test for randomness of residuals signs.
/// Returns estimated p-value (approximate).
pub fn runs_test_p_value(residuals : Array[Double]) -> Double {
  let n = residuals.length()
  if n < 4 {
    return 1.0
  }
  let mut n_plus = 0
  let mut n_minus = 0
  let signs : Array[Int] = []
  for i = 0; i < n; i = i + 1 {
    if residuals[i] >= 0.0 {
      n_plus = n_plus + 1
      signs.push(1)
    } else {
      n_minus = n_minus + 1
      signs.push(-1)
    }
  }
  if n_plus == 0 || n_minus == 0 {
    return 0.0
  }
  let mut runs = 1
  for i = 1; i < n; i = i + 1 {
    if signs[i] != signs[i - 1] {
      runs = runs + 1
    }
  }
  let n1 = n_plus.to_double()
  let n2 = n_minus.to_double()
  let expected_runs = 2.0 * n1 * n2 / (n1 + n2) + 1.0
  let var_runs = 2.0 *
    n1 *
    n2 *
    (2.0 * n1 * n2 - n1 - n2) /
    ((n1 + n2) * (n1 + n2) * (n1 + n2 - 1.0))
  let sd_runs = @math.sqrt_approx(var_runs)
  if sd_runs == 0.0 {
    1.0
  } else {
    let z = @math.abs_double(runs.to_double() - expected_runs) / sd_runs
    // Approximate two-tailed p-value from Z: exp(-0.5 * z^2)
    @math.exp_approx(-0.5 * z * z)
  }
}

///|
/// Run complete diagnostics on a model result.
pub fn run_diagnostics(result : @types.ModelResult) -> ModelDiagnostics {
  let dw = durbin_watson_stat(result.residuals)
  let p_val = runs_test_p_value(result.residuals)
  let is_auto = dw < 1.5 || dw > 2.5
  let m = @math.mean(result.residuals)
  let sd = @math.std_dev(result.residuals)
  ModelDiagnostics::new(dw, p_val, is_auto, m, sd)
}

///|
/// Compare multiple model results and rank them by AIC.
/// Returns array of indices sorted from best (lowest AIC) to worst.
pub fn rank_models_by_aic(models : Array[@types.ModelResult]) -> Array[Int] {
  let n = models.length()
  let indices : Array[Int] = []
  for i = 0; i < n; i = i + 1 {
    indices.push(i)
  }
  // Bubble sort indices based on AIC
  for i = 0; i < n - 1; i = i + 1 {
    for j = 0; j < n - i - 1; j = j + 1 {
      let idx1 = indices[j]
      let idx2 = indices[j + 1]
      if models[idx1].aic > models[idx2].aic {
        indices[j] = idx2
        indices[j + 1] = idx1
      }
    }
  }
  indices
}
