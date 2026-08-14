// ============================================================
// Reference Points Calculation and Summary
// ============================================================

///|
/// Compute biological & economic reference points from Schaefer model result.
pub fn calculate_schaefer_reference_points(
  model_result : @types.ModelResult,
  price_per_unit_catch : Double,
  cost_per_unit_effort : Double,
) -> @types.ReferencePoints {
  let params = model_result.params
  let msy = @surplus.schaefer_msy(params)
  let bmsy = @surplus.schaefer_bmsy(params)
  let fmsy = @surplus.schaefer_fmsy(params)
  let emsy = @surplus.schaefer_emsy(params)
  let mey = @surplus.schaefer_mey(
    params, price_per_unit_catch, cost_per_unit_effort,
  )

  let bio_len = model_result.biomass_series.length()
  let curr_b = if bio_len > 0 {
    model_result.biomass_series[bio_len - 1]
  } else {
    bmsy
  }
  let ratio = curr_b / bmsy

  @types.ReferencePoints::new(msy, bmsy, fmsy, emsy, mey, ratio)
}

///|
/// Compute reference points from Pella-Tomlinson model result.
pub fn calculate_pella_tomlinson_reference_points(
  model_result : @types.ModelResult,
) -> @types.ReferencePoints {
  let params = model_result.params
  let msy = @surplus.pella_tomlinson_msy(params)
  let bmsy = @surplus.pella_tomlinson_bmsy(params)
  let fmsy = @surplus.pella_tomlinson_fmsy(params)
  let emsy = if params.q > 0.0 { fmsy / params.q } else { 0.0 }
  let mey = msy * 0.95 // approximation

  let bio_len = model_result.biomass_series.length()
  let curr_b = if bio_len > 0 {
    model_result.biomass_series[bio_len - 1]
  } else {
    bmsy
  }
  let ratio = curr_b / bmsy

  @types.ReferencePoints::new(msy, bmsy, fmsy, emsy, mey, ratio)
}
