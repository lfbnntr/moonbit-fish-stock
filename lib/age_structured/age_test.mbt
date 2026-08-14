// Unit tests for age-structured models and recruitment

///|
test "Beverton-Holt recruitment computation" {
  let params = RecruitmentParams::beverton_holt(10.0, 0.001)
  let r = beverton_holt_recruitment(500.0, params) catch { _ => 0.0 }
  assert_eq(r, 5000.0 / 1.5)
}

///|
test "Ricker recruitment peak" {
  let params = RecruitmentParams::ricker(5.0, 0.002)
  let peak_s = ricker_peak_spawning_biomass(params)
  assert_eq(peak_s, 500.0)
}

///|
test "Age structure projection one year" {
  let weights = [0.1, 0.5, 1.0, 1.5, 2.0]
  let maturity = [0.0, 0.2, 0.8, 1.0, 1.0]
  let selectivity = [0.1, 0.5, 1.0, 1.0, 1.0]
  let cfg = AgeStructureConfig::new(5, 0.2, weights, maturity, selectivity)
  let initial_n = [1000.0, 800.0, 600.0, 400.0, 200.0]
  let ssb = calculate_ssb(initial_n, cfg)
  assert_true(ssb > 0.0)

  let next_n = project_age_structure_one_year(initial_n, 0.3, 1200.0, cfg) catch {
    _ => []
  }
  assert_eq(next_n.length(), 5)
  assert_eq(next_n[0], 1200.0)
}

///|
test "Baranov catch equation solver" {
  let f = solve_baranov_f(100.0, 1000.0, 0.2)
  assert_true(f > 0.0 && f < 1.0)
}
