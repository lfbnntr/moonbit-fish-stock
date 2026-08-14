# 2026 MoonBit 编程马拉松 (8月月赛) 项目申报书

## 一、 项目基本信息
- **项目名称**: moonbit-fish-stock (MoonBit 渔业资源评估与管理策略模拟库)
- **申报人 / 唯一贡献者**: lfbnntr
- **开源许可证**: Apache-2.0
- **项目开源地址**: https://github.com/lfbnntr/moonbit-fish-stock

## 二、 项目简介与创新点
**moonbit-fish-stock** 是 MoonBit 生态首个填补空白的定量水产学与海洋资源管理原生计算库。项目包含 15 个模块、5,500+ 行代码，提供从渔业捕捞数据处理到闭环管理策略评估 (MSE) 的端到端算法支持。

- **核心创新**: 突破传统 R/ADMB 依赖，利用 MoonBit 极致性能实现纯原生、无依赖的高维参数拟合、Bootstrap 不确定性推断与闭环 MSE 模拟。
- **填补空白**: 填补了国产 MoonBit 生态在生态学、定量水产学与渔业管理计算领域的空白。

## 三、 核心功能模块
1. **剩余产量模型**: Schaefer / Pella-Tomlinson / Fox 模型拟合与 AIC/BIC 校验。
2. **CPUE 标准化**: 几何/算术归一化、线性去趋势与超稳定性假设检验。
3. **龄组结构与 VPA**: Beverton-Holt / Ricker 补充量模型与 Pope 追溯同龄群分析。
4. **环境协变量**: 海表温度 (SST) 距平分析与气候驱动动能承载力模型。
5. **不确定性推断**: Residual Bootstrap 残差重抽样与 95% 置信区间估计。
6. **MSE 闭环模拟**: 观察/过程误差 Operating Model 与 TAC 限额推荐。
7. **可视与报告**: 终端 ASCII 拟合曲线渲染与 Markdown 报告自动生成。

## 四、 质量与规范指标
- **代码规模**: 5,595 行原生 MoonBit 源码（纯手写非空代码 4,562 行）。
- **工具链规范**: 0 警告通过 moon check --deny-warn、moon fmt 与 moon info。
- **单元测试**: 40 项单元测试 100% 通过，配套完整的 GitHub Actions 多平台 CI。
