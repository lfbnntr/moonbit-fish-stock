// ============================================================
// ASCII Chart Renderer for Terminal Visualization
// ============================================================

///|
/// Render a 1D double array into a multi-line ASCII sparkline/chart.
pub fn render_ascii_line_chart(
  title : String,
  data : Array[Double],
  height : Int,
) -> String {
  let n = data.length()
  if n == 0 {
    return title + "\n(empty data)\n"
  }
  let h_safe = if height < 3 { 3 } else { height }

  let mut min_v = data[0]
  let mut max_v = data[0]
  for i = 1; i < n; i = i + 1 {
    if data[i] < min_v {
      min_v = data[i]
    }
    if data[i] > max_v {
      max_v = data[i]
    }
  }

  let range_v = if max_v == min_v { 1.0 } else { max_v - min_v }

  let mut out = "--- " + title + " ---\n"
  out = out + "Max: " + max_v.to_string() + "\n"

  for r = h_safe - 1; r >= 0; r = r - 1 {
    let threshold = min_v + r.to_double() / (h_safe - 1).to_double() * range_v
    let mut line = "|"
    for i = 0; i < n; i = i + 1 {
      let val = data[i]
      if val >= threshold {
        line = line + "*"
      } else {
        line = line + " "
      }
    }
    out = out + line + "\n"
  }

  out = out + "Min: " + min_v.to_string() + "\n"
  out
}
