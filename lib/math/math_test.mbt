// Unit tests for math utilities

///|
test "basic math operations" {
  assert_eq(abs_double(-5.5), 5.5)
  assert_eq(min_double(3.0, 7.0), 3.0)
  assert_eq(max_double(3.0, 7.0), 7.0)
  assert_eq(clamp(15.0, 0.0, 10.0), 10.0)
  assert_eq(clamp(-5.0, 0.0, 10.0), 0.0)
  assert_eq(clamp(5.0, 0.0, 10.0), 5.0)
}

///|
test "sqrt_approx accuracy" {
  let val = sqrt_approx(16.0)
  let diff = abs_double(val - 4.0)
  assert_true(diff < 1.0e-5)
}

///|
test "ln and exp inverse property" {
  let x = 5.0
  let lnx = ln_approx(x)
  let exp_lnx = exp_approx(lnx)
  let diff = abs_double(exp_lnx - x)
  assert_true(diff < 1.0e-3)
}

///|
test "pow_double integer power" {
  let res = pow_double(2.0, 3.0)
  let diff = abs_double(res - 8.0)
  assert_true(diff < 1.0e-3)
}

///|
test "statistics mean and variance" {
  let data = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]
  let m = mean(data)
  assert_eq(m, 5.0)
  let v = variance(data)
  assert_eq(v, 4.0)
  let sd = std_dev(data)
  assert_eq(sd, 2.0)
}

///|
test "matrix vector operations" {
  let v1 = [1.0, 2.0, 3.0]
  let v2 = [4.0, 5.0, 6.0]
  let dot = dot_product(v1, v2)
  assert_eq(dot, 32.0)
}

///|
test "linear regression fit" {
  let x = [1.0, 2.0, 3.0, 4.0, 5.0]
  let y = [2.0, 4.0, 6.0, 8.0, 10.0]
  let (slope, intercept, r2) = linear_regression(x, y)
  assert_true(abs_double(slope - 2.0) < 1.0e-4)
  assert_true(abs_double(intercept - 0.0) < 1.0e-4)
  assert_true(abs_double(r2 - 1.0) < 1.0e-4)
}

///|
test "golden section search 1D optimization" {
  // f(x) = (x - 3)^2
  let f = fn(x : Double) { (x - 3.0) * (x - 3.0) }
  let min_x = golden_section_search(f, 0.0, 5.0, 1.0e-4)
  assert_true(abs_double(min_x - 3.0) < 1.0e-3)
}

///|
test "PRNG output range" {
  let rng = PRNG::new(12345)
  for i = 0; i < 50; i = i + 1 {
    let u = rng.next_double()
    assert_true(u >= 0.0 && u < 1.0)
  }
}
