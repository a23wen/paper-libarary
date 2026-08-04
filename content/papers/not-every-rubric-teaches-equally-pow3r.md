---
title: "Not Every Rubric Teaches Equally: Policy-Aware Rubric Rewards for RLVR"
date: 2026-08-04T17:46:01+08:00
draft: false

# 分类（研究领域）
categories: ["强化学习"]

# 会议/期刊
venues: "arXiv 2026"

# 论文元数据
authors: ["Utkarsh Tyagi", "Xingang Guo", "MohammadHossein Rezaei", "Daniel George", "Anas Mahmoud", "Jackson Lee", "Bing Liu", "Yunzhong He"]
year: "2026"
paper_url: "https://arxiv.org/abs/2605.20164v1"
arxiv_url: "https://arxiv.org/pdf/2605.20164v1"
code_url: ""

rating: 5

summary: "提出 POW3R，将 rubric 的终局重要性与其对当前 policy 的训练价值分开：保留人工权重和类别质量预算，同时根据同一 prompt 下 rollout 的逐 criterion 通过方差，以有界、平滑、跨轮次的动态因子重新分配训练压力。在多模态与 HealthBench 上，POW3R 在 30 个主要比较中赢得 24 个，并以少 2.5–4 倍的训练步数达到静态奖励的相同平台。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文研究的是 rubric-based GRPO 中一个很容易被忽略、却直接决定训练是否有效的问题：**一条 rubric 在最终评价里很重要，不代表它此刻能教会当前 policy 什么。**

标准做法会给每条 criterion 一个固定权重，再把逐条 pass/fail 加权成标量 reward。这个权重通常表达“答错这一项有多严重”。但 GRPO 使用的是同一 prompt 下 rollout 的相对 reward：如果 16 个回答全部通过某条 criterion，或者全部失败，那么这条 criterion 无论权重多大，对组内 advantage 都是常数，无法提供更新方向。

作者把这种错位概括为两个不同问题：

- **What should matter?** 最终答案应该重视什么？这是 rubric 语义、人工权重和质量类别定义的评价目标。
- **What can teach now?** 当前 policy 在什么标准上还存在可学习的组内差异？这是 rollout 分布决定的训练信号。

POW3R（Policy-Aware Rubric Rewards for RLVR）不修改 criterion，也不让 reward judge 改变判断标准。它保留原始人工权重作为 prior，再用当前 policy 的 rollout 通过方差生成一个有界动态因子，在每个 rubric category 内重新分配训练压力。

## 🎯 研究背景

RLVR 在数学、代码等任务上成功，一个重要原因是 reward 清晰且容易验证。但医学建议、科学写作、复杂视觉理解等开放任务没有唯一正确答案，质量往往同时包含：事实正确、内容完整、视觉忠实、指令遵循和表达清楚等多个维度。

Rubrics as Rewards 一类方法将总体质量拆成 prompt-specific criteria，再让 LLM judge 逐条评分，使开放任务也能获得结构化 reward。问题在于，GRPO 最终仍然只能消费一个标量，所以多个 criterion 必须被聚合。

静态加权和隐含了三个假设：

1. 不同类别中的 criterion 数量和总权重天然可比；
2. 同一类别的 criterion 对当前 policy 同样有信息；
3. 人工重要性同时也是当前训练效用。

论文的切入点是第三个假设并不成立，而且它不是小规模偶发现象。作者在两个冻结 policy、1,300 个多模态或 HealthBench prompt 上检查逐 criterion verdict，发现大约一半 criterion 对初始 policy 没有组内对比信号：17%–26% 已经全部通过，20%–33% 全部失败。静态聚合因此把 45%–51% 的类别内训练压力放在当下不能产生 advantage 的条目上。

## ⚠️ 问题与挑战

### 1. 重要性和可学习性发生错位

高权重 criterion 可能是主任务要求，但当前 policy 已全部掌握，因而处于 saturated 状态；也可能难度过高，所有 rollout 都失败，处于 dead 状态。两者的 pass 方差都为零。

例如，一组视觉回答可能都能识别“这是一张车站地图”，因此这一主事实即使权重最高也不再区分；真正有差异的可能是“能否从线路与标注中推出 Tokyo Station 的位置”。训练应暂时把更多压力放到后者，但最终评价不能因此永久忘掉前者。

### 2. 直接按方差赋权会造成目标漂移

只追求组内差异，可能让一个偶然、次要或 judge 不稳定的 criterion 获得全部权重。这样虽然 reward spread 变大，policy 优化的目标却可能偏离原始 rubric。

因此 POW3R 不能把静态权重完全丢掉，而要同时满足：

- 原始人工重要性仍是 prior；
- 每个质量类别的总 reward 预算不被动态信号吞并；
- 动态倍率有上下界；
- 当前批次的噪声不能立即造成剧烈变化。

### 3. 动态因子来自 LLM judge，本身也会有噪声

POW3R 的方差由逐 criterion 二值 verdict 估计。如果 judge 系统性误判，动态权重会进一步放大这种偏差。所以 judge 选择、逐条判断方式和训练/评估解耦都属于方法的一部分，而不只是工程细节。

## 🔍 核心发现 Finding

### 作者明确声称

作者的核心发现是：**rubric 的终局重要性与其对当前 policy 的可学习性是两个不同变量；固定 rubric 可以保持评价目标不变，而 criterion-level training pressure 应随 policy 的 rollout 分布变化。**

### 我的理解

我认为这篇论文真正改变视角的地方，是把 rubric weight 拆成了两个角色：

```text
训练时有效权重 = 终局重要性 prior × 当前 policy 的可学习性因子
```

过去的静态权重像一张“毕业考试分值表”：主问题 5 分，次要细节 1 分。POW3R 指出，学习过程还需要一张“当前错题分布表”。学生已经稳定会做的 5 分题不应继续占据大部分练习时间；但它仍然是毕业考试中的 5 分题，不能从最终标准里删除。

这个区分解决了一个看似矛盾的问题：动态训练目标并不一定意味着评价目标漂移。只要动态因子是有界的、类别质量预算不变，而且最终仍用原始静态 rubric 评测，就可以改变“现在练什么”，而不改变“最终什么算好”。

## 🔬 方法

### 1. 输入与静态 rubric reward

每个 prompt `q` 有若干 criterion：

```text
(criterion c_j, static weight w_j, category k_j)
```

judge 对 rollout `o_i` 的 criterion `j` 返回二值结果：

```text
s_j(o_i, q) ∈ {0, 1}
```

普通静态奖励直接计算 `sum_j w_j s_j`。论文首先构造 category-balanced baseline：每个已出现的 category 占相同总质量预算，在 category 内再按原始 `w_j` 分配。这样可以避免某个类别仅因为条目更多而支配 reward。

### 2. 从 rollout verdict 估计可学习性

对同一 prompt 的 `G=16` 个 rollouts，计算 criterion `j` 的通过率和 Bernoulli 方差：

```text
p_j = mean_i s_j(o_i, q)
v_j = mean_i (s_j(o_i, q) - p_j)^2
    = p_j(1-p_j)                 # 二值 verdict 时
```

- `p_j=0`：所有 rollout 都失败，dead；
- `p_j=1`：所有 rollout 都通过，saturated；
- `p_j` 接近 `0.5`：criterion 能较均衡地分开当前 rollouts。

作者使用标准差而非裸方差作为信号：

```text
g_j = sqrt(v_j + epsilon)
```

### 3. 在 category 内归一化

对 category `k`，用静态权重计算 `g_j` 的加权平均 `g_bar_k`，再得到相对可学习性：

```text
rho_j = g_j / g_bar_{k_j}
```

所以 POW3R 比较的不是不同类别谁的方差更大，而是同一质量类别内哪些 criterion 更能区分当前 policy。类别总预算因此保持不变。

### 4. 混合、裁剪与 EMA

即时目标因子为：

```text
alpha_hat_j = clip((1-lambda) + lambda*rho_j,
                   alpha_min, alpha_max)
```

再跨轮次做 EMA：

```text
alpha_j_next = clip((1-beta_ema)*alpha_j
                    + beta_ema*alpha_hat_j,
                    alpha_min, alpha_max)
```

论文使用：

- `alpha_min=0.67`；
- `alpha_max=1.5`；
- `epsilon=1e-4`；
- `lambda=0.5`；
- `beta_ema=0.2`；
- 至少 75% 的 16 个 rollouts 有合法 verdict，否则保留旧因子。

这个设计很保守：零方差 criterion 不会被删除，最高区分 criterion 也不能无限增权。如果一个 category 的有效方差信号全部消失，则该类别所有目标因子回到 1。

### 5. 动态 reward

动态权重是：

```text
w_tilde_j = w_j * alpha_j
```

最终仍在每个 category 内归一化，再对 category 求平均。所有 `G` 个 rollouts 使用同一套 `alpha_j`，之后才进入普通 GRPO；优化器和 GRPO objective 不需要改。

需要注意时间顺序：论文在第 `t` 轮使用已有 `alpha_j` 计算 reward，再利用该轮 verdict 更新 `alpha_j^(t+1)`。它不是看到当前组结果后立刻为同一组挑选最有利的 weight。

## 📊 实验与结论

### 数据、模型与评测

论文覆盖两个设置：

- **MM**：作者构建的 10k 多模态 rubric-RL 数据，8k/1k/1k 划分，84,403 条 criterion，平均每题 8.4 条；类别包含 Visual perception、Visual reasoning、Content completeness、Instruction following、Truthfulness、Writing style/presentation。
- **HealthBench English**：文本医疗任务，测试使用 500-task hard split，保留官方评测协议。

MM 使用 Qwen3-VL-4B、Qwen3-VL-8B、Gemma 3 4B；HealthBench 使用三个相应文本模型。训练统一使用 16 rollouts、最多 664 GRPO steps、单节点 8×H100。

训练 judge 是 GPT-5.4-nano，held-out judge 是 GPT-5.4-mini。作者用 1,000 个分层 `(task, rollout, criterion)` 三元组对 judge 做成本—质量校准：训练 judge 对高强度参考 judge 的 verdict agreement 为 91.4%，held-out judge 为 93.6%。作者还发现，去掉逐 criterion 的一句解释虽然总体 agreement 接近，但会破坏模型间排序；把同类别多个 criterion 合并到一次调用也会出现合并或漏判，因此正式实验坚持逐 criterion 独立判断。

### 主结果

作者比较 Base、Binary、Static scalar、Category-balanced 和 POW3R dynamic。POW3R 在两个数据集、六个 base-policy 设置的 30 个主要比较中赢得 24 个。

以 Qwen3-VL-8B 的 MM 结果为例：

| 方法 | Rubric reward | Strict completion |
|---|---:|---:|
| Base | 46.8 | 18.4 |
| Static scalar | 49.5 | 20.7 |
| Category-balanced | 50.4 | 21.6 |
| POW3R dynamic | **51.6** | **22.6** |

这组结果说明提升不只来自更多 partial credit：要求所有 required criteria 都通过的 strict completion 也同步上升。

在 Qwen3-VL-4B/MM 上，POW3R 达到相同 validation reward 阈值所需的训练步数比静态方法少 2.5–4 倍。例如达到 46.0 时，POW3R 需要 83 steps，Static scalar 需要 249，Category-balanced 需要 332。

作者还在 HallusionBench、POPE、MM-IFE、MMVetV2、MathVista、RealWorldQA 六个外部 VLM benchmark 上检查迁移。POW3R 没有在所有单项都获胜，但整体没有出现以 rubric reward 提升换取明显外部能力退化的模式。

### 机制证据

离线 replay 显示，POW3R 将落在 dead/saturated criterion 上的类别内训练压力减少 8–12 个百分点，并使 GRPO 标准化之前的 prompt-level reward spread 平均扩大 25%–37%。这直接减少了 `std(reward)=0`、整组 advantage 全零的情况。

分 category 的训练轨迹也符合机制预期：Visual perception、Visual reasoning、Truthfulness 等仍有较多组内差异的类别提升明显；Writing style 大部分已被基础模型掌握，方差和动态因子变化都较小。

## ⚠️ 局限与需要谨慎解释之处

### 作者明确承认

- 动态因子完全建立在 LLM judge verdict 上，judge 的系统性偏差会改变训练压力方向。
- 同时具有 prompt-specific criteria、人工静态权重、类别和足够规模的数据很少；多模态 MM 数据为内部构建。
- 方法尚未在长代码反馈、科学写作和多语言指令遵循中验证。

### 我的判断

1. **方差本身不检查方向。** 论文能使用 direction-free 方差，是因为 rubric 是人工写的、类别和重要性也有人类先验；若 criterion 由弱模型自动生成，错误 rubric 同样可以产生高方差。
2. **缺少动态因子消融。** 论文没有充分分离 `sqrt`、category normalization、`lambda`、上下界和 EMA 各自的贡献，给出的超参数不能直接视为跨任务最优值。
3. **复现边界较强。** 论文未提供代码链接，MM 的完整数据与细粒度收集信息也没有公开，外部团队更容易复现公式，而难以复现同等数据和 judge 条件。
4. **在线更新要求 prompt 被再次访问。** 动态因子在下一轮才生效；若训练数据只跑一个 epoch、每个 prompt 只出现一次，照搬算法几乎不会产生作用。
5. **逐 criterion judge 成本很高。** 论文证明批量判断会损失排序质量，但这种结论是否适用于其他 judge 必须单独校准。

## 💡 对视觉 caption rubric 项目的借鉴

这篇论文与“根据 rollout 区分度动态决定 rubric weight”的想法几乎正面重合，因此最重要的第一条结论是：**不能再把“variance-based dynamic rubric weighting”本身作为主要新颖点。** POW3R 已经给出公式、训练机制和跨模态实验。

但它也明确告诉我们，caption 场景仍有几个值得研究的差异。

### 1. 不应直接照搬“保留静态权重”

POW3R 的 `w_j` 是人工重要性，因此保留它很合理。我们的 v48 weight 是 rubric generator 自动产生的，而现有 rollout 诊断已经显示高 weight criterion 往往更不具区分度。两者的数据契约不同。

因此至少应比较：

```text
v48-static             原生成权重
v48-equal              去掉生成权重，全部以 1 为 prior
v48-POW3R-static       原权重 × policy-aware factor
v48-POW3R-equal        等权 prior × policy-aware factor
```

如果 `v48-POW3R-equal` 优于 `v48-POW3R-static`，结论不是 POW3R 错，而是 synthetic importance prior 不可靠。

### 2. Caption rubric 需要自己的 category 设计

POW3R 强依赖 category normalization，防止所有压力流向单一质量维度。v48 当前只有 `criterion/evaluation_rule/weight`，没有 category。如果直接全局按方差归一化，OCR、精确数字或冷门细节可能因为容易产生 pass/fail 分裂而吞掉主语义。

caption 场景可先尝试少量稳定类别，例如：

- salient content / required coverage；
- factual correctness / hallucination avoidance；
- attribute, count, relation and visible text；
- scene context / semantic interpretation。

类别应先在 held-out 数据上验证，而不是为了复现 POW3R 临时添加。

### 3. 必须把“有区分度”和“方向正确”分开验证

对人工 rubric，`pass=1` 通常可以作为质量方向。对自动生成 rubric，这一假设更弱。因此我们可以在 POW3R 的方差因子之外，加入 held-out GPT pairwise preference alignment：检查某条 criterion 分开两个 rollout 时，pass 的那个是否也是最终 evaluator 偏好的那个。

这可能形成真正的差异化方向：

```text
Policy-aware contrast × preference-aligned reliability
```

它不是只把 reward spread 做大，而是约束 spread 的方向。

### 4. 当前训练契约不能直接复用论文的跨轮次 EMA

论文使用上一轮 verdict 更新下一轮 factor，并运行足够多 steps 让 prompt 被再次训练。若 caption GRPO 只跑单 epoch，应选择以下之一：

- 先用冻结 policy 生成 pilot rollouts，离线计算 factor，再开始正式 GRPO；
- 改为多 epoch，并持久化 `(sample_uid, criterion_id) -> alpha`；
- 设计经过严格校验的 same-group 重权，但要承认它已经不是论文的 lagged update，并测试是否产生 post-selection 偏差。

第一种最容易做出可复现的初步实验。

### 5. 应先校准当前批量 judge

论文正式流程对每个 criterion 单独调用 judge，并保留一句 reasoning；当前 caption reward judge 在一次请求中返回整套 criterion 的 `items:[{pass}]`。在改动态权重前，应抽取一批 `(image, caption, criterion)`，比较：

- 当前 joint-items 判分；
- 逐 criterion 判分；
- 更强 held-out judge 判分。

如果 joint 模式的逐项 verdict 与模型排序足够稳定，就可以保留其成本优势；否则动态权重会把批量漏判放大。

### 建议的最小实验顺序

1. 用已有 rollout/pass cache 离线重算 `equal`、`static`、`POW3R-equal`、`POW3R-static`，先看 GPT pairwise agreement、explicit reversal、tie rate 和 reward spread。
2. 对 prompt/image 做严格 held-out 划分；计算 factor 的 rollouts 与报告结果的 fresh rollouts 分开。
3. 只在离线结果证明方向正确后，做小规模 GRPO。
4. 再决定是否加入 category、EMA 和 preference-aligned reliability。

## 🔑 关键术语

- **Policy-Aware Rubric Reward（策略感知 rubric 奖励）**：根据当前 policy 的 rollout 行为调整 criterion 训练权重，但保留原 rubric 作为评价目标。例子：暂时降低所有回答都已满足的 criterion 的训练压力。
- **Dead Criterion（当前不可达条目）**：同组 rollout 全部失败、`p=0` 的 criterion。例子：当前模型没有任何回答能完成一个复杂视觉推理要求。
- **Saturated Criterion（饱和条目）**：同组 rollout 全部通过、`p=1` 的 criterion。例子：所有回答都能识别图片中的主对象。
- **Contrastive Criterion（有对比信号的条目）**：同组 verdict 同时包含 pass 与 fail，因而能改变组内 reward 排序。
- **Training Pressure（训练压力）**：一条 criterion 在其类别总 reward 权重中所占的份额。
- **Category Normalization（类别归一化）**：先固定各质量类别的总预算，再在类别内部动态分配 criterion 权重，避免一个类别吞掉全部 reward。
- **Strict Completion（严格完成率）**：回答通过全部 required criteria 的比例，不允许用其他条目的部分得分补偿关键遗漏。

## 🔗 相关论文

- Rubrics as Rewards: Reinforcement Learning Beyond Verifiable Domains
- Co-Evolving LLM Evaluators and Policies via DynamicRubric
- Alternating Reinforcement Learning for Rubric-Based Reward Modeling in Non-Verifiable LLM Post-Training
