// ============================================================
// Core Data Types for Fishery Stock Assessment
// ============================================================

///|
/// Error types for typed error handling throughout the library.
pub(all) suberror ErrorType {
  InvalidParameter(String)
  InsufficientData(String)
  ConvergenceFailed(String)
  NumericalError(String)
  OutOfRange(String)
  InvalidState(String)
} derive(Eq)

///|
/// Show implementation for ErrorType.
pub impl Show for ErrorType with fn output(self, logger) {
  match self {
    InvalidParameter(msg) => logger.write_string("InvalidParameter: " + msg)
    InsufficientData(msg) => logger.write_string("InsufficientData: " + msg)
    ConvergenceFailed(msg) => logger.write_string("ConvergenceFailed: " + msg)
    NumericalError(msg) => logger.write_string("NumericalError: " + msg)
    OutOfRange(msg) => logger.write_string("OutOfRange: " + msg)
    InvalidState(msg) => logger.write_string("InvalidState: " + msg)
  }
}

// ------------------------------------------------------------
// Catch Data Records
// ------------------------------------------------------------

///|
/// A single year's catch record with effort and CPUE.
pub(all) struct CatchRecord {
  year : Int
  catch_amount : Double
  effort : Double
  cpue : Double
} derive(Eq)

///|
pub impl Show for CatchRecord with fn output(self, logger) {
  logger.write_string("CatchRecord { year: ")
  logger.write_string(self.year.to_string())
  logger.write_string(", catch: ")
  logger.write_string(self.catch_amount.to_string())
  logger.write_string(", effort: ")
  logger.write_string(self.effort.to_string())
  logger.write_string(", cpue: ")
  logger.write_string(self.cpue.to_string())
  logger.write_string(" }")
}

///|
/// Factory function for CatchRecord.
pub fn CatchRecord::new(
  year : Int,
  catch_amount : Double,
  effort : Double,
) -> CatchRecord {
  let cpue = if effort > 0.0 { catch_amount / effort } else { 0.0 }
  { year, catch_amount, effort, cpue }
}

// ------------------------------------------------------------
// Stock Time Series
// ------------------------------------------------------------

///|
/// Time series of stock data across multiple years.
pub(all) struct StockSeries {
  years : Array[Int]
  catch_data : Array[Double]
  effort_data : Array[Double]
  cpue_data : Array[Double]
} derive(Eq)

///|
pub impl Show for StockSeries with fn output(self, logger) {
  logger.write_string("StockSeries { n=")
  logger.write_string(self.years.length().to_string())
  if self.years.length() > 0 {
    logger.write_string(", years=")
    logger.write_string(self.years[0].to_string())
    logger.write_string("-")
    logger.write_string(self.years[self.years.length() - 1].to_string())
  }
  logger.write_string(" }")
}

///|
/// Create an empty StockSeries.
pub fn StockSeries::empty() -> StockSeries {
  { years: [], catch_data: [], effort_data: [], cpue_data: [] }
}

// ------------------------------------------------------------
// Model Parameters (Surplus Production Models)
// ------------------------------------------------------------

///|
/// Parameters for surplus production models.
/// - r: intrinsic growth rate
/// - k: carrying capacity
/// - q: catchability coefficient
/// - sigma: process error std deviation
/// - n: shape parameter for Pella-Tomlinson (n=2 => Schaefer)
pub(all) struct ModelParams {
  r : Double
  k : Double
  q : Double
  sigma : Double
  n : Double
} derive(Eq)

///|
pub impl Show for ModelParams with fn output(self, logger) {
  logger.write_string("ModelParams { r=")
  logger.write_string(self.r.to_string())
  logger.write_string(", K=")
  logger.write_string(self.k.to_string())
  logger.write_string(", q=")
  logger.write_string(self.q.to_string())
  logger.write_string(", sigma=")
  logger.write_string(self.sigma.to_string())
  logger.write_string(", n=")
  logger.write_string(self.n.to_string())
  logger.write_string(" }")
}

///|
/// Create Schaefer model params (n=2).
pub fn ModelParams::schaefer(r : Double, k : Double, q : Double) -> ModelParams {
  { r, k, q, sigma: 0.01, n: 2.0 }
}

///|
/// Create Fox model params (n=1).
pub fn ModelParams::fox(r : Double, k : Double, q : Double) -> ModelParams {
  { r, k, q, sigma: 0.01, n: 1.0 }
}

///|
/// Create Pella-Tomlinson model params with custom n.
pub fn ModelParams::pella_tomlinson(
  r : Double,
  k : Double,
  q : Double,
  n : Double,
) -> ModelParams {
  { r, k, q, sigma: 0.01, n }
}

// ------------------------------------------------------------
// Model Results
// ------------------------------------------------------------

///|
/// Results from fitting a surplus production model.
pub(all) struct ModelResult {
  params : ModelParams
  biomass_series : Array[Double]
  predicted_cpue : Array[Double]
  residuals : Array[Double]
  sse : Double
  aic : Double
  bic : Double
} derive(Eq)

///|
pub fn ModelResult::new(
  params : ModelParams,
  biomass_series : Array[Double],
  predicted_cpue : Array[Double],
  residuals : Array[Double],
  sse : Double,
  aic : Double,
  bic : Double,
) -> ModelResult {
  { params, biomass_series, predicted_cpue, residuals, sse, aic, bic }
}

///|
pub impl Show for ModelResult with fn output(self, logger) {
  logger.write_string("ModelResult { sse=")
  logger.write_string(self.sse.to_string())
  logger.write_string(", aic=")
  logger.write_string(self.aic.to_string())
  logger.write_string(", bic=")
  logger.write_string(self.bic.to_string())
  logger.write_string(" }")
}

// ------------------------------------------------------------
// Reference Points
// ------------------------------------------------------------

///|
/// Biological and economic reference points.
pub(all) struct ReferencePoints {
  msy : Double
  bmsy : Double
  fmsy : Double
  emsy : Double
  mey : Double
  current_biomass_ratio : Double
} derive(Eq)

///|
pub fn ReferencePoints::new(
  msy : Double,
  bmsy : Double,
  fmsy : Double,
  emsy : Double,
  mey : Double,
  current_biomass_ratio : Double,
) -> ReferencePoints {
  { msy, bmsy, fmsy, emsy, mey, current_biomass_ratio }
}

///|
pub impl Show for ReferencePoints with fn output(self, logger) {
  logger.write_string("ReferencePoints { MSY=")
  logger.write_string(self.msy.to_string())
  logger.write_string(", Bmsy=")
  logger.write_string(self.bmsy.to_string())
  logger.write_string(", Fmsy=")
  logger.write_string(self.fmsy.to_string())
  logger.write_string(", B/Bmsy=")
  logger.write_string(self.current_biomass_ratio.to_string())
  logger.write_string(" }")
}

// ------------------------------------------------------------
// CPUE & Index Types
// ------------------------------------------------------------

///|
pub(all) struct AbundanceIndex {
  year : Int
  cpue : Double
  abundance : Double
  lower_ci : Double
  upper_ci : Double
} derive(Eq)

///|
pub fn AbundanceIndex::new(
  year : Int,
  cpue : Double,
  abundance : Double,
  lower_ci : Double,
  upper_ci : Double,
) -> AbundanceIndex {
  { year, cpue, abundance, lower_ci, upper_ci }
}

///|
pub(all) struct CpueComparison {
  nominal : Array[Double]
  standardized : Array[Double]
  correlation : Double
  bias : Double
} derive(Eq)

///|
pub fn CpueComparison::new(
  nominal : Array[Double],
  standardized : Array[Double],
  correlation : Double,
  bias : Double,
) -> CpueComparison {
  { nominal, standardized, correlation, bias }
}

///|
pub(all) struct TrendResult {
  slope : Double
  intercept : Double
  r_squared : Double
  trend_direction : String
} derive(Eq)

///|
pub fn TrendResult::new(
  slope : Double,
  intercept : Double,
  r_squared : Double,
  trend_direction : String,
) -> TrendResult {
  { slope, intercept, r_squared, trend_direction }
}

// ------------------------------------------------------------
// Harvest Rules and Management
// ------------------------------------------------------------

///|
/// Harvest control rules for management strategies.
pub(all) enum HarvestRule {
  ConstantCatch(Double)
  ConstantEffort(Double)
  ConstantF(Double)
  ThresholdRule(Double, Double, Double) // blim, btarget, fmax
  SlotRule(Double, Double) // min_size, max_size
} derive(Eq)

///|
pub impl Show for HarvestRule with fn output(self, logger) {
  match self {
    ConstantCatch(c) => {
      logger.write_string("ConstantCatch(")
      logger.write_string(c.to_string())
      logger.write_string(")")
    }
    ConstantEffort(e) => {
      logger.write_string("ConstantEffort(")
      logger.write_string(e.to_string())
      logger.write_string(")")
    }
    ConstantF(f) => {
      logger.write_string("ConstantF(")
      logger.write_string(f.to_string())
      logger.write_string(")")
    }
    ThresholdRule(blim, btarget, fmax) => {
      logger.write_string("ThresholdRule(blim=")
      logger.write_string(blim.to_string())
      logger.write_string(", btarget=")
      logger.write_string(btarget.to_string())
      logger.write_string(", fmax=")
      logger.write_string(fmax.to_string())
      logger.write_string(")")
    }
    SlotRule(min_s, max_s) => {
      logger.write_string("SlotRule(")
      logger.write_string(min_s.to_string())
      logger.write_string("-")
      logger.write_string(max_s.to_string())
      logger.write_string(")")
    }
  }
}

///|
/// A management scenario combining rule and projection horizon.
pub(all) struct ManagementScenario {
  name : String
  rule : HarvestRule
  projection_years : Int
  discount_rate : Double
} derive(Eq)

///|
pub fn ManagementScenario::new(
  name : String,
  rule : HarvestRule,
  projection_years : Int,
  discount_rate : Double,
) -> ManagementScenario {
  { name, rule, projection_years, discount_rate }
}

// ------------------------------------------------------------
// Bootstrap / Uncertainty
// ------------------------------------------------------------

///|
/// Result of bootstrap uncertainty analysis.
pub(all) struct BootstrapResult {
  point_estimate : Double
  ci_lower : Double
  ci_upper : Double
  std_error : Double
  samples : Array[Double]
} derive(Eq)

///|
pub fn BootstrapResult::new(
  point_estimate : Double,
  ci_lower : Double,
  ci_upper : Double,
  std_error : Double,
  samples : Array[Double],
) -> BootstrapResult {
  { point_estimate, ci_lower, ci_upper, std_error, samples }
}

///|
pub impl Show for BootstrapResult with fn output(self, logger) {
  logger.write_string("BootstrapResult { estimate=")
  logger.write_string(self.point_estimate.to_string())
  logger.write_string(", CI=[")
  logger.write_string(self.ci_lower.to_string())
  logger.write_string(", ")
  logger.write_string(self.ci_upper.to_string())
  logger.write_string("], se=")
  logger.write_string(self.std_error.to_string())
  logger.write_string(" }")
}

// ------------------------------------------------------------
// Simulation and Projection
// ------------------------------------------------------------

///|
/// Configuration for forward simulation.
pub(all) struct SimulationConfig {
  n_years : Int
  n_replicates : Int
  process_error : Double
  observation_error : Double
  initial_depletion : Double
} derive(Eq)

///|
/// Create a default simulation config.
pub fn SimulationConfig::default() -> SimulationConfig {
  {
    n_years: 20,
    n_replicates: 1000,
    process_error: 0.1,
    observation_error: 0.2,
    initial_depletion: 0.5,
  }
}

///|
/// Result of a forward projection.
pub(all) struct ProjectionResult {
  years : Array[Int]
  biomass_trajectories : Array[Array[Double]]
  catch_trajectories : Array[Array[Double]]
  median_biomass : Array[Double]
  median_catch : Array[Double]
  prob_above_bmsy : Array[Double]
} derive(Eq)

///|
pub fn ProjectionResult::new(
  years : Array[Int],
  biomass_trajectories : Array[Array[Double]],
  catch_trajectories : Array[Array[Double]],
  median_biomass : Array[Double],
  median_catch : Array[Double],
  prob_above_bmsy : Array[Double],
) -> ProjectionResult {
  {
    years,
    biomass_trajectories,
    catch_trajectories,
    median_biomass,
    median_catch,
    prob_above_bmsy,
  }
}
