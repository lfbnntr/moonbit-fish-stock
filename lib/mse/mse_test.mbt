// Unit tests for MSE closed-loop simulation framework

///|
test "Operating model single step and observation" {
  let params = @types.ModelParams::schaefer(0.5, 1000.0, 0.001)
  let cfg = @types.SimulationConfig::default()
  let om = OperatingModel::new(params, 500.0, cfg)
  let prng = @math.PRNG::new(123)

  let obs = om.observe_cpue(prng)
  assert_true(obs > 0.0)

  let b_next = om.step_operating_model(50.0, prng)
  assert_true(b_next > 0.0)
}

///|
test "Closed-loop MSE projection" {
  let params = @types.ModelParams::schaefer(0.5, 1000.0, 0.001)
  let scenario = @types.ManagementScenario::new(
    "ConstantF",
    @types.HarvestRule::ConstantF(0.2),
    5,
    0.05,
  )
  let cfg : @types.SimulationConfig = {
    n_years: 5,
    n_replicates: 10,
    process_error: 0.05,
    observation_error: 0.1,
    initial_depletion: 0.5,
  }
  let proj = run_closed_loop_mse(params, scenario, cfg, 42) catch {
    _ => @types.ProjectionResult::new([], [], [], [], [], [])
  }
  assert_eq(proj.years.length(), 5)
  assert_eq(proj.median_biomass.length(), 5)
  assert_eq(proj.median_catch.length(), 5)
  assert_true(proj.median_biomass[0] > 0.0)
}
