// ============================================================
// StockSeries Operations
// ============================================================

///|
/// Create a StockSeries from parallel arrays, computing CPUE automatically.
pub fn StockSeries::from_arrays(
  years : Array[Int],
  catches : Array[Double],
  efforts : Array[Double],
) -> StockSeries raise ErrorType {
  let n = years.length()
  if catches.length() != n || efforts.length() != n {
    raise InvalidParameter("All arrays must have the same length")
  }
  if n == 0 {
    raise InsufficientData("Cannot create StockSeries from empty arrays")
  }
  let cpue : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    if efforts[i] > 0.0 {
      cpue.push(catches[i] / efforts[i])
    } else {
      cpue.push(0.0)
    }
  }
  { years, catch_data: catches, effort_data: efforts, cpue_data: cpue }
}

///|
/// Filter the series to include only years within [start_year, end_year].
pub fn StockSeries::filter_years(
  self : StockSeries,
  start_year : Int,
  end_year : Int,
) -> StockSeries {
  let years : Array[Int] = []
  let catches : Array[Double] = []
  let efforts : Array[Double] = []
  let cpues : Array[Double] = []
  for i = 0; i < self.years.length(); i = i + 1 {
    let y = self.years[i]
    if y >= start_year && y <= end_year {
      years.push(y)
      catches.push(self.catch_data[i])
      efforts.push(self.effort_data[i])
      if i < self.cpue_data.length() {
        cpues.push(self.cpue_data[i])
      }
    }
  }
  { years, catch_data: catches, effort_data: efforts, cpue_data: cpues }
}

///|
/// Compute CPUE from catch and effort data.
pub fn StockSeries::compute_cpue(self : StockSeries) -> Array[Double] {
  let n = self.catch_data.length()
  let result : Array[Double] = []
  for i = 0; i < n; i = i + 1 {
    if i < self.effort_data.length() && self.effort_data[i] > 0.0 {
      result.push(self.catch_data[i] / self.effort_data[i])
    } else {
      result.push(0.0)
    }
  }
  result
}

///|
/// Get the year range as (min_year, max_year).
pub fn StockSeries::get_year_range(
  self : StockSeries,
) -> (Int, Int) raise ErrorType {
  if self.years.is_empty() {
    raise InsufficientData("Empty series has no year range")
  }
  (self.years[0], self.years[self.years.length() - 1])
}

///|
/// Return the number of data points in the series.
pub fn StockSeries::series_length(self : StockSeries) -> Int {
  self.years.length()
}

///|
/// Compute the mean catch.
pub fn StockSeries::mean_catch(self : StockSeries) -> Double raise ErrorType {
  let n = self.catch_data.length()
  if n == 0 {
    raise InsufficientData("No catch data for mean computation")
  }
  let mut sum = 0.0
  for i = 0; i < n; i = i + 1 {
    sum = sum + self.catch_data[i]
  }
  sum / n.to_double()
}

///|
/// Compute the mean effort.
pub fn StockSeries::mean_effort(self : StockSeries) -> Double raise ErrorType {
  let n = self.effort_data.length()
  if n == 0 {
    raise InsufficientData("No effort data for mean computation")
  }
  let mut sum = 0.0
  for i = 0; i < n; i = i + 1 {
    sum = sum + self.effort_data[i]
  }
  sum / n.to_double()
}

///|
/// Compute the mean CPUE.
pub fn StockSeries::mean_cpue(self : StockSeries) -> Double raise ErrorType {
  let n = self.cpue_data.length()
  if n == 0 {
    raise InsufficientData("No CPUE data for mean computation")
  }
  let mut sum = 0.0
  for i = 0; i < n; i = i + 1 {
    sum = sum + self.cpue_data[i]
  }
  sum / n.to_double()
}

///|
/// Merge two StockSeries (assumes non-overlapping or appending).
pub fn StockSeries::merge_series(
  self : StockSeries,
  other : StockSeries,
) -> StockSeries {
  let years : Array[Int] = []
  let catches : Array[Double] = []
  let efforts : Array[Double] = []
  let cpues : Array[Double] = []
  for i = 0; i < self.years.length(); i = i + 1 {
    years.push(self.years[i])
    catches.push(self.catch_data[i])
    efforts.push(self.effort_data[i])
    if i < self.cpue_data.length() {
      cpues.push(self.cpue_data[i])
    }
  }
  for i = 0; i < other.years.length(); i = i + 1 {
    years.push(other.years[i])
    catches.push(other.catch_data[i])
    efforts.push(other.effort_data[i])
    if i < other.cpue_data.length() {
      cpues.push(other.cpue_data[i])
    }
  }
  { years, catch_data: catches, effort_data: efforts, cpue_data: cpues }
}

///|
/// Convert the series into an array of CatchRecord.
pub fn StockSeries::to_records(self : StockSeries) -> Array[CatchRecord] {
  let n = self.years.length()
  let records : Array[CatchRecord] = []
  for i = 0; i < n; i = i + 1 {
    let cpue = if i < self.cpue_data.length() { self.cpue_data[i] } else { 0.0 }
    records.push({
      year: self.years[i],
      catch_amount: self.catch_data[i],
      effort: self.effort_data[i],
      cpue,
    })
  }
  records
}
