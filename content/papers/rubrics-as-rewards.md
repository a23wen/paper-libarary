---
title: "Rubrics as Rewards: Reinforcement Learning Beyond Verifiable Domains"
date: 2026-04-11T13:35:18+08:00
draft: false

# 分类（研究领域）
categories: ["强化学习"]

# 会议/期刊
venues: "arXiv 2025"

# 论文元数据
authors: ["Anisha Gunjal", "Anthony Wang", "Elaine Lau", "Vaskar Nath", "Yunzhong He", "Bing Liu", "Sean Hendryx"]
year: "2025"
paper_url: "https://arxiv.org/abs/2507.17746"
arxiv_url: "https://arxiv.org/pdf/2507.17746"
code_url: ""

# 阅读状态
status: "completed"
rating: 4
read_date: "2026-04-11"

summary: "提出 Rubrics as Rewards（RaR），把按题目定制的 rubric/checklist 直接变成 GRPO 的奖励信号，使强化学习从数学、代码这类可验证任务扩展到医疗与科学等没有单一标准答案的真实推理场景，并在 HealthBench 与 GPQA-Diamond 上显著优于直接 Likert 打分奖励。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文想解决一个很实际的问题：**强化学习为什么一到真实世界任务就“失灵”了？**

在数学和代码里，RLVR（Reinforcement Learning with Verifiable Rewards）之所以有效，是因为答案对不对很容易检查，例如算式有没有算对、程序能不能通过测试。但一旦任务变成医学问答、科学解释、临床建议这类开放场景，奖励就不再是“0 或 1”这么简单。回答可能没有唯一标准答案，但又明显有高下之分，比如是否完整、是否安全、是否抓住关键症状、是否避免误导。

作者的核心主张是：**与其让一个 judge 直接给整段回答打一个模糊的 Likert 分，不如先把“好回答应该满足什么”拆成一组结构化 rubric，再把这些 rubric 变成 reward。** 这就是 Rubrics as Rewards（RaR）。

你可以把它理解成把“老师给作文打总分”改成“老师先列评分细则：必须点出病因、必须提风险、最好说明下一步检查、不能给出危险建议”，然后 RL 不再学一个模糊总分，而是学这份可解释、可拆解的评分标准。

## 🎯 研究背景与问题挑战

### 研究背景

这篇论文处在两个方向的交叉点：

- **RLVR / reasoning RL**：这类工作关注如何用可验证奖励训练模型，例如数学、代码、逻辑推理。优点是反馈清晰，缺点是只适合“答案可核验”的任务。
- **LLM-as-a-judge / preference-based reward**：这类工作用更强的模型给回答打分或做偏好比较，适合开放任务，但 reward 往往不透明，也容易学到长度、格式、语气这类表面特征。
- **rubric-based evaluation**：最近一些 benchmark，尤其是医疗类 benchmark，会给每个样本配一个评分 rubric，用来更细致地判断回答质量。但这些 rubric 多用于“评测”，很少真正进入“训练回路”。

### 问题与挑战

论文要解决的问题是：**当任务没有唯一正确答案时，如何给 RL 提供既稳定、又细粒度、又可解释的奖励？**

这个问题难，难在这里的挑战不是一句“开放任务更复杂”就说完了，而是有几层内在矛盾：

1. **因为真实任务往往同时包含客观标准和主观标准，所以很难用一个二元正确性信号来表示好坏。**
   例如医疗回答不仅要“诊断方向大体正确”，还要“别遗漏危险征象”“别给出高风险建议”“沟通要清楚”。

2. **因为直接 Likert 打分过于粗糙，所以模型容易学到 judge 的表面偏好，而不是真正重要的内容。**
   例如回答写得更长、更像模板，可能更容易拿高分，但不代表更专业。

3. **因为人工成对偏好数据昂贵且不透明，所以 reward 很难扩展到高专业门槛领域。**
   医疗、科学等领域需要专家知识，人类逐对比较的成本很高。

4. **因为开放任务常常没有单一 ground truth，所以“验证器”不像数学和代码那样天然存在。**
   这意味着 RL 既想要精确反馈，又拿不到明确判题器。

这个问题很有价值，因为如果不能跨过这一步，RL 就只能在数学题和代码题里持续刷榜，很难进入真正重要的现实决策与专业推理场景。

## 🔍 核心发现 Finding

### 作者明确声称

作者的发现是：**instance-specific rubrics 不只是评测工具，也可以作为 on-policy RL 的奖励函数。**

### 我的理解

我认为这篇论文真正有价值的 `Finding` 不是“我们做了一个新的 reward aggregation”，而是下面这个视角转换：

**在开放任务里，问题并不是完全没有奖励，而是“好回答”的标准一直存在，只是它过去被写在 rubric 里、留在专家脑子里、或者混在 judge 的隐式偏好里，没有被显式转写成 RL 可消费的结构化信号。**

这个 insight 为什么重要？因为它把一个看似无解的问题翻译成了一个可解的问题：

- 过去的看法：没有唯一标准答案，所以没法像 RLVR 那样做 RL。
- 这篇论文的新看法：虽然没有唯一答案，但仍然可以把“高质量回答应满足的多条标准”写成 checklist，于是 reward 不再依赖单个总分，而变成一组可解释子目标的组合。

这正好击中了上面的挑战。比如在医疗问题里，直接问 judge “这段回答值几分”很模糊；但若改成：

- 是否识别出关键诊断？
- 是否指出危险信号？
- 是否避免误导性建议？
- 是否说明下一步检查？

那么 reward 就从一个黑箱分数，变成了一套有结构的监督信号。换句话说，**RaR 的关键不是把 judge 换了，而是把“评价语言”结构化了。**

## 🔬 方法

### 整体思路

方法可以概括成两步：

1. **先为每个 prompt 自动生成一份按样本定制的 rubric。**
2. **再用这份 rubric 去评价 policy rollout，并把评价结果作为 GRPO 的 reward。**

### 输入数据是什么

作者主要使用两个训练集：

- **RaR-Medicine**：约 20k 条医学推理数据，来源包括 `medical-o1-reasoning-natural_reasoning`、`SCP-116K`、`GeneralThought-430K`
- **RaR-Science**：约 20k 条科学推理数据，题型与 GPQA-Diamond 的学科分布对齐

基础 policy 是 **Qwen2.5-7B**，训练算法是 **GRPO**，judge 模型主要使用 **gpt-4o-mini**。

### 第一步：生成 rubric

作者不是手工给 4 万条样本写 rubric，而是让更强的 LLM 根据参考答案自动生成 rubric。每个样本生成 **7 到 20 条** criterion，每条 criterion 都要求满足四个设计原则：

1. **Expert grounding**：要贴近专家正确答案或高质量参考答案
2. **Comprehensive coverage**：不仅看事实对错，也看完整性、逻辑性、风格、安全性
3. **Criterion importance**：不同标准重要性不同
4. **Self-contained evaluation**：每条 rubric 尽量独立可判断

作者给 rubric criterion 分配类别权重，例如：

- `Essential`
- `Important`
- `Optional`
- `Pitfall`

一个很直观的例子是医疗问答。对于“某症状最可能是什么诊断”这种题，rubric 可能不是一个总要求，而是拆成：

- 必须指出某个关键诊断
- 必须把某个症状和诊断联系起来
- 最好说明一个关键定量发现
- 必须避免常见误诊或危险建议

### 第二步：把 rubric 变成 reward

作者尝试了两种聚合方式。

#### 1. Explicit aggregation

先让 judge 对每条 criterion 单独判定是否满足，再做加权平均：

- 满足 `Essential` 就给更高权重
- 满足 `Optional` 权重较低
- 满足 `Pitfall`（例如“避免误导信息”）也会带来正向贡献

这个方案的优点是可解释性强。你能知道模型到底是“漏了关键信息”，还是“触发了安全问题”。

#### 2. Implicit aggregation

把整套 rubric 连同 prompt、回答一起交给 judge，由 judge 输出一个总体分数。

这个方案的优点是省掉手工调权重，让 judge 自己做 holistic aggregation。论文里最终最强的是这个版本，即 **RaR-Implicit**。

### 训练流程

训练 loop 很直接：

1. 对每个问题从当前 policy 采样 `k=16` 个回答
2. 用 rubric judge 给每个回答打 reward
3. 用这些 reward 计算 group advantage
4. 用 GRPO 更新 policy

从工程上看，这篇论文并没有引入特别复杂的新 RL 算法，真正的创新点在 reward 的表达方式，而不是 optimizer 本身。

## 📊 实验与结论

### 主结果一：RaR 在医疗开放评测上显著优于直接 Likert 奖励

在 **HealthBench** 上，作者比较了多种策略：

- `Direct-Likert`：judge 直接给回答打 1 到 10 分
- `Reference-Likert`：给定参考答案，再打 Likert 分
- `RaR-Predefined`：使用固定通用 rubric
- `RaR-Explicit`
- `RaR-Implicit`

论文摘要给出的结果是：**最佳 RaR 版本相比 popular Likert-based baseline，在 HealthBench 上最高带来 31% 的相对提升。**

这个 finding 很关键。它说明 rubric 的作用不只是“让评测更细”，而是**真的能改变训练信号的质量**。也就是说，模型学到的不只是“把回答写得像高分答案”，而更像是在学“哪些内容维度真正重要”。

一个直观例子是：

- `Direct-Likert` 可能偏好“写得长、语气稳、像医生”
- `RaR` 更容易奖励“是否明确识别病因、是否提到危险症状、是否避免错误建议”

对于医疗这种高风险领域，后者显然更像我们真正想优化的目标。

### 主结果二：RaR 不只在 rubric 评测上有效，在可验证科学问答上也有效

在 **GPQA-Diamond** 上，`RaR-Implicit` 的平均准确率达到 **37.6%**，高于：

- `Direct-Likert` 的 **34.8%**
- `Reference-Likert` 的 **36.5%**
- `RaR-Explicit` 的 **36.9%**

摘要中总结为：**相比 popular Likert baseline，GPQA-Diamond 上相对提升最高约 7%。**

这点很值得注意，因为它说明 RaR 不是只对 rubric-style benchmark 有效，而是**训练出的 policy 在另一种更接近“标准答案评测”的任务上也有迁移收益**。换句话说，rubric reward 并没有把模型过拟合到“学会讨好 rubric judge”，至少在 GPQA 这个科学多选 benchmark 上不是这样。

### 主结果三：rubric 质量直接决定训练效果

这是论文里我觉得很有启发的一个实验。

作者比较了三种 rubric 来源：

- 人类写的 rubric
- LLM 结合 reference answer 生成的 rubric
- LLM 不看 reference、纯合成的 rubric

在 HealthBench-1k 上：

- `Simple-Likert`：**23.9%**
- `Reference-Likert`：**31.7%**
- `RaR-Implicit-Synthetic-NoRef`：**32.0%**
- `RaR-Implicit-Synthetic`：**35.9%**
- `RaR-Implicit-Human`：**34.8%**

这个结果很有意思，说明：

1. **rubric 不是随便写几条 checklist 就行，关键在于是否有专家 grounding。**
2. **好的合成 rubric，效果可以接近甚至略优于人工 rubric。**
3. **没有 reference guidance 的纯合成 rubric 会明显退化。**

你可以把它理解成：RaR 真正依赖的是“把专家知识翻译成结构化标准”的质量，而不是 rubric 这个形式本身。

### 主结果四：不是所有 rubric 组件都同样重要

在 ablation 中，作者发现：

- 只保留 `Essential` 项目时，性能降到 **34.9%**
- 去掉 categorical labels，性能反而到 **38.8%**
- 去掉 pitfall criteria，约 **37.2%**
- 全量 rubric 约 **37.2%**

这个 finding 说明两件事：

1. **丰富的多维标准比只看关键项更重要。**
   也就是说，模型受益于更密的学习信号，而不只是“抓住主答案”。

2. **synthetic pitfall 的价值暂时没那么稳定。**
   作者推测，负向 criterion 很难自动合成，因为要准确预判模型最容易犯的错，这往往需要更强的人类直觉和领域经验。

这里可以举个例子。对于医学题，写“不要给危险建议”这类 pitfall 看起来很合理，但如果 rubric 生成器并不真正理解场景，它写出来的负向约束可能太泛，最后对训练帮助有限。

### 主结果五：rubric generation model 的能力会传导到 policy 质量

作者还比较了不同 LLM 生成 rubric 的效果。在不看 reference 的设置下：

- `GPT-4o` 生成的 rubric 训练后最好：**34.2%**
- `GPT-4o-mini`：**32.7%**
- `o3-mini`：**32.4%**
- `Qwen-72B-Instruct`：**32.7%**
- `Qwen-32B-Instruct`：**31.1%**
- `Qwen-7B-Instruct`：**31.9%**

这说明 **rubric 生成器本身也是系统性能瓶颈的一部分**。不是只有 judge 大小重要，前面的“标准制定者”能力也很关键。

### 结论

这篇论文最终得出的结论可以概括为三句：

1. **Rubrics 可以作为 RL 的 reward，而且能把 RL 从可验证任务扩展到开放、专业、真实世界任务。**
2. **结构化 rubric reward 比直接 Likert 打分更稳定、更可解释，也更容易带来跨评测格式的收益。**
3. **真正的瓶颈转移到了 rubric 的生成质量与 expert grounding 上。**

如果用一个更通俗的例子来讲：

- 以前做 RL，像是在考试里只知道“总分 86 分”
- 这篇论文的方法，是把试卷拆成“概念题、推理题、步骤分、风险项、加分项”
- 这样模型不只知道“你这次差了 14 分”，而是知道“你主要丢分在遗漏关键症状和给建议不够完整”

这就是为什么它能在没有唯一标准答案的任务上，把 RL 重新变得可用。

## 🧠 关键术语

- **Reinforcement Learning with Verifiable Rewards（带可验证奖励的强化学习，RLVR）**：奖励来自可自动验证的正确性信号。例子：数学题答案对了得 1 分，错了得 0 分；代码通过测试得高分。
- **Rubric（评分细则 / 评价量表）**：把“一个好回答应该满足什么”拆成多条可检查标准。例子：医疗回答既要诊断正确，也要指出风险，还要避免危险建议。
- **Instance-specific rubric（按样本定制的 rubric）**：不是全局固定标准，而是每道题自己的细则。例子：同样是医学题，胸痛题和皮疹题需要检查的关键信息并不一样。
- **GRPO（Group Relative Policy Optimization，组相对策略优化）**：对同一问题采样多个回答，用组内相对表现来更新策略。例子：同一道题采样 16 个答案，满足 rubric 更多的回答会得到更高 advantage。
- **LLM-as-a-judge（用大模型做评委）**：让一个更强的模型来判断回答质量。例子：用 `gpt-4o-mini` 判断某个回答是否满足“指出关键诊断”这条 rubric。
- **Explicit aggregation（显式聚合）**：逐条判断 rubric 是否满足，再按权重合成总 reward。例子：`Essential` 权重更高，`Optional` 权重更低。
- **Implicit aggregation（隐式聚合）**：把整套 rubric 交给 judge，由 judge 直接输出总体得分。例子：judge 综合“是否准确、是否完整、是否安全”后直接打一个归一化分数。
- **Pitfall criterion（陷阱项 / 负向风险标准）**：检查回答是否避免常见错误。例子：在医疗建议里避免推荐明显危险的处理方式。

## 💭 个人评价

### ✅ 优点

- **问题抓得很准**：它真正回答了“RL 怎么从数学和代码走向现实任务”这个关键问题。
- **finding 很清楚**：不是卷新算法，而是把 reward 的表达方式从“黑箱总分”改成“结构化标准”。
- **实验设计有说服力**：既测 rubric benchmark，也测 GPQA 这种多选科学题，还做了 rubric 来源与质量的消融。
- **可解释性更强**：相比直接 Likert 奖励，RaR 更容易定位模型到底学会了什么、没学会什么。

### ⚠️ 局限

- **rubric 质量仍然高度依赖强模型或参考答案**：如果上游 rubric 生成不可靠，整个方法会退化。
- **judge 仍然是 LLM judge**：虽然比直接 Likert 更结构化，但它并没有完全摆脱 judge 偏差问题。
- **目前主要验证在医疗和科学推理**：能否稳定扩展到法律、教育、长程 agent 任务，还需要更多证据。
- **多维 rubric 设计成本不低**：即使自动生成，也要考虑 reference、模板、权重、格式和安全边界。

### 💡 启发

- 对开放任务做 RL，关键可能不是先追求更强 reward model，而是**先把评价标准表达清楚**。
- 很多“不可验证任务”其实不是完全不可验证，而是**可以被拆成多条局部可判断标准**。
- 以后如果做 agent、医疗、教育等高价值场景的 post-training，RaR 这种“结构化 reward”很可能比单一偏好分数更稳。

## 🔗 相关方向

- RLVR / reasoning RL
- LLM-as-a-judge
- Preference-based reward modeling
- HealthBench
- GPQA-Diamond

---

**阅读时间**：约 3 小时  
**推荐指数**：⭐⭐⭐⭐  
**适合读者**：LLM 后训练、强化学习、reward design、医疗/科学推理方向研究者

**一句话总结**：这篇论文最重要的不是提出了一个更复杂的 judge，而是指出了一个更实用的训练观点：对于没有唯一正确答案的任务，真正有用的 reward 往往已经以 rubric 的形式存在，关键是把它们结构化、实例化、再接入 RL。  
