---
title: "Semantic Operators and Their Optimization: Enabling LLM-Based Data Processing with Accuracy Guarantees in LOTUS"
date: 2026-07-16T00:00:00+08:00
draft: false

# 分类（研究领域）
categories: ["数据库系统"]

# 会议/期刊
venues: "PVLDB 2025"

# 论文元数据
authors: ["Liana Patel", "Siddharth Jha", "Melissa Pan", "Harshit Gupta", "Parth Asawa", "Carlos Guestrin", "Matei Zaharia"]
year: "2025"
paper_url: "https://doi.org/10.14778/3749646.3749685"
arxiv_url: "https://www.vldb.org/pvldb/vol18/p4171-patel.pdf"
code_url: "https://github.com/lotus-data/lotus"

rating: 5

summary: "论文提出 semantic operators 与开源系统 LOTUS，把自然语言条件下的 filter、join、top-k、group-by、aggregation、map 等批量语义处理操作提升为声明式数据算子。每个算子由高质量 reference algorithm 定义行为，optimizer 再用小模型或 embedding proxy、采样和置信区间选择低成本执行计划，并以给定失败概率保证优化结果相对 reference algorithm 的 precision、recall 或 accuracy。LOTUS 在事实核查、生物医学多标签分类、检索排序和 arXiv 主题分析中以少量算子表达完整 pipeline，最高获得约 1000 倍参考算法加速，并匹配或超过手写与 LLM analytics 基线。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文解决的是一个数据库与 LLM 交叉的问题：

> 当我们要让 LLM 对成千上万条文本做过滤、连接、排序、分组和聚合时，能否像写 SQL/Pandas 一样声明“想要什么”，再让系统自动选择更便宜的模型与执行计划，同时给出可解释的精度保证？

已有 LLM data processing 工具常落在两个极端：

- **AI UDF / batched inference**：逐行调用 LLM，API 简单但无法表达复杂 ranking、join 和 group-by；
- **agentic optimizer / best-effort system**：能重写 pipeline，却没有稳定的 accuracy guarantee，优化器可能失败或产生高方差计划。

论文提出 **semantic operators**：用自然语言表达数据操作的语义，例如：

```python
papers.sem_filter("the paper {abstract} claims to outperform BERT")
papers.sem_topk("the paper has the funniest {title}", K=5)
papers.sem_group_by("the main research topic of {abstract}", C=10)
```

这些 operator 看起来像关系代数，但 predicate、ranking criteria 或 projection 是自然语言。系统面临的关键问题是：自然语言和 LLM 输出本身含糊，如何定义一个优化计划是“正确”的？

LOTUS 的回答分两层：

1. 每个 operator 先由一个高质量、可执行的 **reference algorithm** 定义行为；
2. optimizer 再用便宜 proxy 近似 reference algorithm，并以给定概率满足相对 reference output 的 precision、recall 或 classification accuracy target。

因此，这里的 guarantee 不是“LLM 一定符合现实真相”，而是：**优化后的执行计划在统计意义上足够接近选定的 reference algorithm。**

## 🎯 研究背景

### 从 row-wise LLM call 到 bulk semantic processing

很多实际任务不是一次问答，而是对整个数据集执行语义计算：

- 从 550 万篇 Wikipedia 文档中为 1,000 条 claim 检索证据并判断真假；
- 把患者报告和 24,000 个药物不良反应标签做语义连接；
- 根据“研究是否真正报告某项性能”而非关键词对论文排序；
- 从数百篇 arXiv 论文中自动发现主题并分组。

这些任务需要模型以特定访问模式遍历数据，而不是简单地把整表放进 prompt。

### 数据库优化的核心是 data/model independence

传统数据库允许用户写声明式 query，而 optimizer 决定 join order、index 和执行算法。应用逻辑不应绑定某个物理计划。

LOTUS 将这个思想扩展为 **model-data independence**：

- 用户用自然语言声明 operator 的目标；
- 同一个 operator 可以由强 LLM、弱 LLM、embedding、vector index 或它们的 cascade 实现；
- optimizer 决定什么时候用便宜 proxy，什么时候回退 oracle；
- 应用不需要手工重写 pipeline。

### LLM operator 的正确性比关系算子更难定义

SQL 的 `age > 30` 有精确语义；“这篇论文是否声称超过某 baseline”没有唯一形式化真值。不同 LLM、prompt 和访问模式可能给出不同结果。

论文因此没有直接宣称 operator 对现实世界绝对正确，而是指定一个 reference algorithm 作为可计算规范。这是一种工程上可操作的“相对语义”。

## ⚠️ 问题与挑战

论文要解决的问题是：**如何为自然语言参数化的批量 AI 操作建立声明式抽象、可计算语义、高质量参考实现，以及带统计精度保证的低成本执行计划。**

### 1. 因为自然语言 predicate 含糊，所以 operator 没有传统关系代数那样的唯一真值

例如“论文是否真正使用某数据集”可能要求读方法部分、区分训练与评测、处理简称。系统必须先说明它用什么算法定义该判断，才能讨论优化是否保持语义。

### 2. 因为 reference algorithm 往往逐行或笛卡尔积调用强 LLM，所以高质量实现可能极其昂贵

- filter 对每个 tuple 调一次 oracle，复杂度约 `O(n)`；
- join 对所有 pair 做判断，复杂度约 `O(nm)`；
- ranking 需要多轮 pairwise comparison；
- group-by 需要先发现 label，再逐条分类。

BioDEX 的 reference nested-loop join 估计需要 `6,092,500` 次 LLM calls，不能直接作为实用计划。

### 3. 因为便宜 proxy 在不同 query 上质量变化很大，所以不能固定相信 embedding 或小模型

有些 predicate 与 embedding similarity 高度相关，例如“论文主题是否相近”；有些则需要逻辑判断，例如“claim 是否被证据支持”。一个固定 proxy budget 用完就强行近似，可能严重掉点。

LOTUS 需要在 query time 采样，估计 proxy 对当前任务是否可靠，再学习 threshold。

### 4. 因为同时要求 precision 与 recall，所以 threshold 学习涉及多重失败事件

只保证平均 accuracy 不够。过滤或连接任务可能要求：

- 返回项大多真的是正例，即 precision；
- reference algorithm 找到的正例尽量不漏，即 recall。

采样估计与多重假设检验会引入额外不确定性，必须用置信区间与 failure probability 控制。

### 5. 因为复杂 operator 有多种模型访问模式，所以优化不仅是“换小模型”

例如 top-k 可以用 pointwise scoring、listwise ranking、pairwise comparison；pairwise 又可用 quadratic sort、heap 或 quickselect。它们会同时影响质量、调用数、并行度和延迟。

## 🔍 核心发现 Finding

### 作者明确声称

作者的核心主张是：**可以把复杂 LLM 数据处理抽象成带自然语言参数的 semantic operators，用 reference algorithm 定义行为，再通过 proxy、采样与统计估计生成低成本计划，并为单个 operator 提供相对 reference 的 accuracy guarantee。**

### 我的理解

我认为这篇论文真正重要的 `Finding` 是：

**LLM 数据系统的“正确性”不必从一个不可获得的绝对真值开始；可以先把高质量但昂贵的模型访问模式当作 executable specification，再让 optimizer 在可接受误差下逼近它。**

这和传统做法的差别是：

- AI UDF 把 prompt 和模型调用方式直接写进应用；
- best-effort optimizer 只追求经验上更快、更准；
- LOTUS 把“operator 语义”“reference plan”“optimized plan”分开。

这个分层让系统同时得到：

1. **声明式接口**：用户描述任务，不描述所有 LLM calls；
2. **可替换执行计划**：同一 query 可用不同 proxy/oracle cascade；
3. **可度量误差**：近似的是明确的 reference output；
4. **自适应退化**：proxy 不可靠时多调用 oracle，而不是强行近似。

例如做事实核查时，embedding proxy 无法稳定判断“证据是否支持 claim”。LOTUS 会通过样本发现 proxy 较弱，把不确定样本交给 Llama-70B；而在语义 join 中，先让 LLM 从论文抽取可能的数据集名，再与候选标签做 embedding matching，proxy 就会强得多。

因此这篇论文的关键不只是“用小模型加速大模型”，而是 **把 proxy 可用性变成 query-specific、可估计、可回退的 optimizer decision。**

## 🔬 方法

### 1. Semantic operator 的定义

论文将 semantic operator 定义为：

> 对一个或多个数据集进行的声明式变换，由自然语言表达式参数化；同一 operator 可由多个 AI algorithm 实现，其正确行为相对一个给定 reference algorithm 定义。

自然语言参数称为 **langex（language expression）**。它可以是 predicate、ranking criterion、projection 或 reducer。

### 2. 核心 operators 与 reference algorithms

#### `sem_filter`

返回满足自然语言 predicate 的 tuples。

Reference：对每个 tuple 单独调用 oracle LLM，输出 boolean。逐行处理避免把全表放进长 context 导致的注意力和位置问题。

#### `sem_join`

对左右两张表的 tuple pair 应用自然语言 predicate。

Reference：nested-loop join，对所有 pair 调用 oracle，复杂度为 `O(|T1| * |T2|)`。

#### `sem_topk`

按自然语言 criterion 返回前 k 个有序 tuples。

Reference：用 pairwise LLM comparison 比较两个 tuple，再用 quickselect 找 top-k。作者选择 pairwise 是因为 pointwise score 难校准，listwise 容易受长 context 和位置影响；选择 quickselect 是因为每轮比较可批处理。

#### `sem_agg`

按自然语言 reducer 把多条记录聚成一个结果，例如总结大量 abstracts。

Reference：hierarchical reduce。每轮并行聚合多个小组，再递归合并，通常比线性 fold 更适合可交换、可结合的摘要任务。

#### `sem_group_by`

既要发现未知 group labels，又要给每条记录分配 label。

Reference 分两阶段：

1. LLM 为每条记录投影一个 candidate label，用 embedding + k-means 聚类，再对每簇聚合出正式 label；
2. 用 LLM 对每条记录做 pointwise classification。

#### `sem_map`

执行任意自然语言 projection。LOTUS 还提供 `sem_extract`，要求输出原文 substring，适合 entity extraction 或可验证引用。

### 3. 正确优化的定义

论文把 correct optimization 定义为：

> 相比 reference algorithm 降低成本，并以至少 `1 - δ` 的概率达到用户指定的 accuracy target。

这里必须强调三点：

1. target 是相对 reference output；
2. guarantee 是统计概率，不是逐条绝对正确；
3. 当前论文主要保证单个 operator，不保证完整多算子 pipeline。

### 4. Filter optimization：小 LLM cascade + 双 threshold

优化流程如下：

1. 用便宜 proxy LLM 对全部 tuples 生成 True/False log-probability score；
2. 对数据做 importance sampling，并让 proxy 与 oracle 都标注样本；
3. 用置信区间估计两个 threshold：一个满足 precision target，一个满足 recall target；
4. 高置信正例直接通过；
5. 高置信负例直接过滤；
6. 中间不确定区间回退 oracle LLM。

算法不会预设 proxy 一定好。如果当前 predicate 上 proxy 很弱，不确定区间会变大，系统会调用更多 oracle 来守住 target。

### 5. Join optimization：自动选择两种 embedding proxy

论文设计两个候选计划。

#### Plan 1：sim-filter

直接计算 left key 与 right key 的 embedding similarity，用 learned thresholds 决定哪些 pair 可由 proxy 判断，哪些回退 LLM。

它适合“通过 join predicate 的 pair 本来就语义相似”的任务。

#### Plan 2：project-sim-filter

先让 LLM 对 left tuple 做 projection，预测 right key 的可能值，再把 projection 与真实 right candidates 做 embedding similarity。

例如论文 abstract 与 dataset name 做 join 时：先从 abstract 生成它可能使用的数据集名，再与候选数据集匹配。原 abstract 与短标签未必 embedding 相似，但 projection 后会更可比。

optimizer 对两个候选计划采样、学习 thresholds、估算 oracle calls，选择成本更低的计划。

### 6. Group-by optimization：embedding proxy 负责容易样本

label discovery 仍沿用 reference algorithm。分类阶段用 candidate-label 与 cluster center 的 embedding similarity 作为 proxy；分数高于 threshold 时直接分配，模糊样本回退 LLM。

### 7. Top-k optimization：用 embedding 改善 pivot selection

quickselect 默认随机选 pivot。若自然语言 ranking 与 query embedding similarity 相关，LOTUS 用 similarity 排序选择更合适的初始 pivot，减少后续比较。

这项优化不改变 pairwise comparison 的最终选择逻辑，因此是 lossless optimization；最坏情况多一轮 pivot，但不降低结果质量。

### 8. LOTUS 系统实现

LOTUS 以 Pandas DataFrame API 暴露 operators：

- structured 与 unstructured columns 可同时参与 langex；
- `sem_index` 为非结构化列建立 semantic index；
- vLLM 负责批量推理；
- FAISS 默认负责本地向量索引；
- `sem_search`、`sem_sim_join` 和 reranking 是专用优化 variant；
- 用户可以配置 accuracy target 与 failure probability，探索 accuracy-latency-cost trade-off。

## 📊 实验与结论

### 实验设置

论文评估四类 bulk semantic applications：

1. FEVER fact-checking；
2. BioDEX biomedical multi-label classification；
3. SciFact 与 HellaSwag-bench search/ranking；
4. arXiv topic analysis。

主要本地实验使用：

- 4 张 A100 80GB；
- Llama-3-70B oracle；
- E5 embeddings；
- vLLM batch size 64；
- temperature 0（ranking 多 trial 实验除外）；
- 默认 accuracy target `0.9`、failure probability `0.2`。

基线包括 AI UDF、UQE、DocETL，以及 FactTool、cross-encoder reranker 等任务专用 pipeline。

### 1. Fact-checking：少量 operator 复现并超过手写 pipeline

FEVER 上抽取 1,000 条 claims，结果为：

| 方法 | Accuracy | 批处理时间 | 非批处理时间 | LoC |
|---|---:|---:|---:|---:|
| FactTool | 80.9 | - | 5,396.1 s | >750 |
| AI UDF map-search-map | 89.9 | 688.9 s | 4,454.2 s | <50 |
| UQE filter | 66.0 | 184.4 s | 738.3 s | 150 |
| LOTUS unoptimized | **91.2** | 329.1 s | 989.0 s | <50 |
| LOTUS optimized | 91.0 | **190.0 s** | **776.4 s** | <50 |

优化版相对未优化版保留 `99.8%` accuracy，并把 batch execution 加速约 `1.7x`。相对 FactTool，作者报告 batch 情况约 `28x` 更快、非 batch 约 `7x` 更快。

UQE 在相近 latency 下明显更差，说明固定 embedding proxy 无法处理需要事实判断的 predicate；LOTUS 能识别 proxy 不可靠并回退 oracle。

### 2. BioDEX join：用 projection 构造更合适的 proxy

任务是从患者文章中预测最多 24,000 个药物反应标签。对 250 篇文章：

| 方法 | RP@5 | RP@10 | 时间 | LLM calls |
|---|---:|---:|---:|---:|
| Search | 0.106 | 0.120 | 2.9 s | 0 |
| UQE | 0.115 | 0.114 | 6,559 s | 15,000 |
| DocETL Join + Rank | 0.262 | **0.282** | 2,342 s | 13,433 |
| LOTUS Join + Rank | **0.265** | 0.280 | 2,503 s | **5,869** |

LOTUS 与 DocETL 成功运行的结果相当，但 DocETL 约每 3 次有 1 次 optimizer failure，并需要 GPT-4o 作为 optimizer。

两个 LOTUS join plan 对比更能说明 optimizer 的作用：

| Join plan | RP@5 | RP@10 | 时间 | LLM calls |
|---|---:|---:|---:|---:|
| sim-filter | 0.154 | 0.170 | 12,563 s | 27,687 |
| project-sim-filter | **0.212** | **0.213** | **2,116 s** | **5,290** |
| nested-loop reference | - | - | 2,144,560 s | 6,092,500 |

project-sim-filter 相对 reference 使用约 `1000x` 更少的 LLM calls。这里的关键不是 embedding 更强，而是先把 abstract 投影成“可能的数据集名”，让 proxy score 更符合 join predicate。

### 3. Ranking：pairwise quickselect 兼顾质量与并行性

| 方法 | SciFact nDCG@10 | HellaSwag-bench nDCG@10 |
|---|---:|---:|
| Search | 0.712 | 0.119 |
| Cross-encoder reranker | 0.741 | 0.461 |
| AI UDF pointwise | 0.457 | 0.091 |
| LOTUS | **0.765** | **0.919** |

SciFact 是相关性任务，专用 reranker 已很强；HellaSwag-bench 需要从 abstract 中读出并比较报告的 accuracy，通用 pairwise LLM reasoning 优势更明显。

排序算法消融显示：quadratic、heap 和 quickselect 的 nDCG 相近，但 quadratic 需要 `20x-82x` 更多 LLM calls；quickselect 利用每轮 batch parallelism，比 heap 延迟低 `16%-32%`。embedding pivot optimization 在 SciFact 上再降低约 `10%` latency，且不损失质量。

### 4. Group-by：在 oracle 与 embedding proxy 间连续调节

作者对 647 篇 cs.DB、cs.IR、cs.CR、cs.RO arXiv 论文发现 5 个主题。label discovery 用时 `44.03` 秒，生成的主题覆盖推荐系统、多模态、生成式检索、LLM 应用、安全和机器人等。

只用 embedding proxy 比 oracle 快 `17.4x`，但 classification accuracy 低约 `39%`。LOTUS 可通过 accuracy target 在两者之间自适应选择，sampling optimization 额外开销低于 5 秒。

### 5. 统计保证在重复试验中基本成立

作者在 fact-checking filter 上改变：

- Llama-8B 或 TinyLlama-1B proxy；
- precision/recall target；
- failure probability。

结果显示，target 增大时实际 precision/recall 上升、oracle calls 增多；proxy 更弱时需要更多 oracle calls。50 次试验中，未达到 target 的比例低于配置的 failure probability，符合保守置信区间的预期。

### 作者可以合理得出的结论

- 自然语言 filter、join、ranking、group-by 和 aggregation 可以形成声明式 operator model；
- 高质量 reference algorithm 能作为 LLM operator 的 executable specification；
- proxy 是否有效取决于当前 query，必须在 query time 估计而不是固定假设；
- 通过 sampling、confidence bounds 和 oracle fallback，可在成本与相对 reference accuracy 间提供可配置 trade-off；
- 模型访问模式与 batching 能力和模型大小同样重要；
- 少量 semantic operators 可以表达复杂的事实核查、分类和检索 pipeline。

### 局限性

#### 作者明确承认

- 当前 accuracy guarantee 只针对单个 operator，不是完整多算子 query 的 end-to-end guarantee；
- optimizer 只探索有限的简单 cost-based plans，尚未系统搜索代理模型、传统索引、code generation 和 operator ordering 的组合；
- semantic plan equivalence rules 尚未建立；
- reference algorithm 虽然质量高，但不一定是最优，改进 reference 本身仍是开放问题；
- semantic aggregation 的详细优化没有在本文中展开。

#### 我的批判性理解

##### 1. Guarantee 是相对 reference，不是相对 ground truth

如果 reference algorithm 系统性误判，optimized plan 可以“准确复现错误”。因此生产系统仍需要独立的 gold evaluation、human audit 或 task-specific verifier。

##### 2. 单算子保证不能直接组合成 pipeline 可靠性

前一个 operator 的 false negative 会改变后续 operator 的输入分布；多个近似误差也可能相关。只有为完整 query 分配 error budget 并处理依赖，才能接近数据库用户期待的端到端约束。

##### 3. 统计假设与数据漂移需要持续监控

threshold 来自当前数据样本。若线上数据、prompt、model version 或 class balance 变化，旧 threshold 的保证可能不再适用。实际系统需要重采样、drift detection 与版本化 calibration。

##### 4. Reference semantics 仍受 prompt 与模型版本影响

自然语言 operator 没有真正消除语义歧义，只是把它固定在 reference algorithm 中。prompt 更新或 oracle 换代会改变 operator output，因此 query reproducibility 需要记录模型、prompt 和索引版本。

##### 5. 实验成本和基线公平性需要结合上下文看

DocETL 的失败率揭示 agentic optimizer 的问题，但该系统处于快速迭代期；LOTUS 对部分 baseline 的实现与参数进行了重现或调优。表格适合比较当前受控环境，不应被解释为所有版本下的永久排名。

## 🧩 关键术语

- **Semantic Operator（语义算子）**: 由自然语言参数化的声明式数据变换。例子：过滤“声称超过 BERT 的论文”。
- **Langex / Language Expression（自然语言表达式）**: operator 的自然语言 predicate、ranking criterion、projection 或 reducer。
- **Reference Algorithm（参考算法）**: 定义 operator 预期行为的高质量可执行算法。例子：对每一行调用 Llama-70B 判断 filter predicate。
- **Oracle Model（强模型/裁决模型）**: reference 或 fallback 使用的高质量但昂贵模型。
- **Proxy Model（代理模型）**: 便宜但可能不准确的小 LLM、embedding 或 index，用来近似 oracle。
- **Model Cascade（模型级联）**: 容易样本由 proxy 处理，不确定样本回退 oracle。
- **Statistical Accuracy Guarantee（统计精度保证）**: 以至少 `1-δ` 的概率满足相对 reference output 的 precision、recall 或 accuracy target。
- **Model-Data Independence（模型-数据独立性）**: 应用描述语义目标，而不是绑定具体模型调用计划。
- **Project-Sim-Filter（投影-相似度过滤）**: 先用 LLM 把一侧 tuple 投影成更可比较的 key，再用 embedding 生成 join proxy score。
- **Pairwise Ranking（成对排序）**: 每次让 LLM 比较两个候选，再通过排序算法聚合比较结果。
- **Quickselect Top-k（快速选择前 k）**: 围绕 pivot 分区寻找 top-k；每轮比较可批处理。
- **Hierarchical Reduce（层次归约）**: 分组并行聚合，再递归合并中间结果。

## 💡 个人评价与研究启发

这篇论文最值得迁移到 agent memory query processing 的思想，是把 memory query 也设计成声明式、可优化且可验证的 operator pipeline。例如：

```text
sem_search(user memories, current query)
    -> sem_filter(currently valid evidence)
    -> sem_join(events, entities, temporal relation)
    -> sem_topk(by answer usefulness)
    -> sem_agg(with provenance)
```

但如果用于记忆系统，我会增加四个约束：

1. reference output 必须携带 provenance 与 source IDs；
2. temporal validity filter 不能只靠语义相似度；
3. update/overwrite 需要可验证的 version semantics；
4. end-to-end 保证应覆盖“检索证据 -> 组合证据 -> 生成回答”，而不只覆盖单 operator。

LOTUS 给出的研究模板是：

```text
先定义高质量但昂贵的行为
        ↓
再设计便宜 proxy
        ↓
用样本估计 proxy 在当前 query 上是否可信
        ↓
把不确定样本交回 oracle
        ↓
报告质量、失败概率、调用数与延迟
```

这比只报告“平均快了多少”更接近可靠 AI data system。

## 🔗 相关资源

- [PVLDB 论文 PDF](https://www.vldb.org/pvldb/vol18/p4171-patel.pdf)
- [ACM DOI 页面](https://doi.org/10.14778/3749646.3749685)
- [LOTUS GitHub](https://github.com/lotus-data/lotus)
- [LOTUS 文档](https://lotus-data.github.io/lotus/)
