# MoonBit 渔业资源评估与管理策略模拟库 (moonbit-fish-stock)

[![Check and Test](https://github.com/lfbnntr/moonbit-fish-stock/actions/workflows/check.yml/badge.svg)](https://github.com/lfbnntr/moonbit-fish-stock/actions)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![MoonBit Toolchain](https://img.shields.io/badge/MoonBit-0.10.4-purple.svg)](https://www.moonbitlang.com)

面向渔业科研、海洋生态管理与定量水产学，**moonbit-fish-stock** 是基�?MoonBit 原生构建的现代化渔业资源评估与管理策略模拟库 (Fishery Stock Assessment and Management Strategy Evaluation System)�?
本库提供从渔业捕捞量/努力量时间序列处理、CPUE 标准化、剩余产量模型拟合、龄组结构补充量计算、环境协变量分析、Bootstrap 不确定性推断，到闭环管理策略评�?(MSE) 的端到端分析工具�?
---

## 核心特�?
- **剩余产量模型 (Surplus Production Models)**:
  - Schaefer 逻辑斯蒂模型 ($B_{t+1} = B_t + r B_t (1 - B_t / K) - C_t$)
  - Pella–Tomlinson 通用形状参数模型 ($n \ge 1.0$)
  - Fox 指数增长模型 ($g(B) = r B \ln(K / B)$)
  - 自动高维网格搜索与极大似�?/ OLS 参数估计
- **CPUE 标准化与资源指数**:
  - 几何均值与算术均值归一�?(Normalize)
  - 线性去趋势 (Detrend) 与季节性效应调�?(Seasonal Adjustment)
  - 丰度指数 (Abundance Index) �?95% 置信区间
  - 超稳定�?(Hyperstability) / 超枯�?(Hyperdepletion) 假设检�?- **龄组结构与补充量模型 (Age-Structured Models)**:
  - Beverton–Holt 陡度 ($h$) 补充量模�?  - Ricker 密度制约补充量模�?  - Pope 追溯同龄群分�?(Pope's Cohort Analysis / VPA)
  - Baranov 捕捞方程数值求解器
  - 产卵亲体生物�?(SSB) �?Leslie 矩阵群落投影
- **环境协变量与气候响�?(Environmental Covariates)**:
  - 海表温度 (SST) 距平计算与跨滞后互相关分�?(Cross-Correlation)
  - 气候驱动的动能承载力方�?($K(t) = K_0 e^{\gamma E_t}$)
- **Bootstrap 不确定性评�?*:
  - 残差重抽�?(Residual Bootstrapping) 算法
  - 百分位法与标准误不确定性推�?- **生物与经济参考点 (Reference Points)**:
  - 最大持续产�?(MSY), $B_{\mathrm{MSY}}$, $F_{\mathrm{MSY}}$, $E_{\mathrm{MSY}}$
  - 最大经济产�?(MEY) 边际收益求解
  - 神户�?(Kobe Plot) 四象限状态判�?(Green / Yellow / Orange / Red)
- **管理策略评估 (MSE) �?TAC 推荐**:
  - Hockey-stick 捕捞控制规则 (HCR) �?Slot 规则
  - 模拟操作模型 (Operating Model) 与观察误�?过程误差闭环模拟
  - 允许捕捞�?(TAC) 推荐�?10 年期种群重建概率预测
- **可视与报告生�?*:
  - 终端 ASCII 拟合曲线�?SPARK 散点渲染�?  - 自动生成符合学术规范�?Markdown 评估报告

---

## 模块架构

```text
moonbit-fish-stock/
├── lib/
�?  ├── types/          # 核心领域数据类型 (StockSeries, ModelParams, ErrorType)
�?  ├── math/           # 基础数学、统计、线性代数、优化与 PRNG 引擎
�?  ├── cpue/           # CPUE 标准化、归一化、去趋势与超稳定性检�?�?  ├── surplus/        # Schaefer, Pella-Tomlinson, Fox 剩余产量模型�?AIC 诊断
�?  ├── age_structured/ # Beverton-Holt, Ricker 补充量与 VPA 同龄群分�?�?  ├── environment/    # 环境协变量、SST 距平与气候响应模�?�?  ├── bootstrap/      # 残差重抽样与置信区间估计
�?  ├── indicators/     # MSY / MEY 参考点计算�?Kobe 图四象限分类
�?  ├── management/     # 捕捞控制规则 (HCR) �?TAC 限额推荐
�?  ├── mse/            # 闭环 MSE 模拟引擎 (Operating Model & Management Procedure)
�?  └── report/         # ASCII 拟合曲线�?Markdown 评估报告生成�?└── cmd/
    └── main/           # CLI 交互示范与端到端集成测试脚本
```

---

## 快速开�?
### 运行环境要求

- MoonBit 工具�?(�?0.10.3)
- Git

### 1. 构建与测�?
```bash
# 复制或下载仓�?git clone https://github.com/lfbnntr/moonbit-fish-stock.git
cd moonbit-fish-stock

# 检查项目与类型
moon check --deny-warn

# 运行全套 40+ 单元测试
moon test --deny-warn
```

### 2. 运行端到端评估示�?CLI

```bash
moon run cmd/main
```

示范脚本输出包含�?1. 20 年合成渔业捕捞量/努力量标准化
2. Schaefer vs Fox 模型拟合�?AIC 信息准则对比
3. 生物与经济参考点 ($MSY, B_{\mathrm{MSY}}, F_{\mathrm{MSY}}, MEY$)
4. 龄组结构补充量预�?5. SST 环境距平响应
6. 100 �?Bootstrap 不确定性置信区�?7. 闭环 MSE 模拟�?10 年期 TAC 推荐
8. 终端 ASCII 拟合曲线�?Markdown 报告

---

## 开源许可证

本项目采�?[Apache License 2.0](LICENSE) 开源许可证�?
