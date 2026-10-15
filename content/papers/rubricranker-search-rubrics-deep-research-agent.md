---
title: "Training Documents Reranker with Search Rubrics for Deep Research Agent"
date: 2026-10-15T08:50:03+08:00
draft: false
categories: ["信息检索"]
venues: "arXiv 2026"
authors: ["Wenhan Liu", "Yu Lu", "Qiaolin Xia", "Hui Xu", "Tong Zhao", "Jian Xi", "Yutao Zhu", "Haijin Liang", "Haibo Shi", "Hao Wang", "Zhicheng Dou"]
year: "2026"
paper_url: "https://arxiv.org/abs/2608.03527v1"
arxiv_url: "https://arxiv.org/pdf/2608.03527v1"
code_url: "https://github.com/8421BCD/RubricRanker"
status: "completed"
read_date: "2026-10-15"
rating: 4
summary: "RubricRanker 将检索目标从单篇相关性转向满足查询需求的文档集合，以集合级相关性、简洁性、一致性和文档级权威性、时效性构造 search rubrics。GPT-5.1 生成参考答案、具体标准和银标签，再用分层聚合奖励进行 GRPO。四项 deep research 平均分为 60.1，较 Rank4Gen 高 2.6；五项 RAG 平均 EM 为 40.0。推理无需具体 rubrics，但仍保留固定元标准指令。"
---

{{< paper-info >}}

阅读依据：[arXiv v1](https://arxiv.org/pdf/2608.03527v1)，2026-08-04，共 28 页，含训练、评测、案例与完整提示附录。数字均来自论文，未独立复现。代码链接来自附录 C。评分为主观阅读评价。

## 研究背景

深度研究 agent 不是一次检索后立即作答。它先规划，再发出子查询，阅读返回材料，决定是否继续搜索，最终综合回答。因此 reranker 选择的文档既是答案证据，也是下一步行动的依据。

以往重排序通常按“每篇文档与查询的相关性”排序，再返回固定数量。但一个文档集合要真正可用，还应覆盖不同方面、避免重复、处理冲突，并在需要时保证来源与时间有效性。几篇都切题的文章可能只反复解释同一个侧面，仍然无法支持完整答案。

本文承接生成导向的检索思路：不是仅学习传统相关性，而是学习什么材料组合能帮助生成。不过，开放式研究问题没有简单的唯一答案，因此作者没有直接用字符串答案匹配作为主奖励，而是把信息需求写成可评价的 search rubrics。

## 问题与挑战

**监督对象与使用对象不一致。** 传统标签评价单篇文档，agent 消费的却是整个集合。因为冗余、覆盖与一致性都是文档之间的关系，独立相关性分数无法完整描述这些属性。

**开放式查询缺少直接可验证的好坏标准。** 同一个研究问题可能有多种合理证据组织方式，单一正确答案或最终回答分数难以直接指导该选哪些文档。

**agent 子查询的信息需求不总是显式。** 一条简短搜索词的具体目标往往藏在此前的推理中；但整段推理也可能包含无关探索。作者让 query intent 辅助解释需求，同时要求以当前 query 为锚点。

**标准需要具体化，推理又不能依赖标准答案。** 训练时借助参考答案生成 rubrics，部署时却拿不到参考答案。解决办法是把 rubric 指导下的选择行为蒸馏进 reranker，而不是每次搜索都在线生成完整 rubrics。

## 核心发现 Finding

**作者明确声称：为每个查询显式定义高质量文档集合应满足的条件，可以比只用相关性标签更有效地训练生成导向的重排序器。**

**我的理解：关键变化是把 query 从“匹配文本”转成“证据需求清单”。** 参考答案在这里不是强制生成器复制的目标文本，而是帮助识别需要哪些事实、方面和约束的中间蓝图。将这些需求写成 rubrics 后，教师能产生更符合任务的集合标签，RL 也获得比泛泛偏好更具体的评价依据。

例如附录的 motion dazzle 案例需要材料分别解释现象、对速度和方向判断的影响、视觉机制及其对一般知觉理论的意义。多篇只重复定义的文章会很相关，却无法满足这份需求清单。这个例子说明 rubric 的构造方式；论文没有对该案例提供独立的逐维人工验证结果。

这个 Finding 不等于“GPT-5.1 打分一定正确”，也不等于“每个 rubric 都能提供有效学习信号”。它首先是一种把检索任务具体化的监督设计。

## 方法

### 1. 构造贴近实际使用的训练 query

deep research 数据来自 OpenScholar、SearchArena、GlaiveAI-Reasoning-v1-20M 和 WebWalker-Silver。作者用 Dr-Tulu-8B 为原始问题生成完整轨迹，再从每条轨迹随机采样两个 agent 子查询。这样训练的是搜索工具真正接收的子查询，而不是只用原始长问题替代它。

RAG 部分采样 HotpotQA 与 NQ 训练问题。Table 4 共列出 **9,843 个 SFT query、14,624 个 RL query**，合计 24,467。RL 数据池大小不等于论文实际 150 步训练遍历了全部样本。

### 2. 从参考答案生成分层 search rubrics

对开放式 agent 子查询，GPT-5.1 配合 web search 合成参考答案；RAG 问题则直接使用数据集提供的 gold answer。随后 GPT-5.1 结合 query、可选 query intent、reference answer 和固定元标准生成具体条目，每项权重为 1–5。

| 层级 | 元标准 | 含义 |
|---|---|---|
| 集合级 | Relevance | 整组是否覆盖问题需要的主要事实与方面 |
| 集合级 | Conciseness | 是否避免重复、冗余和无关材料 |
| 集合级 | Consistency | 对关键事实的说法是否相容，差异是否得到合理区分 |
| 文档级 | Source Authority | 在对来源敏感的场景中，相关证据是否来自可靠来源 |
| 文档级 | Timeliness | 在存在时间要求时，相关证据是否满足时间约束 |

这里的 Relevance 已包含整组需求覆盖，不能按普通的单篇主题相关性理解。权威性与时效性有适用条件：某项不需要时输出空列表；无关文档不会因为来自权威网站就获得相应认可。

附录还限制条目数量：相关性最多 7 条，简洁性和一致性各 1 条，文档级两个维度最多各 1 条。因此五类元标准不等于每个 query 固定五条 rubric。

### 3. Rubrics-guided SFT：教师有标准，学生学选择

每题候选池大小在 10–40 之间变化。deep research 通过 Serper Google Search API 检索网页，RAG 用 BGE-base 检索维基文档。

GPT-5.1 看到具体 rubrics 后，输出保留文档的 ID 序列。学生 Qwen3-8B 只看 query、候选材料以及 agent 场景的 query intent，学习同样的选择结果，不输入 query-specific rubrics。

附录 Figure 12–13 表明学生仍看得到五类固定 meta-rubric 指令，且最多选 10 篇。因此“推理不需要 rubrics”准确地说是 **不需要针对当前查询合成的具体标准**，不是完全没有标准文本。

SFT 使用 LlamaFactory，训练 2 个 epoch，学习率 5e−6，每 GPU batch 1、梯度累积 8，采用 BF16、ZeRO-2 与 FlashAttention-2。

### 4. Rubric-based RL：先分层评分，再聚合成标量

Qwen3-8B 为同一输入生成多个文档 ID 序列。GPT-5.1 judge 对集合级条目直接评价整组，对文档级条目分别评价每篇文档并取集合内均值，再按 rubric 权重加权：

```text
F(document_rubric, selected_set)
    = mean(score(document_rubric, each_selected_document))

reward(selected_set)
    = [Σ set_weight × set_score + Σ doc_weight × F]
      / [Σ set_weight + Σ doc_weight]
```

正文将分项分数定义在 0–1；附录 judge prompt 输出 0–10 整数，因此实现时必须检查归一化。格式正确时用上述奖励，格式错误时为 −1。

最终以 GRPO 训练，含 clipped objective 和相对参考策略的 KL 惩罚。配置为每步 16 个输入、mini-batch 8、每题 8 个 rollout、150 步、学习率 1e−6，使用 8 张 H20。

虽然评分过程包含文档级条目，**最终仍聚合成一个集合奖励**，同一输出序列的 token 共享组内 outcome advantage。它并没有对每个文档 ID 分配独立的贡献奖励，这正是后续 AdaTutoRank 进一步处理的问题。

## 实验与结论

### 四项 deep research：在固定 agent 下更换 reranker

主实验固定 Dr-Tulu-8B，所有 reranker 处理搜索 API 返回的前 30 篇。传统完整排序方法返回前 5，集合选择方法自行决定子集。测试集大小依次为 WebWalkerQA 200、HealthBench 100、DRB 100、ResearchQA 100。

| 方法 | WebWalkerQA | HealthBench | DRB | ResearchQA | 平均 |
|---|---:|---:|---:|---:|---:|
| Initial Retrieval | 44.5 | 55.2 | 45.3 | 71.1 | 54.0 |
| BGE-Reranker-Large | 52.0 | 58.7 | 46.5 | 71.2 | 57.1 |
| Rank4Gen | 52.0 | 59.2 | 46.6 | 72.0 | 57.5 |
| RubricRanker | **58.0** | **61.5** | **46.8** | **74.2** | **60.1** |

平均比 Rank4Gen 高 **2.6 分**。但增益分布不均：WebWalkerQA 为 +6.0，DRB 只有 +0.2，不能用均值暗示每个任务都有同等幅度提升。

四项不是同一个统一指标：HealthBench、WebWalkerQA 使用 GPT-4.1 judge，DRB 使用 Gemini 2.5 Flash，ResearchQA 使用 GPT-4.1-mini。HealthBench 还把多轮案例展平成对话上下文。60.1 是论文协议下的跨任务均值，不是统一准确率。

### 五项 RAG：精确匹配表现

固定 Qwen3-8B 作生成器，使用 BGE 从 2018-12 维基语料检索前 30 段：

| 方法 | HotpotQA | Bamboogle | NQ | PopQA | TriviaQA | 平均 EM |
|---|---:|---:|---:|---:|---:|---:|
| Initial Retrieval | 29.8 | 15.2 | 31.0 | 37.2 | 58.4 | 34.3 |
| Rank4Gen | 35.1 | 20.0 | 33.2 | 41.0 | 61.7 | 38.2 |
| RubricRanker | **38.0** | **23.2** | **34.0** | **42.2** | **62.4** | **40.0** |

相对 Rank4Gen 的平均提升是 **1.8 个百分点**，论文概述写“约 2 点”。模型在训练中已使用 HotpotQA/NQ，因此“泛化到 RAG”不能理解为完全没有 RAG 训练数据；跨场景能力来自混合训练后的评测。

### 代表性消融：rubrics 的收益是否只是多做一次 RL？

Table 3 只覆盖 WebWalkerQA、HealthBench、HotpotQA，不能与上面四项或五项均值混用。

| 配置 | 三项平均 |
|---|---:|
| 完整 RubricRanker | 52.5 |
| 去掉 RL，仅保留 SFT | 51.1 |
| 去掉 SFT，直接 RL | 48.3 |
| 银标签生成时不给具体 rubrics | 49.2 |
| 用相关性完整排序标签替代集合选择标签 | 48.1 |

这组实验最清楚的结论是：**教师构造的初始化很重要，RL 在此基础上进一步改善。** 去掉 SFT 损失 4.2 分，大于去掉 RL 的 1.4 分；银标签不受具体 rubrics 指导时损失 3.3 分。

因此不能把全部收益归功于 RL。结果同时支持“更好的教师标签”和“后续奖励优化”两条路径。反过来，它也没有单独验证每个 rubric 维度、权重或分层平均操作的独立必要性。

### 搜索次数与候选池规模

HealthBench 上，Rank4Gen 平均搜索 3.4 次，RubricRanker 为 2.9 次，下降约 14.7%；ResearchQA 为 3.5→2.9，下降约 17.1%。这支持所测 agent 更快获得足够证据的解释，但论文没有完整计入重排序耗时、输入 token 和模型费用，不能把搜索次数直接换算成端到端成本或延迟收益。

候选池从 10 增至 50 时，性能并非一直上升：WebWalkerQA 大约在 30 篇后饱和，HotpotQA 大约在 40 篇后饱和。更多候选既可能补足证据，也会扩大重排序输入、引入噪声，部署时应联合检查召回率与上下文预算。

### 局限

作者明确指出三点：GPT-5.1 奖励构造成本高；deep research 只测了部分样本；最终回答评价会混入 agent 推理与写作能力，缺少直接评价文档集合的独立指标。

进一步看，参考答案、rubrics、银标签与 reward judge 高度依赖同一模型家族，可能传递共同偏差；论文未充分报告独立人工核验、多种 judge 一致性或多随机种子区间。训练子查询又来自 Dr-Tulu-8B，主要 deep research 评测也使用它，所以跨 agent 的普适性仍需额外实验。

此外，不同方法保留文档数可能不同，质量提升可能同时受到集合长度与内容选择影响。若要严格研究集合优化机制，应增加同文档数、同总 token 和同候选池的匹配对照。

## 关键术语

- **Search Rubrics（搜索评价标准）**: 描述某个查询所需证据集合的具体条件。例子：材料既要说明现象，也要提供机制与实验依据。
- **Meta Rubrics（元标准）**: 用于生成具体标准的固定维度框架。例子：相关性、简洁性、一致性并不直接列出某问题需要的人名或日期。
- **Query Intent（查询意图）**: agent 发出当前子查询前的相关推理。例子：简短关键词背后可能是寻找某个机制，而不是收集百科定义。
- **Silver Labels（银标签）**: 强模型自动生成、但不保证完全正确的监督标签。例子：GPT-5.1 给出应保留的 `[2] [4] [13]`。
- **Hierarchical Reward Aggregation（分层奖励聚合）**: 按对象层级评分后统一聚合。例子：权威性先逐文档取平均，覆盖度直接评分整组，最后按条目权重组合。
- **GRPO（组相对策略优化）**: 对同一输入的多个输出比较奖励，获得相对训练方向。例子：8 个候选文档集合中，得分高于组平均的输出更倾向被强化。

## 与另外两篇论文的关系

| 维度 | RRPO | RubricRanker | AdaTutoRank |
|---|---|---|---|
| 核心关注 | 文档排序与真实回答效用对齐 | 用具体标准定义高质量文档集合 | 将集合评价转成更细且适应样本的训练信号 |
| 输出与选择 | pointwise 分数支持逐步无放回选择 | 自回归生成文档 ID 子集 | 自回归生成文档 ID 子集 |
| 主要奖励 | Reader 答案与 gold answer 的 EM/F1/Hit | 两层五类 rubric 的加权集合奖励 | 三层九维 rubric 奖励 + token 蒸馏 advantage |
| 稳定或指导机制 | 固定参考排序器的贪心反馈基线 | rubric-guided SFT + GRPO/KL | 当前快照生成提示，固定 SFT 教师蒸馏 |
| 不能忽略的边界 | 仍需标准答案；策略不显式重编码已选段落 | 集合分数仍对 token 共享；强教师依赖 | token 信号不是精确边际贡献；理论主要是局部解释 |

阅读链接：[RRPO 笔记]({{< relref "papers/optimizing-rag-rerankers-with-llm-feedback-rrpo.md" >}})、[AdaTutoRank 笔记]({{< relref "papers/adatutorank-adaptive-tutoring-document-set-reranking.md" >}})。

**三篇不能按原文绝对分数排列强弱。** RRPO 使用 BM25 前 100 候选与 Qwen2.5 Reader；RubricRanker 的 RAG 使用 BGE 前 30 候选与 Qwen3-8B；AdaTutoRank 使用 BM25 前 20 候选与 Llama-3.1-8B，部分数据集和测试子集也不同。可靠的直接比较应来自同一论文内控制过设置的表格，或重新统一协议。

## 可操作的启发

先区分“评价需求是否明确”和“标准能否产生有效训练信号”：RubricRanker 主要建立前者，AdaTutoRank 进一步处理后者。若开展后续研究，应在固定 rubrics、judge 和教师标签下比较奖励聚合与 advantage 设计，避免同时改变数据质量和优化算法后难以归因。

对开放式多模态任务，可以借鉴“先形成信息需求蓝图，再具体化标准”的流程；但参考答案的正确性、标准与输入证据的一致性需要独立检查。不能仅因 rubric 写得具体，就假定其可靠或适合强化学习。
