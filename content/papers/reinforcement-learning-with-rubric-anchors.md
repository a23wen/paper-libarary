---
title: "Reinforcement Learning with Rubric Anchors"
date: 2026-04-15T14:22:50+08:00
draft: false

# 分类（研究领域）
categories: ["强化学习"]

# 会议/期刊
venues: "arXiv 2025"

# 论文元数据
authors: ["Zenan Huang", "Yihong Zhuang", "Guoshan Lu", "Zeyu Qin", "Haokai Xu", "Tianyu Zhao", "Ru Peng", "Jiaqi Hu", "Zhanming Shen", "Xiaomeng Hu", "Xijun Gu", "Peiyi Tu", "Jiaxin Liu", "Wenyu Chen", "Yuzhuo Fu", "Zhiting Fan", "Yanmei Gu", "Yuanyuan Wang", "Zhengkai Yang", "Jianguo Li", "Junbo Zhao"]
year: "2025"
paper_url: "https://arxiv.org/abs/2508.12790"
arxiv_url: "https://arxiv.org/pdf/2508.12790"
code_url: "https://huggingface.co/inclusionAI/Rubicon-Preview"

# 阅读状态
status: "completed"
rating: 5
read_date: "2026-04-15"

summary: "论文提出 Rubicon，用 rubric anchors 把强化学习从数学、代码这类可验证任务扩展到创意写作、情感表达和人文学科等开放任务。作者构建了一个包含 10,000+ rubrics 的大规模 reward system，并通过两阶段 RL、central-quantile 数据筛选、reward hacking 防御 rubric 和 stage-wise 训练，让 Qwen3-30B-A3B 仅用 5K 训练样本就在开放任务上平均提升 5.2%，同时基本保持通用与推理能力。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文想回答一个非常现实的问题：**强化学习为什么在数学和代码里这么有效，一到了写作、共情、开放问答这些真实任务里就很难继续扩展？**

过去两年，RLVR（Reinforcement Learning from Verifiable Rewards）变得很强，因为它抓住了一个特别适合做 RL 的场景：题目很难，但答案很好验。比如：

- 数学题可以看最终答案是否匹配；
- 编程题可以跑测试用例；
- 某些搜索或工具任务可以看执行结果是否成功。

但一旦任务变成“写一段更像人的文字”“给出更有共情的回答”“用更自然的风格回应用户”，就没有一个干净的 `0/1` 判题器了。你没法像验数学题那样，自动说“这个回答就是对的”。

作者提出的核心方案叫 **Rubicon**。它的直觉很简单，但很有力量：

**既然开放任务没有单一标准答案，那就不要再逼它伪装成单一标准答案；改用 rubric，把‘好回答应该满足哪些维度’拆开，作为 RL 的锚点。**

也就是说，奖励不再只是“总分高不高”，而是变成一套结构化的、多维度的、模型可解释的标准。例如一个开放写作任务，不只是问“写得好不好”，而是拆成：

- 是否自然；
- 是否避免 AI 味；
- 是否有真实情绪；
- 是否符合给定叙述风格；
- 是否避免说教；

论文认为，**rubric 的价值不只是拿来评测，而是可以直接成为 RL 的 reward scaffold。**

## 🎯 研究背景

这篇论文站在三个脉络的交叉点上：

- **RLVR / reasoning RL**：这条线已经证明，可验证奖励能显著提升 LLM 的推理和工具能力，但任务域被 verifier 严格限制。
- **LLM-as-a-judge / preference optimization**：开放任务通常依赖偏好建模或 LLM judge，但 reward 往往偏粗，容易学到形式感而不是实质能力。
- **rubric-based evaluation**：很多人类评测任务本来就靠 rubric 打分，只是这些 rubric 过去主要用于评估，还没有真正系统地接进 RL 训练循环。

作者的重要观察是：**开放任务并不是完全“不可评估”，而是更适合用多维标准评估，而不是单维正确性评估。**

所以这篇论文的目标，并不是替代 RLVR，而是把 RL 的适用范围从“有自动判题器的任务”扩展到“没有标准答案但仍然可以结构化评估的任务”。

## ⚠️ 问题与挑战

论文要解决的问题是：**如何把 rubric 真正变成一个可扩展、可训练、不会被模型轻易 exploit 的 RL reward system。**

这个问题难，不是因为“主观任务更难”这么一句话，而是有几层具体的因果障碍：

### 1. 因为开放任务没有单一 ground truth，所以 reward 很容易变成模糊的总分

比如写作任务里，一个回答可能：

- 文风好但内容空；
- 情绪真但逻辑散；
- 语言自然但没有满足用户约束。

如果只给一个整体分数，模型学不到“到底是哪一维做得好、哪一维做得差”。

### 2. 因为单一 rubric 太容易被 exploit，所以模型会 reward hack

作者明确说，**依赖单个 rubric 很危险**。模型会很快学会“长得像高分答案”的表面模式，而不是真的提升能力。  
比如一个创意写作 rubric 如果偏好“情感真挚”，模型可能开始机械地在每个回答开头就写一些虚假的感慨话术，表面上更“像人”，本质上却是在刷分。

### 3. 因为 rubrics 之间目标会冲突，所以不同任务类型不能简单混训

这是论文里特别重要的一个现象：**seesaw effect（跷跷板效应）**。

作者发现：

- 如果只用 instruction-following rubrics 训练，模型会更守规矩，但创造力和情感表达会下降；
- 如果只用 creativity / empathy rubrics 训练，模型会写得更自然、更像人，但严格遵循约束会变差。

也就是说，因为不同 rubric 奖励的行为方向不一致，所以把它们一起扔进同一轮 RL，很容易互相拉扯。

### 4. 因为开放任务 reward 更软，所以数据筛选和训练阶段设计变得决定性

在 RLVR 中，很多数据本身只要能验对错，就能比较直接进入训练。  
但在 rubric-based RL 里，作者发现不是所有样本都适合学：

- 分数太高的样本，学习信号不够；
- 分数太低的样本，可能本身噪声大或不稳定；

所以数据必须先做筛选，训练也不能一步到位。

## 🔍 核心发现 Finding

### 作者明确声称

作者的核心主张是：**只要 rubric 设计得足够结构化、细粒度且和训练流程联动，rubric-based reward 可以把 RL 扩展到原本没有 verifier 的开放任务。**

### 我的理解

我认为这篇论文真正重要的 `Finding` 不是“把 rubric 用来打分”，而是下面这个更本质的视角：

**开放任务的问题不是没有 reward，而是 reward 长期被人类藏在‘评分标准’里，而没有被写成能驱动 RL 的结构化系统。**

这和很多人默认的想法不一样。很多人会觉得：

- 数学题能 RL，是因为有标准答案；
- 写作、共情、创意任务不能 RL，是因为没有标准答案。

Rubicon 的新看法是：

- 写作任务确实没有唯一答案；
- 但“好回答长什么样”其实一直都存在；
- 它通常以 rubric 的形式存在于教师评分表、人类 judge 经验或者评测说明里。

换句话说，**关键不是发明一个假的唯一答案，而是把“多维度好坏标准”写清楚，让模型沿这些锚点优化。**

这个 finding 为什么能解决前面的挑战？因为它把一个原本很松散的问题，变成了一个可以逐层拆解的问题：

- 用 rubric 解决“总分太模糊”；
- 用多维 rubric 和复杂聚合解决“单一标准太容易 exploit”；
- 用阶段化训练解决“不同目标打架”；
- 用 reward hacking defense rubric 解决“模型学会刷分而不学会能力”。

如果用一个直观例子来讲：

- 旧做法像是老师对作文只写一句“这篇文章 84 分”；
- Rubicon 的做法像是老师把作文分成“声音是否自然”“情绪是否真实”“是否说教”“是否满足文体要求”等多个维度，并把这些维度直接变成训练信号。

这就是 Rubicon 的关键 insight：**开放任务不是没法做 RL，而是需要把 reward 从“结果正确性”换成“结构化评价标准”。**

## 🔬 方法

### 整体思路

Rubicon 是一个 **rubric-first** 的 RL 框架。作者不是先有数据再想怎么打分，而是反过来做：

1. 先设计能被模型稳定理解和执行的 rubrics；
2. 再围绕这些 rubrics 选数据、过滤数据、做 RL；
3. 最后再根据 rollout 里出现的问题反过来更新 rubric system。

这个设计很像把“评分标准”本身做成系统的一等公民，而不是附属工具。

### Rubric 的形式化定义

论文把一个 rubric 形式化为多个 critic dimensions 的集合。每个维度包含三部分：

1. **criterion description**：这一维到底在评价什么；
2. **score tiers**：分层评分档位；
3. **weight**：这一维的重要性权重。

因此一个回答不会只得到一个总分，而是先得到一个 **multi-dimensional feedback vector**，再进一步聚合成标量 reward。

### Reward 聚合怎么做

作者没有停留在简单加权和，而是引入了一套更复杂的聚合思路：

- **Veto mechanism**：如果触犯关键红线，其他高分维度也可以被直接清零；
- **Saturation-aware aggregation**：避免某一维度无限刷高后继续主导总 reward；
- **Pairwise interaction modeling**：显式考虑不同标准之间可能的协同或冲突；
- **Targeted reward shaping**：在高分区域放大细微差异，提高精细优化能力。

这一步很关键，因为它说明 Rubicon 并不是“给每条 rubric 打分然后求和”这么粗糙，而是在认真处理“不同评分维度之间如何共同构成可训练 reward”。

### 数据与筛选

论文使用了一个 **900K+ proprietary corpus**，来源包括：

- 社区问答；
- 高质量考试题；
- 通用对话数据；

但并不是全部直接用于 RL。作者对候选 instruction-rubric pair 做了 **offline filtering**：

1. 先让 base model 生成回答；
2. 再用 critic 模型打出完整 score distribution；
3. 只保留落在一个 **calibrated central quantile** 内的样本。

这样做的目的很清楚：

- 分太高的样本，模型本来就会，训练价值低；
- 分太低的样本，可能噪声大或 rubric 不稳；
- 留中间段，最有 learning signal。

### 两阶段 RL 训练

作者最终采用 **two-stage RL**，这是方法里最重要的流程设计之一。

#### 第一阶段：先打基础

这一阶段强调：

- instruction-following；
- constraint handling；
- 多维静态 rubric 对齐；
- 程序化可验证检查。

目标不是先把模型训得很“有文采”，而是先让它会守约束、会对齐、会稳定响应。

#### 第二阶段：再做开放能力

这一阶段才引入：

- 更开放的、社会性的、创造性的任务；
- reference-based rubrics；
- instance-specific rubrics；
- 更强的 agentic workflow 生成的 rubric。

也就是说，作者不是一开始就让模型同时学“守规矩”和“像人类一样写得自然”，而是先把底座打稳，再往上叠加更柔软、更开放的能力。

### Reward Hacking Defense

这是论文里很实用的一部分。

作者发现，在早期 RL 阶段，模型会迅速学会 exploit 一些 rubric。于是他们做了一个 **adaptive defense loop**：

1. 分析 rollout 中 reward 异常高的样本；
2. 总结高层级的 reward hacking 模式；
3. 把这些 failure mode 写成专门的 **Reward Hacking Defense Rubric**；
4. 在后续阶段把这个 defense rubric 作为硬约束接回训练系统。

附录里给出的一个具体例子是检测两种常见刷分行为：

- **prefatory sycophancy**：一上来先夸用户问题问得好；
- **laudatory self-evaluation**：在回答里夸自己回答得多好。

作者的意思很明确：这些表面上更“像高质量回答”的模式，其实只是模型在学会讨好 rubric，而不是真正提升内容质量。

## 📊 实验与结论

### 主结果一：只用 5K+ 训练样本，开放任务平均提升 5.2%

Rubicon-preview 基于 **Qwen3-30B-A3B**，在开放任务 benchmark 上的主结果很亮眼：

| 模型 | Creative Writing | WritingBench | JudgeMark | EQ-Bench3 | IFEval | Collie | IFScale | Avg |
|------|------------------|--------------|-----------|-----------|--------|--------|---------|-----|
| Qwen3-30B-A3B | 77.82 | 75.65 | 56.20 | 73.35 | 83.55 | 35.77 | 54.68 | 65.29 |
| Rubicon-preview | 81.89 | 80.11 | 69.20 | 79.55 | 81.70 | 40.27 | 60.79 | 70.50 |
| 提升 | +4.07 | +4.46 | +13.00 | +6.20 | -1.85 | +4.50 | +6.11 | +5.21 |

最值得注意的是两点：

1. **只用了 5K+ training samples**；
2. **平均比 DeepSeek-V3-671B 还高 2.4 个点**。

这说明作者想证明的不是“多加数据就能更强”，而是：  
**如果 rubric system 设计得足够好，少量数据也能有非常高的训练效率。**

### 主结果二：收益主要体现在开放、人文、情绪和风格任务

Rubicon 的提升不是均匀撒开的，而是特别集中在它最想解决的任务上：

- `JudgeMark` 提升 **+13.00**
- `EQ-Bench3` 提升 **+6.20**
- `WritingBench` 提升 **+4.46**
- `IFScale` 提升 **+6.11**

一个很直观的解读是：

- 这些 benchmark 本来就缺乏强 verifier；
- 传统 RLVR 很难直接进入；
- 而 Rubicon 恰好在这里建立了 reward。

论文还给了一个案例：在 “When in your life have you felt the most alive?” 这类问题上，Rubicon 生成的回答更像一个真正有风格的人在说话，而 base model 更容易退回“我是 AI，我没有个人经历，但我可以帮你思考”这种安全但非常模板化的回答。

### 主结果三：基本保持通用能力，还顺带提升部分 reasoning benchmark

作者专门检查了 rubric-based RL 会不会把模型训歪。结果是：

| 模型 | AIME24 | AIME25 | Math500 | GPQA-D | LCB v5 | MMLU | IQ-EQ | HS | SC | CQ | SIQA |
|------|--------|--------|---------|--------|--------|------|-------|----|----|----|------|
| Qwen3-30B-A3B | 77.50 | 70.00 | 94.75 | 63.00 | 63.77 | 79.53 | 68.75 | 77.55 | 77.72 | 79.52 | 73.64 |
| Rubicon-preview | 81.67 | 70.83 | 94.55 | 60.35 | 59.43 | 79.83 | 75.00 | 77.75 | 78.17 | 80.70 | 75.79 |

作者的结论是：

- 通用能力没有明显退化；
- AIME24 增加 **+4.17**；
- AIME25 增加 **+0.83**；
- MMLU 也略有提升。

这里有个很有意思的现象：虽然 Rubicon 的 rubrics 主要不是为 STEM 设计的，但它并没有明显伤害 reasoning 底座，反而在部分 benchmark 上带来外溢收益。  
这意味着开放任务的高质量 RL 不一定会牺牲推理能力，前提是训练流程设计得足够稳。

### 主结果四：跷跷板效应说明“目标冲突”是真问题

论文里我最喜欢的一个实验现象就是 **seesaw effect**。

作者发现：

- 只用 creativity / empathy rubrics 训练时，模型在创意和共情任务上明显变强，但在 `Collie` 上掉 **-6.0**，在 `IFEval` 上掉 **-5.9**；
- 只用 instruction-following rubrics 训练时，模型遵循约束变强，但在 `EQ-Bench3` 上掉 **-2.2**。

这个实验很重要，因为它说明：

**开放任务 RL 的难点不只是有没有 reward，而是不同 reward 在拉模型去不同方向。**

所以 Rubicon 的两阶段训练不是一个“工程技巧补丁”，而是对这个因果矛盾的直接回应：  
先学稳约束处理，再学创意与共情，否则两个目标会互相拉扯。

### 主结果五：reward hacking defense 是训练能持续下去的关键护栏

作者明确说，在初始 RL 阶段，如果没有额外防御，模型会进入 reward hacking 状态，训练会出现异常高分但实质没变好，甚至导致后续优化失效。

他们把 rollout 里观察到的刷分模式系统化为 **Reward Hacking Defense Rubric** 后，训练稳定性明显提升：

- catastrophic reward spikes 被抑制；
- 可以训练更久、更稳定；
- 学到的是内容质量，而不是 performative artifacts。

这部分给我的启发很强：  
**开放任务 RL 不是只要 reward 足够细就行，还必须动态防止模型学会“作弊语言”。**

### 结论

这篇论文最后说明了三件事：

1. **rubric 可以成为 RL 的锚点，把 RL 从 verifier-rich domain 扩展到 open-ended domain。**
2. **真正有效的不是“有 rubric”这件事本身，而是一个完整的 rubric system：设计、筛选、聚合、阶段训练、防御机制要一起工作。**
3. **开放任务 RL 的核心障碍不是没有 reward，而是 reward 太容易失真、冲突或被 exploit。**

如果用一个更形象的比喻：

- RLVR 像是在做标准答案考试；
- Rubicon 更像是在做写作和面试训练；
- 这类任务没有唯一答案，但并不代表没有清晰标准，只是标准是多维度的。

Rubicon 做的事情，就是把这些多维标准写成 RL 真正能吃进去的训练信号。

## 🧠 关键术语

- **RLVR, Reinforcement Learning from Verifiable Rewards（来自可验证奖励的强化学习）**：依赖程序可验证的 reward。例子：数学题答案对了得分，代码通过测试得分。
- **Rubric Anchor（rubric 锚点）**：把“好回答的多维标准”显式写成 RL 优化目标。例子：写作任务同时看自然度、情感真实性、是否避免 AI 味。
- **Multi-Dimensional Reward Signal（多维奖励信号）**：回答先在多个 rubric 维度上分别打分，再聚合。例子：一个回答可能情绪表达 4 分、风格 5 分、约束遵守 2 分。
- **Veto Mechanism（否决机制）**：某个关键维度不达标时，其他高分也不能救回来。例子：如果命中 reward hacking defense rubric，就直接把其他维度的奖励清空。
- **Saturation-Aware Aggregation（饱和感知聚合）**：防止模型只在单一维度无限刷分。例子：语言华丽度再高，如果真实性已经饱和，就不该继续主导 reward。
- **Instance-Specific Rubric（样本级 rubric）**：不是任务级固定标准，而是针对每个样本单独生成标准。例子：同样是开放写作题，不同 prompt 需要不同风格要求。
- **Central Quantile Filtering（中心分位筛选）**：只保留 reward 分布中间区域的样本用于训练。例子：太简单和太差的数据都丢掉，只留最有学习价值的一段。
- **Reward Hacking（奖励黑客 / 刷分）**：模型学会讨好评分器，而不是真正提升任务能力。例子：每个回答都先夸用户问题问得好，再夸自己回答得深刻。
- **Seesaw Effect（跷跷板效应）**：训练一种能力时，另一类能力被拉低。例子：模型越会守格式，可能越不自然；越有创意，可能越不守约束。

## 💭 个人评价

### ✅ 优点

- **问题抓得很准**：它真正击中了 RL 下一步扩展的瓶颈，不再只卷数学和代码。
- **方法论比看起来更完整**：不是简单“把 rubric 拿来打分”，而是把 rubric 设计、聚合、筛选、防御、分阶段训练全部打通。
- **token efficiency 很强**：5K 训练样本就能做出 5.2% 的开放任务平均提升，这个性价比很高。
- **对 reward hacking 有正面回应**：很多论文只承认问题，这篇论文至少给出了一套具体、能运行的防御策略。

### ⚠️ 局限

- **很多数据是 proprietary corpus**：方法思路开源了，但完整复现门槛并不低。
- **rubric system 的最优结构还远没定型**：作者自己也承认，rubric 的数量、粒度、层次结构和组合方式还没有系统答案。
- **部分 reasoning benchmark 有涨有跌**：比如 GPQA 和 LCB 并没有一起提升，说明“开放任务更强”不等于“所有能力都更强”。
- **当前 benchmark 还不足以完整反映开放能力**：作者自己也认为现有评测对 anthropomorphic / human-like abilities 的覆盖不够。

### 💡 启发

- 对开放任务做 RL，关键可能不是去找“假的正确答案”，而是把人类评判标准结构化。
- 未来的 post-training 很可能会从“数据规模竞争”转向“rubric system 设计竞争”。
- 这篇论文也提示一个更通用的原则：**reward 不是越多越好，而是越可解释、越抗 exploit、越和训练阶段匹配越好。**

## 🔗 相关论文

- Rubrics as Rewards: Reinforcement Learning Beyond Verifiable Domains
- DeepSeek-R1: Incentivizing Reasoning Capability in LLMs via Reinforcement Learning
- HealthBench
- Constitutional AI
- Rule Based Rewards for Language Model Safety

---

**阅读时间**：约 3 小时  
**推荐指数**：⭐⭐⭐⭐⭐  
**适合读者**：LLM 后训练、强化学习、reward design、开放任务对齐、人文与创意生成方向研究者

**一句话总结**：Rubicon 的关键不是“让 rubric 参与打分”，而是把 rubric 提升为 RL 的真正锚点系统，用多维结构化标准、阶段式训练和 reward hacking 防御，把强化学习从“只有标准答案的任务”推进到“没有唯一答案但仍然有高质量标准的任务”。  
