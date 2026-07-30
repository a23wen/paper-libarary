---
title: "Co-Evolving LLM Evaluators and Policies via DynamicRubric"
date: 2026-07-30T10:05:00+08:00
draft: false

# 分类（研究领域）
categories: ["强化学习"]

# 会议/期刊
venues: "arXiv 2026"

# 论文元数据
authors: ["Beining Wang", "Weihang Su", "Hongtao Tian", "Hao Kong", "Tao Yang", "Ting Yao", "Qingyi Pan", "Yueyue Wu", "Qingyao Ai", "Min Zhang", "Yiqun Liu"]
year: "2026"
paper_url: "https://arxiv.org/abs/2607.20083v2"
arxiv_url: "https://arxiv.org/pdf/2607.20083v2"
code_url: ""

rating: 5

summary: "DynamicRubric 研究 evaluator-guided post-training 中的评价器滞后问题：随着 policy 变强，同一 prompt 下的候选回答越来越接近，固定 reward model 或预先生成的 rubric 容易失去区分度。论文证明，在候选响应集合内把概率质量从一个回答转移到另一个回答时，局部目标增益恰好等于两者的 evaluator 分差；因此相对分差就是 policy 更新信号。DynamicRubric 让 rubric generator 根据当前 policy 的整组回答动态生成带权二元标准，再用冻结 verifier 打分，并交替优化 evaluator 与 policy。8B generator 在评估上超过更大的零样本 dynamic rubric generator，并作为 policy 监督信号超过 70B reward model 与 235B 静态 rubric supervisor；训练后的生产模型已部署到微信搜索 AI 问答全量流量。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文关注 LLM post-training 里的一个动态问题：

**当 policy 不断变强时，负责监督它的 evaluator 是否也应该跟着变化？**

典型的 evaluator-guided 优化流程是：

- 当前 policy 对一个 prompt 采样多个回答；
- reward model、LLM judge 或 rubric evaluator 给这些回答打分；
- GRPO 等算法根据组内相对分数更新 policy；
- policy 生成分布随之改变。

在训练早期，回答之间的差异通常很大：

- 一个答对，一个答错；
- 一个遵守格式，一个完全忽略；
- 一个有完整推理，一个只有一句结论。

固定 evaluator 很容易区分。

但 policy 变强后，多个回答都可能：

- 基本正确；
- 语言流畅；
- 满足大部分通用标准；
- 只在一个约束、一个推理步骤或一个用户意图上有细微差异。

此时，真正决定下一轮 policy 更新的是这些细小但关键的差别。如果 evaluator 给所有回答相近分数，组内 advantage 会塌缩；如果分差方向错了，policy 还会被推向更差的回答。

DynamicRubric 的核心做法是：

1. 用当前 policy 对 prompt 采样一组 responses；
2. 让 `DR-Generator` 同时看到 prompt 和整组候选；
3. 针对组内真实差异生成带权二元 rubric；
4. 用冻结的 `DR-Verifier` 对每个回答逐条判断 yes/no；
5. 汇总为 response-level score；
6. 先更新 rubric generator，再用更新后的 evaluator 优化 policy；
7. policy 分布变化后，重新生成适配新候选的 rubric。

作者把这称为 evaluator 与 policy 的 **co-evolution**。

## 🎯 研究背景

### 1. Policy optimization 依赖相对信号

在 GRPO、RLHF 或其他基于候选比较的 post-training 中，重要的通常不是一个回答的绝对分数，而是：

- 哪个回答更好；
- 好多少；
- 应该把多少概率质量从差回答转给好回答。

如果同组回答全部得到 `0.8`，就没有更新方向。

如果好回答是 `0.81`、差回答是 `0.80`，信号非常弱。

如果分数方向颠倒，更新就是有害的。

因此 evaluator 的任务不是永远维护一个静态、全局一致的“质量刻度”，而是在当前 policy 产生的候选集合上提供可靠相对差异。

### 2. 静态 rubric 会饱和

Rubric-based evaluation 把总体质量拆成显式标准，例如：

- 是否直接回答用户问题；
- 是否事实正确；
- 是否结构清楚；
- 是否包含必要解释。

这种结构比黑盒标量更可解释，但 rubric 只有在能区分当前候选时才有用。

当所有回答都已经：

- 清晰；
- 基本正确；
- 有条理；
- 没有明显格式错误，

这些宽泛标准就全部通过，分差重新塌缩。

下一轮真正有用的标准可能是：

- 是否漏掉一个隐藏约束；
- 某个推理步骤是否偷换概念；
- 是否错误处理边界条件；
- 给出的建议是否匹配用户真正意图。

这些标准只有在看到当前响应集合后才容易发现。

### 3. 只让 scalar reward model 看到整组回答并不充分

一个可能的简单方案是：把候选集合也喂给现有 reward model。

但论文实验发现，`Skywork-27B w/ responses` 和 `Nemotron-70B w/ responses` 并没有稳定优于各自的 prompt-response 版本，有些指标反而下降。

这说明：

**response-set access 是必要的输入条件，但不是自动获得判别能力的充分条件。**

DynamicRubric 进一步通过：

- 结构化二元标准；
- 组内可分性奖励；
- 有方向的 anchor ranking

把“看到差异”转成可训练目标。

## ⚠️ 问题与挑战

论文要解决的核心问题是：

**如何让 evaluator 随 policy 产生的响应分布共同演化，在候选越来越接近时仍保持方向正确、足够强的相对分差？**

这个目标包含四个困难。

### 1. 因为当前 policy 的在线样本通常没有人工排序，所以很难直接训练 evaluator

训练时可以不断从最新 policy 采样 responses，但这些新回答没有现成人工偏好标签。

因此 evaluator 虽然看到了最新分布，却不知道：

- 哪种差异是真正的质量差异；
- 哪个方向更好；
- 哪些只是表面风格区别。

### 2. 因为“把回答分开”不等于“按质量分开”，所以纯 discriminability 可能奖励错误标准

假设一个 rubric 把回答分成两组：

- 用了“首先”的通过；
- 没用“首先”的不通过。

它具有很强区分度，但与回答质量无关。

更严重的是，任何二元判断全部翻转后，组内方差不变，但偏好方向完全相反。

所以 DynamicRubric 必须同时拥有：

- direction-free 的“是否能区分”信号；
- direction-aware 的“区分方向是否正确”信号。

### 3. 因为 evaluator 和 policy 互相改变对方的数据分布，所以联合优化是非平稳的

- evaluator 决定 policy 往哪里更新；
- policy 更新后又改变 evaluator 面对的候选；
- 旧 evaluator 的标准可能在新 policy 上饱和；
- 同时更新两者又可能造成目标漂移。

论文因此采用双层、交替优化：

1. 固定当前 policy，先适配 evaluator；
2. 固定更新后的 evaluator，再优化 policy。

### 4. 因为动态 rubric 需要 generator 和 verifier 调用，所以训练成本会上升

相比单个 scalar reward model，DynamicRubric 需要：

- 读取整组 responses；
- 生成多条 rubric；
- 用 verifier 将每条 rubric 应用于每个回答。

这增加了输入长度、推理次数和串行延迟。论文通过同 backbone 权重换入换出降低最小 GPU 常驻资源，但总 GPU hours 仍高于规则奖励基线。

## 🔍 核心发现 Finding

### 作者明确声称

作者的核心主张是：

**相对 evaluator 分差就是当前候选集合上的 policy 优化信号；随着 policy-induced response distribution 改变，evaluator 必须适配最新候选，才能持续提供有判别力的更新方向。**

论文从三个层面支持它：

- 理论上证明概率质量转移的局部增益等于 evaluator 分差；
- 实验上显示 response-set-conditioned、经训练的 8B rubric generator 优于更大静态或零样本 evaluator；
- 连续 co-evolution 实验显示，用新 policy 的响应更新 evaluator，再用新 evaluator 更新 policy，优于使用 stale distribution 或 stale evaluator。

### 我的理解

我认为这篇论文最重要的 insight 是：

**Reward 不是一个固定测量仪器，而是 policy 学习过程中的自适应分辨率。**

训练早期需要识别大错误：

- 是否答非所问；
- 是否事实相反；
- 是否完全漏掉指令。

训练后期需要识别小错误：

- 哪个约束没有完全满足；
- 哪一步推理最薄弱；
- 哪个表述虽然正确但不符合用户意图。

如果始终使用同一套宏观评价标准，就像用厘米刻度去测微米级差异。不是回答真的一样好，而是测量工具的分辨率不够。

DynamicRubric 的作用，就是针对当前候选生成一套局部坐标系：

- 只关注这组回答之间真正不同的地方；
- 用共享 rubric 保证组内分数可比较；
- 用二元判断让差异可追踪；
- 用 anchor ranking 保证“分开”的方向与质量一致。

这也解释了为什么一个 8B 动态 evaluator 可以胜过 70B reward model 或 235B 静态 rubric generator：决定监督质量的不只是模型大小，而是评价标准是否对准当前 policy 的剩余误差。

## 🧮 理论视角：为什么分差就是优化信号

### 1. 候选集合上的归一化 policy mass

给定 prompt `x`，从当前 policy 采样 `K` 个回答：

```text
y_1,\ldots,y_K \sim \pi_\theta(\cdot|x), \qquad
C=\{y_1,\ldots,y_K\}
```

把 policy 在集合 `C` 上的概率归一化：

```text
\alpha_i =
\frac{\pi_\theta(y_i|x)}
{\sum_{j=1}^{K}\pi_\theta(y_j|x)}
```

于是：

```text
\sum_{i=1}^{K}\alpha_i=1
```

### 2. 局部目标

对 evaluator `E`，定义候选集合上的局部 proxy objective：

```text
J_{x,C}^{\text{local}}(\alpha;E)
=
\sum_{i=1}^{K}\alpha_i E(x,y_i)
```

它表示 policy 在当前候选上的概率分配与 evaluator 分数的加权和。

### 3. 从差回答向好回答转移概率质量

假设把一个无穷小概率质量从 `y_j` 转给 `y_i`。对应方向是：

```text
d_{i\leftarrow j}=e_i-e_j
```

沿这个方向的导数为：

```text
\left.
\frac{d}{d\epsilon}
J_{x,C}^{\text{local}}(\alpha+\epsilon d_{i\leftarrow j};E)
\right|_{\epsilon=0}
=
E(x,y_i)-E(x,y_j)
```

也就是说：

**从 `y_j` 向 `y_i` 转移概率能带来多大局部收益，恰好由二者的 evaluator score gap 决定。**

因此：

- 分差为正，policy 应提高 `y_i` 的概率；
- 分差越大，更新信号越强；
- 分差为零，没有方向；
- 分差为负，policy 会被推错。

### 4. Response-set-conditioned evaluator 的函数类更大

Prompt-only evaluator 是：

```text
E(x,y)
```

Response-set-conditioned evaluator 是：

```text
E(x,y|C)
```

前者只是后者不使用 `C` 的特殊情况，因此：

```text
\mathcal{E}_{prompt}\subseteq\mathcal{E}_{set}
```

在理论最优条件下，集合条件 evaluator 的期望局部 ranking loss 不会更差，因为它至少可以模拟 prompt-only evaluator，还能利用候选间关系。

需要注意的是，这个结论是函数类包含关系，不代表任意实现都自动更好。论文中 scalar RM 加入 response set 后的混合结果，也说明额外输入必须配合合适的训练目标。

## 🔬 方法

### 1. 三个模型角色

DynamicRubric 包含：

- `DR-Policy`：生成候选回答；
- `DR-Generator`：根据 prompt 和整组 responses 生成 rubric；
- `DR-Verifier`：将每条 rubric 应用于每个回答，输出 yes/no。

三者可以由同一个 backbone 的独立副本初始化。主实验使用：

- DR-Policy：Qwen3-8B；
- DR-Generator：Qwen3-8B；
- DR-Verifier：冻结的 Qwen3-30B-A3B。

附录也验证了 Llama-3.1-8B-Instruct backbone 和多种 verifier。

### 2. 动态 rubric

给定 `(x,C)`，DR-Generator 输出：

```text
\{(r_m,w_m)\}_{m=1}^{M}
```

其中：

- `r_m` 是一条二元 rubric；
- `w_m ∈ {1,\ldots,5}` 是权重；
- rubric 数量 `M` 不固定；
- 权重分配也由 generator 自己决定。

DR-Verifier 对回答 `y` 输出：

```text
v_m(y;C)\in\{0,1\}
```

最终 response-level score 是加权通过率：

```text
E_\phi(x,y|C)
=
\frac{\sum_{m=1}^{M}w_m v_m(y;C)}
{\sum_{m=1}^{M}w_m}
```

同一组回答使用共享 rubric，因此分数差异可以追溯到具体标准。

### 3. Discriminability objective

对 rubric `m`，计算组内通过率：

```text
\bar v_m = \frac{1}{K}\sum_{i=1}^{K}v_m(y_i;C)
```

其 Bernoulli 方差为：

```text
\bar v_m(1-\bar v_m)
```

如果所有回答都通过或都不通过，方差为 0；若回答被较均衡地分开，方差更高。

加权 discriminability reward 为：

```text
R_{\text{disc}}(x,C;\phi)
=
\frac{
\sum_{m=1}^{M}w_m \bar v_m(1-\bar v_m)
}{
\sum_{m=1}^{M}w_m
}
```

它鼓励 generator 针对当前响应集合生成非平凡标准。

### 4. Anchor ranking objective

仅优化可分性会产生错误或无关的分割，所以作者引入 ranked anchor data。

每个 anchor 包含：

```text
C_{\text{anchor}}
=
(y_1^0,\ldots,y_n^0),
\qquad
y_1^0 \succ y_2^0 \succ \cdots \succ y_n^0
```

训练数据来自 Nectar，每个 prompt 有 7 个已排序回答。

关键设计是：

- DR-Generator 只根据当前 policy 的 `(x,C)` 生成 rubric；
- 同一套 rubric 再应用到有排序的 anchor responses；
- generator 不直接看到 anchor 回答来写针对性捷径。

设 anchor response 分数为 `S_i`，作者使用 Bradley–Terry 风格目标：

```text
R_{\text{anchor}}
=
\sum_{i=1}^{n-1}
\sum_{j=i+1}^{n}
\frac{\log\sigma(S_i-S_j)}
{(j-i)\cdot 2^{i-1}}
```

权重强调：

- 排名靠前的回答；
- 排名接近、质量差异细微的 pair。

它给 discriminability 加上正确方向。

### 5. Evaluator objective

两部分结合：

```text
J_{\text{evaluator}}^t
=
J_{\text{disc}}^t
+ \lambda J_{\text{anchor}}^t
```

主实验在 advantage 层面组合二者，并令 `λ=1`。

附录进一步给出：该组合目标可以提高目标相对分差的一个下界。

直观上：

- `J_disc` 问：标准能否把当前回答分开？
- `J_anchor` 问：分开的方向是否符合质量排序？

二者缺一不可。

### 6. Policy objective

更新完 generator 后，冻结它并优化 policy：

```text
J_{\text{policy}}^t
=
\mathbb{E}_{x,C}
\left[
\frac{1}{|C|}
\sum_{y\in C}
E_{\phi_t}(x,y|C)
\right]
```

DR-Policy 使用 GRPO，把同组 rubric score 转换为相对 advantage。

### 7. 双层交替优化

每轮训练包含两个阶段：

1. **Evaluator update**
   - 固定 `P_{t-1}`；
   - 从当前 policy 采样 response set；
   - 优化 `G_{t-1} → G_t`。

2. **Policy update**
   - 固定最新 `G_t`；
   - 用其 rubric score 优化 `P_{t-1} → P_t`。

形式化为：

```text
\phi_t \in
\arg\max_\phi
J_{\text{evaluator}}^t(\phi;\theta_{t-1})
```

```text
\theta_t \in
\arg\max_\theta
J_{\text{policy}}^t(\theta;\phi_t)
```

这就是 evaluator-policy co-evolution。

### 8. 训练配置

主实验使用 WeChat-YATT 中的 GRPO：

- 每个 instance 采样 `K=8` 个回答；
- global batch size：256；
- KL 系数 `β=0.01`；
- DR-Generator learning rate：`5×10⁻⁶`；
- DR-Policy learning rate：`1×10⁻⁶`；
- Policy 最大输入/输出：8K/8K；
- Generator 最大输入/输出：24K/8K；
- 用 SGLang structured output 约束 rubric 和 verifier 生成 JSON。

Generator 需要更长输入，因为它同时读取整组 responses。

## 🧪 实验与结果

### 1. Evaluator benchmark

评估覆盖四个 pairwise 和两个 listwise benchmark：

- JudgeBench；
- Personalized-RewardBench；
- RM-Bench；
- UltraFeedback；
- AEOLLM；
- LMSYS-Chat-1M。

主要结果如下：

| Evaluator | Size | JudgeBench | Personalized-RB | RM-Bench | UltraFeedback | AEOLLM Acc. | LMSYS Acc. |
|---|---:|---:|---:|---:|---:|---:|---:|
| Skywork Reward | 27B | 52.1 | 64.7 | 67.7 | 63.4 | 43.8 | 21.0 |
| Nemotron Reward | 70B | 66.0 | 68.6 | 85.2 | 72.8 | 57.5 | 20.4 |
| Qwen3 zero-shot rubric | 8B | 36.4 | 53.7 | 52.2 | 54.7 | 17.8 | 12.0 |
| Qwen3 zero-shot rubric | 32B | 46.4 | 67.6 | 64.7 | 64.6 | 29.7 | 15.1 |
| **DR-Generator** | **8B** | **57.4** | **73.3** | **69.8** | **68.7** | **51.2** | **28.0** |

结论不是 DR-Generator-8B 在每个指标上都超过 Nemotron-70B；例如 RM-Bench 和 AEOLLM Acc. 仍是 70B 更高。

更准确的结论是：

- 它在全部指标上超过 8B/32B zero-shot dynamic rubric generator；
- 在全部报告指标上超过 Skywork-27B；
- 与 70B scalar reward model 具有竞争力；
- 在 Personalized-RB 与 LMSYS strict accuracy 上超过 Nemotron-70B。

### 2. Policy optimization

作者用不同 supervisor 优化同一个 Qwen3-8B policy，并在四个开放式生成 benchmark 上评估：

| Supervisor | Size | AlpacaEval2 | ArenaHard v2.0 | WildBench | WritingBench |
|---|---:|---:|---:|---:|---:|
| Native Qwen3-8B | — | 38.5 | 9.0 | 16.4 | 57.8 |
| Native Qwen3-32B | — | 50.2 | 20.8 | 29.7 | 62.0 |
| Skywork Reward | 27B | 50.6 | 15.3 | 22.3 | 60.2 |
| Nemotron Reward | 70B | 35.2 | 10.3 | 17.5 | 56.2 |
| RaR static rubric | 235B | 58.5 | 15.7 | 25.2 | 61.6 |
| **DR-Generator** | **8B** | **67.1** | **21.0** | **30.7** | **64.3** |

DynamicRubric 在四项上都最好，并且超过：

- 更大的 32B native policy；
- 27B/70B scalar reward supervision；
- 235B static rubric generator。

作者用 DeepSeek-V4-Flash 作为主 judge，并用 GPT-4.1 复评，排序保持一致。GPT-4.1 评估下，相比 235B 静态 rubric，DynamicRubric 分别提升：

- AlpacaEval2：`+13.0`；
- ArenaHard v2.0：`+9.2`；
- WildBench：`+4.0`；
- WritingBench：`+3.4`。

### 3. Objective ablation

| Evaluator objective | Macro average |
|---|---:|
| 只有 discriminability | 56.9 |
| 只有 anchor | 52.7 |
| 两者结合 | **58.1** |

现象符合方法动机：

- 去掉 anchor，rubric 可以区分回答，但不保证质量相关；
- 去掉 discriminability，方向有校准，但不够适应当前 response set；
- 完整目标兼顾局部分辨率和偏好方向。

### 4. Continuous co-evolution

作者设计两组对比：

#### Evaluator 是否需要适配新 policy

- `G₁` 继续在旧 `P₀` 响应上训练，得到 `G̃₂`；
- `G₁` 在新 `P₁` 响应上训练，得到 `G₂`。

在当前 policy 分布上训练的 `G₂` 更强，而继续使用旧分布可能退化。

#### Policy 是否需要最新 evaluator

- 用旧 `G₁` 更新 `P₁`；
- 用新 `G₂` 更新 `P₁`。

最新 evaluator 在四个生成 benchmark 上都提供更强监督。

这说明 co-evolution 不是只做一次动态 rubric，而是需要持续让评价器追踪 policy-induced distribution shift。

### 5. Verifiable task transfer

虽然 DR-Policy 在开放式生成任务上优化，作者还评估：

- MATH-500；
- MMLU-Pro 的科学问答；
- CodeScope。

DynamicRubric policy 相比初始 policy 在数学、科学 QA 和代码任务上都提升，没有出现开放式偏好优化常见的可验证推理退化。

论文正文图中给出趋势，具体任务评估使用：

- MATH-500：Math-Verify；
- MMLU-Pro：exact match；
- CodeScope：exact match。

### 6. Cross-verifier robustness

作者固定 rubric generator，更换 verifier：

- Llama-3.1-8B-Instruct；
- Qwen3-8B；
- Qwen3-30B-A3B；
- Qwen3-32B；
- Qwen3-235B-A22B。

在每一种 verifier 下，训练后的 DR-Generator-8B 都一致优于 Qwen3-8B 和 Qwen3-32B 的 zero-shot rubric generation。

这说明 learned rubric quality 不是只针对单一 verifier 的 prompt hack。

### 7. Cross-backbone robustness

作者用 Llama-3.1-8B-Instruct 重复完整流程。Llama 版 DR-Generator 在六个 evaluator benchmark 上都优于原始 zero-shot Llama generator。

这表明方法不局限于 Qwen backbone。

### 8. 计算开销

计算成本以 rule-based Qwen3-8B policy training 为 `1×`：

| Supervisor | 最小 GPU allocation | 实际 GPU hours |
|---|---:|---:|
| Rule-based | 1× | 1× |
| Skywork-27B | 1.125× | 2.2× |
| Nemotron-70B | 1.5× | 2.4× |
| RaR 235B static rubric | 1×* | 2.5×* |
| DynamicRubric 8B | 1× | 3.0× |

星号表示 RaR 的数值没有计入用 235B generator 为 36K prompts 离线生成 rubric 的成本。

DynamicRubric 的优势是三个角色属于同一 backbone family，可以用 SGLang flush/reload 权重，最小常驻 GPU 不增加；代价是在线生成和逐项验证让总训练时间达到 `3×`。

### 9. 微信搜索线上部署

生产模型使用 WeLM-V4-80B-A3B。

论文报告：

- 场景是微信搜索 AI 问答；
- 每天处理数千万请求；
- A/B test 相比旧生产模型，在总搜索量、用户时长和绝对正向用户行为上获得统计显著提升；
- 优化后的模型已替换旧模型，服务全量线上流量。

由于商业保密，论文没有公布：

- 指标绝对值；
- 相对提升幅度；
- 实验时长；
- 流量切分；
- 置信区间。

所以这部分能证明方法已在真实规模部署，但无法独立评估线上收益大小。

## 💡 关键洞察

### 1. Rubric 的作用不是解释分数，而是制造可用分差

很多 rubric 方法把标准当作 evaluator 输出后的解释层。DynamicRubric 更强调它的优化功能：

- rubric 决定哪些差异会被看见；
- verifier 判断各回答是否满足；
- 权重决定这些差异对 policy advantage 的贡献。

因此 rubric 本身就是 reward shaping 的结构。

### 2. “动态”至少有两个层次

DynamicRubric 同时包含：

1. **Instance-level dynamic**
   - 每个 prompt、每组 responses 都生成不同 rubric。

2. **Training-time dynamic**
   - policy 更新后，generator 也在新响应分布上继续训练。

只做第一层而不做第二层，evaluator 仍可能随着 policy 变强而滞后。

### 3. Shared rubric 提供组内共同坐标系

如果每个回答单独生成一套标准，两个总分未必可比。

DynamicRubric 先为整组 responses 生成共享 rubric，再逐个应用。这让 score gap 可以解释为：

- 回答 A 通过了哪条；
- 回答 B 漏了哪条；
- 哪条差异权重更高。

### 4. Discriminability 与 correctness 是正交要求

一个 evaluator 可以：

- 方向正确但分差很小；
- 分差很大但方向错误。

前者训练信号弱，后者训练信号有害。

`J_disc + J_anchor` 正是在分别处理：

- 强度；
- 方向。

### 5. Evolving evaluator 可以看作一种在线课程

随着 policy 能力变化，rubric 会从：

- 大粒度错误

逐渐转向：

- 当前模型仍未解决的细粒度问题。

这相当于 evaluator 自动调整训练课程，不断把监督集中到“下一步最值得修的差异”。

## 📉 局限性与批判性评价

### 1. 训练时间成本仍然较高

DynamicRubric 的总 GPU hours 是规则奖励基线的 `3×`。虽然低于“持续常驻多个大模型”所需的最小资源，并且 235B 静态 rubric 基线还漏算了离线生成成本，但实际 wall-clock latency 仍受到串行 generator-verifier 调用影响。

响应集合更大、rubric 更多或 verifier 更强时，成本可能继续上升。

### 2. Verifier 决定可学习信号的上限

Rubric 写得再好，也需要 verifier 正确判断回答是否满足。

论文虽然测试了多个 verifier，但训练中保持 verifier 冻结，没有研究：

- verifier 与 generator 一起演化；
- rubric-specific calibration；
- 多 verifier ensemble；
- 对抗性回答如何利用 verifier。

因此方法把一部分 reward model 风险转移到了 rubric verification。

### 3. Discriminability 可能鼓励过度局部化

生成器被奖励寻找组内差异，可能产生很具体、很容易分割当前候选的标准。

Anchor objective 提供方向校准，但仍需要进一步研究：

- rubric 是否过拟合当前采样组；
- 同一 prompt 重新采样后标准是否稳定；
- 局部偏好是否与全局用户价值一致；
- policy 是否会利用反复出现的 verifier 模式。

### 4. 理论结论是局部 proxy 分析

“分差等于概率转移的方向导数”在定义的候选集合局部线性目标上是精确的。

但真实 LLM 参数更新还受到：

- token-level parameter sharing；
- KL regularization；
- rollout sampling noise；
- credit assignment；
- policy parameterization；
- optimizer dynamics

影响。

因此理论很好地解释了为什么 score gap 重要，但不能单独保证更大分差必然带来更好的全局 policy。

### 5. Response-set function class 更大不等于实践中一定更好

集合条件 evaluator 的理论函数类包含 prompt-only evaluator，但额外条件也可能带来：

- 顺序偏差；
- 候选间相互污染；
- 长上下文退化；
- 对集合组成敏感。

论文里 scalar RM 加 response set 后反而出现混合结果，恰好说明“条件更多”本身不是性能保证。

### 6. 线上结果不可量化复核

微信搜索部署规模很有价值，但因为业务保密，没有报告具体数值。读者无法判断：

- 提升是 0.1% 还是 10%；
- 哪个指标最稳定；
- 是否存在某些用户群体或 query 类型退化；
- evaluator 更新如何处理安全、事实性和商业目标之间的冲突。

### 7. 自动 judge 仍可能有偏差

开放式 policy benchmark 主要依赖 DeepSeek-V4-Flash，并用 GPT-4.1 做鲁棒性复评。两个 judge 都支持同一排序，提高了可信度，但并不等同于人工盲评。

尤其 AlpacaEval、ArenaHard、WritingBench 等开放任务容易受到：

- 长度偏好；
- 风格偏好；
- judge 家族偏好；
- 表面结构

影响。

## 🔗 与相关工作的关系

### 与静态 Rubric-as-Reward 的区别

静态 RaR：

- 主要根据 prompt 预先生成 rubric；
- 不观察当前 policy 的候选集合；
- 生成后不随 policy 演化。

DynamicRubric：

- 根据 prompt 和当前整组 responses 生成；
- 目标是区分当前候选；
- generator 随 policy 分布持续更新。

### 与 Rubric-ARM 的区别

两者都把 rubric generator 从固定 prompt 模块变成可训练组件，但重点不同：

- Rubric-ARM 主要通过 preference correctness 交替优化 rubric generator 和 judge；
- DynamicRubric 固定 verifier，把 evaluator 训练重点放在当前 response set 的 discriminability 与 anchor-calibrated direction；
- DynamicRubric 还显式论证 evaluator 必须跟踪 policy-induced distribution shift。

### 与 scalar reward model 的区别

Scalar RM 学习：

```text
(x,y)\rightarrow s
```

DynamicRubric 学习：

```text
(x,C)\rightarrow \text{rubrics}
\rightarrow
\{(y_i,\text{binary judgements})\}
\rightarrow s_i
```

后者把“为什么有分差”暴露成中间结构，也允许标准依赖同组候选。

## 📝 总结

DynamicRubric 的核心贡献是把 evaluator 从一个静态裁判改造成与 policy 共同演化的训练参与者。

它首先给出一个清晰理论视角：

> 在当前候选集合上，两个回答的 evaluator 分差，就是把概率质量从一个转向另一个的局部收益。

由此，评价器最重要的能力不是输出看似精确的绝对分数，而是：

- 在当前 policy 的响应上保持足够区分度；
- 保证分差方向与真实质量一致；
- 随 policy 分布变化及时更新。

DynamicRubric 用三部分实现这一点：

1. response-set-conditioned 的带权二元 rubric；
2. `discriminability + anchor ranking` 的 evaluator 目标；
3. evaluator 先更新、policy 后更新的双层 co-evolution。

实验上，8B DynamicRubric supervisor 在四个开放式生成 benchmark 上超过 70B scalar reward model、235B 静态 rubric generator 和原生 32B policy，并且方法已用于微信搜索 AI 问答的全量线上模型。

如果把这篇论文压缩成一句话：

> **Policy 越强，剩余错误越细；评价器如果不提高分辨率，就会成为 post-training 的瓶颈。**
