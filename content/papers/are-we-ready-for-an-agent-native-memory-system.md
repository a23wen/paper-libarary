---
title: "Are We Ready For An Agent-Native Memory System?"
date: 2026-07-16T00:00:00+08:00
draft: false

# 分类（研究领域）
categories: ["数据库系统"]

# 会议/期刊
venues: "arXiv 2026"

# 论文元数据
authors: ["Wei Zhou", "Xuanhe Zhou", "Shaokun Han", "Hongming Xu", "Guoliang Li", "Zhiyu Li", "Feiyu Xiong", "Fan Wu"]
year: "2026"
paper_url: "https://arxiv.org/abs/2606.24775"
arxiv_url: "https://arxiv.org/pdf/2606.24775"
code_url: "https://github.com/OpenDataBox/MemoryData"

rating: 4

summary: "论文把智能体记忆重新定义为一套长期数据管理系统，并分解为表示与存储、提取、检索与路由、维护四个模块。作者在 5 类 workload、11 个数据集上统一比较 12 个记忆系统与 2 个基线，并从端到端效果、证据召回、动态更新、长程稳定性和成本五方面评估。核心结论是不存在通用最优架构：结构必须匹配 workload 瓶颈；高召回依赖显式证据组织；保留原始证据通常比激进摘要更重要；写入应保守、过滤应尽量后置；局部维护比全局重组更具成本效益。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文研究的不是“给 LLM 再接一个向量库是否会变好”，而是一个系统问题：

> 如果 memory 已经成为智能体长期运行的基础设施，我们是否拥有一套真正面向智能体的 memory system？

作者认为，当前 memory evaluation 通常把整个系统看成黑盒，只比较最终 F1、BLEU 或 task success。这会掩盖真正决定系统行为的模块差异：

- 写入时保存原文、摘要、fact、graph 还是复合对象？
- query 时用 dense search、graph traversal、LLM planning 还是 hybrid routing？
- 新事实和旧事实冲突时如何更新？
- memory 变大后如何压缩、遗忘和控制延迟？
- 回答失败究竟是没存、没取回、取回后丢细节，还是生成模型没用对？

论文据此把 agent memory system 形式化为四个模块组成的元组：

```text
M_sys = <R, S, Q, U>

R: Representation & Storage
S: Extraction
Q: Retrieval & Routing
U: Maintenance
```

然后统一评估 12 个代表性系统和 Long Context、Embedding RAG 两个基线，覆盖 5 类 benchmark workloads、11 个数据集，并提出五个端到端研究问题与四组模块消融。

论文标题的答案是：**还没有准备好。** 目前没有一个架构在所有 workload 上占优；结构化系统常有更好的证据组织与更新能力，却可能带来数量级更高的构建和查询成本；摘要、抽取和 consolidation 每增加一层，都可能不可逆地丢失证据。

## 🎯 研究背景

### Agent memory 已经从 RAG 插件变成状态基础设施

早期做法常把历史对话切块、向量化、检索 top-k。现代 agent memory 则需要维护：

- 多 session 用户信息；
- 工具执行轨迹和中间状态；
- 事件、偏好和关系；
- 新旧事实的版本与有效时间；
- 短期 buffer、长期 archive 和不同存储后端；
- 在线 consolidation、eviction 与更新。

这更像数据库系统，而不是一次性的 prompt augmentation。

### 为什么不能只看最终任务分数

两个系统可能有相近 Answer F1，却有完全不同的工程含义：

- A 每次查询 1 秒，但偶尔遗漏远距离证据；
- B 构建一个复杂知识图谱，每次查询 100 秒，更新也要全局重组；
- C 召回证据很好，但摘要抹去了精确日期；
- D Exact Match 较低，却能正确完成一系列数据库操作。

如果只报告一个平均分，无法判断系统适合聊天、跨 session 事实回忆、动态更新，还是有状态工具执行。

### 与 RAG、context engineering 的边界

论文明确区分：

- **RAG**：通常是对静态语料执行无状态、只读检索，再增强单次生成；
- **Context engineering**：为当前有限 context window 选择 prompt、工具描述和相关事实；
- **Agent memory system**：长期持久、可更新，负责表示、存储、检索和维护完整生命周期。

这个区分很重要，因为 memory update、conflict resolution、versioning 和 eviction 不能由普通 RAG 自动提供。

## ⚠️ 问题与挑战

论文要解决的问题是：**如何从统一的数据管理视角分解、比较和诊断异构 agent memory systems，并找出不同 workload 下的效果、稳定性与成本规律。**

### 1. 因为系统实现高度异构，所以“memory vs. no memory”无法解释模块贡献

Mem0、Zep、MemTree、MemoryOS、A-MEM、Letta 等系统使用不同表示、存储、检索和维护策略。端到端比较只能告诉你谁赢，不能告诉你为什么。

论文必须先建立统一 taxonomy，再构造只修改一个模块的受控 variant。

### 2. 因为不同 workload 的正确性结构不同，所以不存在一个足够的指标

- LoCoMo 有大量短事实，可看 EM 与 Answer F1；
- LongMemEval 需要跨 session 综合，表面形式可能不同，要看 ROUGE-L 与 LLM judge；
- DB-Bench 关注最终数据库状态，字符串不完全相同也可能任务成功；
- memory retrieval 还要单独测 gold evidence Recall@k；
- 更新与长程稳定性需要随时间距离变化的曲线。

所以论文采用多指标而不是压成单一 leaderboard。

### 3. 因为记忆会演化，所以静态问答无法暴露 stale fact

真实用户信息会改变，例如：

```text
旧事实：Kim 住在 Paris
新事实：Kim 搬到 London
```

append-only 系统可能同时检索到两个版本；摘要系统可能把二者错误合并；dense retrieval 可能因为旧事实出现次数更多而优先返回它。动态更新测试必须判断系统能否返回当前有效状态。

### 4. 因为结构越丰富维护越贵，所以准确率提升必须和成本一起看

图结构、跨引擎索引和全局 consolidation 可能提高组织能力，但 construction、query 和 maintenance 都会变慢。一个只提高几点指标、却把单 query 延迟从几秒推到数百秒的系统未必适合生产。

### 5. 因为抽象会丢信息，所以“更聪明的摘要”可能破坏长期可恢复性

每次 summary、fact extraction 或 graph construction 都是有损变换。如果当时被判为不重要的日期、措辞或上下文后来成为关键证据，系统无法从摘要中恢复它。

## 🔍 核心发现 Finding

### 作者明确声称

作者的总体结论是：没有单一 memory architecture 能主导所有 workload；有效性取决于 memory structure 是否匹配 workload bottleneck。显式结构有利于分散证据的组织与更新，局部维护比全局重组更高效，而激进的提取和摘要会损害证据保真度。

### 我的理解

我认为这篇论文最重要的 `Finding` 可以概括为：

**Agent memory 的核心不是尽可能压缩历史，而是让未来尚未知的问题仍能恢复所需证据；因此应该把“证据保真度、访问路径和维护范围”作为一等设计目标。**

它把常见的 memory pipeline 从“先智能抽取、再智能总结”改写成一种更保守的系统原则：

```text
写入时尽量保留信息
        ↓
用结构建立可定位的访问路径
        ↓
在 query 时根据任务过滤
        ↓
只局部更新受影响的状态
```

为什么这能解释主要结果？

- Raw memory 在精确事实上优于 abstractive summary，因为未提前删除未来可能需要的细节；
- graph/tree 在较大 k 和远距离证据上更强，因为它们能把分散证据连接起来；
- lightweight planning 比“检索后再反思”更有效，因为前者明确访问路径，后者只是增加推理与延迟；
- conservative merge 优于 aggressive consolidation，因为错误合并会破坏证据边界；
- localized maintenance 的成本更低，因为每次新写入不需要重组全局状态。

这也说明“memory 越结构化越好”不是论文结论。**结构只有在保留证据并限制维护范围时才有价值。**

## 🔬 方法

### 1. 四模块分析框架

#### M1：Memory Representation & Storage

表示决定 memory 的逻辑形态，存储决定物理落点。

论文把逻辑表示分为：

1. **Token-level sequence**：原始文本、离散 facts、内部 summary、KV cache；
2. **Graph/tree topology**：temporal KG、entity-relation graph、hierarchical tree；
3. **Heterogeneous composite**：文本、embedding、timestamp、category 和 links 组成复合 memory object。

物理存储分为：

- transient in-context register；
- specialized single engine，如 vector DB、graph DB、relational DB；
- heterogeneous multi-engine，如 vector + graph + SQL/BM25。

#### M2：Memory Extraction

写入时把 message、trajectory 或 observation 转为 memory：

1. **Raw sequence concatenation**：保留原始序列；
2. **Schema-free semantic extraction**：由 LLM 提取自由形式 fact/summary；
3. **Schema-constrained structured extraction**：抽取成 JSON、triples 或预定义字段。

#### M3：Memory Retrieval & Query Routing

论文归纳五种读取方式：

1. Native attention：把 memory 直接放入 context；
2. Semantic dense retrieval：embedding KNN；
3. Topological traversal：在 graph/tree 中展开邻居；
4. Autonomous agentic routing：LLM 生成 tool call 或 query expansion；
5. Multi-stage hybrid：dense、BM25、graph、filter、reranker 组合。

#### M4：Memory Maintenance

维护处理冲突、容量与压缩：

1. Timestamp-based multi-versioning：保留历史版本，用有效期或 invalidation 标记；
2. Capacity-driven eviction：FIFO、token limit、heat/decay score；
3. LLM-driven semantic consolidation：merge、summary 或 tool-driven CRUD；
4. Continuous parametric optimization：异步把历史用于微调模型参数。

### 2. 被比较的系统

taxonomy 覆盖了 sequential、structural topological 与 multi-paradigm hybrid 三类系统。端到端实验比较 12 个代表性 memory systems，并加入：

- **Long Context**：保留历史并直接放进上下文；
- **Embedding RAG**：标准 flat dense retrieval。

代表系统包括 Mem0、MemoChat、Cognee、Zep、MemTree、Letta、LightMem、SimpleMem、MemOS、MemoryOS 和 A-MEM 等。

### 3. 五个端到端研究问题

| RQ | 研究问题 | 代表 benchmark / 指标 |
|---|---|---|
| RQ1 | 不同 workload 上是否有效 | LoCoMo、LongMemEval、DB-Bench；EM、F1、LLM judge、Task Success |
| RQ2 | 是否取回 gold evidence | LoCoMo Recall@1/5/10、evidence distance bins |
| RQ3 | 能否处理事实更新 | LoCoMo Temporal、LongMemEval Knowledge Update / Temporal Reasoning |
| RQ4 | horizon 增长后是否稳定 | LongBench 长度桶、LongMemEval session 数、LoCoMo 证据距离 |
| RQ5 | 效果与成本是否匹配 | construction + query latency、normalized utility |

### 4. 四组 fine-grained component ablation

作者不是只跑默认系统，还构造受控 variant：

- M1：raw vs. summary vs. compressed；shallow vs. deeper tree；
- M2：heuristic vs. LLM topic；fast vs. fine memorize；user-only vs. hybrid raw；
- M3：balanced vs. sparse-leaning fusion；no planning vs. planning vs. planning + reflect；
- M4：default vs. conservative merge vs. delayed flush；multi-topic vs. single-topic summary。

这种实验的价值在于把“某系统赢了”转成可迁移的设计原则。

## 📊 实验与结论

### 1. 不存在跨 workload 的唯一赢家

不同任务的领先系统不同：

- LongMemEval：Zep 的 LLM Judge Accuracy 为 `48.0`，Cognee 的 ROUGE-L F1 为 `35.3`；
- LoCoMo：MemOS 的 EM 最高，为 `11.5`；Long Context 的 Answer F1 为 `32.8`，MemOS 为 `32.2`；
- DB-Bench：Long Context 的 EM 为 `48.2`，MemoChat 的 Task Success Rate 为 `55.4`，Letta 两项都是 `61.6`。

论文的解释是：

- 跨 session 聚合更适合 relation/time-aware memory；
- 长但语义连贯的对话适合 coarse-to-fine filtering；
- 依赖操作顺序的任务需要保留 execution trace。

这也说明 Exact Match 不是统一答案。LongMemEval 的正确回答可能是 paraphrase，DB-Bench 更应检查最终状态是否正确。

### 2. Retrieval 的关键是“补全证据”，不是只把一个相关 item 排第一

LoCoMo gold evidence 结果：

| 方法 | Recall@1 | Recall@5 | Recall@10 |
|---|---:|---:|---:|
| Embedding RAG | 3.8 | 16.0 | 17.7 |
| SimpleMem | **39.0** | 64.6 | 75.1 |
| MemTree | 24.8 | 59.7 | 80.5 |
| A-MEM | 31.3 | **69.5** | **85.9** |

SimpleMem 最擅长提前找到一个高相关 item；A-MEM 与 MemTree 在更大的 k 下更能收集完整的、分散的 evidence set，并且随 session distance 增长退化更慢。

这表明 memory retrieval 应分成两个目标：

1. early localization；
2. evidence assembly。

### 3. 动态更新依赖时间结构，而不是单纯扩大 backbone

在 LongMemEval Knowledge Update 上：

- Zep 达到 `44.4` Substring EM / `36.8` ROUGE-L F1；
- Cognee 在 Temporal Reasoning 达到 `18.7` / `35.8`；
- LoCoMo temporal slice 上，MemOS EM 为 `8.9`，Cognee Answer F1 为 `28.1`。

更换 Qwen3-8B、DeepSeek-Chat、GPT-5.4-mini、GPT-5.4 后，绝对答案质量会变，但 memory pipeline 的相对趋势比较稳定。作者据此认为：强 backbone 可以润色已正确定位的证据，却不能可靠弥补 stale fact selection。

### 4. Horizon 增长后，flat context 和 flat RAG 退化更快

LongBench 上，Long Context 从 short bucket 的 `42.6` accuracy 降到 medium bucket 的 `19.0`，而 SimpleMem 从 `35.2` 到 `34.9` 基本稳定。

LoCoMo 随 evidence gap 增长时，Embedding RAG 的 Answer F1 从 `37.1` 降到 `7.4`；Cognee、MemOS、MemoryOS 等显式组织证据的系统更稳定。

这说明长程问题不是“存储容量不够”，而是远距离事实是否仍和实体、时间、session abstraction 保持连接。

### 5. Localized maintenance 有更好的 cost-utility trade-off

| 系统 | Normalized Utility | 平均 operation latency / query |
|---|---:|---:|
| LightMem | 48.3 | 3.67 s |
| MemTree | 63.5 | 15.9 s |
| A-MEM | 57.7 | 17.9 s |
| MemoryOS | 82.0 | 28.6 s |
| Cognee | >84 | 116.5 s |
| Zep | >84 | 155.1 s |

更丰富的结构并非天然昂贵，真正决定成本的是每次写入需要触及多大的状态范围：

- path-local aggregation 和 segmented retrieval 较便宜；
- graph-wide consolidation、multi-store synchronization 和 whole-memory rewriting 较贵。

### 6. 表示消融：raw evidence 通常优于摘要

LightMem variant：

| 表示 | LoCoMo EM / F1 | LongMemEval Substring EM / ROUGE-L F1 |
|---|---:|---:|
| User-Only Raw | **24.2 / 38.9** | **26.0 / 31.4** |
| User-Only Compressed | 23.6 / 38.6 | 10.7 / 19.1 |
| User-Only Summary | 8.5 / 15.6 | 11.7 / 17.4 |

轻压缩在 LoCoMo reasoning 上接近 raw，却在 LongMemEval 精确细节上大幅下降；abstractive summary 两边都弱。更深的 MemTree 只有小幅提升，说明 hierarchy 无法恢复已删除的信息。

### 7. 提取消融：写入应保守，过滤尽量后置

MemOS Fast Memorize 在 LoCoMo 达到 `25.5` EM / `40.8` F1，Fine Memorize 只有 `2.5` / `5.0`；后者在 LongMemEval 略有优势，却严重破坏组合推理。

LightMem 同时保留 user 与 assistant turns，LoCoMo 略优于只保留 user，因为 assistant 常包含澄清后的日期或表达。

作者据此提出 **Late Filtering Principle**：写入时优先保留上下文，query 时再针对任务筛选。

### 8. 检索消融：planning 有用，额外 reflection 不一定有用

SimpleMem：

| 路由方式 | LoCoMo F1 / Recall | LongMemEval Substring EM / ROUGE-L F1 |
|---|---:|---:|
| No Planning | 18.7 / 86.4 | 17.0 / 22.9 |
| Planning Only | **20.7 / 90.6** | **21.7 / 27.9** |
| Planning + Reflect | 20.0 / 88.6 | 21.3 / 26.1 |

轻量 query planning 帮助拆解约束；额外 reflection 反而略降并增加延迟。A-MEM 的 balanced dense-sparse fusion 也优于 sparse-leaning 配置。

### 9. 维护消融：conservative merge 是更安全的默认值

MemoryOS Conservative-Merge 比默认设置略好；Delayed-Flush 更差。MemoChat 强制每个窗口只生成一个 topic summary，也弱于默认 multi-topic consolidation。

原因是：

- merge 太激进会混淆独立事实；
- flush 太晚使近期证据在 query 时仍碎片化；
- summary 太粗会抹去稀疏但关键的线索。

### 作者可以合理得出的结论

- memory architecture 必须按 workload 选择，不存在通用冠军；
- 精确回忆、跨 session 综合、时间更新和有状态执行需要不同组织方式；
- evidence-level retrieval 必须与最终 answer metric 分开测；
- 写入时保留证据、读取时再过滤，通常比提前激进摘要更稳；
- temporal versioning 和 entity binding 是动态更新的基础；
- 结构化 memory 的收益必须与 construction、query 和 maintenance 成本一起报告；
- localized maintenance 是更可扩展的系统设计。

### 局限性与需要谨慎解释的地方

论文没有单独的 limitations section，下面是我的批判性判断。

#### 1. 这是横向实验研究，不是新的完整 memory architecture

论文提供 taxonomy、testbed 与设计原则，但没有给出一个同时解决所有矛盾的新系统。因此标题的“agent-native”更多是目标定义，而不是已实现的统一方案。

#### 2. “统一测试”仍难完全消除实现成熟度差异

被测系统来自不同代码库，默认 prompt、embedding、索引参数、失败重试和依赖版本可能显著影响结果。论文给出了统一 workload 与时间 trace，但正文对每个系统的参数对齐与运行失败处理披露有限。

#### 3. 部分指标依赖强 LLM judge

LongMemEval 使用 GPT-5.4-based judge，能处理 paraphrase，但也引入 judge bias、版本漂移和复现实验成本。它不应替代可验证的 evidence 与 end-state 检查。

#### 4. 代表性仍有限

12 个系统覆盖主要范式，却不能代表快速变化的 memory 生态；某些结果也来自特定 benchmark slice。不能把“某系统在当前表格领先”解释为生产环境的普遍排名。

#### 5. 成本度量主要是时间，而不是完整 TCO

生产成本还包括 token/API 费用、存储增长、索引内存、并发吞吐、故障恢复和数据治理。单 query latency 只是其中一部分。

## 🧩 关键术语

- **Agent-Native Memory System（智能体原生记忆系统）**: 为 agent 长期状态而设计、覆盖写入到维护全生命周期的持久数据系统。例子：能记录用户搬家、让旧地址失效，并在以后只返回当前地址。
- **Representation Fidelity（表示保真度）**: memory 表示是否仍保留未来回答所需的原始证据。例子：摘要保留“去过欧洲”，却丢掉“2025 年 6 月去巴黎”的日期与地点。
- **Evidence Assembly（证据组装）**: 把分散在多个 turns 或 sessions 的支持证据一起取回。例子：把宠物名字、收养日期和过敏史组合起来回答问题。
- **Temporal Versioning（时间版本管理）**: 为同一事实保留有效时间或版本链。例子：Paris 版本在搬家日期后失效，London 版本生效。
- **Late Filtering Principle（延后过滤原则）**: 写入阶段保留更多信息，把任务相关筛选放到 query 阶段。
- **Coarse-to-Fine Retrieval（由粗到细检索）**: 先确定相关 session/topic，再在局部找精确事实。
- **Hybrid Retrieval（混合检索）**: 组合 dense、BM25、structured filters、graph traversal 和 reranker。
- **Localized Maintenance（局部维护）**: 新写入只更新受影响的节点、路径或 segment，避免重组整个 memory。
- **Conservative Consolidation（保守整合）**: 只有相似度和语义关系足够明确时才合并事实，避免过度摘要。
- **Hallucinations of the Past（过去事实幻觉）**: 系统返回曾经正确、现在已经过时的事实。

## 💡 个人评价与研究启发

这篇论文适合作为设计 agent memory benchmark 或系统的检查表。一个更完整的实验报告至少应分开给出：

```text
Write fidelity
Retrieval fidelity
Answer correctness
Update correctness
Long-horizon drift
Construction / query / maintenance cost
```

对实际系统，我会采用以下默认策略作为起点：

1. 保留可追溯的 raw evidence，不让 summary 成为唯一真相；
2. 为 entity、event 和 timestamp 建轻量结构，但避免默认全局 graph rebuild；
3. 写入时保守抽取，query 时做 query planning 与 hybrid filtering；
4. 新旧事实用 versioning/invalidation 管理，而不是简单 append；
5. consolidation 采用局部、可逆、保留 provenance 的策略；
6. 同时测 answer F1、evidence Recall/Precision、stale-fact rate 和 latency。

## 🔗 相关资源

- [arXiv 论文页](https://arxiv.org/abs/2606.24775)
- [MemoryData 评测代码与数据](https://github.com/OpenDataBox/MemoryData)
- [Agent Memory Taxonomy](https://github.com/OpenDataBox/awesome-agent-memory)
