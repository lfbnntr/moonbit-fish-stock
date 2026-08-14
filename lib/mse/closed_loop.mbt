// ============================================================
// Closed-Loop Simulation Engine for Management Strategy Evaluation (MSE)
// ============================================================

///|
/// Performance metrics for evaluating a Management Strategy.
pub(all) struct MSEPerformanceMetrics {
  mean_catch : Double
  catch_aav : Double // Average Annual Variation in Catch: mean(|C_t - C_{t-1}| / C_t)
  prob_above_bmsy : Double
  prob_below_blim : Double
  final_depletion : Double
} derive(Eq)

///|
pub fn MSEPerformanceMetrics::new(
  mean_catch : Double,
  catch_aav : Double,
  prob_above_bmsy : Double,
  prob_below_blim : Double,
  final_depletion : Double,
) -> MSEPerformanceMetrics {
  { mean_catch, catch_aav, prob_above_bmsy, prob_below_blim, final_depletion }
}

///|
/// Run a closed-loop MSE simulation over multiple replicates.
pub fn run_closed_loop_mse(
  true_params : @types.ModelParams,
  scenario : @types.ManagementScenario,
  config : @types.SimulationConfig,
  seed : Int,
) -> @types.ProjectionResult raise @types.ErrorType {
  @types.validate_simulation_config(config)
  @types.validate_management_scenario(scenario)

  let prng = @math.PRNG::new(seed)
  let n_years = config.n_years
  let n_reps = config.n_replicates
  let bmsy = true_params.k / 2.0

  let years : Array[Int] = []
  for y = 0; y < n_years; y = y + 1 {
    years.push(2026 + y)
  }

  let biomass_trajectories : Array[Array[Double]] = []
  let catch_trajectories : Array[Array[Double]] = []

  for _rep = 0; _rep < n_reps; _rep = _rep + 1 {
    let init_b = true_params.k * config.initial_depletion
    let om = OperatingModel::new(true_params, init_b, config)
    let rep_b : Array[Double] = []
    let rep_c : Array[Double] = []

    for y = 0; y < n_years; y = y + 1 {
      let b_curr = om.current_biomass
      rep_b.push(b_curr)
      let target_c = @management.evaluate_hcr_catch(
        scenario.rule,
        b_curr,
        true_params.q,
      )
      let c_realized = if target_c > b_curr { b_curr * 0.9 } else { target_c }
      rep_c.push(c_realized)
      let _ = om.step_operating_model(c_realized, prng)
    }
    biomass_trajectories.push(rep_b)
    catch_trajectories.push(rep_c)
  }

  let median_biomass : Array[Double] = []
  let median_catch : Array[Double] = []
  let prob_above_bmsy : Array[Double] = []

  for y = 0; y < n_years; y = y + 1 {
    let year_b : Array[Double] = []
    let year_c : Array[Double] = []
    let mut count_above = 0
    for r = 0; r < n_reps; r = r + 1 {
      let b_val = biomass_trajectories[r][y]
      year_b.push(b_val)
      year_c.push(catch_trajectories[r][y])
      if b_val >= bmsy {
        count_above = count_above + 1
      }
    }
    median_biomass.push(@math.mean(year_b))
    median_catch.push(@math.mean(year_c))
    prob_above_bmsy.push(count_above.to_double() / n_reps.to_double())
  }

  @types.ProjectionResult::new(
    years, biomass_trajectories, catch_trajectories, median_biomass, median_catch,
    prob_above_bmsy,
  )
}
