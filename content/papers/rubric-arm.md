---
title: "Alternating Reinforcement Learning for Rubric-Based Reward Modeling in Non-Verifiable LLM Post-Training"
date: 2026-04-23T17:13:35+08:00
draft: false

# 分类（研究领域）
categories: ["强化学习"]

# 会议/期刊
venues: "arXiv 2026"

# 论文元数据
authors: ["Ran Xu", "Tianci Liu", "Zihan Dong", "Tony Yu", "Ilgee Hong", "Carl Yang", "Linjun Zhang", "Tuo Zhao", "Haoyu Wang"]
year: "2026"
paper_url: "https://arxiv.org/abs/2602.01511"
arxiv_url: "https://arxiv.org/pdf/2602.01511"
code_url: "https://huggingface.co/collections/OpenRubrics/rubricarm"

# 阅读状态
status: "completed"
rating: 4
read_date: "2026-04-23"

summary: "这篇论文提出 Rubric-ARM：把 rubric 生成从静态 prompt 或独立 SFT 模块，改写成一个会影响 judge 正确性的潜变量动作，并用交替强化学习联合优化 rubric generator 和 judge。核心 insight 是：在非可验证任务里，高质量 reward 不是一个单独的标量打分器，而是“评价标准”和“基于标准的判断”共同演化出来的系统。实验显示 Rubric-ARM 在多个 reward modeling benchmark 上优于 Rubric-RM 等白盒基线，并能作为 DPO/GRPO 的奖励信号提升下游策略模型。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文解决的是 LLM post-training 里一个越来越核心的问题：

**在没有标准答案的开放任务里，reward model 到底应该怎么判断一个回答好不好？**

比如下面这些任务：

- 创意写作；
- 开放式指令跟随；
- 风格、语气、结构约束；
- 需要同时满足多个软硬标准的回答；
- 两个回答都“看起来不错”，但一个更符合用户真实偏好的场景。

传统 reward model 往往输出一个标量分数，或者直接判断 A/B 哪个更好。这个做法的问题是：开放任务的质量不是单维的。

一个回答可能：

- 事实正确，但没有遵守格式；
- 语气自然，但漏掉关键词；
- 内容更长，但偏离用户真正问的问题；
- 推理更充分，但违反了硬约束。

所以近年的一条路线是 **rubric-based reward modeling**：先生成一组评价标准，再根据这些标准判断回答优劣。

这篇论文的重点不是“使用 rubric”本身，而是问了一个更进一步的问题：

**rubric 应该是人工写好的、prompt 生成后固定不变的，还是应该像 policy 一样被训练出来？**

作者提出的答案是 **Rubric-ARM**：

- 用一个 **rubric generator** 根据 prompt 生成评价标准；
- 用一个 **judge** 根据 prompt、两个 response 和 rubric 判断偏好；
- 把 rubric 当成一个 latent action；
- 通过 preference correctness reward 同时训练 rubric generator 和 judge；
- 为了避免两个模块同时变化导致不稳定，采用 **alternating reinforcement learning**：先固定 rubric generator 训练 judge，再固定 judge 训练 rubric generator。

## 🎯 研究背景

这篇工作位于三个研究方向的交叉处。

### 1. Reward Modeling

Reward model 是 RLHF / RLAIF / DPO / GRPO 等 post-training 流程里的评价器。它的作用像一个“指南针”：告诉策略模型哪个回答更接近人类偏好。

早期 reward model 常见形式是：

- 输入 prompt 和 response；
- 输出一个 scalar score；
- 或者输入两个 response，输出哪个更好。

这种形式在可验证任务里相对直接，比如数学题、代码题、选择题，因为答案对错可以验证。但在非可验证任务里，问题就复杂得多。

例如用户要求：

> 用兴奋的语气，解释 Nextcloud 是什么，正好写两段，并包含 `cloud storage` 和 `open-source` 两个关键词。

这个任务的好坏不是一个简单分数能解释的，因为它同时包含：

- 内容覆盖；
- 语气；
- 段落数量；
- 精确关键词；
- 比较对象；
- 逻辑结构。

### 2. LLM-as-a-Judge

另一条路线是让 LLM 直接当 judge。它可以生成 reasoning，再输出 A/B 偏好。

这比纯标量 reward 更可解释，但也有问题：

- 容易被 response 顺序影响，也就是 position bias；
- 可能被更长、更像“认真回答”的文本欺骗；
- 遇到复杂指令时，可能在推理中漏掉硬约束；
- judge 的 reasoning 不一定真的围绕用户需求展开。

### 3. Rubric-Based Reward Modeling

Rubric-based 方法试图把评价过程结构化：

- 先列出评价标准；
- 再逐条检查回答是否满足标准；
- 最后做整体判断。

这类方法更像“老师批作文”：

- 不能只说 85 分；
- 要先说明评分维度；
- 再解释为什么扣分或加分。

已有方法的问题是，rubric 往往来自：

- 人工标注；
- frozen LLM prompt；
- SFT 训练出的静态模块；
- 与 judge 分开训练的 pipeline。

这使得 rubric generator 和 judge 很难真正适应同一个 preference distribution。

## ⚠️ 问题与挑战

论文要解决的问题是：

**如何在非可验证任务中，训练一个能够自动生成高质量 rubric，并用这些 rubric 做准确偏好判断的 reward model。**

这个问题有几层挑战。

### 1. 因为非可验证任务没有标准答案，所以 reward 不能只依赖 outcome correctness

数学题可以看最终答案是不是对。代码题可以跑测试。但创意写作、开放式问答、指令跟随往往没有唯一答案。

所以很难设计类似“答对给 1 分，答错给 0 分”的 reward。

这导致训练信号只能来自 pairwise preference：

- 给定 prompt；
- 给定 response A 和 response B；
- 数据集告诉你哪个更被偏好。

但 preference label 只告诉你结果，不告诉你为什么。

### 2. 因为回答质量是多维的，所以单一标量 judge 容易丢失评价结构

如果 reward model 只输出 A 更好，它可能没有显式区分：

- A 是否满足硬约束；
- A 是否只是更长；
- A 是否覆盖了关键词；
- A 是否语气更符合要求；
- A 是否逻辑更清楚。

这会使 reward signal 变得模糊。下游 policy 如果用这种信号训练，就可能学到错误偏好。

例如，模型可能学到“更长就是更好”，而不是“满足用户的 exact constraints 更好”。

### 3. 因为 rubric 本身没有监督标签，所以很难直接训练 rubric generator

真实数据里通常只有：

- prompt；
- 两个 responses；
- 哪个 response 更好。

但没有告诉你“最好的 rubric 应该怎么写”。

所以 rubric generator 的训练目标很尴尬：

- 如果只用 LLM 合成 rubric 做 SFT，它学到的是 teacher 的表面风格；
- 如果 rubric generator 和 judge 分开训练，它不知道自己生成的 rubric 是否真的能帮助判断；
- 如果直接同时训练两个模块，judge 和 rubric generator 都在变，学习目标会不断漂移。

### 4. 因为两个模块相互依赖，所以联合优化天然不稳定

Rubric generator 生成标准，judge 根据标准做判断。

如果 rubric generator 很差，judge 会收到噪声标准；
如果 judge 很差，rubric generator 收到的 reward 也不可靠。

这形成一个因果困境：

**因为 rubric 的好坏要通过 judge 的判断正确性来体现，而 judge 的判断又依赖 rubric 的质量，所以两个模块同时更新时，reward 信号会高度非平稳。**

这就是论文里 alternating RL 要解决的核心训练难点。

## 🔍 核心发现 Finding

### 作者明确声称

作者明确的主张是：

**rubric generation 可以被视为一个 latent action，并通过它对 preference prediction correctness 的影响来训练；同时，先稳定 judge、再训练 rubric generator 的交替优化，可以降低梯度方差并提升训练稳定性。**

### 我的理解

我认为这篇论文真正的 `Finding` 是：

**开放任务的 reward modeling 不应该被看成“一个模型给回答打分”，而应该被看成“先生成适配当前 prompt 的评价坐标系，再在这个坐标系里判断回答”的联合决策过程。**

这个 finding 和已有方法的差别很关键。

传统 reward model 的世界观是：

- response 质量是一个隐含标量；
- reward model 要学会估计这个标量。

Rubric-based 旧方法的世界观是：

- rubric 是一个有用的解释中间件；
- 但 rubric 可以由固定 prompt 或 SFT 模块生成；
- judge 再利用这个中间件判断。

Rubric-ARM 的世界观则是：

- rubric 不是静态说明书；
- rubric 是会改变 judge 行为的 action；
- 一个 rubric 的好坏，应该由它是否帮助 judge 找回真实 preference 来定义；
- 因此 rubric generator 和 judge 必须通过共同目标 co-evolve。

这就把问题从：

> 怎么写一个更好的评分 prompt？

改写成：

> 怎么训练一个能为当前 prompt 生成“最有判别力评价标准”的 policy？

这个视角使得原本没有 rubric 标签的问题变得可解。因为虽然我们不知道标准答案 rubric 是什么，但我们知道最终 preference label。如果某个 rubric 能让 judge 更稳定地选中偏好答案，这个 rubric 就是更好的 latent action。

举个例子：

用户问“thumb war 是否 violent？我关心 physical 和 psychological violence。”

一个差的 rubric 可能泛泛地写：

- 是否解释 war；
- 是否讨论 violence；
- 是否逻辑清楚。

这会让 judge 被 response A 里关于战争的大段解释带偏。

一个好的 rubric 会抓住任务真正的硬约束：

- 必须直接回答 thumb war 是否构成 violence；
- 必须分别讨论 physical violence 和 psychological violence。

Rubric-ARM 的 insight 是：这种“抓住当前 prompt 关键约束”的能力，不应该只靠 prompt engineering，而应该通过 preference correctness 训练出来。

## 🔬 方法

### 输入数据

训练数据是 pairwise preference dataset：

- prompt `x`；
- 两个候选回答 `y1` 和 `y2`；
- preference label `o*`，表示哪一个回答更好。

注意：数据里没有 ground-truth rubric。

### 整体框架

Rubric-ARM 有两个模块：

1. **Rubric Generator `pi_r`**
   输入 prompt，输出 rubric。

2. **Judge `pi_j`**
   输入 prompt、两个回答和 rubric，输出 reasoning chain 与偏好判断。

目标是最大化：

- judge 的预测偏好 `o` 与真实 preference label `o*` 是否一致。

也就是一个二值 correctness reward：

- 预测对了，reward 为 1；
- 预测错了，reward 为 0。

### Stage I: SFT Warmup

作者先做监督微调 warmup，让两个模块具备基本能力。

使用的数据来自 OpenRubrics 的 general-domain 部分，以及相关开源数据：

- UltraFeedback；
- SkyWork；
- Magpie；
- Synthetic Instruction Following。

这一阶段的作用不是完成最终优化，而是让模型先会做两件事：

- rubric generator 能生成像样的结构化评价标准；
- judge 能根据 rubric 写出判断过程并给出偏好。

可以把它理解成“先让学生学会考试格式”。

### Stage II: Alternating Reinforcement Learning

SFT 之后，作者用 GRPO 做交替 RL。

#### 第一步：固定 rubric generator，训练 judge

流程是：

1. 用当前 rubric generator 为每个 prompt 生成 rubric；
2. 缓存这些 rubric；
3. 固定 rubric generator；
4. 训练 judge 在这些 rubric 下更准确地恢复 preference label。

judge 的 reward 包含两部分：

- `Racc`: 偏好预测是否正确；
- `Rfmt`: 输出格式是否有效。

`Rfmt` 很重要，因为 judge 不应该只在最后给 A/B，而应该：

- 逐条检查 rubric criteria；
- 给出每条 criterion 的解释；
- 做整体 justification；
- 最后给出明确判断。

#### 第二步：固定 judge，训练 rubric generator

流程是：

1. 固定 judge；
2. rubric generator 为 prompt 生成 rubric；
3. judge 根据这个 rubric 判断两个回答；
4. 如果 judge 选对 preference label，这个 rubric 就得到正向 reward；
5. 用 GRPO 更新 rubric generator。

直觉是：

**rubric generator 学到的不是“写得像 rubric”，而是“写出能让 judge 判断正确的 rubric”。**

### 为什么先 judge 后 rubric generator

论文的理论分析围绕梯度方差展开。

作者比较两种策略：

- Strategy A: 先固定并复用 rubric，训练 judge；
- Strategy B: 训练 rubric generator，让它探索不同 rubric。

结论是：

- judge 训练阶段的方差主要来自二分类判断的不确定性；
- rubric generator 训练阶段还额外包含 cross-rubric inconsistency；
- 早期 rubric generator 的探索会主导学习动态，使梯度方向更不稳定。

所以作者认为：先把 judge 稳住，再用稳定 judge 给 rubric generator 提供 reward，是更合理的顺序。

### 和 EM 的关系

作者把这个过程类比成 generalized EM：

- rubric 是 latent variable；
- judge 更新类似 M-step，在给定 rubric 下最大化 preference correctness；
- rubric generator 更新类似 amortized E-step，把概率质量放到更能帮助 judge 预测正确的 rubric 上。

这个类比有助于理解为什么 rubric 不是简单的解释文本，而是隐变量。

### 用 Rubric-ARM 训练 policy

训练好 Rubric-ARM 后，它可以作为下游 policy 的 reward signal。

作者实验了两种方式：

1. **Offline DPO / IterDPO**
   对同一个 prompt 采样两个回答，用 Rubric-ARM 判断偏好，然后用 DPO 更新 policy。

2. **Online GRPO**
   对 prompt 生成 greedy baseline response 和若干 sampled responses，再用 Rubric-ARM 评估 sampled response 是否优于 baseline，并作为 GRPO reward。

为减少 position bias，online RL 中会用同一个 rubric 对 response 顺序进行双向评估。

## 📊 实验与结论

### 实验设置

Rubric-ARM 的两个模块都从 **Qwen-3-8B** fine-tune。

reward model 评测覆盖多个 benchmark：

- RewardBench；
- RM-Bench；
- PPE-IFEval；
- FollowBench；
- InfoBench；
- IFBench；
- RewardBench2；
- WritingPreferenceBench；
- HelpSteer3。

下游 policy 训练用 **Qwen2.5-7B-Instruct**，评估包括：

- IFEval；
- InfoBench；
- IFBench；
- Arena-Hard；
- AlpacaEval 2；
- WildBench；
- Creative Writing Benchmark v3。

### 1. Rubric-ARM 作为 reward model 优于同类白盒基线

主表里，Rubric-ARM 在多个 reward modeling benchmark 上取得最强白盒结果。

关键数字：

- Rubric-RM 平均分：70.1；
- Rubric-ARM 平均分：74.8；
- Rubric-ARM-voting@5 平均分：76.2。

这说明相较于 SFT-only 的 rubric generator + judge，交替 RL 确实带来提升。

更重要的是，这个提升不只是“多训练了一下”，而是符合论文的 finding：

- rubric generator 通过 judge correctness 学会生成更有判别力的标准；
- judge 通过固定 rubric 训练获得更稳定的 rubric-conditioned judging 能力。

### 2. OOD 写作偏好上也有提升

WritingPreferenceBench 是一个偏分布外的写作偏好 benchmark。

结果：

- Rubric-RM: 60.3；
- Rubric-ARM: 63.2；
- RM-R1-Qwen2.5-7B: 59.8。

这很有价值，因为创意写作和开放式文本质量特别难用静态标准覆盖。

作者的解释是：Rubric-ARM 学到的不是某个数据集上的固定评分模板，而是“根据 prompt 生成可迁移评价维度”的能力。

例如在 poetry、promotional writing、non-fiction 等不同类型里，好的 rubric 应该完全不同。一个能自动适配 prompt 的 rubric generator，比固定 judge 更容易泛化。

### 3. Ablation 证明训练顺序和 format reward 都重要

作者做了两个关键消融。

#### 交换优化顺序会变差

默认顺序：

- 先优化 judge；
- 再优化 rubric generator。

如果改成反过来，平均分从：

- 74.8 降到 72.4；
- voting@5 从 76.2 降到 74.9。

在 RewardBench2-Precise IF 上尤其明显：

- 默认 Rubric-ARM: 41.9；
- switch opt: 24.4。

这和理论分析一致：早期 rubric generator 的探索噪声太大，如果 judge 还没稳定，rubric generator 收到的 reward 会更乱。

#### 去掉 format reward 也会变差

去掉 `Rfmt` 后：

- 平均分从 74.8 降到 72.6；
- voting@5 从 76.2 降到 75.5。

这说明 judge 的输出格式不是表面问题。对 rubric-based judging 来说，如果 judge 不逐条检查 criteria，就容易退化成普通 LLM judge。

举个例子：

- rubric 里有“必须包含 exact keyword open-source”；
- judge 如果不按 rubric 检查，只凭整体印象判断，可能会把包含 “open” 但不包含 “open-source” 的回答误判为满足要求。

### 4. 下游 DPO / IterDPO 能从 Rubric-ARM reward 中受益

在 IFEval 和 InfoBench 上，用 Rubric-ARM 训练 policy 效果最好：

- DPO via Rubric-ARM: IFEval 平均 80.4，InfoBench 83.7；
- IterDPO via Rubric-ARM: IFEval 平均 80.8，InfoBench 85.0。

在 IFBench 上：

- RLCF IterDPO: 32.0；
- Rubric-RM IterDPO: 33.7；
- Rubric-ARM IterDPO: 35.4。

这说明 Rubric-ARM 不只是 benchmark judge 分数更高，它产生的 preference label 确实能作为更好的训练信号。

### 5. 开放偏好和创意写作也有收益

Arena-Hard / AlpacaEval：

- DPO via Rubric-ARM 平均 51.7；
- IterDPO via Rubric-ARM 平均 53.4。

WildBench：

- DPO via Rubric-ARM: 53.7；
- IterDPO via Rubric-ARM: 55.7；
- IterDPO via Rubric-RM: 54.0。

Creative Writing Benchmark v3：

- Rubric-ARM DPO: 39.0；
- Rubric-ARM IterDPO: 39.3；
- Rubric-RM DPO: 38.3；
- Rubric-RM IterDPO: 38.8。

这个结果和论文主题很一致：越是非可验证、主观、多维的任务，rubric 这种显式评价结构越有用。

### 6. Online GRPO 中也能当 reward signal

在线 RL 实验中，作者用 Rubric-ARM 给 GRPO 提供 reward。

平均结果：

- Qwen2.5-7B-Instruct base: 46.8；
- GRPO with RM-R1: 52.3；
- GRPO with Rubric-ARM: 55.4。

这说明 Rubric-ARM 不只是适合离线 DPO 标注偏好对，也能在在线采样、在线优化中作为 reward model。

### 7. Case study 显示 Rubric-ARM 更擅长抓硬约束

论文中的 thumb war 例子很有代表性。

Prompt 问的是：

> Wars involve armed conflicts... Is a thumb war violent? I care about both physical and psychological violence.

错误模型容易被 “war” 这个词带偏，选择讨论战争暴力的长回答。

Rubric-ARM 生成的 rubric 把重点拉回：

- 必须直接回答 thumb war 是否 violent；
- 必须考虑 physical violence；
- 必须考虑 psychological violence。

因此它能选中更短但真正回答问题的 response。

这个 case 的意义是：Rubric-ARM 不只是让 judge 更会解释，而是让评价标准先对准 prompt 的关键约束，再开始判断。

### 8. 效率也不错

虽然 Rubric-ARM 有两个 Qwen-3-8B 模块，但推理并不慢。

在 100 个 RewardBench2 prompts 上：

- Rubric-ARM-8B: 33.50 秒；
- Rubric-RM-8B: 105.12 秒；
- RM-R1-7B 等 reasoning-based baselines 更慢。

作者认为原因是：Rubric-ARM 用较短的 rubric + lightweight judging 替代了长链式推理。

### 结论

作者可以合理得出的结论是：

1. Rubric generation 可以作为 latent action 训练，而不只是 prompt engineering。
2. Rubric generator 和 judge 联合优化比独立 SFT 更有效。
3. 先 judge 后 rubric generator 的交替顺序能缓解训练不稳定。
4. Rubric-ARM 作为 reward model，不仅自身 benchmark 表现强，还能提升下游 offline DPO 和 online GRPO。
5. 这个方法尤其适合非可验证、多约束、主观性强的开放任务。

我的保留意见：

- 论文主要依赖已有 preference label，因此不是完全无监督 reward learning；
- rubric generator 和 judge 都基于 Qwen-3-8B，系统成本仍高于单模型 reward；
- correctness reward 仍由 benchmark preference 决定，如果 preference 数据本身有偏，rubric 也会学习这种偏；
- 论文强调稳定性，但对 rubric 质量本身的人工可解释性评价还可以更深入。

## 🧩 关键术语

- **Rubric（评价规约）**: 一组结构化评价标准，用来说明回答应该满足哪些要求。例子：对于“写两段并包含 open-source”的 prompt，rubric 会包含“必须正好两段”和“必须包含 exact keyword open-source”。

- **Rubric Generator（评价规约生成器）**: 根据 prompt 自动生成 rubric 的模型。例子：看到用户要求比较 Nextcloud 和其他云存储，它应该生成关于定义、使用原因、比较维度、语气和关键词的标准。

- **Judge（裁判模型）**: 根据 prompt、两个 candidate responses 和 rubric 判断哪个回答更好。例子：如果 response A 满足所有 hard rules，而 response B 漏掉关键词，judge 应该选择 A。

- **Non-Verifiable Domain（非可验证领域）**: 没有唯一标准答案、无法简单用规则验证对错的任务。例子：创意写作、开放式问答、语气控制、复杂指令跟随。

- **Preference Correctness Reward（偏好正确性奖励）**: 判断模型预测的偏好是否等于数据集中的偏好标签。例子：数据标注 A 优于 B，judge 也选 A，则 reward 为 1。

- **Latent Action（潜在动作）**: 不直接被监督、但会影响最终结果的中间决策。在这篇论文里，rubric 就是 latent action，因为数据集没有告诉模型正确 rubric 是什么，但 rubric 会影响 judge 能否选对。

- **Alternating Reinforcement Learning（交替强化学习）**: 不同时更新两个模块，而是在每轮中先固定一个、训练另一个。例子：先固定 rubric generator 训练 judge，再固定 judge 训练 rubric generator。

- **GRPO, Group Relative Policy Optimization（组相对策略优化）**: 一种不依赖 value model 的 RL 优化方法，通过同一 prompt 下多个生成结果的相对表现更新模型。例子：Rubric-ARM 用 GRPO 更新 judge 和 rubric generator。

- **Format Reward（格式奖励）**: 鼓励 judge 按指定结构输出的奖励。例子：要求 judge 逐条检查 rubric、给 per-criterion explanation、写整体 justification、最后输出 A/B。

- **Position Bias（位置偏置）**: judge 对 response 顺序敏感，而不是只根据内容判断。例子：同样两个回答，A/B 交换顺序后，模型偏好也改变。

- **DPO, Direct Preference Optimization（直接偏好优化）**: 用偏好对直接优化 policy 的方法。例子：Rubric-ARM 标注哪个 response 更好，然后用这些偏好对训练 Qwen2.5-7B-Instruct。

- **IterDPO, Iterative DPO（迭代式直接偏好优化）**: 多轮重复采样、标注偏好、DPO 更新的流程。例子：Rubric-ARM 的 IterDPO 在 IFEval、InfoBench、WildBench 上进一步超过单轮 DPO。

- **Online RL（在线强化学习）**: policy 在训练过程中不断采样新回答，并用 reward model 实时打分更新。例子：作者用 Rubric-ARM 作为 reward model，对 Qwen2.5-7B-Instruct 做 GRPO。

- **Rubric-Conditioned Judging（基于评价规约的判断）**: judge 的判断明确依赖 rubric，而不是直接凭整体印象投票。例子：先检查“是否正好两段”，再检查“是否包含 exact keyword”，最后决定哪个 response 更好。

## 💡 个人评价

这篇论文的价值在于把 rubric 从“解释性辅助文本”提升成了“可优化的中间决策”。这个视角和最近 rubric-as-reward、rubric anchor、open-ended RL 的趋势很一致：当任务不能用标准答案验证时，关键不是强行造一个标量 reward，而是把评价标准显式化、结构化，并让它参与训练。

我觉得最值得借鉴的是两个点：

- 如果要做开放任务 RL，不要只训练 judge，也要训练“评价标准生成器”。
- 多模块 reward 系统联合训练时，先稳定 evaluator，再训练 criteria generator，可能比端到端同时更新更可靠。

如果后续实现类似系统，我会优先复现三个部分：

- prompt-specific rubric generation；
- rubric-conditioned pairwise judging；
- order-swapped consistency filtering，降低 position bias。

## 🔗 相关论文

- Rubrics as Rewards: Reinforcement Learning Beyond Verifiable Domains
- Reinforcement Learning with Rubric Anchors
- OpenRubrics: Towards Scalable Synthetic Rubric Generation for Reward Modeling and LLM Alignment
- Reward Modeling as Reasoning
- Learning to Summarize with Human Feedback
