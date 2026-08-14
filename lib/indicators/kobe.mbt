// ============================================================
// Kobe Plot Status Indicators & Classification
// ============================================================

///|
/// Kobe plot quadrant status enum.
pub(all) enum KobeQuadrant {
  Green // Healthy: B >= B_MSY, F <= F_MSY
  Yellow // Overfishing: B >= B_MSY, F > F_MSY
  Orange // Overfished: B < B_MSY, F <= F_MSY
  Red // Overfished & Overfishing: B < B_MSY, F > F_MSY
} derive(Eq)

///|
pub impl Show for KobeQuadrant with fn output(self, logger) {
  match self {
    Green => logger.write_string("Green (Healthy)")
    Yellow => logger.write_string("Yellow (Overfishing)")
    Orange => logger.write_string("Orange (Overfished)")
    Red => logger.write_string("Red (Overfished & Overfishing)")
  }
}

///|
/// A single year's Kobe plot coordinate (B/B_MSY, F/F_MSY).
pub(all) struct KobePoint {
  year : Int
  b_ratio : Double // B / B_MSY
  f_ratio : Double // F / F_MSY
  quadrant : KobeQuadrant
} derive(Eq)

///|
pub fn KobePoint::new(
  year : Int,
  b_ratio : Double,
  f_ratio : Double,
) -> KobePoint {
  let q = if b_ratio >= 1.0 && f_ratio <= 1.0 {
    KobeQuadrant::Green
  } else if b_ratio >= 1.0 && f_ratio > 1.0 {
    KobeQuadrant::Yellow
  } else if b_ratio < 1.0 && f_ratio <= 1.0 {
    KobeQuadrant::Orange
  } else {
    KobeQuadrant::Red
  }
  { year, b_ratio, f_ratio, quadrant: q }
}

///|
/// Compute Kobe plot trajectory for a stock given biomass, catch, and reference points.
pub fn compute_kobe_trajectory(
  years : Array[Int],
  biomass : Array[Double],
  catches : Array[Double],
  ref_pts : @types.ReferencePoints,
) -> Array[KobePoint] raise @types.ErrorType {
  let n = years.length()
  if n == 0 {
    raise @types.ErrorType::InsufficientData("Empty years array")
  }
  @types.validate_same_length(years, catches, "years", "catches")
  let trajectory : Array[KobePoint] = []
  for i = 0; i < n; i = i + 1 {
    let b_t = if i < biomass.length() { biomass[i] } else { 1.0 }
    let b_ratio = b_t / ref_pts.bmsy
    let f_t = if b_t > 0.0 { catches[i] / b_t } else { 0.0 }
    let f_ratio = f_t / ref_pts.fmsy
    trajectory.push(KobePoint::new(years[i], b_ratio, f_ratio))
  }
  trajectory
}

///|
/// Calculate probability of stock being in the Green Kobe quadrant across a trajectory.
pub fn green_quadrant_probability(trajectory : Array[KobePoint]) -> Double {
  let n = trajectory.length()
  if n == 0 {
    return 0.0
  }
  let mut green_count = 0
  for i = 0; i < n; i = i + 1 {
    match trajectory[i].quadrant {
      Green => green_count = green_count + 1
      _ => ()
    }
  }
  green_count.to_double() / n.to_double()
}
