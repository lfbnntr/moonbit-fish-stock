// Unit tests for CPUE standardization and indices

///|
test "raw CPUE computation" {
  let c = raw_cpue(100.0, 20.0) catch { _ => 0.0 }
  assert_eq(c, 5.0)
}

///|
test "compute CPUE series" {
  let catches = [100.0, 200.0, 150.0]
  let efforts = [10.0, 20.0, 15.0]
  let cpues = compute_cpue_series(catches, efforts) catch { _ => [] }
  assert_eq(cpues, [10.0, 10.0, 10.0])
}

///|
test "geometric mean CPUE" {
  let series = [10.0, 10.0, 10.0]
  let gmean = geometric_mean_cpue(series) catch { _ => 0.0 }
  let diff = @math.abs_double(gmean - 10.0)
  assert_true(diff < 1.0e-3)
}

///|
test "normalize CPUE" {
  let series = [5.0, 10.0, 15.0]
  let norm = normalize_cpue(series) catch { _ => [] }
  assert_eq(norm, [0.5, 1.0, 1.5])
}

///|
test "CPUE trend analysis" {
  let series = [1.0, 2.0, 3.0, 4.0, 5.0]
  let res = cpue_trend_analysis(series) catch {
    _ =>
      { slope: 0.0, intercept: 0.0, r_squared: 0.0, trend_direction: "error" }
  }
  assert_eq(res.trend_direction, "increasing")
  assert_true(@math.abs_double(res.slope - 1.0) < 1.0e-3)
}
