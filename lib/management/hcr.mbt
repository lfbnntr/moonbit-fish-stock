// ============================================================
// Harvest Control Rules (HCR) & Management Strategies
// ============================================================

///|
/// Evaluate fishing mortality F under a given Harvest Control Rule and current biomass.
pub fn evaluate_hcr_f(
  rule : @types.HarvestRule,
  current_biomass : Double,
  q_catchability : Double,
) -> Double {
  match rule {
    ConstantCatch(c) =>
      if current_biomass > 0.0 {
        let f = c / current_biomass
        if f > 2.0 {
          2.0
        } else {
          f
        }
      } else {
        0.0
      }
    ConstantEffort(e) => e * q_catchability
    ConstantF(f) => f
    ThresholdRule(blim, btarget, fmax) =>
      if current_biomass <= blim {
        0.0
      } else if current_biomass >= btarget {
        fmax
      } else {
        fmax * (current_biomass - blim) / (btarget - blim)
      }
    SlotRule(_, _) => 0.2
  }
}

///|
/// Evaluate target catch amount C under a given Harvest Control Rule and current biomass.
pub fn evaluate_hcr_catch(
  rule : @types.HarvestRule,
  current_biomass : Double,
  q_catchability : Double,
) -> Double {
  match rule {
    ConstantCatch(c) => c
    _ => {
      let f = evaluate_hcr_f(rule, current_biomass, q_catchability)
      f * current_biomass
    }
  }
}
