///|
/// Compute the sum of an array of Doubles
pub fn sum(data : Array[Double]) -> Double {
  let mut s = 0.0
  for i = 0; i < data.length(); i = i + 1 {
    s = s + data[i]
  }
  s
}

///|
/// Compute the sum of squares of an array of Doubles
pub fn sum_sq(data : Array[Double]) -> Double {
  let mut s = 0.0
  for i = 0; i < data.length(); i = i + 1 {
    s = s + data[i] * data[i]
  }
  s
}

///|
/// Compute the arithmetic mean
pub fn mean(data : Array[Double]) -> Double {
  if data.length() == 0 {
    return 0.0
  }
  sum(data) / data.length().to_double()
}

///|
/// Compute the population variance
pub fn variance(data : Array[Double]) -> Double {
  if data.length() == 0 {
    return 0.0
  }
  let m = mean(data)
  let n = data.length().to_double()
  let mut ss = 0.0
  for i = 0; i < data.length(); i = i + 1 {
    let diff = data[i] - m
    ss = ss + diff * diff
  }
  ss / n
}

///|
/// Compute the sample variance (with Bessel's correction)
pub fn sample_variance(data : Array[Double]) -> Double {
  if data.length() <= 1 {
    return 0.0
  }
  let m = mean(data)
  let n = data.length().to_double()
  let mut ss = 0.0
  for i = 0; i < data.length(); i = i + 1 {
    let diff = data[i] - m
    ss = ss + diff * diff
  }
  ss / (n - 1.0)
}

///|
/// Compute the population standard deviation
pub fn std_dev(data : Array[Double]) -> Double {
  sqrt_approx(variance(data))
}

///|
/// Compute the sample standard deviation
pub fn sample_std_dev(data : Array[Double]) -> Double {
  sqrt_approx(sample_variance(data))
}

///|
/// Sort an array of Doubles in-place (insertion sort for simplicity)
fn sort_doubles(data : Array[Double]) -> Unit {
  let n = data.length()
  for i = 1; i < n; i = i + 1 {
    let key = data[i]
    let mut j = i - 1
    while j >= 0 && data[j] > key {
      data[j + 1] = data[j]
      j = j - 1
    }
    data[j + 1] = key
  }
}

///|
/// Compute the median of an array of Doubles
pub fn median(data : Array[Double]) -> Double {
  if data.length() == 0 {
    return 0.0
  }
  // Make a copy to avoid modifying the original
  let sorted : Array[Double] = Array::make(data.length(), 0.0)
  for i = 0; i < data.length(); i = i + 1 {
    sorted[i] = data[i]
  }
  sort_doubles(sorted)
  let n = sorted.length()
  if n % 2 == 1 {
    sorted[n / 2]
  } else {
    (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
  }
}

///|
/// Compute the p-th percentile (p in [0, 100])
pub fn percentile(data : Array[Double], p : Double) -> Double {
  if data.length() == 0 {
    return 0.0
  }
  let sorted : Array[Double] = Array::make(data.length(), 0.0)
  for i = 0; i < data.length(); i = i + 1 {
    sorted[i] = data[i]
  }
  sort_doubles(sorted)
  let n = sorted.length()
  if p <= 0.0 {
    return sorted[0]
  }
  if p >= 100.0 {
    return sorted[n - 1]
  }
  let rank = p / 100.0 * (n - 1).to_double()
  let lower = floor_double(rank).to_int()
  let upper = ceil_double(rank).to_int()
  if lower == upper {
    sorted[lower]
  } else {
    let frac = rank - lower.to_double()
    sorted[lower] * (1.0 - frac) + sorted[upper] * frac
  }
}

///|
/// Compute the covariance of two arrays
pub fn covariance(x : Array[Double], y : Array[Double]) -> Double {
  let n = min_double(x.length().to_double(), y.length().to_double()).to_int()
  if n == 0 {
    return 0.0
  }
  let mx = mean(x)
  let my = mean(y)
  let mut cov = 0.0
  for i = 0; i < n; i = i + 1 {
    cov = cov + (x[i] - mx) * (y[i] - my)
  }
  cov / n.to_double()
}

///|
/// Compute the Pearson correlation coefficient
pub fn correlation(x : Array[Double], y : Array[Double]) -> Double {
  let cov = covariance(x, y)
  let sx = std_dev(x)
  let sy = std_dev(y)
  if sx == 0.0 || sy == 0.0 {
    return 0.0
  }
  cov / (sx * sy)
}

///|
/// Weighted mean of data with given weights
pub fn weighted_mean(data : Array[Double], weights : Array[Double]) -> Double {
  let n = min_double(data.length().to_double(), weights.length().to_double()).to_int()
  if n == 0 {
    return 0.0
  }
  let mut weighted_sum = 0.0
  let mut weight_total = 0.0
  for i = 0; i < n; i = i + 1 {
    weighted_sum = weighted_sum + data[i] * weights[i]
    weight_total = weight_total + weights[i]
  }
  if weight_total == 0.0 {
    return 0.0
  }
  weighted_sum / weight_total
}

///|
/// Compute skewness (Fisher's definition)
pub fn skewness(data : Array[Double]) -> Double {
  let n = data.length()
  if n < 3 {
    return 0.0
  }
  let m = mean(data)
  let sd = std_dev(data)
  if sd == 0.0 {
    return 0.0
  }
  let nd = n.to_double()
  let mut m3 = 0.0
  for i = 0; i < n; i = i + 1 {
    let diff = (data[i] - m) / sd
    m3 = m3 + diff * diff * diff
  }
  m3 / nd
}

///|
/// Compute excess kurtosis
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
  let nd = n.to_double()
  let mut m4 = 0.0
  for i = 0; i < n; i = i + 1 {
    let diff = (data[i] - m) / sd
    let d2 = diff * diff
    m4 = m4 + d2 * d2
  }
  m4 / nd - 3.0
}

///|
/// Compute the z-score of a value given mean and standard deviation
pub fn z_score(x : Double, m : Double, sd : Double) -> Double {
  if sd == 0.0 {
    return 0.0
  }
  (x - m) / sd
}

///|
/// Compute the simple moving average with given window size
pub fn moving_average(data : Array[Double], window : Int) -> Array[Double] {
  let n = data.length()
  if n == 0 || window <= 0 || window > n {
    return []
  }
  let result_len = n - window + 1
  let result : Array[Double] = Array::make(result_len, 0.0)
  // Compute first window sum
  let mut window_sum = 0.0
  for i = 0; i < window; i = i + 1 {
    window_sum = window_sum + data[i]
  }
  result[0] = window_sum / window.to_double()
  // Slide the window
  for i = 1; i < result_len; i = i + 1 {
    window_sum = window_sum + data[i + window - 1] - data[i - 1]
    result[i] = window_sum / window.to_double()
  }
  result
}

///|
/// Exponential smoothing (single exponential)
/// alpha is the smoothing factor in (0, 1)
pub fn exponential_smoothing(
  data : Array[Double],
  alpha : Double,
) -> Array[Double] {
  let n = data.length()
  if n == 0 {
    return []
  }
  let result : Array[Double] = Array::make(n, 0.0)
  result[0] = data[0]
  for i = 1; i < n; i = i + 1 {
    result[i] = alpha * data[i] + (1.0 - alpha) * result[i - 1]
  }
  result
}

///|
/// Compute the range (max - min) of data
pub fn data_range(data : Array[Double]) -> Double {
  if data.length() == 0 {
    return 0.0
  }
  let mut lo = data[0]
  let mut hi = data[0]
  for i = 1; i < data.length(); i = i + 1 {
    if data[i] < lo {
      lo = data[i]
    }
    if data[i] > hi {
      hi = data[i]
    }
  }
  hi - lo
}

///|
/// Find the minimum value in an array
pub fn array_min(data : Array[Double]) -> Double {
  if data.length() == 0 {
    return 0.0
  }
  let mut lo = data[0]
  for i = 1; i < data.length(); i = i + 1 {
    if data[i] < lo {
      lo = data[i]
    }
  }
  lo
}

///|
/// Find the maximum value in an array
pub fn array_max(data : Array[Double]) -> Double {
  if data.length() == 0 {
    return 0.0
  }
  let mut hi = data[0]
  for i = 1; i < data.length(); i = i + 1 {
    if data[i] > hi {
      hi = data[i]
    }
  }
  hi
}
