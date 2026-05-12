---
title: "EvoLM: Self-Evolving Language Models through Co-Evolved Discriminative Rubrics"
date: 2026-05-12T00:00:00+08:00
draft: false

# 分类（研究领域）
categories: ["强化学习"]

# 会议/期刊
venues: "arXiv 2026"

# 论文元数据
authors: ["Shuyue Stella Li", "Rui Xin", "Teng Xiao", "Yike Wang", "Rulin Shao", "Zoey Hao", "Melanie Sclar", "Sewoong Oh", "Faeze Brahman", "Pang Wei Koh", "Yulia Tsvetkov"]
year: "2026"
paper_url: "https://arxiv.org/abs/2605.03871"
arxiv_url: "https://arxiv.org/pdf/2605.03871"
code_url: "https://github.com/stellalisy/EvoLM"

# 阅读状态
status: "completed"
rating: 4
read_date: "2026-05-12"

summary: "EvoLM 提出一种不依赖人工标注、专有 API、外部 reward model 或可验证答案的 LLM 后训练方法。它让同一个 Qwen3-8B 同时扮演 policy 和 rubric generator，通过交替 GRPO 训练 co-evolve：policy 用 rubric-conditioned judge 分数更新，rubric generator 则用当前 policy 与早期 checkpoint 输出之间的 temporal contrast 偏好对来学习更有判别力的评价标准。实验显示 EvoLM policy 在 OLMo3-Adapt 12 项平均达到 69.3%，超过 GPT-4.1 prompted rubrics 和 SkyWork-RM-V2 等基线。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文讨论的是 LLM post-training 里一个非常关键的问题：

**如果不依赖人工偏好、专有大模型 API、外部 reward model，也没有数学/代码那种可验证答案，模型还能不能自己产生有效的训练奖励？**

传统后训练通常有几类 reward 来源：

- 人类偏好标注；
- GPT-4 这类专有模型做 judge；
- 标量 reward model；
- 数学、代码这类可验证任务里的 verifier。

这些方法都有上限。人类标注贵，而且很难监督超过人类自身能力的行为；专有 API 会带来依赖；标量 reward model 容易 reward overoptimization；verifiable reward 又只适用于有标准答案的领域。

EvoLM 的核心主张是：**语言模型在预训练中已经编码了大量评价知识，只是这些知识通常隐含在模型权重里。要让模型自我改进，关键是把这种隐含评价能力转写成显式、可检查、可训练的 rubric。**

于是作者提出一个自演化闭环：

1. 一个模型生成回答，作为 policy；
2. 同一个模型也生成 rubric，作为 rubric generator；
3. 一个小的冻结 judge 根据 rubric 给 policy 的回答打分；
4. policy 用这些 rubric-conditioned scores 做 GRPO；
5. rubric generator 用 policy 现在和过去 checkpoint 的输出差异构造偏好对，再学习能把好坏回答区分开的 rubric；
6. policy 变强后，rubric generator 必须生成更细、更具体的评价标准；rubric 变强后，又给 policy 提供更尖锐的 reward。

这就是论文标题里说的 **self-evolving language models through co-evolved discriminative rubrics**。

## 🎯 研究背景

这篇工作位于三个研究方向的交叉处。

### 1. LLM 后训练与 reward design

RLHF、DPO、GRPO 等后训练方法本质上都依赖 reward 或 preference signal。模型能学到什么，很大程度上取决于 reward 质量。如果 reward 过粗、过静态或有偏，policy 很容易学会讨好 reward，而不是真正提升能力。

标量 reward model 的问题尤其明显：它在静态偏好 benchmark 上可能很强，但当 policy 持续优化它时，reward landscape 会被 policy 改写，模型可能进入 reward hacking 或 overoptimization。

### 2. Rubric-based reward modeling

Rubric 方法把“好回答应该满足什么”拆成明确评价标准。相比一个黑箱分数，rubric 更可解释，也更容易让 judge 逐项检查。

已有路线包括：

- 用 GPT-4 等模型生成 rubric；
- 用人工或专家 rubric 做评测；
- 用 reference preference pairs 训练 rubric generator；
- 用 verifier 或外部标签筛选 rubric。

这些方法仍然依赖外部监督。EvoLM 关心的是更激进的问题：**rubric 能不能也由模型自己训练出来，而且训练信号来自 policy 自身演化？**

### 3. 自我改进与 self-rewarding

Self-Rewarding LM、SPIN、Meta-Rewarding 等工作都尝试让模型从自己的输出里获得训练信号。但很多方法仍然依赖固定 judge prompt、外部 reference 或隐式评判能力。

EvoLM 的区别是：它不只是让模型“自己打分”，而是让模型学习生成显式 rubric，并且用一个形式化目标优化 rubric 的判别力。

## ⚠️ 问题与挑战

论文要解决的问题是：**如何在没有外部偏好标签、没有专有教师、没有 verifier 的情况下，为 LLM policy 构造能持续改进的 reward signal。**

这个问题难在几个层面。

### 1. 因为开放任务没有 ground truth，所以不能直接套 RLVR

数学题可以看答案是否正确，代码题可以跑测试。可开放问答、写作、复杂指令、研究型回答往往没有唯一答案。

如果没有 verifier，reward 就很容易退化成“看起来不错”这种模糊判断。模糊 reward 对 policy 来说很危险，因为模型会优化 judge 的偏好表象，而不是问题本身的质量。

### 2. 因为外部监督会限制扩展性，所以 reward 不能总靠人或 GPT-4

人类标注和 GPT-4 生成 rubric 都能工作，但它们会成为系统瓶颈：

- 成本高；
- 不可控；
- 难以大规模迭代；
- 很难随 policy 的输出分布共同变化。

当 policy 变强后，固定的外部 rubric 可能不再能区分当前回答之间的细微差异。

### 3. 因为小 judge 自己不会制定好标准，所以必须把评价知识显式化

论文使用 Qwen3-1.7B 作为默认冻结 judge。这个 judge 不一定能独立判断复杂回答，但如果给它一个具体 rubric，它可以做更可靠的逐项检查。

这就形成一个关键张力：**judge 小且固定，但 rubric 可以变得更具体、更可检查。** EvoLM 的训练目标正是让 rubric generator 把隐含评价知识转写成小 judge 能执行的标准。

### 4. 因为 policy 会改变 reward 分布，所以 rubric 必须随 policy co-evolve

如果 rubric generator 先训练好再冻结，policy 训练几百步后可能学会绕过这些标准。此时固定 rubric 就变钝了。

EvoLM 的挑战是让两者一起演化：policy 变强，rubric 要变得更尖锐；rubric 变尖锐，policy 才能继续获得有信息量的 reward。

## 🔍 核心发现 Finding

### 作者明确声称

作者明确的发现是：**把模型已有的评价知识结构化为可判别 rubric，并让 rubric generator 与 policy 交替共演化，可以在不使用外部监督的情况下实现 LLM 自我改进。**

### 我的理解

我认为这篇论文真正的 `Finding` 是：

**自我改进的关键不是让模型直接“给自己打分”，而是让模型先学会把隐含偏好转写成小 judge 能执行的检查表，再用这些检查表训练未来的自己。**

这个 finding 的价值在于，它把一个看似循环论证的问题拆开了。

如果直接问模型“哪个回答更好”，模型的评价能力是隐式的、不稳定的，也很难训练。但如果让模型生成 rubric，事情就变成：

- rubric 是否能让固定 judge 把当前好回答和差回答区分开；
- 如果能，说明 rubric 把某种有效评价标准显式化了；
- 这个 rubric 可以反过来给 policy 提供 reward；
- policy 变强后，新的好坏差异会迫使 rubric generator 学到更细标准。

举个例子，早期 rubric 可能写：

- 回答是否准确；
- 是否解释清楚；
- 是否遵循格式。

训练后的 EvoLM rubric 会变得更像：

- 数学题必须给出最大面积 144，并说明来自周长 48 的约束；
- constrained writing 必须恰好包含指定关键词，并且段落数满足要求；
- scientific explanation 必须覆盖某个中间机制，而不是只给结论。

这种变化说明模型不是学会了写更漂亮的评分语言，而是学会了把 holistic judgment 压缩成更具体、可验证、可模式匹配的 criteria。对一个 1.7B 小 judge 来说，这类 rubric 比抽象标准更容易执行。

## 🔬 方法

### 整体框架

EvoLM 有三个角色：

1. **Policy `pi_theta`**  
   根据问题生成回答。

2. **Rubric generator `rho_phi`**  
   根据问题生成自然语言 rubric。

3. **Frozen judge `J`**  
   给定问题、rubric 和回答，输出一个 0 到 1 的分数。

主要实验中，policy 和 rubric generator 都由同一个 **Qwen3-8B** 承担，只通过不同 prompt 区分角色；judge 是冻结的 **Qwen3-1.7B**。

### Rubric 作为 latent variable

论文把 rubric 当作解释偏好关系的潜变量。

给定问题 `q` 和偏好对 `(a+, a-)`，一个好 rubric 应该让 judge 给 `a+` 更高分：

```text
J(q, r, a+) > J(q, r, a-)
```

因此 rubric generator 的目标不是“写得像 rubric”，而是最大化 **discriminative utility（判别效用）**：rubric 是否能扩大 preferred response 和 dispreferred response 之间的 judge score margin。

作者从 variational inference 推导出目标，把 rubric generator 看成一个 agent，生成离散文本 rubric，并通过 policy gradient / GRPO 优化。

实践中，rubric reward 由两部分组成：

- **margin reward**：`J(q, r, a+) - J(q, r, a-)`；
- **format reward**：rubric 是否符合可解析的 JSON schema。

默认权重里 margin 占 0.7，format reward 占 0.3。

### 交替训练流程

EvoLM 不是同时更新 policy 和 rubric generator，而是以 `K` 步为周期交替训练。主设置中 `K = 50`。

#### Phase 1: 用固定 rubric generator 训练 policy

1. 对每个问题生成 rubric；
2. policy 对同一问题采样多个回答；
3. 冻结 judge 根据 rubric 给回答打分；
4. 对同一问题内的多个回答做 group-relative reward；
5. 用 GRPO 更新 policy。

这一步让 policy 学会更好地满足当前 rubric。

#### Phase 2: 用当前 policy 输出训练 rubric generator

1. 从当前 policy 和历史输出构造偏好对；
2. rubric generator 为问题采样多个 candidate rubrics；
3. judge 分别用这些 rubric 给 preferred / dispreferred responses 打分；
4. 哪个 rubric 能让 judge 更清楚地区分好坏，哪个 rubric 就得到更高 reward；
5. 用 GRPO 更新 rubric generator。

这一步让 rubric generator 学会更好地评价当前 policy 的输出分布。

### 偏好对从哪里来

论文强调不使用人工标注或外部偏好数据，而是从 policy 自己的输出中构造 preference pairs。作者讨论三种方式。

#### 1. Temporal contrast

当前 checkpoint 的回答作为 `a+`，较早 checkpoint 的回答作为 `a-`。

直觉是：随着训练推进，当前 policy 通常比早期 policy 更强，所以晚期输出可以作为相对 preferred response。时间间隔 `[20, 100]` 控制难度：间隔太大，差异容易；间隔太小，rubric 需要捕捉更细差别。

这是主配置中最重要的偏好信号。

#### 2. Inferred question

给定一个好回答，让 policy 反推出它像是在回答什么问题，再对这个 inferred question 生成另一个回答作为对比。

这个信号主要训练 rubric 是否能检查“回答是否真的切中问题”。

#### 3. Rubric-conditioned

给 policy 同时输入问题和 rubric，生成一个 rubric-conditioned response；再只输入问题生成普通 response。前者被视为 preferred。

这个信号鼓励 rubric generator 产生真正能指导回答质量的标准。

## 📊 实验与结论

### 实验设置

训练数据来自 **Tulu 3 preference mixture**，去重后约 271K prompts，覆盖：

- general chat；
- instruction following；
- math；
- code；
- scientific literature understanding；
- persona-driven synthetic instructions。

评测分两类：

1. **Policy quality**：OLMo3-Adapt suite 的 12 个 benchmark，包括 GSM8K、MATH、HumanEval+、MBPP+、BBH、MMLU、IFEval、PopQA、GPQA、ZebraLogic、AGI-Eval、AlpacaEval v3。
2. **Rubric quality**：RewardBench 2 和 JudgeBench，测试 rubric-conditioned evaluation 能否正确排序偏好回答。

### 1. EvoLM 的 policy 表现最好

主结果显示，EvoLM 的下游 policy 在 OLMo3-Adapt 12 项平均达到 **69.3%**，超过：

- GPT-4.1 prompted rubrics: 66.7%；
- Qwen3-8B prompted rubrics: 67.5%；
- RAR / RRD / RLCER / Rubric-ARM 等 rubric-based RL baselines: 66.7-67.6%；
- SkyWork-RM-V2 scalar reward model: 59.7%。

最明显的收益出现在代码生成上：HumanEval+ 达到 86.2%，高于下一强方法的 80.5%。作者的解释是，代码任务里好 rubric 可以写出很具体的可检查条件，因此 reward 更尖锐。

### 2. 静态 reward benchmark 高不等于训练 policy 好

一个很重要的反直觉结果是：SkyWork-RM-V2 在 RewardBench 2 上达到 86.4%、JudgeBench 达到 80.8%，静态 reward benchmark 很强；但它训练出的 policy 平均只有 59.7%，比 EvoLM 低 9.6 点。

这说明：**静态偏好 benchmark 上更会排序，不等于作为 RL reward 更可靠。** 当 policy 开始优化 reward，输出分布会移动，固定 reward model 可能被过度优化甚至 exploit。

EvoLM 的优势是 rubric 会随 policy co-evolve，保持对当前输出分布的判别力。

### 3. Co-evolving 比 sequential 更适合 policy 训练

顺序训练里，先训练 rubric generator，再冻结它训练 policy。这个方法的静态 rubric accuracy 反而更高：RewardBench 2 平均 47.2%，高于 EvoLM 的 46.0%。

但下游 policy 表现是 EvoLM 更好：69.3% vs. 68.3%。

这进一步说明论文的关键不是追求静态 rubric benchmark 最高，而是让 rubric 在 policy 变化过程中持续提供有效 reward。

### 4. Rubric 会从抽象标签演化成可验证检查

论文做了定性和统计分析，发现训练后的 rubric 发生了很清楚的形态变化：

- label-only criteria 从 21.9% 降到 0.3%；
- embedding specific expected values 的 criteria 从 6.9% 升到 19.3%；
- constraint-type criteria 从 7.7% 升到 20.3%；
- criteria 平均长度从 59 个字符增加到 112 个字符；
- criteria 数量大体保持在 3-4 条。

这说明 EvoLM 不只是写更多 criteria，而是把 criteria 写得更密、更具体、更容易检查。

### 5. OOD expert rubric 对齐也更好

作者用 HealthBench 和 ResearchQA 测试泛化。这两个任务有 expert-written rubrics，且不在 EvoLM 的训练分布中。

EvoLM 生成的 rubric 用 Qwen3-1.7B judge 打分后，与专家 rubric 排名的一致性最好：

- HealthBench pairwise accuracy: 58.4%，高于 Qwen3-8B prompted 的 53.0% 和 GPT-4.1 prompted 的 52.5%；
- ResearchQA pairwise accuracy: 59.3%，高于 Qwen3-8B prompted 的 57.2% 和 GPT-4.1 prompted 的 51.0%；
- ResearchQA Acc@0.05 达到 68.7%。

这说明 EvoLM 学到的不是某个训练集上的固定模板，而是能迁移到专家评测任务的评价结构。

### 6. learned rubrics 能迁移到未见 policy 和 judge

作者把主实验中训练好的 rubric generator 冻结，拿去训练未见 policy：

- Qwen3-4B: EvoLM rubric 训练结果 65.2%，高于 GPT-4.1 rubric 的 64.4%；
- Llama-3.1-8B: EvoLM rubric 训练结果 46.9%，高于 GPT-4.1 rubric 的 45.7%。

跨 judge 评测中，用 Qwen3-8B、OLMo-3-7B 等未见 judge 评估时，EvoLM rubric 也普遍优于 prompted rubrics。多 judge 训练还会提升跨 judge 可解释性，但在主训练设置下，单一 1.7B judge 反而给出了最好的 downstream policy。

### 7. 消融实验说明 format 和自演化闭环最关键

作者消融了 reward design、交替频率、单模型/双模型、偏好信号、judge size、temporal contrast step gap、跨架构等因素。

几个关键结论：

- 加上 format reward 很重要，否则 rubric validity 会从 85% 以上降到 23%；
- `K = 50` 的 policy 平均 69.3%，比 K=2/10/20/100 都略好；
- single-model 和 two-model 都达到 69.3%，说明共享同一个 Qwen3-8B 可节省内存且不损失性能；
- temporal contrast 单独作为偏好信号时 policy 最好，达到 69.3%；
- 1.7B judge 已经足够，4B/8B judge 虽然提高 RewardBench 2，但 policy 表现反而下降；
- 每组消融中，RewardBench 2 最高的设置都不是 downstream policy 最好的设置。

最后一点很重要：**rubric 的静态排序能力和作为动态训练 reward 的有效性不是同一个指标。**

### 结论

作者可以合理得出的结论是：

1. LLM 的预训练知识中已经包含可用的评价能力，关键是把它结构化成 rubric。
2. Rubric quality 可以用 discriminative utility 定义：是否帮助 judge 区分 preferred / dispreferred responses。
3. Policy 和 rubric generator 交替共演化，比先训好固定 rubric 再训练 policy 更适合动态 RL。
4. EvoLM 不需要人工标注、专有 API、外部 reward model 或 verifier，也能构造有效 reward。
5. 学到的 rubric 可以迁移到未见 policy、未见 judge 和 OOD expert-rubric tasks。

我的保留意见：

- 论文主要在 general-purpose post-training 数据上验证，医学、法律等专业领域的真实训练效果仍是开放问题。
- rubric enrichment 在数学、代码、格式约束等可检查任务上最清楚；纯主观任务中的效果机制还不够明确。
- 冻结 judge 有助于隔离 rubric generator 的贡献，但也限制了 rubric 可以表达的复杂标准。
- Temporal contrast 默认假设当前 checkpoint 通常优于早期 checkpoint；如果训练不稳定或任务分布变化，这个假设可能被破坏。
- 训练成本不低，主实验仍需要 Qwen3-8B、长周期 alternating GRPO 和大规模 rollout。

## 🧩 关键术语

- **EvoLM（自演化语言模型）**: 让 policy 和 rubric generator 交替改进的后训练框架。例子：policy 用 rubric reward 学会更好回答，rubric generator 再用新旧 policy 输出差异学习更尖锐的评价标准。

- **Discriminative Rubric（判别式评价标准）**: 不是泛泛描述好回答，而是能把 preferred response 和 dispreferred response 分开的 rubric。例子：数学题里直接检查是否得到关键中间值和最终答案。

- **Discriminative Utility（判别效用）**: rubric 的训练目标，衡量它是否让 judge 给好回答更高分、差回答更低分。例子：某 rubric 让 score margin 从 0.05 增加到 0.4，它的判别效用更高。

- **Temporal Contrast（时间对比）**: 用当前 checkpoint 输出作为 preferred response，用早期 checkpoint 输出作为 dispreferred response。例子：step 500 的回答和 step 420 的回答配对，假设后者整体较弱。

- **Rubric-conditioned Reward（基于 rubric 的奖励）**: judge 不是直接整体打分，而是在给定 rubric 后给回答评分。例子：先看回答是否满足每条 criteria，再给出 0 到 1 的分数。

- **Frozen Judge（冻结裁判）**: 训练过程中参数不更新的 judge。例子：EvoLM 默认用 Qwen3-1.7B 作为小 judge，所有改进来自 rubric generator 和 policy。

- **GRPO, Group Relative Policy Optimization（组相对策略优化）**: 对同一问题采样多个回答或多个 rubric，用组内相对奖励计算 advantage。例子：同一问题下 8 个回答按 judge 分数归一化后更新 policy。

- **Reward Overoptimization（奖励过度优化）**: policy 把固定 reward model 的漏洞越优化越明显。例子：SkyWork-RM-V2 静态 benchmark 很强，但训练出的 policy 平均表现反而低。

- **Rubric Validity（评价标准有效格式率）**: rubric 是否满足可解析 schema。例子：format reward 保证 judge 能逐项读取 criteria，否则 rubric 可能变成散乱自然语言。

- **Co-evolution（共演化）**: 两个模块在训练中相互改变对方的数据分布和学习目标。例子：policy 变强后，rubric 需要更具体；rubric 更具体后，policy 又能继续改进。

## 💡 个人评价

这篇论文和 Rubric-ARM、Rubrics-as-Rewards 属于同一条大趋势：把 reward 从黑箱标量变成结构化、可解释、可训练的评价标准。但 EvoLM 的推进点更激进：它试图去掉外部监督，让 rubric generator 的训练信号来自 policy 自己的演化轨迹。

我觉得最值得借鉴的是 **discriminative utility** 这个定义。它把“什么是好 rubric”从主观语言质量改写成一个可优化目标：能不能让固定 judge 区分好坏回答。这让 rubric 不再只是 prompt engineering，而成为一个可以和 policy 一起训练的模块。

另一个有启发的结果是：RewardBench 2 / JudgeBench 分数最高的设置并不一定训练出最好的 policy。这对 reward model 研究很重要，因为它提醒我们，静态偏好排序只是 reward 的一部分；真正关键的是 reward 在 policy 优化过程中是否仍然保持有信息量。

后续我会重点关注三个问题：

- temporal contrast 的偏好假设在更噪声、更长周期训练里是否稳定；
- 专业领域里 rubric generator 是否能学到足够可靠的领域标准；
- 是否可以让 judge 也缓慢演化，同时避免 Rubric-ARM 式多模块非平稳问题。

## 🔗 相关论文

- Rubric-ARM: Alternating Reinforcement Learning for Rubric-Based Reward Modeling
- Rubrics as Rewards: Reinforcement Learning Beyond Verifiable Domains
- Reinforcement Learning with Rubric Anchors
- Self-Rewarding Language Models
- SPIN: Self-Play Fine-Tuning Converts Weak Language Models to Strong Language Models
- Meta-Rewarding Language Models
- GRPO / DeepSeek-R1
- Skywork-RM-V2
