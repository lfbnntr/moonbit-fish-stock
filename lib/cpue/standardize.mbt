/// CPUE standardization routines for fishery stock assessment.
/// Provides functions to compute, normalize, detrend, and adjust CPUE series.

///|
/// Compute raw CPUE from total catch and total effort.
/// CPUE = Catch / Effort
pub fn raw_cpue(
  catch_amount : Double,
  effort : Double,
) -> Double raise @types.ErrorType {
  if effort <= 0.0 {
    raise @types.ErrorType::InvalidParameter("Effort must be positive")
  }
  if catch_amount < 0.0 {
    raise @types.ErrorType::InvalidParameter("Catch must be non-negative")
  }
  catch_amount / effort
}

///|
/// Compute a CPUE time series from parallel arrays of catches and efforts.
pub fn compute_cpue_series(
  catches : Array[Double],
  efforts : Array[Double],
) -> Array[Double] raise @types.ErrorType {
  let n = catches.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData("Empty catch array")
  }
  if n != efforts.length() {
    raise @types.ErrorType::InvalidParameter(
      "Catches and efforts arrays must have the same length",
    )
  }
  let result : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    if efforts[i] <= 0.0 {
      raise @types.ErrorType::InvalidParameter(
        "Effort must be positive at index",
      )
    }
    result.push(catches[i] / efforts[i])
  }
  result
}

///|
/// Compute the geometric mean of a CPUE series.
/// Geometric mean = exp(mean(ln(x_i))) for all x_i > 0.
pub fn geometric_mean_cpue(
  cpue_series : Array[Double],
) -> Double raise @types.ErrorType {
  let n = cpue_series.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData("Empty CPUE series")
  }
  let mut sum_log = 0.0
  for i = 0; i < n; i = i + 1 {
    if cpue_series[i] <= 0.0 {
      raise @types.ErrorType::InvalidParameter(
        "All CPUE values must be positive for geometric mean",
      )
    }
    sum_log = sum_log + @math.ln_approx(cpue_series[i])
  }
  @math.exp_approx(sum_log / n.to_double())
}

///|
/// Normalize a CPUE series by dividing each value by the arithmetic mean.
/// Returns values centered around 1.0.
pub fn normalize_cpue(
  series : Array[Double],
) -> Array[Double] raise @types.ErrorType {
  let n = series.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData("Empty CPUE series")
  }
  let m = @math.mean(series)
  if m == 0.0 {
    raise @types.ErrorType::NumericalError("Mean is zero, cannot normalize")
  }
  let result : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    result.push(series[i] / m)
  }
  result
}

///|
/// Compute relative CPUE with respect to a base year.
/// Each value is divided by the value at `base_year_index`.
pub fn relative_cpue(
  series : Array[Double],
  base_year_index : Int,
) -> Array[Double] raise @types.ErrorType {
  let n = series.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData("Empty CPUE series")
  }
  if base_year_index < 0 || base_year_index >= n {
    raise @types.ErrorType::InvalidParameter("Base year index out of range")
  }
  let base = series[base_year_index]
  if base == 0.0 {
    raise @types.ErrorType::NumericalError(
      "Base year CPUE is zero, cannot compute relative CPUE",
    )
  }
  let result : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    result.push(series[i] / base)
  }
  result
}

///|
/// Remove a linear trend from a CPUE series using ordinary least squares.
/// Returns detrended residuals (observed - predicted by trend line).
pub fn detrend_cpue(
  series : Array[Double],
) -> Array[Double] raise @types.ErrorType {
  let n = series.length()
  if n < 2 {
    raise @types.ErrorType::InsufficientData(
      "Need at least 2 data points to detrend",
    )
  }
  let nf = n.to_double()
  let mut sum_x = 0.0
  let mut sum_y = 0.0
  for i = 0; i < n; i = i + 1 {
    sum_x = sum_x + i.to_double()
    sum_y = sum_y + series[i]
  }
  let mean_x = sum_x / nf
  let mean_y = sum_y / nf
  let mut ss_xy = 0.0
  let mut ss_xx = 0.0
  for i = 0; i < n; i = i + 1 {
    let dx = i.to_double() - mean_x
    let dy = series[i] - mean_y
    ss_xy = ss_xy + dx * dy
    ss_xx = ss_xx + dx * dx
  }
  if ss_xx == 0.0 {
    raise @types.ErrorType::NumericalError(
      "Cannot compute trend: zero variance in x",
    )
  }
  let slope = ss_xy / ss_xx
  let intercept = mean_y - slope * mean_x
  let result : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    let predicted = intercept + slope * i.to_double()
    result.push(series[i] - predicted)
  }
  result
}

///|
/// Adjust a CPUE series for seasonal effects.
/// Computes the mean for each season (modulo `period`) and subtracts it.
pub fn seasonal_adjustment(
  series : Array[Double],
  period : Int,
) -> Array[Double] raise @types.ErrorType {
  let n = series.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData("Empty CPUE series")
  }
  if period <= 0 {
    raise @types.ErrorType::InvalidParameter("Period must be positive")
  }
  if period > n {
    raise @types.ErrorType::InvalidParameter(
      "Period must not exceed series length",
    )
  }
  let seasonal_sum : Array[Double] = []
  let seasonal_count : Array[Int] = []
  for s = 0; s < period; s = s + 1 {
    seasonal_sum.push(0.0)
    seasonal_count.push(0)
  }
  for i = 0; i < n; i = i + 1 {
    let s = i % period
    seasonal_sum[s] = seasonal_sum[s] + series[i]
    seasonal_count[s] = seasonal_count[s] + 1
  }
  let seasonal_mean : Array[Double] = []
  for s = 0; s < period; s = s + 1 {
    if seasonal_count[s] > 0 {
      seasonal_mean.push(seasonal_sum[s] / seasonal_count[s].to_double())
    } else {
      seasonal_mean.push(0.0)
    }
  }
  let mut overall = 0.0
  for s = 0; s < period; s = s + 1 {
    overall = overall + seasonal_mean[s]
  }
  overall = overall / period.to_double()
  let result : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    let s = i % period
    result.push(series[i] - seasonal_mean[s] + overall)
  }
  result
}

///|
/// Apply natural log transformation to a CPUE series.
/// All values must be positive.
pub fn log_cpue(series : Array[Double]) -> Array[Double] raise @types.ErrorType {
  let n = series.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData("Empty CPUE series")
  }
  let result : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    if series[i] <= 0.0 {
      raise @types.ErrorType::InvalidParameter(
        "All CPUE values must be positive for log transform",
      )
    }
    result.push(@math.ln_approx(series[i]))
  }
  result
}
