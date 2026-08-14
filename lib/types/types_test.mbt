// Unit tests for core types, validation, and series operations

///|
test "CatchRecord creation and CPUE" {
  let rec = CatchRecord::new(2020, 100.0, 20.0)
  assert_eq(rec.year, 2020)
  assert_eq(rec.catch_amount, 100.0)
  assert_eq(rec.effort, 20.0)
  assert_eq(rec.cpue, 5.0)
}

///|
test "StockSeries from_arrays" {
  let years = [2018, 2019, 2020]
  let catches = [100.0, 120.0, 110.0]
  let efforts = [10.0, 12.0, 11.0]
  let series = StockSeries::from_arrays(years, catches, efforts) catch {
    _ => StockSeries::empty()
  }
  assert_eq(series.series_length(), 3)
  assert_eq(series.compute_cpue(), [10.0, 10.0, 10.0])
}

///|
test "Validation positive" {
  let res = try {
    validate_positive(10.0, "test")
    true
  } catch {
    _ => false
  }
  assert_true(res)

  let res_err = try {
    validate_positive(-5.0, "test")
    false
  } catch {
    _ => true
  }
  assert_true(res_err)
}

///|
test "StockSeries filtering" {
  let years = [2015, 2016, 2017, 2018, 2019]
  let catches = [50.0, 60.0, 70.0, 80.0, 90.0]
  let efforts = [5.0, 6.0, 7.0, 8.0, 9.0]
  let series = StockSeries::from_arrays(years, catches, efforts) catch {
    _ => StockSeries::empty()
  }
  let filtered = series.filter_years(2016, 2018)
  assert_eq(filtered.series_length(), 3)
  assert_eq(filtered.years, [2016, 2017, 2018])
}
