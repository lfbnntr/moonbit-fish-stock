// Math constants
///|
pub let pi : Double = 3.14159265358979323846

///|
pub let e : Double = 2.71828182845904523536

///|
pub let ln2 : Double = 0.69314718055994530942

///|
pub let epsilon : Double = 2.220446049250313e-16

///|
pub let max_value_double : Double = 1.7976931348623157e+308

///|
pub let min_positive_double : Double = 2.2250738585072014e-308

///|
/// Absolute value for Double
pub fn abs_double(x : Double) -> Double {
  if x < 0.0 {
    -x
  } else {
    x
  }
}

///|
/// Minimum of two Doubles
pub fn min_double(a : Double, b : Double) -> Double {
  if a <= b {
    a
  } else {
    b
  }
}

///|
/// Maximum of two Doubles
pub fn max_double(a : Double, b : Double) -> Double {
  if a >= b {
    a
  } else {
    b
  }
}

///|
/// Square root approximation using Newton's method (~15 iterations)
pub fn sqrt_approx(x : Double) -> Double {
  if x < 0.0 {
    return -1.0 // Indicate error for negative input
  }
  if x == 0.0 {
    return 0.0
  }
  let mut guess = x
  if x > 1.0 {
    guess = x / 2.0
  } else {
    guess = 1.0
  }
  for i = 0; i < 15; i = i + 1 {
    guess = (guess + x / guess) / 2.0
  }
  guess
}

///|
/// Natural logarithm approximation
/// Uses the identity ln(x) = 2 * arctanh((x-1)/(x+1)) series expansion
pub fn ln_approx(x : Double) -> Double {
  if x <= 0.0 {
    return -1.0e308 // Indicate error
  }
  if x == 1.0 {
    return 0.0
  }
  let mut val = x
  let mut n = 0
  while val >= 2.0 {
    val = val / 2.0
    n = n + 1
  }
  while val < 1.0 {
    val = val * 2.0
    n = n - 1
  }
  let t = (val - 1.0) / (val + 1.0)
  let t_sq = t * t
  let mut result = 0.0
  let mut term = t
  for k = 0; k < 30; k = k + 1 {
    let denom = (2 * k + 1).to_double()
    result = result + term / denom
    term = term * t_sq
  }
  result = 2.0 * result
  result + n.to_double() * ln2
}

///|
/// Exponential function approximation using Taylor series
pub fn exp_approx(x : Double) -> Double {
  if x > 709.0 {
    return max_value_double
  }
  if x < -709.0 {
    return 0.0
  }
  let k_raw = x / ln2
  let mut k = 0
  if k_raw >= 0.0 {
    k = floor_double(k_raw).to_int()
  } else {
    k = ceil_double(k_raw).to_int()
  }
  let r = x - k.to_double() * ln2
  let mut sum = 1.0
  let mut term = 1.0
  for i = 1; i < 25; i = i + 1 {
    term = term * r / i.to_double()
    sum = sum + term
    if abs_double(term) < epsilon {
      break
    }
  }
  let mut result = sum
  if k > 0 {
    for _i = 0; _i < k; _i = _i + 1 {
      result = result * 2.0
    }
  } else if k < 0 {
    let neg_k = -k
    for _i = 0; _i < neg_k; _i = _i + 1 {
      result = result / 2.0
    }
  }
  result
}

///|
/// Power function: x raised to the power n (Double exponent)
pub fn pow_double(x : Double, n : Double) -> Double {
  if n == 0.0 {
    return 1.0
  }
  if x == 0.0 {
    return 0.0
  }
  if x == 1.0 {
    return 1.0
  }
  if x > 0.0 {
    return exp_approx(n * ln_approx(x))
  }
  let n_int = n.to_int()
  if n_int.to_double() == n {
    let magnitude = exp_approx(n * ln_approx(abs_double(x)))
    if n_int % 2 == 0 {
      magnitude
    } else {
      -magnitude
    }
  } else {
    -1.0 // Error: complex result
  }
}

///|
/// Floor function for Double - returns largest integer <= x as Double
pub fn floor_double(x : Double) -> Double {
  let xi = x.to_int()
  let xd = xi.to_double()
  if xd > x {
    (xi - 1).to_double()
  } else {
    xd
  }
}

///|
/// Ceiling function for Double - returns smallest integer >= x as Double
pub fn ceil_double(x : Double) -> Double {
  let xi = x.to_int()
  let xd = xi.to_double()
  if xd < x {
    (xi + 1).to_double()
  } else {
    xd
  }
}

///|
/// Round to nearest integer (as Double)
pub fn round_double(x : Double) -> Double {
  floor_double(x + 0.5)
}

///|
/// Clamp value between low and high
pub fn clamp(x : Double, low : Double, high : Double) -> Double {
  if x < low {
    low
  } else if x > high {
    high
  } else {
    x
  }
}

///|
/// Check if a Double value is finite (not infinity or NaN)
pub fn is_finite(x : Double) -> Bool {
  x == x && x - x == 0.0
}

///|
/// Check if a Double value is NaN
pub fn is_nan(x : Double) -> Bool {
  x != x
}

///|
/// Sign function: returns -1.0, 0.0, or 1.0
pub fn sign_double(x : Double) -> Double {
  if x > 0.0 {
    1.0
  } else if x < 0.0 {
    -1.0
  } else {
    0.0
  }
}

///|
/// Linear interpolation between a and b
pub fn lerp(a : Double, b : Double, t : Double) -> Double {
  a + (b - a) * t
}
