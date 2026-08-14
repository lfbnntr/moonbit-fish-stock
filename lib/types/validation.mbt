// ============================================================
// Input Validation Functions
// ============================================================

///|
/// Validate that a value is strictly positive.
pub fn validate_positive(value : Double, name : String) -> Unit raise ErrorType {
  if value <= 0.0 {
    raise InvalidParameter(name + " must be positive")
  }
}

///|
/// Validate that a value falls within [min, max].
pub fn validate_range(
  value : Double,
  min : Double,
  max : Double,
  name : String,
) -> Unit raise ErrorType {
  if value < min || value > max {
    raise OutOfRange(
      name + " must be between " + min.to_string() + " and " + max.to_string(),
    )
  }
}

///|
/// Validate that an array is non-empty.
pub fn[T] validate_non_empty(
  arr : Array[T],
  name : String,
) -> Unit raise ErrorType {
  if arr.is_empty() {
    raise InsufficientData(name + " must not be empty")
  }
}

///|
/// Validate that two arrays have the same length.
pub fn[T, U] validate_same_length(
  a : Array[T],
  b : Array[U],
  name_a : String,
  name_b : String,
) -> Unit raise ErrorType {
  if a.length() != b.length() {
    raise InvalidParameter(
      name_a + " and " + name_b + " must have the same length",
    )
  }
}

///|
/// Validate a CatchRecord.
pub fn validate_catch_record(rec : CatchRecord) -> Unit raise ErrorType {
  if rec.catch_amount < 0.0 {
    raise InvalidParameter("catch_amount must be non-negative")
  }
  if rec.effort < 0.0 {
    raise InvalidParameter("effort must be non-negative")
  }
  if rec.year < 1800 || rec.year > 2200 {
    raise OutOfRange("year must be between 1800 and 2200")
  }
}

///|
/// Validate a StockSeries for consistency and data quality.
pub fn validate_stock_series(series : StockSeries) -> Unit raise ErrorType {
  validate_non_empty(series.years, "years")
  validate_non_empty(series.catch_data, "catch_data")
  validate_non_empty(series.effort_data, "effort_data")
  let n = series.years.length()
  if series.catch_data.length() != n {
    raise InvalidParameter("catch_data length must match years length")
  }
  if series.effort_data.length() != n {
    raise InvalidParameter("effort_data length must match years length")
  }
  if series.cpue_data.length() > 0 && series.cpue_data.length() != n {
    raise InvalidParameter(
      "cpue_data length must match years length if provided",
    )
  }
  for i = 0; i < n; i = i + 1 {
    if series.catch_data[i] < 0.0 {
      raise InvalidParameter("catch_data contains negative values")
    }
    if series.effort_data[i] < 0.0 {
      raise InvalidParameter("effort_data contains negative values")
    }
  }
  for i = 1; i < n; i = i + 1 {
    if series.years[i] <= series.years[i - 1] {
      raise InvalidParameter("years must be in ascending order")
    }
  }
}

///|
/// Validate ModelParams for biological plausibility.
pub fn validate_model_params(params : ModelParams) -> Unit raise ErrorType {
  validate_positive(params.r, "r (growth rate)")
  validate_positive(params.k, "K (carrying capacity)")
  validate_positive(params.q, "q (catchability)")
  if params.sigma < 0.0 {
    raise InvalidParameter("sigma must be non-negative")
  }
  if params.n <= 0.0 {
    raise InvalidParameter("n (shape parameter) must be positive")
  }
  if params.r > 5.0 {
    raise OutOfRange("r (growth rate) exceeds plausible range (0, 5]")
  }
  if params.k < 1.0 {
    raise OutOfRange("K (carrying capacity) must be >= 1.0")
  }
}

///|
/// Validate a SimulationConfig.
pub fn validate_simulation_config(
  config : SimulationConfig,
) -> Unit raise ErrorType {
  if config.n_years <= 0 {
    raise InvalidParameter("n_years must be positive")
  }
  if config.n_replicates <= 0 {
    raise InvalidParameter("n_replicates must be positive")
  }
  if config.process_error < 0.0 {
    raise InvalidParameter("process_error must be non-negative")
  }
  if config.observation_error < 0.0 {
    raise InvalidParameter("observation_error must be non-negative")
  }
  validate_range(config.initial_depletion, 0.0, 1.0, "initial_depletion")
}

///|
/// Validate a ManagementScenario.
pub fn validate_management_scenario(
  scenario : ManagementScenario,
) -> Unit raise ErrorType {
  if scenario.projection_years <= 0 {
    raise InvalidParameter("projection_years must be positive")
  }
  if scenario.discount_rate < 0.0 || scenario.discount_rate > 1.0 {
    raise OutOfRange("discount_rate must be between 0.0 and 1.0")
  }
  match scenario.rule {
    ConstantCatch(c) =>
      if c < 0.0 {
        raise InvalidParameter("constant catch must be non-negative")
      }
    ConstantEffort(e) =>
      if e < 0.0 {
        raise InvalidParameter("constant effort must be non-negative")
      }
    ConstantF(f) =>
      if f < 0.0 {
        raise InvalidParameter("constant F must be non-negative")
      }
    ThresholdRule(blim, btarget, fmax) => {
      validate_positive(blim, "blim")
      validate_positive(btarget, "btarget")
      validate_positive(fmax, "fmax")
      if blim >= btarget {
        raise InvalidParameter("blim must be less than btarget")
      }
    }
    SlotRule(min_s, max_s) => {
      validate_positive(min_s, "min_size")
      validate_positive(max_s, "max_size")
      if min_s >= max_s {
        raise InvalidParameter("min_size must be less than max_size")
      }
    }
  }
}
