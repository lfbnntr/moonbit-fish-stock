// ============================================================
// Total Allowable Catch (TAC) Calculator
// ============================================================

///|
/// TAC recommendation struct.
pub(all) struct TACRecommendation {
  scenario_name : String
  recommended_tac : Double
  target_f : Double
  projected_biomass : Double
  status : String
} derive(Eq)

///|
pub fn TACRecommendation::new(
  scenario_name : String,
  recommended_tac : Double,
  target_f : Double,
  projected_biomass : Double,
  status : String,
) -> TACRecommendation {
  { scenario_name, recommended_tac, target_f, projected_biomass, status }
}

///|
/// Compute TAC recommendation for a stock given current assessment model result and scenario.
pub fn calculate_tac(
  model_result : @types.ModelResult,
  scenario : @types.ManagementScenario,
) -> TACRecommendation raise @types.ErrorType {
  @types.validate_management_scenario(scenario)
  let n_bio = model_result.biomass_series.length()
  let curr_b = if n_bio > 0 {
    model_result.biomass_series[n_bio - 1]
  } else {
    model_result.params.k
  }
  let target_f = evaluate_hcr_f(scenario.rule, curr_b, model_result.params.q)
  let tac = evaluate_hcr_catch(scenario.rule, curr_b, model_result.params.q)

  let b_next = curr_b +
    model_result.params.r * curr_b * (1.0 - curr_b / model_result.params.k) -
    tac
  let b_next_safe = if b_next < 1.0e-6 { 1.0e-6 } else { b_next }

  let bmsy = model_result.params.k / 2.0
  let status_str = if b_next_safe >= bmsy {
    "Sustainable"
  } else if b_next_safe >= bmsy * 0.5 {
    "Rebuilding Needed"
  } else {
    "Overfished"
  }

  TACRecommendation::new(scenario.name, tac, target_f, b_next_safe, status_str)
}
