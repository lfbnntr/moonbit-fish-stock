// ============================================================
// Operating Model (OM) for Closed-Loop MSE Simulation
// ============================================================

///|
/// Operating Model state containing true underlying population parameters and current state.
pub(all) struct OperatingModel {
  params : @types.ModelParams
  mut current_biomass : Double
  config : @types.SimulationConfig
} derive(Eq)

///|
pub fn OperatingModel::new(
  params : @types.ModelParams,
  initial_biomass : Double,
  config : @types.SimulationConfig,
) -> OperatingModel {
  { params, current_biomass: initial_biomass, config }
}

///|
/// Advance the Operating Model by one timestep given actual realized catch.
/// Applies process error to biomass dynamics.
pub fn OperatingModel::step_operating_model(
  self : OperatingModel,
  catch_realized : Double,
  prng : @math.PRNG,
) -> Double {
  let r = self.params.r
  let k = self.params.k
  let b = self.current_biomass
  let growth = r * b * (1.0 - b / k)
  let b_next_true = b + growth - catch_realized

  let process_err = if self.config.process_error > 0.0 {
    let z = prng.next_normal(0.0, self.config.process_error)
    @math.exp_approx(z)
  } else {
    1.0
  }

  let b_stochastic = b_next_true * process_err
  let b_clamped = if b_stochastic < 1.0e-6 { 1.0e-6 } else { b_stochastic }
  self.current_biomass = b_clamped
  b_clamped
}

///|
/// Generate noisy observation of CPUE with observation error.
/// Observed CPUE = q * B * exp(observation_error * Z)
pub fn OperatingModel::observe_cpue(
  self : OperatingModel,
  prng : @math.PRNG,
) -> Double {
  let true_cpue = self.params.q * self.current_biomass
  if self.config.observation_error > 0.0 {
    let z = prng.next_normal(0.0, self.config.observation_error)
    let observed = true_cpue * @math.exp_approx(z)
    if observed < 1.0e-6 {
      1.0e-6
    } else {
      observed
    }
  } else {
    true_cpue
  }
}
