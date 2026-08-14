// ============================================================
// Markdown & ASCII Stock Assessment Report Generator
// ============================================================

///|
/// Format a complete Stock Assessment Summary Report in Markdown.
pub fn generate_markdown_assessment_report(
  stock_name : String,
  model_result : @types.ModelResult,
  ref_pts : @types.ReferencePoints,
) -> String {
  let mut report = "# Stock Assessment Report: " + stock_name + "\n\n"

  report = report + "## 1. Estimated Model Parameters\n\n"
  report = report + "| Parameter | Symbol | Value |\n"
  report = report + "|---|---|---|\n"
  report = report +
    "| Intrinsic Growth Rate | r | " +
    model_result.params.r.to_string() +
    " |\n"
  report = report +
    "| Carrying Capacity | K | " +
    model_result.params.k.to_string() +
    " |\n"
  report = report +
    "| Catchability | q | " +
    model_result.params.q.to_string() +
    " |\n"
  report = report +
    "| Process Error Std | sigma | " +
    model_result.params.sigma.to_string() +
    " |\n"
  report = report +
    "| Shape Parameter | n | " +
    model_result.params.n.to_string() +
    " |\n\n"

  report = report + "## 2. Biological & Economic Reference Points\n\n"
  report = report + "| Metric | Symbol | Value |\n"
  report = report + "|---|---|---|\n"
  report = report +
    "| Maximum Sustainable Yield | MSY | " +
    ref_pts.msy.to_string() +
    " |\n"
  report = report +
    "| Biomass at MSY | B_MSY | " +
    ref_pts.bmsy.to_string() +
    " |\n"
  report = report +
    "| Fishing Mortality at MSY | F_MSY | " +
    ref_pts.fmsy.to_string() +
    " |\n"
  report = report +
    "| Effort at MSY | E_MSY | " +
    ref_pts.emsy.to_string() +
    " |\n"
  report = report +
    "| Maximum Economic Yield | MEY | " +
    ref_pts.mey.to_string() +
    " |\n"
  report = report +
    "| Current B / B_MSY Ratio | B/B_MSY | " +
    ref_pts.current_biomass_ratio.to_string() +
    " |\n\n"

  report = report + "## 3. Goodness of Fit & Information Criteria\n\n"
  report = report +
    "- Sum of Squared Errors (SSE): `" +
    model_result.sse.to_string() +
    "`\n"
  report = report +
    "- Akaike Information Criterion (AIC): `" +
    model_result.aic.to_string() +
    "`\n"
  report = report +
    "- Bayesian Information Criterion (BIC): `" +
    model_result.bic.to_string() +
    "`\n\n"

  let status_str = if ref_pts.current_biomass_ratio >= 1.0 {
    "HEALTHY (B >= B_MSY)"
  } else if ref_pts.current_biomass_ratio >= 0.5 {
    "CAUTION (B < B_MSY)"
  } else {
    "OVERFISHED (B < 0.5 * B_MSY)"
  }

  report = report + "## 4. Stock Status Determination\n\n"
  report = report + "**Current Stock Status**: `" + status_str + "`\n"

  report
}

///|
/// Format a comparison table for multiple management scenarios.
pub fn generate_scenario_comparison_table(
  scenarios : Array[@types.ManagementScenario],
  projections : Array[@types.ProjectionResult],
) -> String {
  let n = scenarios.length()
  let mut table = "| Scenario | Rule | Horizon (Yrs) | Final Median Biomass | Median Catch |\n"
  table = table + "|---|---|---|---|---|\n"
  for i = 0; i < n; i = i + 1 {
    let sc = scenarios[i]
    let pr = if i < projections.length() {
      projections[i]
    } else {
      @types.ProjectionResult::new([], [], [], [], [], [])
    }
    let n_bio = pr.median_biomass.length()
    let final_b = if n_bio > 0 { pr.median_biomass[n_bio - 1] } else { 0.0 }
    let mean_c = @math.mean(pr.median_catch)

    table = table +
      "| " +
      sc.name +
      " | " +
      sc.rule.to_string() +
      " | " +
      sc.projection_years.to_string() +
      " | " +
      final_b.to_string() +
      " | " +
      mean_c.to_string() +
      " |\n"
  }
  table
}
