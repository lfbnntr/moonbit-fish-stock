// Unit tests for Kobe plot indicators and reference points

///|
test "Kobe point quadrant classification" {
  let kp_green = KobePoint::new(2020, 1.2, 0.8)
  assert_true(kp_green.quadrant == KobeQuadrant::Green)

  let kp_yellow = KobePoint::new(2021, 1.1, 1.3)
  assert_true(kp_yellow.quadrant == KobeQuadrant::Yellow)

  let kp_orange = KobePoint::new(2022, 0.8, 0.9)
  assert_true(kp_orange.quadrant == KobeQuadrant::Orange)

  let kp_red = KobePoint::new(2023, 0.7, 1.4)
  assert_true(kp_red.quadrant == KobeQuadrant::Red)
}

///|
test "Green quadrant probability" {
  let pts = [
    KobePoint::new(2018, 1.2, 0.8), // Green
    KobePoint::new(2019, 1.1, 0.9), // Green
    KobePoint::new(2020, 0.9, 1.2), // Red
    KobePoint::new(2021, 0.8, 0.8), // Orange
  ]
  let prob = green_quadrant_probability(pts)
  assert_eq(prob, 0.5)
}

///|
test "Schaefer reference points calculation" {
  let params = @types.ModelParams::schaefer(0.4, 1000.0, 0.001)
  let bio = [1000.0, 900.0, 800.0]
  let pred = [1.0, 0.9, 0.8]
  let res = [0.0, 0.0, 0.0]
  let res_model = @types.ModelResult::new(params, bio, pred, res, 0.0, 0.0, 0.0)
  let ref_pts = calculate_schaefer_reference_points(res_model, 10.0, 2.0)
  assert_eq(ref_pts.msy, 100.0)
  assert_eq(ref_pts.bmsy, 500.0)
  assert_eq(ref_pts.fmsy, 0.2)
}
