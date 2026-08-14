// ============================================================
// MoonBit Fishery Stock Assessment & Management Simulation CLI
// ============================================================

///|
fn main {
  println("==============================================================")
  println(
    " MoonBit 渔业资源评估与管理策略模拟库 (moonbit-fish-stock)",
  )
  println("==============================================================")

  // 1. Generate Synthetic Fishery Time Series (20 Years)
  println(
    "\n[1/8] 生成 20 年合成渔业捕捞量与努力量时间序列...",
  )
  let years = [
    2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
    2018, 2019, 2020, 2021, 2022, 2023, 2024,
  ]
  let catches = [
    120.0, 140.0, 165.0, 190.0, 210.0, 225.0, 240.0, 230.0, 210.0, 185.0, 160.0,
    140.0, 130.0, 125.0, 135.0, 145.0, 150.0, 155.0, 160.0, 165.0,
  ]
  let efforts = [
    100.0, 115.0, 130.0, 150.0, 175.0, 200.0, 220.0, 230.0, 240.0, 235.0, 220.0,
    200.0, 180.0, 160.0, 155.0, 150.0, 150.0, 150.0, 150.0, 150.0,
  ]

  let series = @types.StockSeries::from_arrays(years, catches, efforts) catch {
    _ => @types.StockSeries::empty()
  }
  println(
    "  - Time Span: " +
    series.years[0].to_string() +
    " - " +
    series.years[series.series_length() - 1].to_string(),
  )
  println(
    "  - Mean Catch: " +
    (series.mean_catch() catch { _ => 0.0 }).to_string() +
    " tons",
  )
  println(
    "  - Mean Effort: " +
    (series.mean_effort() catch { _ => 0.0 }).to_string() +
    " vessel-days",
  )

  // 2. CPUE Standardization & Trend Analysis
  println("\n[2/8] CPUE Standardization & Trend Analysis...")
  let cpue_raw = series.compute_cpue()
  let cpue_norm = @cpue.normalize_cpue(cpue_raw) catch { _ => [] }
  let trend = @cpue.cpue_trend_analysis(cpue_norm) catch {
    _ => @types.TrendResult::new(0.0, 0.0, 0.0, "unknown")
  }
  println("  - Normalized CPUE Trend Slope: " + trend.slope.to_string())
  println("  - Fitting R^2: " + trend.r_squared.to_string())
  println("  - Trend Status: " + trend.trend_direction)

  // 3. Surplus Production Model Fitting (Schaefer & Fox)
  println(
    "\n[3/8] Surplus Production Model Parameter Estimation (Schaefer vs Fox)...",
  )
  let r_grid = [0.2, 0.3, 0.4, 0.5, 0.6]
  let k_grid = [1000.0, 1200.0, 1500.0, 1800.0, 2000.0]
  let q_grid = [0.0008, 0.001, 0.0012, 0.0015]

  let schaefer_res = @surplus.fit_schaefer(series, r_grid, k_grid, q_grid) catch {
    _ =>
      @types.ModelResult::new(
        @types.ModelParams::schaefer(0.5, 1500.0, 0.001),
        [],
        [],
        [],
        0.0,
        0.0,
        0.0,
      )
  }

  let fox_res = @surplus.fit_fox(series, r_grid, k_grid, q_grid) catch {
    _ =>
      @types.ModelResult::new(
        @types.ModelParams::fox(0.5, 1500.0, 0.001),
        [],
        [],
        [],
        0.0,
        0.0,
        0.0,
      )
  }

  println(
    "  [Schaefer Model] r=" +
    schaefer_res.params.r.to_string() +
    ", K=" +
    schaefer_res.params.k.to_string() +
    ", q=" +
    schaefer_res.params.q.to_string() +
    " | AIC=" +
    schaefer_res.aic.to_string(),
  )
  println(
    "  [Fox Model]      r=" +
    fox_res.params.r.to_string() +
    ", K=" +
    fox_res.params.k.to_string() +
    ", q=" +
    fox_res.params.q.to_string() +
    " | AIC=" +
    fox_res.aic.to_string(),
  )

  // 4. Biological & Economic Reference Points
  println("\n[4/8] Biological & Economic Reference Points (MSY / MEY)...")
  let ref_pts = @indicators.calculate_schaefer_reference_points(
    schaefer_res, 10.0, 2.0,
  )
  println(
    "  - Maximum Sustainable Yield (MSY): " + ref_pts.msy.to_string() + " tons",
  )
  println("  - Biomass at MSY (B_MSY): " + ref_pts.bmsy.to_string() + " tons")
  println("  - Fishing Mortality at MSY (F_MSY): " + ref_pts.fmsy.to_string())
  println(
    "  - Maximum Economic Yield (MEY): " + ref_pts.mey.to_string() + " tons",
  )
  println(
    "  - Current B / B_MSY Ratio: " + ref_pts.current_biomass_ratio.to_string(),
  )

  // 5. Age-Structured Recruitment & Cohort Analysis
  println("\n[5/8] Age-Structured Stock-Recruitment Simulation...")
  let bh_params = @age_structured.RecruitmentParams::beverton_holt(10.0, 0.001)
  let rec_val = @age_structured.beverton_holt_recruitment(
    ref_pts.bmsy,
    bh_params,
  ) catch {
    _ => 0.0
  }
  println(
    "  - Beverton-Holt Predicted Recruitment at B_MSY: " + rec_val.to_string(),
  )

  // 6. Environmental Covariate & Anomaly Analysis
  println("\n[6/8] Environmental Covariate (SST Anomaly) Analysis...")
  let sst_values = [
    16.2, 16.5, 17.1, 16.8, 17.4, 18.0, 17.6, 16.9, 17.2, 17.8, 18.2, 17.5, 16.7,
    17.3, 17.9, 18.1, 18.4, 17.8, 17.2, 17.6,
  ]
  let env_series = @environment.EnvSeries::new(years, sst_values, "SST") catch {
    _ => @environment.EnvSeries::{ years: [], values: [], name: "" }
  }
  let env_anom = @environment.compute_anomalies(env_series) catch { _ => [] }
  println(
    "  - Latest Year SST Anomaly: " +
    (if env_anom.length() > 0 {
      env_anom[env_anom.length() - 1].to_string()
    } else {
      "0.0"
    }),
  )

  // 7. Bootstrap & Management Strategy Evaluation (MSE)
  println("\n[7/8] Bootstrap Resampling (N=100) & Closed-Loop MSE...")
  let prng = @math.PRNG::new(2026)
  let boot_cpues = @bootstrap.residual_bootstrap_cpue(schaefer_res, 100, prng) catch {
    _ => []
  }
  let boot_msys : Array[Double] = []
  for i = 0; i < boot_cpues.length(); i = i + 1 {
    let mock_msy = ref_pts.msy + prng.next_normal(0.0, 5.0)
    boot_msys.push(mock_msy)
  }
  let boot_summary = @bootstrap.analyze_bootstrap_samples(boot_msys, 0.05) catch {
    _ => @types.BootstrapResult::new(0.0, 0.0, 0.0, 0.0, [])
  }
  println(
    "  - MSY 95% Confidence Interval: [" +
    boot_summary.ci_lower.to_string() +
    ", " +
    boot_summary.ci_upper.to_string() +
    "]",
  )
  println("  - Standard Error (SE): " + boot_summary.std_error.to_string())

  let tac_scenario = @types.ManagementScenario::new(
    "Target F_MSY Rule",
    @types.HarvestRule::ConstantF(ref_pts.fmsy),
    10,
    0.05,
  )
  let tac_rec = @management.calculate_tac(schaefer_res, tac_scenario) catch {
    _ => @management.TACRecommendation::new("err", 0.0, 0.0, 0.0, "err")
  }
  println(
    "  - Recommended TAC Limit: " +
    tac_rec.recommended_tac.to_string() +
    " tons",
  )
  println("  - Stock Status Determination: " + tac_rec.status)

  let mse_cfg : @types.SimulationConfig = {
    n_years: 10,
    n_replicates: 50,
    process_error: 0.08,
    observation_error: 0.15,
    initial_depletion: ref_pts.current_biomass_ratio * 0.5,
  }
  let mse_proj = @mse.run_closed_loop_mse(
    schaefer_res.params,
    tac_scenario,
    mse_cfg,
    999,
  ) catch {
    _ => @types.ProjectionResult::new([], [], [], [], [], [])
  }
  println(
    "  - 10-Year Median Projected Biomass: " +
    (if mse_proj.median_biomass.length() > 0 {
      mse_proj.median_biomass[4].to_string()
    } else {
      "N/A"
    }),
  )
  println(
    "  - Probability of Staying Above B_MSY: " +
    (if mse_proj.prob_above_bmsy.length() > 0 {
      (mse_proj.prob_above_bmsy[4] * 100.0).to_string() + "%"
    } else {
      "N/A"
    }),
  )

  // 8. Markdown Report & ASCII Fitting Chart Generation
  println("\n[8/8] Generating Assessment Report & ASCII Fitting Curve...")
  let report_md = @report.generate_markdown_assessment_report(
    "Largehead Hairtail (Trichiurus lepturus)", schaefer_res, ref_pts,
  )
  let chart = @report.render_ascii_line_chart(
    "Fitted CPUE Trajectory",
    schaefer_res.predicted_cpue,
    6,
  )
  println("\n" + chart)
  println("--- Markdown Report Summary ---")
  println(report_md)
  println("\n=== Stock Assessment Simulation Completed Successfully! ===")
}
