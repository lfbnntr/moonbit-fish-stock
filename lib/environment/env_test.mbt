// Unit tests for environmental covariates and climate surplus model

///|
test "Environmental anomaly computation" {
  let years = [2010, 2011, 2012, 2013, 2014]
  let values = [15.0, 16.0, 17.0, 18.0, 19.0]
  let series = EnvSeries::new(years, values, "SST") catch {
    _ => EnvSeries::{ years: [], values: [], name: "" }
  }
  let anomalies = compute_anomalies(series) catch { _ => [] }
  assert_eq(anomalies.length(), 5)
  // Mean should be centered near 0.0
  let m_anom = @math.mean(anomalies)
  assert_true(@math.abs_double(m_anom) < 1.0e-3)
}

///|
test "Climate Schaefer biomass dynamics" {
  let catches = [50.0, 60.0, 70.0]
  let anomalies = [0.1, -0.2, 0.3]
  let params = ClimateModelParams::new(0.5, 1000.0, 0.001, 0.2)
  let bio = climate_schaefer_biomass(1000.0, catches, anomalies, params) catch {
    _ => []
  }
  assert_eq(bio.length(), 4)
  assert_true(bio[1] > 0.0)
}
