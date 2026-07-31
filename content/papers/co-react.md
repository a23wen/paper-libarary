---
title: "Co-ReAct: Rubrics as Step-Level Collaborators for ReAct Agents"
date: 2026-08-01T01:35:00+08:00
draft: false

# 分类（研究领域）
categories: ["强化学习"]

# 会议/期刊
venues: "arXiv 2026"

# 论文元数据
authors: ["Jiazheng Kang", "Bowen Zhang", "Zixin Song", "Jiangwang Chen", "Xiao Yang", "Da Zhu", "Guanjun Jiang"]
year: "2026"
paper_url: "https://arxiv.org/abs/2605.23590"
arxiv_url: "https://arxiv.org/pdf/2605.23590"
code_url: "https://github.com/ZBWpro/Co-ReAct"

rating: 4

summary: "Co-ReAct 把 rubric 从训练奖励或最终报告评分表，改造成 ReAct 搜索智能体在每个决策点使用的行动规范。系统根据问题与当前轨迹生成带权 step-level rubric，引导下一次 Reason-or-Act，再用独立 verifier 检查行动并在失败时定向重试。为避免貌似合理但实际误导搜索的 rubric，作者从真实轨迹分叉点构造四候选行动排序数据，以三位 frontier judge 的 Borda 共识为目标，用 listwise Spearman reward 和 GRPO 训练 Qwen3-14B rubric generator。Co-ReAct 在 DeepResearchBench 与 SQA-CS-V2 上跨 8B、14B 和闭源模型稳定提升，并可作为插件增强 Best-of-N、Step-Back 与 CRITIC。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文研究的是 deep research agent 在搜索过程中的一个局部决策问题：

**当智能体已经看过一部分证据、正准备采取下一步行动时，谁来告诉它“这一步具体应该做到什么”？**

标准 ReAct 把搜索组织成循环：

1. `Reason`：模型根据问题和当前轨迹思考；
2. `Act`：调用搜索、论文检索或网页浏览工具；
3. `Observe`：读取工具返回结果；
4. 重复以上过程，直到模型决定输出答案。

这个框架简洁，但下一步往哪里走几乎完全依赖模型自己的即时判断。模型可能：

- 重复发起意思相近的查询；
- 看到一个貌似合理的答案后过早停止；
- 一直围绕同一类来源搜索；
- 用摘要 snippet 代替打开原始来源；
- 没有针对当前缺失信息设计查询；
- 产生了不合格行动，却不知道具体该改哪里。

已有方法会增加 test-time compute：

- Self-Refine 让模型自我批评后重写；
- Best-of-N 采样多个候选再选一个；
- Step-Back 先抽象出高层视角；
- CRITIC 用工具做外部检查。

但这些方法的指导信号通常来自未经训练的 prompted LLM，而且往往是泛化的“再想想”“检查一下”或整体评分。

Co-ReAct 提出的变化是：

**在每个工具调用之前，先生成一份只针对当前轨迹状态的带权 rubric，明确下一步行动应该满足哪些可检查条件；行动提出后，再按同一份 rubric 验证，失败就携带逐项反馈重试一次。**

于是标准 ReAct 的三元组：

```text
(Reason, Act, Observe)
```

变成五元组：

```text
(Rubric, Reason, Act, Verify, Observe)
```

rubric 不再只回答“已经生成的结果值多少分”，而是提前回答：

> 在这个具体分叉点，下一步要满足什么条件，才更可能把整条搜索轨迹带向高质量答案？

## 🎯 研究背景

### 1. ReAct 把推理和工具调用串起来，但没有外部行动规范

ReAct 的重要贡献是让语言模型交替执行自然语言推理与环境行动。对 deep research 来说，行动可能是：

- `google_search`：搜索开放网页；
- `academic_search`：检索论文；
- `browse_webpage`：打开具体页面读取原始内容。

每一步都改变后续可见信息，因此局部行动质量会沿轨迹累积。

例如一个问题要求比较某项技术与两个既有方法：

- 如果第一步只搜技术名称，可能找到项目主页；
- 如果第二步继续搜新闻稿，可能得到发布日期；
- 如果第三步仍只看摘要，就可能误解模型结构；
- 一处错误最后会进入长报告，形成带引用的事实性错误。

所以 deep research 的质量不仅取决于最终写作模型，也取决于搜索阶段每个分叉点选择了什么行动。

### 2. Test-time compute 试图修正行动，但指导信号往往不够具体

现有增强方法主要增加推理或采样预算：

- **Self-Refine**：让模型判断自己的行动是否需要修改；
- **Best-of-N**：并行生成多个候选轨迹，再选最高分者；
- **Step-Back**：先从问题中抽象更高层目标；
- **CRITIC**：调用工具检查中间结果，再根据反馈重试。

它们都承认单次自回归决策不够可靠，但仍存在两个问题：

1. 指导信号通常由未专门训练的模型生成；
2. 信号没有被校准为“能否在当前候选行动中排出正确顺序”。

一段批评可能听起来很专业，却没有真正改变行动选择。

### 3. Rubric 过去主要是评价工具，而不是行动工具

Rubric-based 方法通常用在：

- 训练时的 reward；
- LLM-as-a-Judge 的评分模板；
- 完成答案后的解释性评估；
- deep research 最终报告的完整性、引用和忠实度检查。

这些用法解决的是：

> 已经产生的回答应该获得多少 credit？

Co-ReAct 关心的是另一个问题：

> 根据已经看过的证据，下一步应该满足哪些要求？

评价是 retrospective 的，行动指导则是 prescriptive 的。论文的主要概念变化就在这里。

### 4. 为什么归入「强化学习」

这篇论文的应用场景是信息检索与 deep research，但核心方法贡献是：

- 构造分叉点上的 listwise preference data；
- 定义 rubric-induced ranking reward；
- 用 GRPO 训练 rubric generator；
- 通过消融验证 RL 与 listwise reward 的必要性。

仓库中 Rubrics as Rewards、Rubric-ARM、DynamicRubric 等相似工作都归入「强化学习」，因此这里保持同一分类。

## ⚠️ 问题与挑战

论文要解决的问题是：

**如何为固定的 ReAct 搜索策略提供可靠、轨迹相关、可以直接影响下一步行动的外部指导，而不重新训练搜索 agent 本身？**

这个问题有四层因果性挑战。

### 1. 因为正确行动依赖当前轨迹，所以 query-level 通用 rubric 不够

同一个研究问题在不同阶段缺少的信息不同。

例如：

- 开始时需要广泛寻找候选方向；
- 已找到核心论文后，需要打开 primary source；
- 已掌握方法后，需要检索对比基线；
- 已有多个来源后，需要核对时间、数字或冲突陈述。

如果只在问题开始时生成一份“答案应全面、有引用”的 rubric，它无法告诉第 3 步究竟应该搜索什么。

因此 rubric 必须条件化于：

- 原始问题 `q`；
- 当前轨迹前缀 `h_t`；
- 已采取行动与已观察证据。

### 2. 因为自然语言标准很容易“听起来合理”，所以 plausible rubric 不等于 useful rubric

一个 rubric 可以写得非常漂亮：

- 使用权威来源；
- 保持搜索全面；
- 避免遗漏重要信息。

但如果它不能区分当前四个候选行动哪个更好，就不会改善搜索。

更糟的是，rubric 会被注入模型上下文。错误标准不只是没有帮助，还可能让模型主动选择更差行动。

论文消融正好验证这一点：用未经过 RL 训练的 base model 生成 rubric，SQA-CS-V2 Global Average 从标准 ReAct 的 `72.76` 降到 `72.44`。

所以方法真正需要的不是“会写 rubric 的模型”，而是“rubric 所诱导的行动排序与专家排序一致的模型”。

### 3. 因为一个分叉点通常有多个看似合理行动，所以 pairwise 信号不够完整

在真实搜索步骤中，可能同时存在：

- 一个更具体的 Google query；
- 一个论文检索 query；
- 打开已经找到的原始页面；
- 换一个实体或年份继续搜索。

二元偏好只告诉模型 A 比 B 好，却没有利用整组候选的相对结构。

Co-ReAct 因此使用 listwise ranking：一次比较四个行动，并要求 rubric 诱导出的完整排序接近专家共识排序。

### 4. 因为增加验证和重试会提高推理成本，所以质量提升必须来自定向纠错

每一步新增：

- 一次 rubric generation；
- 一次逐项 verification；
- 失败时最多一次 retry。

如果 verifier 过严，会频繁重试并浪费预算；如果过松，验证步骤形同虚设。

因此系统需要一个平衡：只拦截真正不满足当前行动规范的步骤，并让反馈足够具体，保证一次重试就能修正。

## 🔍 核心发现 Finding

### 作者明确声称

作者明确提出：

**Rubric 可以从“对已完成输出进行评分的评价对象”，转变为“在推理时被 agent 消费的、轨迹感知的 step-level 行动选择信号”。**

但只有经过 listwise expert-ranking 对齐的 rubric 才可靠。论文把这类 rubric 称为 step-level collaborator：

- 行动之前给出目标；
- 行动之后提供验证标准；
- 失败时把未满足条件变成重试反馈。

### 我的理解

我认为这篇论文真正的新视角是：

**搜索智能体的局部失败，很多时候不是缺少更多思考，而是缺少一份对当前分叉点足够具体的“行动合同”。**

Self-Refine、Best-of-N 和 CRITIC 都在增加 compute，但它们主要让模型：

- 多想一次；
- 多采样几次；
- 多检查一次。

Co-ReAct 则先改变“检查什么”：

1. 根据当前轨迹诊断下一步的缺口；
2. 把缺口写成原子化、带权、可验证的标准；
3. 让行动生成和行动验证共享这份标准；
4. 只在行动违反标准时重试；
5. 用专家完整排序训练 rubric generator，使标准真正具有选择能力。

可以把它类比成代码协作中的验收条件。

如果只对工程师说“把功能写好”，他可能继续沿错误方向实现；如果在动手前明确：

- 必须调用已有接口；
- 必须覆盖某个边界条件；
- 不得修改公共 schema；

那么这些条件既能引导实现，也能在完成后检查。

Co-ReAct 给搜索行动做了类似处理。

### Finding 如何解决前面的挑战

逻辑链如下：

```text
当前轨迹决定当前缺口
        ↓
轨迹条件 rubric 把缺口写成下一步要求
        ↓
要求在行动生成前作为上下文约束
        ↓
同一要求在行动执行前用于逐项验证
        ↓
失败条件直接成为定向重试反馈
        ↓
listwise GRPO 保证这些要求能诱导专家一致的候选排序
```

这条链的关键不是 rubric 的语言形式，而是 rubric 同时连接了：

- trajectory state；
- action generation；
- action verification；
- retry feedback；
- expert preference。

## 🔬 方法

方法分为三个阶段：

1. 从真实 ReAct 轨迹的分叉点收集候选行动及专家排序；
2. 用 listwise Spearman reward 和 GRPO 训练 rubric generator；
3. 推理时运行 inject–verify–retry 循环，或把 rubric 作为插件注入其他方法。

### 第一阶段：收集 branching-point preference data

#### 输入是什么

给定一个 research query `q`，ReAct 轨迹表示为：

```text
(a_1, o_1, a_2, o_2, ...)
```

其中：

- `a_t` 是第 `t` 步行动；
- `o_t` 是环境观察；
- `h_t` 是第 `t` 步之前的完整轨迹前缀。

每个 `(q, h_t)` 都被看成一个 branching point：在这里，agent 可以采取多个不同的下一步行动。

#### 生成多样化候选

作者在每个分叉点生成 12 个 continuation：

- Qwen3-8B；
- Qwen3-14B；
- Qwen3-32B；

每个模型分别使用四个温度：

```text
{0.1, 0.4, 0.7, 1.0}
```

组合不同模型规模和采样温度，是为了让候选不仅措辞不同，也覆盖不同搜索策略。

#### 去重并选择四个候选

作者先删除完全重复的行动，再使用基于 BM25 相似度的 Maximum Marginal Relevance 选择 `k=4` 个候选。

MMR 同时考虑：

- 候选是否具有代表性；
- 候选之间是否足够不同。

如果一个分叉点已经输出最终答案，或者无法得到四个不同候选，就丢弃该样本。

#### 多 judge 生成完整排序

四个候选随机重排，并改名为中性标识：

```text
{X, Y, Z, W}
```

这样可以减少位置和模型身份偏差。

三位不同模型家族的 frontier judge 分别输出完整排序：

- Claude 4.5 Sonnet；
- Gemini 2.5 Pro；
- GPT-5。

作者使用 Borda count 聚合：把每个候选在三份排序中的名次相加，再按总名次得到 expert consensus ranking。

只有至少两位 judge 返回可解析完整排序的分叉点才保留。

#### Depth-wise expansion

作者不是先固定一条普通 agent 轨迹，再离线抽取其中的步骤。

在每个深度：

1. 采样四个候选；
2. 获得专家排序；
3. 只执行排名第一的行动；
4. 把它的 observation 加入历史；
5. 在新轨迹前缀上继续采样下一组候选。

这样收集到的训练状态沿着专家偏好的 trajectory spine 展开。

最终数据规模是：

- 11,406 个 DR-Tulu 训练 query；
- 29,866 个有效 branching point；
- 每个 branching point 有四候选完整排序。

### 第二阶段：用 listwise GRPO 训练 rubric generator

#### Generator 的输入与输出

Rubric generator 是一个自回归策略：

```text
pi_theta(R | q, h_t)
```

输入：

- 原始研究问题；
- 当前部分轨迹。

输出是一组简短、带权标准，用来说明一个好行动应该覆盖什么。

例如某一步可能生成：

```text
[0.5] 使用 browse_webpage 打开 primary source
[0.3] 查询中必须比较 Marigold 与 ChronoDepth
[0.2] 将结果限制在 2024 年
```

#### Rubric-induced ranking

对一个采样 rubric `R`，独立 evaluator LLM 读取：

```text
(q, h_t, candidate_action, R)
```

然后计算候选行动满足了多少带权标准。四个候选按满足比例排序，得到 rubric-induced ranking。

#### Listwise Spearman reward

主奖励比较：

- rubric-induced ranking；
- multi-judge expert consensus ranking。

作者使用 Spearman rank correlation，并把范围从 `[-1, 1]` 映射到 `[0, 1]`：

```text
r_rank(R) = (Spearman(rubric_ranking, expert_ranking) + 1) / 2
```

因此：

- 完全反向排序得到 0；
- 随机排序的期望约为 0.5；
- 完全一致得到 1。

这个目标直接惩罚“写得合理但排不对行动”的 rubric。

#### 两个轻量 shaping reward

总奖励还加入：

- `r_atom`：鼓励每条 criterion 只检查一个事实或要求；
- `r_fmt`：保证输出符合预期 schema。

权重为：

```text
r(R) = 0.75 * r_rank + 0.15 * r_atom + 0.10 * r_fmt
```

如果 rubric 的 4-gram 重复率超过 40%，总奖励直接清零，防止模型用重复模板刷格式奖励。

#### GRPO 配置

Rubric generator 从 Qwen3-14B 初始化：

- 每个 branching point 采样 `G=8` 份 rubric；
- 组内标准化 reward 得到 relative advantage；
- 训练 2 个 epoch；
- learning rate：`2 × 10^-6`；
- KL coefficient：`5 × 10^-3`；
- gradient clipping norm：`1.0`；
- Spearman 排序由独立 Gemini 2.5 Pro evaluator 计算。

需要强调：作者训练的是外部 rubric generator，不是底层搜索 policy。

### 第三阶段：Co-ReAct 推理

每个工具调用步骤执行三项新操作。

#### 1. Inject

Rubric generator 根据 `(q, h_t)` 生成当前步骤的 rubric，并加入 search agent 上下文。

search agent 随后基于：

- 原始问题；
- 当前轨迹；
- 当前 rubric

生成 Reason 与 Act。

#### 2. Verify

行动尚未真正执行前，独立 verifier 逐项检查它是否满足 rubric。

系统计算带权 criterion 通过比例。当比例超过阈值：

```text
tau = 0.5
```

行动才被接受并发送给工具。

#### 3. Retry

如果验证失败：

- verifier 返回每条未满足 criterion；
- rubric 与逐项反馈固定在上下文；
- agent 重新规划该步骤；
- 重试行动替换原行动。

每一步最多重试一次，以控制推理成本。

### 推理配置

- Rubric generator：temperature `0.7`，top-p `0.95`；
- 每份 rubric 最多 1,024 output tokens；
- Search agent：temperature `0`；
- Verifier：temperature `0`；
- Search trajectory 在进入 answer rewriter 前截断到 6,000 tokens。

### Drop-in plugin 模式

训练好的 rubric generator 不一定要使用完整 verify–retry loop。

它也可以只把当前 rubric 注入已有方法：

- Best-of-N；
- Step-Back；
- CRITIC。

原方法的选择或纠错机制保持不变。这用来检验 rubric 是独立可组合的行动信号，还是只能在 Co-ReAct 自己的 pipeline 中工作。

## 🧪 实验与结论

### 1. 数据集

#### DeepResearchBench（DRB）

包含中文和英文开放研究问题，需要：

- 多轮网页搜索；
- 长篇报告生成；
- 引用证据。

使用 RACE protocol，从四个维度评估：

- `Comp.`：Comprehensiveness；
- `Ins.`：Insight；
- `IF`：Instruction Following；
- `Read.`：Readability；
- `Avg.`：整体平均。

#### SQA-CS-V2

包含需要搜索和引用综合的计算机科学问题，指标包括：

- `IR`：Ingredient Recall；
- `AP`：Answer Precision；
- `CR`：Citation Recall；
- `CP`：Citation Precision；
- `Avg.`：全局平均。

### 2. 对照方法与公平性控制

对照方法包括：

- ReAct；
- Self-Refine；
- Best-of-N，`N=4`；
- Step-Back；
- CRITIC；
- Co-ReAct。

主实验分别使用 Qwen3-8B 和 Qwen3-14B 作为 search agent。

所有方法共享：

- academic search；
- Google search；
- webpage browsing；
- Qwen3-235B answer rewriter。

这样最终报告的写作模型保持一致，差异主要来自搜索轨迹质量。

DRB 与 SQA-CS-V2 都使用官方协议和 Gemini judge。

### 3. 主结果

#### Qwen3-8B search agent

| 方法 | DRB Avg. | SQA Avg. |
|---|---:|---:|
| ReAct | 33.18 | 72.76 |
| Self-Refine | 33.71 | 74.18 |
| Best-of-N | 33.27 | 70.08 |
| Step-Back | 32.05 | 69.00 |
| CRITIC | 33.37 | 71.69 |
| **Co-ReAct** | **34.01** | **74.80** |

Co-ReAct 在两个 benchmark 都最高：

- DRB 相比 ReAct 相对提升 `2.50%`；
- SQA 相比 ReAct 相对提升 `2.80%`；
- 相比最强 baseline Self-Refine，分别高 `0.89%` 和 `0.84%`。

#### Qwen3-14B search agent

| 方法 | DRB Avg. | SQA Avg. |
|---|---:|---:|
| ReAct | 34.23 | 72.73 |
| Self-Refine | 34.24 | 74.22 |
| Best-of-N | 33.19 | 70.81 |
| Step-Back | 31.69 | 68.19 |
| CRITIC | 35.64 | 73.40 |
| **Co-ReAct** | **36.92** | **76.05** |

14B 上优势进一步扩大：

- DRB 相比 ReAct 相对提升 `7.86%`；
- SQA 相比 ReAct 相对提升 `4.56%`；
- 比第二名 CRITIC 的 DRB 高 `3.59%`；
- 比第二名 Self-Refine 的 SQA 高 `2.47%`。

SQA 的 Ingredient Recall 从 `48.23` 增至 `57.62`，相对提升 `19.5%`，是最显著的子指标变化。

这说明 rubric 主要帮助 agent 找齐更多关键证据，而不是只改善最终措辞。

### 4. 一个反直觉结果：更强 agent 从 rubric 中获益更多

从 8B 扩展到 14B 后，Co-ReAct 相对 ReAct 的提升扩大：

- DRB：`2.50% → 7.86%`；
- SQA：`2.80% → 4.56%`。

作者据此认为，更强模型不是更不需要 rubric，反而更能理解并执行结构化行动要求。

我的理解是：rubric 更像“方向信息”而不是“能力替代品”。弱模型即使知道该查什么，也未必能很好构造查询或利用证据；强模型拿到明确目标后，更容易把能力转化为有效行动。

### 5. Baseline 的不同失败模式

实验展示了 test-time compute 并非越多越好。

#### Best-of-N

在 SQA 上平均只有 3.0 次工具调用，而 ReAct 有 5.2 次。很多候选在得到貌似合理答案后就提前停止，外部 scorer 又倾向选中这些短轨迹，因此证据覆盖下降。

#### Step-Back

它在 SQA 上得到最高 Answer Precision：

- 8B：`81.08`；
- 14B：`82.19`。

但 Ingredient Recall 和 Citation Recall 较低。说明高层抽象有时能使回答更聚焦，却会把 agent 从细粒度检索上带走，形成 precision–recall trade-off。

#### Self-Refine 与 CRITIC

二者是最强 baseline，因为都包含检查和纠错。但它们依赖 search agent 自己诊断缺口，Co-ReAct 则把这项工作交给经过 RL 训练的专用 rubric generator。

### 6. Ablation study

消融在 SQA-CS-V2、Qwen3-8B search agent 上进行：

| 配置 | RL 训练 | Verify | Global Avg. |
|---|---|---|---:|
| 无 Co-ReAct | 无 | 无 | 72.76 |
| 未训练 rubric | 无 | 有 | 72.44 |
| Pairwise GRPO | Pairwise | 有 | 74.04 |
| 无 verification | Listwise | 无 | 74.08 |
| **完整 Co-ReAct** | **Listwise** | **有** | **74.80** |

这个表支持三个结论。

#### 结论一：Rubric quality 是硬前提

未训练 rubric 得分 `72.44`，低于无 rubric 的 ReAct `72.76`。

所以自然语言 checklist 并非无害；未校准标准会误导 agent。

#### 结论二：Listwise 比 pairwise 更适合行动 slate

Pairwise GRPO 为 `74.04`，完整 listwise 为 `74.80`。

四候选完整排序提供了更丰富的相对信息，也与推理时“多个行动都可能合理”的结构更匹配。

#### 结论三：Inject 已贡献大部分增益，verify–retry 提供额外纠错

关闭 verification 后仍有 `74.08`，说明训练后的 rubric 作为上下文指导本身有效；加入 verify–retry 后再提升到 `74.80`，相对增加约 `0.96%`。

### 7. 搜索行为分析

| 方法 | Tool Calls | Links | Citations | Utilization |
|---|---:|---:|---:|---:|
| ReAct | 5.2 | 12.7 | 11.2 | 0.88 |
| Self-Refine | 4.3 | 16.6 | 15.1 | 0.91 |
| Best-of-N | 3.0 | 9.7 | 8.2 | 0.85 |
| Step-Back | 4.1 | 10.5 | 9.1 | 0.87 |
| CRITIC | 5.0 | 14.2 | 12.8 | 0.90 |
| **Co-ReAct** | **6.5** | **19.3** | **18.6** | **0.96** |

相较 ReAct：

- 工具调用增加约 25%；
- 检索链接增加约 52%；
- 唯一引用来源增加约 66%；
- utilization 从 0.88 升到 0.96。

如果只有 tool calls 增加，可能只是暴力搜索；但链接、引用和利用率同时提升，说明额外调用更可能找到真正进入答案的证据。

CRITIC 使用 5.0 次调用，却只得到 14.2 个链接。作者解释，CRITIC 的额外搜索更偏向检查已有结果，而 Co-ReAct rubric 更常引导发现新证据。

### 8. Verification 是否过度触发

在 SQA 评估集上：

- 共执行 743 个 rubric-guided step；
- 平均每个问题 7.4 步；
- 159 步验证失败；
- failure/retry rate 为 `21.4%`。

约五分之一行动被拦截，说明 verifier 既不是几乎永远通过，也不是大多数行动都拒绝。

不过论文只用最终分数证明 retry 有益，没有进一步报告：

- retry 后的通过率；
- 每类 criterion 的失败频率；
- 额外 token、延迟和 API 成本。

### 9. 闭源模型泛化

作者还在 Gemini 3.1 Pro 上测试 prompt-only Co-ReAct：

- Gemini 同时担任 search agent、answer generator 和 rubric generator；
- 没有 GRPO fine-tuning；
- 仍使用 step-level rubric 与 verification feedback。

在 DRB 上：

- Co-ReAct Overall RACE 为 `37.13`；
- 相比 ReAct 相对提升 `4.44%`；
- 相比最强 baseline Step-Back 相对提升 `3.89%`；
- 所有子指标均为最高。

Self-Refine、Best-of-N 和 CRITIC 在这个强模型上都没超过 ReAct，作者认为通用自我修正和重采样在强 agent 上边际收益下降，而结构化 rubric 仍能提供新信息。

需要注意：这个实验测试的是 Co-ReAct 的 prompt paradigm，不是 GRPO-trained rubric generator 的跨 API 迁移。

### 10. Plug-in rubric portability

作者把训练好的 14B rubric generator 注入其他方法，同时关闭 verify–retry：

| 方法 | DRB 原分数 | 注入后 | 相对提升 | SQA 原分数 | 注入后 | 相对提升 |
|---|---:|---:|---:|---:|---:|---:|
| Best-of-N | 33.2 | 35.7 | +7.6% | 70.8 | 75.7 | +6.9% |
| Step-Back | 31.7 | 36.4 | +14.8% | 68.2 | 75.3 | +10.5% |
| CRITIC | 35.6 | 36.3 | +1.8% | 73.4 | 74.2 | +1.2% |

六个“方法 × benchmark”组合全部提升。

提升规律也有解释性：

- 最弱的 Step-Back 提升最大；
- 已有工具交互式 critique、与 rubric 信号部分重叠的 CRITIC 提升最小。

这支持 rubric 是可组合的 context signal，而不是只能依赖 Co-ReAct 完整循环的专有模块。

### 11. DepthCrafter case study

问题询问 DepthCrafter 是什么，以及它与已有 monocular depth estimator 有何不同。

ReAct 和 Co-ReAct 前两步完全相同。第三步出现分歧。

#### ReAct

ReAct 再次调用 academic search，只读取摘要 snippet，最终错误写成：

> DepthCrafter 使用从头训练的视频 diffusion model。

#### Co-ReAct

第三步 rubric 要求：

1. 使用 `browse_webpage` 打开 primary source；
2. 查询必须比较 Marigold 与 ChronoDepth；
3. 限制 2024 年资料。

第一次行动仍调用 academic search，因此 verifier 判断：

- 工具不对，没有打开原始来源；
- 查询没有包含两个比较对象。

重试后，agent 打开 arXiv 页面，找到正确事实：DepthCrafter 是 fine-tune Stable Video Diffusion，而不是从头训练，并能解释它与逐帧 image diffusion 方法的差异。

这个例子清楚展示了 rubric 的三个作用：

- 规定证据类型；
- 规定比较范围；
- 把失败原因转成可执行修改。

## 📉 局限性与批判性评价

### 1. 没有与 end-to-end RL search agent 直接比较

作者把 Co-ReAct 定位为固定 policy 上的 ReAct enhancement，因此只比较 test-time 方法，没有对比：

- Search-R1；
- R1-Searcher；
- 其他端到端训练的 search policy。

这个边界合理，但也意味着目前无法判断：

- 训练外部 rubric generator；
- 直接训练 search policy；
- 两者叠加

谁的收益、成本和迁移性更好。

论文明确把“叠加在 RL-trained search agent 上”留作未来工作。

### 2. 评估严重依赖 LLM judge

训练排序来自 Claude、Gemini 和 GPT-5 的 council，rubric-induced ranking 又由 Gemini 2.5 Pro 计算；DRB 与 SQA 的最终评估同样使用 Gemini。

虽然多 judge、随机候选顺序和 Borda count 能降低单一 judge 偏差，但仍可能存在：

- verbosity bias；
- 模型家族偏好；
- 对搜索行动格式的偏好；
- 训练 evaluator 与最终 judge 的相关性。

论文自己的 Limitations 也明确提到 verbosity bias。

### 3. 推理成本没有被完整量化

完整 Co-ReAct 在每个步骤增加 rubric generation 和 verification，约 21.4% 步骤还会重试。

论文报告了工具调用数量，却没有报告：

- 端到端延迟；
- 输入/输出 token；
- GPU 或 API 成本；
- 与 Best-of-N、CRITIC 的等预算比较。

因此当前实验能证明质量提升，但不能回答单位成本收益。

### 4. 更彻底的搜索也可能放大答案长度与 judge 偏好

Co-ReAct 检索更多链接、引用更多来源，并有更高 utilization。这很可能是真实优势，但也可能间接生成更长、更完整外观的报告，从而受益于 LLM judge 的 verbosity preference。

一个更强验证可以包括：

- 人工盲评；
- 固定答案长度；
- 相同 citation budget；
- 事实单元级验证；
- 每增加一次工具调用带来的边际收益。

### 5. 训练数据与任务类型仍然集中

Rubric 数据来自 DR-Tulu 的 11,406 个 deep research query，评估只有两个搜索与引用综合 benchmark。

尚不清楚方法能否同样迁移到：

- 数据库或代码 agent；
- 有确定环境反馈的 embodied agent；
- 长期规划任务；
- 高风险医学或法律搜索；
- 非搜索类工具编排。

### 6. Borda consensus 不是客观 ground truth

Borda count 能聚合完整排序并降低单 judge outlier，但它仍可能：

- 抹平 judge 间真实分歧；
- 把三个模型共享的偏差当作专家共识；
- 忽略候选之间差异很小、排序本身不确定的情况。

论文没有报告 judge 间一致性、排序置信度或按一致性过滤后的敏感性分析。

### 7. Rubric 可能约束探索

Step-level rubric 让行动更有目标，但强约束也可能减少意外发现。

如果 rubric generator 根据已有轨迹错误判断“当前缺口”，后续 agent 可能围绕错误目标持续优化。未训练 rubric 的负结果已经说明这种风险真实存在。

值得进一步研究：

- 给 rubric 加不确定性；
- 保留一部分无 rubric exploration；
- 多 rubric ensemble；
- 发现新证据后主动废弃旧 rubric。

## 🔗 与相关工作的区别

### 与 Rubrics as Rewards 的区别

Rubrics as Rewards 把 instance-specific rubric 用作 policy training reward，rubric 主要被训练循环消费。

Co-ReAct 则让 rubric 在 inference time 被 agent 本身消费，用于选择下一步行动。

### 与 Rubric-ARM / DynamicRubric 的区别

- Rubric-ARM 联合训练 rubric generator 与 judge，提高开放回答偏好判断；
- DynamicRubric 根据当前 response set 生成评价标准，并让 evaluator 随 policy 共演化；
- Co-ReAct 根据当前 trajectory prefix 生成行动标准，训练目标是让标准诱导的 next-action 排序符合专家共识。

三者的共同点是：rubric 不是静态文本，而是可训练的中间决策结构。

### 与 Harness-1 的关系

Harness-1 把候选池、证据图、验证记录等搜索状态外置到环境，让 policy 在显式状态上决策。

Co-ReAct 不重构状态存储，而是在每个已有状态上生成“下一步行动应该满足什么”的规范。

二者理论上互补：

- Harness-1 提供结构化 state；
- Co-ReAct 提供 trajectory-conditioned action criteria。

但论文没有实际验证组合效果。

## 📚 关键术语

**ReAct（推理与行动协同）**：让模型交替进行自然语言推理、工具行动和环境观察的 agent 范式。例子：先判断缺少论文原文，再调用 academic search，读取结果后继续规划。

**Step-Level Rubric（步骤级评分标准）**：针对当前决策点的下一步行动要求，而不是针对最终答案的总体评分表。例子：要求下一步打开 primary source、覆盖两个指定基线并限制年份。

**Prescriptive Guidance（规范性指导）**：在行动发生前规定应该做到什么。例子：搜索前要求使用官方来源，而不是答案完成后才批评引用不可靠。

**Branching Point（轨迹分叉点）**：给定问题和部分轨迹后，可以选择多个候选下一步行动的状态。例子：此时既可以继续 Google 搜索，也可以打开已找到论文，或搜索另一个对比方法。

**Candidate Slate（候选行动列表）**：同一分叉点上同时比较的一组候选。例子：Co-ReAct 每个训练样本保留四个多样化行动，而不是只比较一对。

**Listwise Ranking（列表式排序）**：一次学习整个候选列表的相对顺序。例子：专家给出 `X > Z > Y > W`，比只知道 `X > Y` 包含更多结构。

**Spearman Rank Correlation（斯皮尔曼秩相关系数）**：衡量两份排序一致程度的统计量。例子：rubric 排序与专家排序完全相同得 1，完全相反得 -1，论文再映射到 0 到 1。

**Borda Count（波达计数）**：把多位 judge 给出的名次相加来聚合完整排序。例子：一个候选分别排名第 1、2、1，总名次优于分别排名第 2、1、3 的候选。

**GRPO（组相对策略优化）**：不单独训练 value model，而是用同一输入下多份采样结果的组内相对 reward 构造 advantage。例子：同一分叉点采样八份 rubric，能诱导更好行动排序的 rubric 获得更高相对优势。

**Inject–Verify–Retry（注入–验证–重试）**：先把 rubric 放入上下文，生成行动后逐项检查，失败则携带反馈重试一次。例子：agent 想继续搜摘要，但 rubric 要求打开原文，验证失败后改用网页浏览工具。

**Maximum Marginal Relevance, MMR（最大边际相关性）**：在相关性与多样性之间权衡的候选选择方法。例子：从 12 个行动中避免选出四个几乎相同的查询。

**Utilization Ratio（证据利用率）**：检索到的链接中最终被引用或使用的比例。例子：Co-ReAct 检索更多链接的同时 utilization 达到 0.96，说明增加的不只是无效搜索量。

## 💡 可操作启示

### 对 Agent 系统设计

如果 agent 经常在局部步骤犯错，可以先问：

- 它真的缺少能力，还是缺少当前步骤的验收条件？
- 反馈是在行动前提供，还是只能事后评分？
- 生成和验证是否使用同一份明确标准？
- 失败反馈能否直接转成下一次行动约束？

### 对 Rubric 训练

不要只检查 rubric 是否语言自然。至少验证：

- 能否区分同一状态下的多个行动；
- 诱导排序是否与可靠偏好一致；
- 未训练 rubric 是否会造成负迁移；
- pairwise、listwise 与 pointwise 信号谁更匹配真实决策结构。

### 对后续研究

最值得继续验证的方向是：

1. 把 Co-ReAct 叠加到 RL-trained search agent；
2. 与 stateful harness 结合，让 rubric 直接读取结构化工作记忆；
3. 在相同 token、延迟和工具预算下做成本公平比较；
4. 让 rubric 表达不确定性并保留探索；
5. 用人类或确定性环境反馈校准 judge council；
6. 研究 rubric generator、search policy 和 verifier 的联合或交替演化。

## 📝 总结

Co-ReAct 的主要贡献不是多加一次自我反思，而是改变 rubric 在 agent 系统中的位置：

- 过去的 rubric 在输出完成后评价；
- Co-ReAct 的 rubric 在每个行动前规定目标；
- 行动后又作为验证和重试依据。

作者通过真实轨迹分叉点、四候选 listwise ranking、三 judge Borda 共识和 Spearman-GRPO，把 rubric generator 从“会写合理标准”训练成“能诱导正确行动排序”。

最关键的实验事实是：

- 未训练 rubric 比不使用 rubric 更差；
- pairwise 训练弱于 listwise 训练；
- inject-only 已有效，verify–retry 进一步提升；
- 8B、14B 和 Gemini 3.1 Pro 均受益；
- 同一 generator 注入三种现有方法，在两个 benchmark 的六种组合上全部提升。

因此，论文可以合理支持的结论是：

> **经过排序校准、依赖当前轨迹的 step-level rubric，可以成为固定搜索 policy 之上的轻量、可组合行动控制层。**

它尚未证明这种方式优于端到端训练搜索策略，也没有完整回答推理成本问题，但它清楚展示了一个值得延伸的方向：让 agent 不只“多想一步”，而是在每一步之前先得到一份经过学习的行动合同。
