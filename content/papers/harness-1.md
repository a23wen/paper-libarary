---
title: "Harness-1: Reinforcement Learning for Search Agents with State-Externalizing Harnesses"
date: 2026-07-30T10:00:00+08:00
draft: false

# 分类（研究领域）
categories: ["信息检索"]

# 会议/期刊
venues: "arXiv 2026"

# 论文元数据
authors: ["Pengcheng Jiang", "Zhiyi Shi", "Kelly Hong", "Xueqiang Xu", "Jiashuo Sun", "Jimeng Sun", "Hammad Bashir", "Jiawei Han"]
year: "2026"
paper_url: "https://arxiv.org/abs/2606.02373"
arxiv_url: "https://arxiv.org/pdf/2606.02373"
code_url: "https://github.com/pat-jj/harness-1"

rating: 5

summary: "Harness-1 研究搜索智能体中的“状态应该由谁维护”。作者不再让语言模型从不断增长的原始轨迹中反复恢复候选文档、证据关系和验证记录，而是把这些可恢复的记账工作外置到一个有状态 harness 中，只让策略负责搜索、筛选、验证和停止等语义决策。基于 gpt-oss-20b 的模型经 SFT 和 CISPO 强化学习后，在八个检索基准上取得 0.730 平均 curated recall，较下一名开源搜索子智能体高 11.4 个百分点，并在未参与训练的迁移任务上获得更大的提升。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文讨论的是搜索智能体里一个经常被当作工程细节、实际却直接决定训练效果的问题：

**在多轮搜索过程中，候选文档、已验证事实、跨文档线索和上下文预算，到底应该由模型自己记，还是由环境替它维护？**

传统搜索智能体通常被建模为：

- 模型看到问题；
- 调用搜索或阅读工具；
- 工具结果追加到对话轨迹；
- 模型从越来越长的历史里判断下一步；
- 最后返回证据或答案。

表面上看，模型只是在学习“怎么搜索”。但作者指出，模型实际上同时承担了两类性质完全不同的工作：

1. **语义决策**
   - 下一步搜什么；
   - 哪篇文档值得保留；
   - 哪个主张需要验证；
   - 证据是否已经足够。

2. **机械记账**
   - 哪些文档已经看过；
   - 哪些候选重复；
   - 当前保留了哪些证据；
   - 文档之间共享哪些实体或日期；
   - 哪些主张已经验证；
   - 还剩多少上下文预算。

第二类工作大多可以从环境状态中可靠恢复，却被塞进了语言模型的上下文和强化学习目标。结果是 RL 不仅要学搜索策略，还要学会在不断增长的原始文本里重建状态。

Harness-1 的核心做法是把这部分工作外置：

- 环境维护持久化的 `WORKINGMEMORY`；
- 搜索结果进入候选池，并自动压缩、去重；
- 最终证据集有显式的重要性标签；
- 文档间的实体、日期和数字关系被整理成轻量证据图；
- 验证结果和搜索历史被结构化保存；
- 模型每轮看到的是预算内的状态渲染，而不是完整原始轨迹；
- 模型仍然保留所有关键语义决策权。

论文把这一设计称为 **stateful cognitive offloading**，即“有状态的认知卸载”。

## 🎯 研究背景

### 搜索智能体不只是查询生成器

长程搜索通常包含多个互相依赖的操作：

- 扩展查询；
- 发现候选；
- 阅读全文；
- 回溯已有文档；
- 比较多个来源；
- 建立实体或事件之间的桥接关系；
- 验证某个具体主张；
- 从已发现文档中选出最终证据。

如果所有结果都只是追加到 transcript，模型每轮都必须从头推断“当前搜索已经走到哪里”。轨迹越长，这种状态恢复就越昂贵，也越不可靠。

### RL 会放大状态管理问题

在监督学习里，一个示范轨迹可以告诉模型该调用哪个工具。但在强化学习里，奖励通常只在 episode 结束时给出。

如果最终结果为空或错误，奖励很难区分失败来自哪里：

- 根本没搜到；
- 搜到了但忘记；
- 搜到了但没有加入最终集合；
- 加入了错误文档；
- 没有验证关键事实；
- 一直重复搜索，耗尽回合。

于是 RL 面临一个信用分配问题：它需要同时优化语义搜索和可恢复的状态维护，而终局奖励并没有明确指出是哪一部分出了错。

### “发现证据”和“选择证据”不是同一件事

论文区分了三个指标：

- `Trajectory Recall`：整个搜索轨迹中曾经遇到多少相关文档；
- `Recall`：最终 curated set 覆盖多少相关文档；
- `Final-Answer Recall`：最终集合是否保留了直接支持答案的 gold 文档。

这个区分很重要。一个智能体可以在搜索过程中找到正确证据，却在最终整理时把它丢掉。此时问题不是 discovery，而是 selection。

Harness-1 的设计目标正是让“发现之后的整理、验证和保留”成为显式、可学习的状态操作。

## ⚠️ 问题与挑战

论文要解决的问题可以概括为：

**怎样设计一个适合强化学习的有状态搜索接口，使模型专注于不可替代的语义决策，同时让环境可靠维护可恢复的搜索状态？**

作者识别出三个直接影响 RL 可训练性的要求。

### 1. 因为空的 curated set 让早期轨迹奖励高度同质，所以需要 warm start

如果每次搜索都从空的最终集合开始，尚未学会 `curate` 的模型很容易返回空集合。很多不同的失败轨迹最终都得到相同空集惩罚，RL 无法判断哪些搜索方向更有潜力。

Harness-1 因此在第一次成功搜索后，自动把重排后的前 8 个结果以 `fair` 重要性加入暂定 curated set。

这不是替模型做最终判断，而是把问题从：

> 从零构造一个集合

变成：

> 对一个尚不可靠但包含候选的集合做增删、升降级和验证。

后者能产生更丰富的训练差异。

### 2. 因为派生状态也会占上下文，所以必须压缩而不是无限堆积

状态外置不等于把所有状态重新塞回 prompt。候选池、搜索历史、证据图和验证记录如果完整展开，同样会挤占证据文本。

因此 harness 只渲染紧凑摘要：

- 候选池的关键条目；
- 最终集合及重要性；
- 高频实体、桥接文档和 singleton；
- 已验证主张；
- 最近搜索的新增文档数；
- 剩余上下文预算。

完整文档则保存在 prompt 之外，需要时通过 `review_docs` 或 `read_document` 取回。

### 3. 因为 RL 会利用最容易的奖励路径，所以丰富工具不等于会使用丰富工具

如果奖励只鼓励“发现更多 gold 文档”，模型最容易学到的是反复调用搜索。这样 trajectory recall 可能上升，但 curation 和 verification 会消失。

因此论文额外加入工具多样性奖励，鼓励搜索、阅读、整理和验证形成节奏。实验显示，没有该奖励时工具多样性从约 6 降到 3.5，最终 curated recall 停在约 0.53；加入后多样性稳定在约 4.3，recall 最终达到约 0.60。

## 🔍 核心发现 Finding

### 作者明确声称

作者的核心主张是：

**搜索智能体的 harness 不应只是工具调用的薄封装，而应是强化学习方法的一部分。把可恢复的状态管理交给环境，可以让策略在稳定、显式的搜索状态上学习语义操作，并获得更强的跨域迁移能力。**

论文用三类证据支持这一主张：

- Harness-1 在八个检索基准上显著优于其他开源搜索子智能体；
- 相比 Context-1，提升在 held-out benchmark 上反而比训练相关 benchmark 更大；
- 固定同一个模型、只切换 harness，也能让 GPT-5.4 的 recall 提升约 4.2 个百分点。

### 我的理解

我认为这篇论文真正重要的 finding 是：

**Agent RL 的学习对象不只是模型参数，还包括“模型被允许看到什么状态，以及通过什么操作改变状态”。**

传统思路容易把能力问题归因于模型：

- 记不住文档，说明上下文不够长；
- 不会整理证据，说明模型不够大；
- 搜索重复，说明 policy 训练不够；
- 找到但没保留，说明 reward 不够好。

Harness-1 给出了另一种解释：

**这些失败中有相当一部分来自决策接口不合适。**

如果模型面对的是原始 append-only transcript，那么“比较两个候选”“回看旧文档”“检查某个主张是否被支持”都要先完成一次隐式的信息恢复。

而在 Harness-1 里：

- 候选是可寻址的对象；
- 最终集合是可编辑的状态；
- 重要性是显式标签；
- 文档关系是可见的图摘要；
- 验证是一等操作；
- 上下文预算是环境信号。

这样 RL 学到的就不是“如何在某个领域的长文本里勉强记账”，而是：

- 如何精炼候选集；
- 如何利用桥接实体继续搜索；
- 何时回看；
- 何时验证；
- 何时停止。

这些操作更接近领域无关的搜索算法，所以它们能迁移到 LongSealQA、Seal0QA、FRAMES 和 HotpotQA。

从更广的 agent 设计角度看，这篇论文在强调一个边界：

> 应该把不可替代的判断留给 policy，把确定性、可恢复、容易审计的状态变换交给环境。

## 🔬 方法

### 1. Harness 状态

每个搜索 episode 都有一个持久化状态：

- `P_t`：压缩和去重后的候选文档池；
- `C_t`：最终 curated set；
- `I_t`：curated 文档的重要性标签；
- `D_t`：检索过的完整文档文本与元数据；
- `G_t`：实体、日期与文档构成的证据图；
- `V_t`：主张验证记录；
- `H_t`：搜索历史和结果摘要；
- `B_t`：上下文预算与安全渲染状态。

它采用两层存储：

1. **Prompt-facing tier**
   - 只放紧凑且可操作的工作状态；
   - 每一轮渲染给模型。

2. **Outer tier**
   - 保存完整文档；
   - 不持续占用 prompt；
   - 模型需要时显式回看。

### 2. Policy 和 harness 的分工

| 状态或操作 | Harness 负责 | Policy 负责 |
|---|---|---|
| 候选池 | 压缩、去重、存储 | 决定读哪些候选 |
| Curated set | 容量限制、自动淘汰 | 增加、删除、升降级 |
| 全文记忆 | 保存已读文档 | 决定何时回看 |
| 证据图 | 抽取实体并汇总关系 | 决定追踪哪个 bridge |
| 验证记录 | 执行文本支持检查并存档 | 决定验证什么主张 |
| 搜索历史 | 汇总新增量和进展 | 决定继续、改道或停止 |
| 上下文预算 | 安全裁剪和渲染 | 决定如何使用剩余回合 |

这个分工的关键是：harness 不替模型判断“什么是相关证据”，只替它做可以机械恢复的维护工作。

### 3. 工具接口

Harness-1 提供八个主要工具：

- `fan_out_search(queries)`：最多并行执行五个多样化查询；
- `search_corpus(query)`：BM25 与 dense retrieval 的混合搜索；
- `grep_corpus(pattern)`：正则精确匹配；
- `read_document(doc_id)`：读取完整文档；
- `review_docs(doc_ids)`：重新渲染已存文档，不发起新检索；
- `curate(add, remove, importance)`：编辑最终集合；
- `verify(doc_ids, claim)`：逐文档检查某个主张是否得到支持；
- `end_search(reasoning)`：结束并返回 curated set。

相比只有 `search` 和 `answer` 的薄接口，这组工具把搜索过程中的关键状态变换显式化。

### 4. Curated set 与 importance tag

`curate` 可以：

- 添加文档；
- 删除文档；
- 给新增文档标记 `very high`、`high`、`fair` 或 `low`。

最终集合最多 30 篇文档。达到容量后，harness 优先淘汰重要性最低的文档。

重要性标签既表达策略信心，也把容量管理与语义判断解耦：

- 模型决定谁重要；
- harness 执行确定性的容量约束。

### 5. Auto-seeding

第一次成功搜索后：

- 从候选池重排结果中取前 `k=8`；
- 自动加入 curated set；
- 初始重要性都为 `fair`。

模型随后要通过阅读、精确搜索和验证：

- 提升强证据；
- 删除假阳性；
- 替换弱候选。

这是论文所谓的 warm-started curation。

### 6. Evidence graph

证据图使用轻量正则抽取三类信息：

- 多词首字母大写的专名；
- 四位年份或年代；
- 数字日期。

环境维护：

- `entity → docs`；
- `doc → entities`。

渲染时显示：

- 跨多篇文档出现的高频实体；
- 同时包含多个高频实体的 bridge document；
- 只在一篇文档中出现的 singleton entity。

它不是一个完整知识图谱，也不负责推理。它的作用是把原本散落在长轨迹里的跨文档重叠变成可直接查询的线索。

### 7. 观察压缩与去重

搜索结果先经过 sentence-level BM25：

- 以当前查询为条件给句子打分；
- 选择前 `K=4` 个句子；
- 按原文顺序渲染。

显式 `read_document` 仍可返回全文。

去重分两层：

- chunk ID 去重；
- content fingerprint 近重复去重。

这减少同一内容反复挤占上下文。论文也诚实报告了一个反例：去掉内容指纹去重后，BC+ 的 recall 反而略升，因为其 qrels 有时把近重复文档标成多个不同 gold ID。说明去重主要服务 token 效率，而不是直接提升 recall。

### 8. SFT

SFT 的目标很克制：只教模型如何操作接口。

GPT-5.4 作为 teacher，在完整 Harness-1 环境中生成轨迹。指导内容包括：

- 搜索后及时 curate；
- 高置信提升前先验证；
- 低收益搜索后回溯或换方向；
- 证据足够时尽早停止。

过滤条件是：

- 工具格式有效；
- 至少返回一篇文档；
- 最终 curated recall 不低于 0.10。

最终保留 899 条轨迹。每条轨迹按回合展开成监督样本，用 LoRA rank 32 在 gpt-oss-20b 上训练 3 个 epoch。

### 9. RL

RL 从 SFT checkpoint 开始：

- 算法：on-policy CISPO；
- 训练数据：SEC train split，共 3,453 个 query；
- 完整 episode rollout；
- 最多 40 轮；
- terminal-only reward；
- 无 KL anchor；
- 同组 rollout 奖励完全相同时不计算梯度。

非空结果的奖励由以下部分组成：

```text
R =
w_F F_\beta
+ w_\tau \rho_\tau
+ w_A \rho_A
+ w_{\tau A}\rho_{\tau A}
+ B_A \mathbf{1}[\rho_A > 0]
+ w_{\text{div}}\min(\nu/\nu_0,1)
- w_{\text{miss}}(\rho_{\tau A}-\rho_A)_+
- \pi_{\text{turn}}(t)
```

其中：

- `F_β` 衡量最终集合质量，`β=2`，召回权重是精度的四倍；
- `ρ_τ` 是 trajectory recall；
- `ρ_A` 是最终集合的 final-answer recall；
- `ρ_τA` 是轨迹中的 final-answer recall；
- 工具多样性目标 `ν_0=6`；
- 如果轨迹找到答案证据却没加入最终集合，会受到 answer-miss penalty；
- 20 轮后开始加入 turn penalty；
- 空 curated set 直接得到 `-0.2`。

这个奖励显式区分：

- 有没有发现；
- 有没有正确选择；
- 是否漏掉已经发现的答案证据；
- 是否形成多样化工具使用；
- 是否过度搜索。

## 🧪 实验与结果

### 1. 数据集与协议

论文评估八个检索基准：

- BrowseComp+；
- Web synthetic；
- Patents；
- SEC filings；
- LongSealQA；
- Seal0QA；
- FRAMES；
- HotpotQA。

前四个 benchmark family 出现在 SFT 数据中，RL 只使用 SEC。后四个完全不参与 SFT 或 RL，因此被视为 held-out transfer。

所有方法共享：

- 相同检索 primitive；
- 相同 web backend；
- Qwen3-Reranker-8B；
- 最多返回 30 篇文档。

### 2. 总体检索性能

Harness-1 的平均 curated recall 为 `0.730`。

主要结论：

- 比下一名开源搜索子智能体 Tongyi DeepResearch 30B 高 `11.4` 个百分点；
- 在论文协议下高于 GPT-5.4、Sonnet-4.6、Kimi-K2.5 和 GPT-OSS-120B；
- frontier 模型中只有 Opus-4.6 的平均 curated recall 更高。

按数据集看，Harness-1 的 curated recall 为：

| Benchmark | Recall |
|---|---:|
| BrowseComp+ | 0.584 |
| Web | 0.787 |
| Patents | 0.890 |
| SEC | 0.589 |
| LongSealQA | 0.891 |
| Seal0QA | 0.551 |
| FRAMES | 0.710 |
| HotpotQA | 0.841 |

### 3. Held-out transfer 是最有说服力的结果

相比 Context-1，Harness-1 在四个 source-family benchmark 上平均提升 `+7.9` 个百分点：

- BC+：`+6.2`；
- Web：`+9.8`；
- Patents：`+3.3`；
- SEC：`+12.2`。

而在完全未参与 SFT/RL 的四个 benchmark 上平均提升 `+17.0`：

- LongSealQA：`+32.8`；
- Seal0QA：`+18.4`；
- FRAMES：`+7.2`；
- HotpotQA：`+9.5`。

held-out 增益是 source-family 增益的 `2.2×`。

作者据此认为，模型学到的不是 SEC 或 web 领域里的固定查询模板，而是对显式搜索状态进行操作的通用行为。

### 4. 组件消融

作者固定同一个已训练 checkpoint，只在推理时关闭某个 harness 机制。

| 配置 | Recall | 相对变化 | FA Recall | 相对变化 |
|---|---:|---:|---:|---:|
| 完整 Harness-1 | 0.584 | — | 0.667 | — |
| 去掉 importance tag | 0.560 | -4.1% | 0.614 | -7.9% |
| 去掉句子 BM25 压缩 | 0.585 | +0.2% | 0.620 | -7.0% |
| 去掉 auto-seed | 0.582 | -0.3% | 0.624 | -6.4% |
| 隐藏 evidence graph | 0.569 | -2.6% | 0.631 | -5.4% |
| 关闭 verify | 0.566 | -3.1% | 0.641 | -3.9% |
| 关闭 review docs | 0.598 | +2.4% | 0.641 | -3.9% |
| 去掉内容指纹去重 | 0.611 | +4.6% | 0.678 | +1.6% |
| 关闭全部机制 | 0.513 | -12.2% | 0.624 | -6.4% |

六个主要机制被移除后，模型都会回退到“宽而浅”的搜索模式：

- `search_corpus` 使用增加；
- `read_document` 和 `verify` 明显减少；
- 找到更多候选，却更难形成高质量最终集合。

这说明状态机制不只是提供额外信息，也改变了策略如何分配每一轮的行为。

### 5. 同模型、不同 harness

为了分离模型训练和接口贡献，作者让同一个 GPT-5.4 在三种环境中运行：

- naive search-add；
- Context-1 harness；
- Harness-1 harness。

Curated recall 依次为：

- `0.511`；
- `0.807`；
- `0.849`。

Final-answer recall 依次为：

- `0.612`；
- `0.821`；
- `0.876`。

也就是说，不做 RL、只替换 harness，GPT-5.4 相比 Context-1 就获得约 `+4.2` recall point。

### 6. 数据效率

Harness-1 使用：

- 899 条 SFT 轨迹；
- 3,453 个 SEC RL query；
- 合计 4,352 个唯一训练 item。

作者对比：

- Context-1 约 17.2K 个 SFT/RL item；
- Search-R1 在 221,328 行 NQ+HotpotQA 数据上训练。

这不是严格的 compute 对比，但它说明一部分行为先验可以被编码进接口，而不一定全靠大规模轨迹学习。

### 7. Modular RAG

作者把不同搜索子智能体的 curated set 交给冻结的 frontier answer generator：

- generator 只看到 query 和最终文档；
- 不看到搜索轨迹；
- 不参与搜索优化。

结果显示，更高质量的 curated set 能稳定转化为更高答案准确率，Harness-1 在该设置下优于其他开源搜索子智能体。

这说明提升不是只发生在检索指标上，而能传递到下游问答。

## 💡 关键洞察

### 1. Context engineering 和 policy learning 不是两个独立问题

如果训练、评估和真实运行时使用不同的状态渲染，模型学到的行为很难稳定迁移。

Harness-1 在：

- teacher 数据生成；
- SFT replay；
- RL rollout；
- evaluation

中使用同一个 working-memory renderer。这种训练—推理一致性是方法的一部分。

### 2. 长上下文不能替代可寻址状态

即便上下文足够长，模型仍需要：

- 找到旧文档位置；
- 判断它是否已验证；
- 与其他证据建立关系；
- 决定是否保留。

显式状态把这些操作从“在文本中回忆”变成“在对象上编辑”。这不仅节省 token，也降低决策难度。

### 3. RL reward 必须覆盖完整闭环

只奖励搜索发现，会得到 search-only policy；只奖励最终集合，又可能让早期训练陷入空集同质奖励。

Harness-1 通过：

- auto-seed 改善早期状态；
- trajectory reward 奖励发现；
- curated reward 奖励选择；
- answer-miss penalty 惩罚发现后丢失；
- diversity bonus 维持工具节奏；
- turn penalty 控制成本。

把整个搜索闭环纳入信用分配。

### 4. Harness 是一种 compute allocation mechanism

模型算力可以用来：

- 重复恢复“我看过什么”；
- 或者判断“下一步应该验证什么”。

有状态 harness 的价值，就是把有限推理预算从前者转给后者。

## 📉 局限性与批判性评价

### 1. 任务范围主要是 evidence-seeking retrieval

实验集中在：

- needle-in-a-haystack；
- 多跳搜索；
- 有标注相关文档的任务。

它尚未覆盖：

- 开放式研究报告；
- 强调覆盖广度而非特定 gold evidence 的任务；
- 缺少证据时的 abstention；
- 对抗性网页环境。

因此 `0.730 recall` 不能直接等价为真实世界 deep research 的整体可靠性。

### 2. 证据图仍然非常初级

证据图依赖正则抽取：

- 专名；
- 年份；
- 日期。

它无法可靠处理：

- 实体别名；
- 代词指代；
- 隐式关系；
- 同名实体；
- 不确定性。

论文的 transfer 结果证明轻量结构已经有价值，但未来更强的 entity linking 和 relation extraction 可能进一步提高效果。

### 3. Verify 不是确定性 verifier

`verify` 使用 LLM 作为 entailment proxy。它在：

- 模糊主张；
- 高度专业文本；
- 条件不完整的陈述

上仍可能误判。

因此“有验证记录”不等于“事实已经可靠验证”。

### 4. 句子压缩可能损失篇章上下文

Sentence-BM25 偏向局部词项匹配。若相关性依赖：

- 跨句因果；
- 否定范围；
- 表格上下文；
- 前后文指代；
- 长距离论证，

只保留四个高分句子可能删掉关键语境。

### 5. 消融主要在 BrowseComp+ 的 100 个 query 上完成

组件消融很有解释力，但样本量与任务范围有限，且属于推理时关闭机制、没有重新训练。它能说明已训练 policy 对这些状态组件存在依赖，但不能完全回答：

- 每个组件独立训练时的长期贡献；
- 不同领域是否有相同排序；
- 更大模型是否同样依赖这些机制。

### 6. 基准标注会影响 recall 解释

内容去重消融反而略升，就是因为近重复文档可能拥有不同 gold ID。说明 qrels 的完整性和重复标注会直接影响 recall。

因此论文结果更适合解释为：

> 在给定检索后端、候选预算、标注集合和 harness 协议下的证据覆盖表现。

而不是普适的搜索质量上限。

## 🔗 与相关方向的关系

### 与 Context-1 的区别

Context-1 让 policy 学会主动裁剪自己的上下文，已经把 context management 引入搜索行为。

Harness-1 更进一步：

- 不只提供 prune；
- 把候选池、curated set、证据关系、验证记录和预算都做成环境侧持久状态；
- 让模型通过结构化操作编辑这些状态。

### 与传统 memory agent 的区别

很多 memory system 关注长期用户记忆、情景记忆或跨会话知识存储。Harness-1 关注的是单个搜索 episode 内的工作记忆：

- 生命周期更短；
- 状态变化更频繁；
- 与动作和奖励直接耦合；
- 目标是提高搜索决策和最终证据选择。

### 与软件工程 agent harness 的共同点

软件工程 agent 也依赖：

- 文件树；
- diff；
- 测试结果；
- issue 状态；
- 可回滚编辑。

这些都不是模型凭空记忆的文本，而是环境维护的结构化对象。Harness-1 表明，检索 agent 也需要类似的状态基础设施。

## 📝 总结

Harness-1 的贡献不是简单地增加几个搜索工具，而是重新划分了搜索智能体中 policy 与 environment 的责任：

- policy 负责不可替代的语义判断；
- harness 负责可恢复、确定性、可压缩的状态维护。

论文最有说服力的证据有三点：

1. 20B 模型在八个检索基准上取得 `0.730` 平均 curated recall，比下一名开源方法高 `11.4` 个百分点；
2. 对未参与 SFT/RL 的任务提升更大，说明学到的是状态操作而非领域模板；
3. 固定模型只替换 harness 也能提高性能，证明接口本身不是中性的实现细节。

如果把这篇论文压缩成一句话：

> **不要用强化学习训练模型去重新记住环境本来就能可靠维护的东西；让模型在显式状态上做真正需要判断的决策。**
