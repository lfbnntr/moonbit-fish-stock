// ============================================================
// Leslie Matrix Age-Structured Population Projection
// ============================================================

///|
/// Age-structured population config.
pub(all) struct AgeStructureConfig {
  num_ages : Int
  natural_mortality : Array[Double]
  weight_at_age : Array[Double]
  maturity_at_age : Array[Double]
  selectivity_at_age : Array[Double]
} derive(Eq)

///|
pub fn AgeStructureConfig::new(
  num_ages : Int,
  m_val : Double,
  weight_at_age : Array[Double],
  maturity_at_age : Array[Double],
  selectivity_at_age : Array[Double],
) -> AgeStructureConfig {
  let m_arr : Array[Double] = []
  for _i = 0; _i < num_ages; _i = _i + 1 {
    m_arr.push(m_val)
  }
  {
    num_ages,
    natural_mortality: m_arr,
    weight_at_age,
    maturity_at_age,
    selectivity_at_age,
  }
}

///|
/// Project an age-structured population forward by one year given fishing mortality F.
pub fn project_age_structure_one_year(
  current_numbers : Array[Double],
  f_mortality : Double,
  recruits : Double,
  config : AgeStructureConfig,
) -> Array[Double] raise @types.ErrorType {
  let num_ages = config.num_ages
  if current_numbers.length() != num_ages {
    raise @types.ErrorType::InvalidParameter(
      "current_numbers length must match num_ages",
    )
  }
  let next_numbers : Array[Double] = []
  // Age 0 (Recruits)
  next_numbers.push(recruits)

  // Ages 1 to A-1
  for a = 0; a < num_ages - 1; a = a + 1 {
    let m = config.natural_mortality[a]
    let sel = config.selectivity_at_age[a]
    let z = m + f_mortality * sel
    let survival = @math.exp_approx(-z)
    next_numbers.push(current_numbers[a] * survival)
  }

  // Plus group (last age class accumulates remaining survivors)
  let last_age = num_ages - 1
  let m_last = config.natural_mortality[last_age]
  let sel_last = config.selectivity_at_age[last_age]
  let z_last = m_last + f_mortality * sel_last
  let surv_last = @math.exp_approx(-z_last)
  let prev_plus = current_numbers[last_age - 1] *
    @math.exp_approx(
      -(config.natural_mortality[last_age - 1] +
      f_mortality * config.selectivity_at_age[last_age - 1]),
    )
  let curr_plus = current_numbers[last_age] * surv_last
  next_numbers[last_age] = prev_plus + curr_plus

  next_numbers
}

///|
/// Calculate Spawning Stock Biomass (SSB) from age-structured numbers.
pub fn calculate_ssb(
  numbers : Array[Double],
  config : AgeStructureConfig,
) -> Double {
  let mut ssb = 0.0
  let n = numbers.length()
  for a = 0; a < n; a = a + 1 {
    let w = if a < config.weight_at_age.length() {
      config.weight_at_age[a]
    } else {
      1.0
    }
    let mat = if a < config.maturity_at_age.length() {
      config.maturity_at_age[a]
    } else {
      1.0
    }
    ssb = ssb + numbers[a] * w * mat
  }
  ssb
}

///|
/// Calculate Yield (Total Catch Biomass) for a year given F.
pub fn calculate_yield(
  numbers : Array[Double],
  f_mortality : Double,
  config : AgeStructureConfig,
) -> Double {
  let mut total_yield = 0.0
  let n = numbers.length()
  for a = 0; a < n; a = a + 1 {
    let m = config.natural_mortality[a]
    let sel = config.selectivity_at_age[a]
    let f_a = f_mortality * sel
    let z_a = m + f_a
    let w_a = if a < config.weight_at_age.length() {
      config.weight_at_age[a]
    } else {
      1.0
    }
    if z_a > 0.0 {
      let catch_n = f_a / z_a * numbers[a] * (1.0 - @math.exp_approx(-z_a))
      total_yield = total_yield + catch_n * w_a
    }
  }
  total_yield
}
