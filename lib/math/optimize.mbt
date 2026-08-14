///|
/// Golden section search for 1D minimization
/// Finds x in [a, b] that minimizes f(x)
/// Returns the x value that minimizes f
pub fn golden_section_search(
  f : (Double) -> Double,
  a : Double,
  b : Double,
  tol : Double,
) -> Double {
  let gr = (sqrt_approx(5.0) - 1.0) / 2.0 // golden ratio conjugate ~0.618
  let mut lo = a
  let mut hi = b
  let mut c = hi - gr * (hi - lo)
  let mut d = lo + gr * (hi - lo)
  let max_iter = 200
  for _i = 0; _i < max_iter; _i = _i + 1 {
    if abs_double(hi - lo) < tol {
      break
    }
    if f(c) < f(d) {
      hi = d
    } else {
      lo = c
    }
    c = hi - gr * (hi - lo)
    d = lo + gr * (hi - lo)
  }
  (lo + hi) / 2.0
}

///|
/// Gradient descent for 1D optimization
/// Finds x that minimizes f(x), starting from x0
/// Uses numerical gradient with central differences
pub fn gradient_descent_1d(
  f : (Double) -> Double,
  x0 : Double,
  learning_rate : Double,
  tol : Double,
  max_iter : Int,
) -> Double {
  let h = 1.0e-8
  let mut x = x0
  for _i = 0; _i < max_iter; _i = _i + 1 {
    // Numerical gradient via central difference
    let grad = (f(x + h) - f(x - h)) / (2.0 * h)
    let x_new = x - learning_rate * grad
    if abs_double(x_new - x) < tol {
      break
    }
    x = x_new
  }
  x
}

///|
/// Bisection method for root finding
/// Finds x in [a, b] such that f(x) �?0
/// Assumes f(a) and f(b) have opposite signs
pub fn bisection(
  f : (Double) -> Double,
  a : Double,
  b : Double,
  tol : Double,
  max_iter : Int,
) -> Double {
  let mut lo = a
  let mut hi = b
  // Ensure f(lo) < 0 and f(hi) > 0
  if f(lo) > 0.0 {
    let tmp = lo
    lo = hi
    hi = tmp
  }
  for _i = 0; _i < max_iter; _i = _i + 1 {
    let mid = (lo + hi) / 2.0
    if abs_double(hi - lo) < tol {
      break
    }
    let fm = f(mid)
    if fm < 0.0 {
      lo = mid
    } else {
      hi = mid
    }
  }
  (lo + hi) / 2.0
}

///|
/// Grid search for 1D parameter optimization
/// Evaluates f at n_points evenly spaced points in [a, b]
/// Returns the x that gives the minimum f(x)
pub fn grid_search_1d(
  f : (Double) -> Double,
  a : Double,
  b : Double,
  n_points : Int,
) -> Double {
  if n_points <= 1 {
    return (a + b) / 2.0
  }
  let step = (b - a) / (n_points - 1).to_double()
  let mut best_x = a
  let mut best_f = f(a)
  for i = 1; i < n_points; i = i + 1 {
    let x = a + i.to_double() * step
    let fx = f(x)
    if fx < best_f {
      best_f = fx
      best_x = x
    }
  }
  best_x
}

///|
/// Grid search for 2D parameter optimization
/// Evaluates f(x, y) on a grid and returns (best_x, best_y)
pub fn grid_search_2d(
  f : (Double, Double) -> Double,
  x_min : Double,
  x_max : Double,
  y_min : Double,
  y_max : Double,
  nx : Int,
  ny : Int,
) -> (Double, Double) {
  let x_step = if nx > 1 { (x_max - x_min) / (nx - 1).to_double() } else { 0.0 }
  let y_step = if ny > 1 { (y_max - y_min) / (ny - 1).to_double() } else { 0.0 }
  let mut best_x = x_min
  let mut best_y = y_min
  let mut best_f = f(x_min, y_min)
  for i = 0; i < nx; i = i + 1 {
    let x = x_min + i.to_double() * x_step
    for j = 0; j < ny; j = j + 1 {
      let y = y_min + j.to_double() * y_step
      let fv = f(x, y)
      if fv < best_f {
        best_f = fv
        best_x = x
        best_y = y
      }
    }
  }
  (best_x, best_y)
}

///|
/// Nelder-Mead simplex method for 2D optimization
/// Minimizes f(x, y) starting from initial point (x0, y0)
/// Returns (best_x, best_y)
pub fn nelder_mead_2d(
  f : (Double, Double) -> Double,
  x0 : Double,
  y0 : Double,
  step : Double,
  tol : Double,
  max_iter : Int,
) -> (Double, Double) {
  // Initial simplex: 3 points for 2D
  let sx : Array[Double] = [x0, x0 + step, x0]
  let sy : Array[Double] = [y0, y0, y0 + step]
  let sf : Array[Double] = [f(x0, y0), f(x0 + step, y0), f(x0, y0 + step)]
  let alpha = 1.0 // Reflection
  let gamma = 2.0 // Expansion
  let rho = 0.5 // Contraction
  let sigma = 0.5 // Shrink
  for _iter = 0; _iter < max_iter; _iter = _iter + 1 {
    // Sort vertices by function value (simple bubble for 3 elements)
    for i = 0; i < 2; i = i + 1 {
      for j = 0; j < 2 - i; j = j + 1 {
        if sf[j] > sf[j + 1] {
          let tx = sx[j]
          sx[j] = sx[j + 1]
          sx[j + 1] = tx
          let ty = sy[j]
          sy[j] = sy[j + 1]
          sy[j + 1] = ty
          let tv = sf[j]
          sf[j] = sf[j + 1]
          sf[j + 1] = tv
        }
      }
    }
    // Check convergence
    let size = abs_double(sf[2] - sf[0])
    if size < tol {
      break
    }
    // Centroid of best 2 points (excluding worst)
    let cx = (sx[0] + sx[1]) / 2.0
    let cy = (sy[0] + sy[1]) / 2.0
    // Reflection
    let rx = cx + alpha * (cx - sx[2])
    let ry = cy + alpha * (cy - sy[2])
    let fr = f(rx, ry)
    if fr < sf[1] && fr >= sf[0] {
      sx[2] = rx
      sy[2] = ry
      sf[2] = fr
      continue
    }
    // Expansion
    if fr < sf[0] {
      let ex = cx + gamma * (rx - cx)
      let ey = cy + gamma * (ry - cy)
      let fe = f(ex, ey)
      if fe < fr {
        sx[2] = ex
        sy[2] = ey
        sf[2] = fe
      } else {
        sx[2] = rx
        sy[2] = ry
        sf[2] = fr
      }
      continue
    }
    // Contraction
    let ccx = cx + rho * (sx[2] - cx)
    let ccy = cy + rho * (sy[2] - cy)
    let fc = f(ccx, ccy)
    if fc < sf[2] {
      sx[2] = ccx
      sy[2] = ccy
      sf[2] = fc
      continue
    }
    // Shrink
    for i = 1; i < 3; i = i + 1 {
      sx[i] = sx[0] + sigma * (sx[i] - sx[0])
      sy[i] = sy[0] + sigma * (sy[i] - sy[0])
      sf[i] = f(sx[i], sy[i])
    }
  }
  // Return best point
  let mut best_idx = 0
  for i = 1; i < 3; i = i + 1 {
    if sf[i] < sf[best_idx] {
      best_idx = i
    }
  }
  (sx[best_idx], sy[best_idx])
}
