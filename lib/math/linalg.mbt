///|
/// Matrix struct for simple linear algebra operations
pub struct Matrix {
  rows : Int
  cols : Int
  data : Array[Double]
}

///|
/// Create a new matrix filled with zeros
pub fn Matrix::new(rows : Int, cols : Int) -> Matrix {
  { rows, cols, data: Array::make(rows * cols, 0.0) }
}

///|
/// Create a matrix from a flat array of values (row-major order)
pub fn Matrix::from_array(
  rows : Int,
  cols : Int,
  values : Array[Double],
) -> Matrix {
  let data = Array::make(rows * cols, 0.0)
  let n = min_double((rows * cols).to_double(), values.length().to_double()).to_int()
  for i = 0; i < n; i = i + 1 {
    data[i] = values[i]
  }
  { rows, cols, data }
}

///|
/// Create an identity matrix of size n x n
pub fn Matrix::identity(n : Int) -> Matrix {
  let m = Matrix::new(n, n)
  for i = 0; i < n; i = i + 1 {
    m.data[i * n + i] = 1.0
  }
  m
}

///|
/// Get the value at (row, col)
pub fn Matrix::get(self : Matrix, row : Int, col : Int) -> Double {
  self.data[row * self.cols + col]
}

///|
/// Set the value at (row, col)
pub fn Matrix::set(self : Matrix, row : Int, col : Int, value : Double) -> Unit {
  self.data[row * self.cols + col] = value
}

///|
/// Add two matrices (must have same dimensions)
pub fn Matrix::add(self : Matrix, other : Matrix) -> Matrix {
  let result = Matrix::new(self.rows, self.cols)
  let n = self.rows * self.cols
  for i = 0; i < n; i = i + 1 {
    result.data[i] = self.data[i] + other.data[i]
  }
  result
}

///|
/// Subtract another matrix from this one
pub fn Matrix::subtract(self : Matrix, other : Matrix) -> Matrix {
  let result = Matrix::new(self.rows, self.cols)
  let n = self.rows * self.cols
  for i = 0; i < n; i = i + 1 {
    result.data[i] = self.data[i] - other.data[i]
  }
  result
}

///|
/// Multiply two matrices (self.cols must equal other.rows)
pub fn Matrix::multiply(self : Matrix, other : Matrix) -> Matrix {
  let result = Matrix::new(self.rows, other.cols)
  for i = 0; i < self.rows; i = i + 1 {
    for j = 0; j < other.cols; j = j + 1 {
      let mut s = 0.0
      for k = 0; k < self.cols; k = k + 1 {
        s = s + self.get(i, k) * other.get(k, j)
      }
      result.set(i, j, s)
    }
  }
  result
}

///|
/// Scale a matrix by a scalar value
pub fn Matrix::scale(self : Matrix, scalar : Double) -> Matrix {
  let result = Matrix::new(self.rows, self.cols)
  let n = self.rows * self.cols
  for i = 0; i < n; i = i + 1 {
    result.data[i] = self.data[i] * scalar
  }
  result
}

///|
/// Transpose the matrix
pub fn Matrix::transpose(self : Matrix) -> Matrix {
  let result = Matrix::new(self.cols, self.rows)
  for i = 0; i < self.rows; i = i + 1 {
    for j = 0; j < self.cols; j = j + 1 {
      result.set(j, i, self.get(i, j))
    }
  }
  result
}

///|
/// Dot product of two arrays (treated as vectors)
pub fn dot_product(a : Array[Double], b : Array[Double]) -> Double {
  let n = min_double(a.length().to_double(), b.length().to_double()).to_int()
  let mut s = 0.0
  for i = 0; i < n; i = i + 1 {
    s = s + a[i] * b[i]
  }
  s
}

///|
/// Euclidean norm of a vector
pub fn vector_norm(v : Array[Double]) -> Double {
  let mut s = 0.0
  for i = 0; i < v.length(); i = i + 1 {
    s = s + v[i] * v[i]
  }
  sqrt_approx(s)
}

///|
/// Determinant of a 2x2 matrix
/// | a  b |
/// | c  d |  = ad - bc
pub fn determinant_2x2(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
) -> Double {
  a * d - b * c
}

///|
/// Determinant of a 3x3 matrix (given as a Matrix struct)
pub fn determinant_3x3(m : Matrix) -> Double {
  let a = m.get(0, 0)
  let b = m.get(0, 1)
  let c = m.get(0, 2)
  let d = m.get(1, 0)
  let e = m.get(1, 1)
  let f = m.get(1, 2)
  let g = m.get(2, 0)
  let h = m.get(2, 1)
  let k = m.get(2, 2)
  a * (e * k - f * h) - b * (d * k - f * g) + c * (d * h - e * g)
}

///|
/// Solve a 2x2 linear system:
///   a*x + b*y = e
///   c*x + d*y = f
/// Returns (x, y) or (0, 0) if singular
pub fn solve_2x2(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  e : Double,
  f : Double,
) -> (Double, Double) {
  let det = determinant_2x2(a, b, c, d)
  if abs_double(det) < epsilon {
    return (0.0, 0.0) // Singular system
  }
  let x = (e * d - b * f) / det
  let y = (a * f - e * c) / det
  (x, y)
}

///|
/// Ordinary least squares linear regression
/// Returns (slope, intercept, r_squared)
pub fn linear_regression(
  x : Array[Double],
  y : Array[Double],
) -> (Double, Double, Double) {
  let n = min_double(x.length().to_double(), y.length().to_double()).to_int()
  if n < 2 {
    return (0.0, 0.0, 0.0)
  }
  let nd = n.to_double()
  let mut sx = 0.0
  let mut sy = 0.0
  let mut sxy = 0.0
  let mut sxx = 0.0
  let mut syy = 0.0
  for i = 0; i < n; i = i + 1 {
    sx = sx + x[i]
    sy = sy + y[i]
    sxy = sxy + x[i] * y[i]
    sxx = sxx + x[i] * x[i]
    syy = syy + y[i] * y[i]
  }
  let denom = nd * sxx - sx * sx
  if abs_double(denom) < epsilon {
    return (0.0, sy / nd, 0.0)
  }
  let slope = (nd * sxy - sx * sy) / denom
  let intercept = (sy - slope * sx) / nd
  // R-squared computation
  let ss_tot = syy - sy * sy / nd
  let ss_reg = slope * slope * (sxx - sx * sx / nd)
  let r_squared = if abs_double(ss_tot) < epsilon {
    1.0
  } else {
    clamp(ss_reg / ss_tot, 0.0, 1.0)
  }
  (slope, intercept, r_squared)
}
