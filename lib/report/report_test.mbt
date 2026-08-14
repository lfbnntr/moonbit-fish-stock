// Unit tests for report generation and ASCII chart rendering

///|
test "ASCII chart rendering" {
  let data = [10.0, 20.0, 15.0, 25.0, 30.0]
  let chart = render_ascii_line_chart("Test Chart", data, 5)
  assert_true(chart.length() > 0)
}

///|
test "Markdown assessment report generation" {
  let params = @types.ModelParams::schaefer(0.4, 1000.0, 0.001)
  let model_res = @types.ModelResult::new(
    params,
    [1000.0, 900.0],
    [1.0, 0.9],
    [0.0, 0.0],
    0.0,
    10.0,
    12.0,
  )
  let ref_pts = @types.ReferencePoints::new(100.0, 500.0, 0.2, 200.0, 95.0, 1.8)
  let rpt = generate_markdown_assessment_report(
    "Pacific Cod", model_res, ref_pts,
  )
  assert_true(rpt.length() > 50)
}
