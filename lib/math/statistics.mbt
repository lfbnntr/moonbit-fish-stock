// ============================================================
// Comprehensive Statistical Functions & Multivariate Analysis
// ============================================================

///|
/// Mean of an array of Doubles.
pub fn mean(data : Array[Double]) -> Double {
  let n = data.length()
  if n == 0 {
    return 0.0
  }
  let mut sum = 0.0
  for i = 0; i < n; i = i + 1 {
    sum = sum + data[i]
  }
  sum / n.to_double()
}

///|
/// Weighted mean.
pub fn weighted_mean(data : Array[Double], weights : Array[Double]) -> Double {
  let n = data.length()
  if n == 0 || n != weights.length() {
    return 0.0
  }
  let mut sum_wx = 0.0
  let mut sum_w = 0.0
  for i = 0; i < n; i = i + 1 {
    sum_wx = sum_wx + data[i] * weights[i]
    sum_w = sum_w + weights[i]
  }
  if sum_w == 0.0 {
    0.0
  } else {
    sum_wx / sum_w
  }
}

///|
/// Population variance.
pub fn variance(data : Array[Double]) -> Double {
  let n = data.length()
  if n == 0 {
    return 0.0
  }
  let m = mean(data)
  let mut sum_sq = 0.0
  for i = 0; i < n; i = i + 1 {
    let d = data[i] - m
    sum_sq = sum_sq + d * d
  }
  sum_sq / n.to_double()
}

///|
/// Sample variance (n - 1 denominator).
pub fn sample_variance(data : Array[Double]) -> Double {
  let n = data.length()
  if n <= 1 {
    return 0.0
  }
  let m = mean(data)
  let mut sum_sq = 0.0
  for i = 0; i < n; i = i + 1 {
    let d = data[i] - m
    sum_sq = sum_sq + d * d
  }
  sum_sq / (n.to_double() - 1.0)
}

///|
/// Standard deviation.
pub fn std_dev(data : Array[Double]) -> Double {
  sqrt_approx(variance(data))
}

///|
/// Sample standard deviation.
pub fn sample_std_dev(data : Array[Double]) -> Double {
  sqrt_approx(sample_variance(data))
}

///|
/// Median of an array of Doubles.
pub fn median(data : Array[Double]) -> Double {
  let n = data.length()
  if n == 0 {
    return 0.0
  }
  let sorted : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    sorted.push(data[i])
  }
  for i = 0; i < n - 1; i = i + 1 {
    for j = 0; j < n - i - 1; j = j + 1 {
      if sorted[j] > sorted[j + 1] {
        let tmp = sorted[j]
        sorted[j] = sorted[j + 1]
        sorted[j + 1] = tmp
      }
    }
  }
  if n % 2 == 1 {
    sorted[n / 2]
  } else {
    (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
  }
}

///|
/// Percentile (p in [0, 100]).
pub fn percentile(data : Array[Double], p : Double) -> Double {
  let n = data.length()
  if n == 0 {
    return 0.0
  }
  let sorted : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    sorted.push(data[i])
  }
  for i = 0; i < n - 1; i = i + 1 {
    for j = 0; j < n - i - 1; j = j + 1 {
      if sorted[j] > sorted[j + 1] {
        let tmp = sorted[j]
        sorted[j] = sorted[j + 1]
        sorted[j + 1] = tmp
      }
    }
  }
  let idx = p / 100.0 * (n - 1).to_double()
  let i_floor = floor_double(idx).to_int()
  let i_ceil = ceil_double(idx).to_int()
  if i_floor == i_ceil {
    sorted[i_floor]
  } else {
    let weight = idx - i_floor.to_double()
    lerp(sorted[i_floor], sorted[i_ceil], weight)
  }
}

///|
/// Covariance between two series.
pub fn covariance(x : Array[Double], y : Array[Double]) -> Double {
  let n = x.length()
  if n <= 1 || n != y.length() {
    return 0.0
  }
  let mx = mean(x)
  let my = mean(y)
  let mut sum_cov = 0.0
  for i = 0; i < n; i = i + 1 {
    sum_cov = sum_cov + (x[i] - mx) * (y[i] - my)
  }
  sum_cov / (n.to_double() - 1.0)
}

///|
/// Pearson correlation coefficient.
pub fn correlation(x : Array[Double], y : Array[Double]) -> Double {
  let n = x.length()
  if n <= 1 || n != y.length() {
    return 0.0
  }
  let cov = covariance(x, y)
  let sdx = sample_std_dev(x)
  let sdy = sample_std_dev(y)
  let denom = sdx * sdy
  if denom == 0.0 {
    0.0
  } else {
    clamp(cov / denom, -1.0, 1.0)
  }
}

///|
/// Skewness (3rd standardized moment).
pub fn skewness(data : Array[Double]) -> Double {
  let n = data.length()
  if n < 3 {
    return 0.0
  }
  let m = mean(data)
  let sd = sample_std_dev(data)
  if sd == 0.0 {
    return 0.0
  }
  let mut sum_m3 = 0.0
  for i = 0; i < n; i = i + 1 {
    let z = (data[i] - m) / sd
    sum_m3 = sum_m3 + z * z * z
  }
  let nf = n.to_double()
  nf / ((nf - 1.0) * (nf - 2.0)) * sum_m3
}

///|
/// Kurtosis (excess kurtosis, 4th standardized moment - 3).
pub fn kurtosis(data : Array[Double]) -> Double {
  let n = data.length()
  if n < 4 {
    return 0.0
  }
  let m = mean(data)
  let sd = std_dev(data)
  if sd == 0.0 {
    return 0.0
  }
  let mut sum_m4 = 0.0
  for i = 0; i < n; i = i + 1 {
    let z = (data[i] - m) / sd
    sum_m4 = sum_m4 + z * z * z * z
  }
  sum_m4 / n.to_double() - 3.0
}

///|
/// Simple 1D Moving Average with window size k.
pub fn moving_average(data : Array[Double], k : Int) -> Array[Double] {
  let n = data.length()
  let result : Array[Double] = []
  if k <= 0 || n == 0 {
    return result
  }
  for i = 0; i < n; i = i + 1 {
    let start = if i - k + 1 < 0 { 0 } else { i - k + 1 }
    let mut sum = 0.0
    let mut count = 0
    for j = start; j <= i; j = j + 1 {
      sum = sum + data[j]
      count = count + 1
    }
    result.push(sum / count.to_double())
  }
  result
}

///|
/// Single Exponential Smoothing with parameter alpha in (0, 1).
pub fn exponential_smoothing(
  data : Array[Double],
  alpha : Double,
) -> Array[Double] {
  let n = data.length()
  let result : Array[Double] = []
  if n == 0 {
    return result
  }
  result.push(data[0])
  let mut s_prev = data[0]
  for i = 1; i < n; i = i + 1 {
    let s_curr = alpha * data[i] + (1.0 - alpha) * s_prev
    result.push(s_curr)
    s_prev = s_curr
  }
  result
}

///|
/// One-Way Analysis of Variance (ANOVA) F-statistic between groups.
pub fn one_way_anova_f_stat(groups : Array[Array[Double]]) -> Double {
  let k = groups.length()
  if k < 2 {
    return 0.0
  }
  let mut total_n = 0
  let mut grand_sum = 0.0
  for g = 0; g < k; g = g + 1 {
    let len = groups[g].length()
    total_n = total_n + len
    for i = 0; i < len; i = i + 1 {
      grand_sum = grand_sum + groups[g][i]
    }
  }
  if total_n <= k {
    return 0.0
  }
  let grand_mean = grand_sum / total_n.to_double()

  let mut ss_between = 0.0
  let mut ss_within = 0.0

  for g = 0; g < k; g = g + 1 {
    let n_g = groups[g].length().to_double()
    let m_g = mean(groups[g])
    let diff = m_g - grand_mean
    ss_between = ss_between + n_g * diff * diff
    for i = 0; i < groups[g].length(); i = i + 1 {
      let d = groups[g][i] - m_g
      ss_within = ss_within + d * d
    }
  }

  let df_between = (k - 1).to_double()
  let df_within = (total_n - k).to_double()

  let ms_between = ss_between / df_between
  let ms_within = ss_within / df_within

  if ms_within == 0.0 {
    0.0
  } else {
    ms_between / ms_within
  }
}
