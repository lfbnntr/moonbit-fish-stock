// Unit tests for bootstrap resampling and uncertainty analysis

///|
test "Analyze bootstrap samples" {
  let samples = [10.0, 12.0, 11.0, 9.0, 13.0, 10.5, 11.5, 9.5]
  let result = analyze_bootstrap_samples(samples, 0.05) catch {
    _ => @types.BootstrapResult::new(0.0, 0.0, 0.0, 0.0, [])
  }
  assert_true(result.point_estimate > 10.0 && result.point_estimate < 12.0)
  assert_true(result.ci_lower <= result.ci_upper)
  assert_true(result.std_error > 0.0)
}

///|
test "Residual bootstrap CPUE generation" {
  let params = @types.ModelParams::schaefer(0.5, 1000.0, 0.001)
  let bio = [1000.0, 900.0, 850.0]
  let pred = [1.0, 0.9, 0.85]
  let res = [0.05, -0.02, 0.01]
  let model_res = @types.ModelResult::new(
    params, bio, pred, res, 0.003, 10.0, 12.0,
  )
  let prng = @math.PRNG::new(42)
  let bootstrapped = residual_bootstrap_cpue(model_res, 5, prng) catch {
    _ => []
  }
  assert_eq(bootstrapped.length(), 5)
  assert_eq(bootstrapped[0].length(), 3)
}
