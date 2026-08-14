// Unit tests for surplus production models

///|
test "Schaefer biomass dynamics and MSY" {
  let p = @types.ModelParams::schaefer(0.4, 1000.0, 0.001)
  let msy = schaefer_msy(p)
  let bmsy = schaefer_bmsy(p)
  let fmsy = schaefer_fmsy(p)
  assert_eq(msy, 100.0)
  assert_eq(bmsy, 500.0)
  assert_eq(fmsy, 0.2)
}

///|
test "Pella-Tomlinson reduces to Schaefer when n=2" {
  let p = @types.ModelParams::pella_tomlinson(0.4, 1000.0, 0.001, 2.0)
  let msy_pt = pella_tomlinson_msy(p)
  let bmsy_pt = pella_tomlinson_bmsy(p)
  let fmsy_pt = pella_tomlinson_fmsy(p)
  assert_eq(msy_pt, 100.0)
  assert_eq(bmsy_pt, 500.0)
  assert_eq(fmsy_pt, 0.2)
}

///|
test "Fox model reference points" {
  let p = @types.ModelParams::fox(0.4, 1000.0, 0.001)
  let fmsy_fox = fox_fmsy(p)
  let bmsy_fox = fox_bmsy(p)
  assert_eq(fmsy_fox, 0.4)
  let diff = @math.abs_double(bmsy_fox - 1000.0 / @math.e)
  assert_true(diff < 1.0e-3)
}

///|
test "Durbin-Watson statistic computation" {
  let res = [0.1, -0.1, 0.15, -0.05, 0.2, -0.1]
  let dw = durbin_watson_stat(res)
  assert_true(dw > 0.0 && dw < 4.0)
}
