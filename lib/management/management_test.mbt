// Unit tests for HCR and TAC recommendation

///|
test "Constant F HCR evaluation" {
  let rule = @types.HarvestRule::ConstantF(0.2)
  let f = evaluate_hcr_f(rule, 1000.0, 0.001)
  let c = evaluate_hcr_catch(rule, 1000.0, 0.001)
  assert_eq(f, 0.2)
  assert_eq(c, 200.0)
}

///|
test "Threshold HCR evaluation" {
  let rule = @types.HarvestRule::ThresholdRule(200.0, 800.0, 0.4)
  // Below Blim => 0
  let f_below = evaluate_hcr_f(rule, 100.0, 0.001)
  assert_eq(f_below, 0.0)

  // Above Btarget => Fmax
  let f_above = evaluate_hcr_f(rule, 900.0, 0.001)
  assert_eq(f_above, 0.4)

  // Midpoint => Fmax / 2
  let f_mid = evaluate_hcr_f(rule, 500.0, 0.001)
  assert_eq(f_mid, 0.2)
}

///|
test "TAC calculation" {
  let params = @types.ModelParams::schaefer(0.5, 1000.0, 0.001)
  let model_res = @types.ModelResult::new(
    params,
    [1000.0, 900.0, 800.0],
    [1.0, 0.9, 0.8],
    [0.0, 0.0, 0.0],
    0.0,
    0.0,
    0.0,
  )
  let scenario = @types.ManagementScenario::new(
    "TargetF",
    @types.HarvestRule::ConstantF(0.2),
    10,
    0.05,
  )
  let rec = calculate_tac(model_res, scenario) catch {
    _ => TACRecommendation::new("err", 0.0, 0.0, 0.0, "err")
  }
  assert_eq(rec.recommended_tac, 160.0)
  assert_eq(rec.status, "Sustainable")
}
