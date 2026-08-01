---
title: "Harness-G: A Graph-Structured Harness for Search Agents"
date: 2026-08-01T10:30:00+08:00
draft: false

# 分类（研究领域）
categories: ["信息检索"]

# 会议/期刊
venues: "arXiv 2026"

# 论文元数据
authors: ["Yanning Hou", "Haoyuan Chen", "Sihang Zhou", "Xiaoshu Chen", "Xirui Liu", "Duanyang Yuan", "Lingyuan Meng", "Quan Liu", "Jian Huang"]
year: "2026"
paper_url: "https://arxiv.org/abs/2607.27652v1"
arxiv_url: "https://arxiv.org/pdf/2607.27652v1"
code_url: "https://github.com/7HHHHH/Harness-G"

rating: 5

summary: "Harness-G 发现 Search-R1 式智能体即使持续生成表面不同的自然语言查询，实际检索到的证据集合也会在训练中迅速趋同；作者将这种动作字符串多样、环境转移却等价的现象称为 retrieval-equivalence collapse。论文不再让策略自由写查询，而是在程序化构建的段落—句子—实体图上提供有限、可验证、可预览的动作菜单，并用 Structured Non-myopic Credit 比较同状态备选动作、沿来源图把延迟收益归还给早期桥接动作。该方法在六个问答基准和 Qwen2.5 1.5B/3B 两种规模上取得最高平均 F1，相比 Graph-R1 分别提高 10.74 和 3.98 分；受控实验同时表明，动作接口重构带来的收益大于新增过程信用本身。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文从一个看似反直觉的训练现象开始：

**搜索智能体生成的查询越来越多样，并不代表它探索到的检索结果也越来越多样。**

Search-R1 一类方法通常把检索建模为自由文本生成：

1. 策略根据问题和当前轨迹写出一条自然语言查询；
2. 搜索环境执行查询并返回证据；
3. 智能体重复若干轮；
4. 最后按答案正确性获得奖励；
5. GRPO 等算法比较同一问题下多个 rollout 的回报，更新策略。

这种建模默认了一个前提：不同查询字符串大致对应不同的检索决策。但作者在训练 Search-R1 时发现，rollout 仍然写出大量措辞不同的查询，其累计证据集合却越来越重合。

论文把这个现象称为 **retrieval-equivalence collapse，检索等价性坍缩**。

它不是普通的“语言输出重复”，而是更隐蔽的环境层坍缩：

- 字符串看起来不同；
- 搜索引擎返回的证据几乎相同；
- 同组轨迹在检索意义上变得等价；
- 最终回报的差异只能来自回答生成等后续随机性；
- group-relative RL 因而缺少可归因于检索动作的有效对比。

Harness-G 的回答不是继续修改 reward，而是先重构 policy 与 environment 之间的接口：

- 用程序化方式构建段落—句子—实体图；
- 环境根据当前状态生成有限的动作菜单；
- 策略只选择一个动作 ID；
- 环境负责确定性查询构造、检索、去重、校验和状态更新；
- 每个动作的实际环境转移都可以在执行前预览；
- 再利用这些可比较的备选动作计算结构化过程信用。

论文因此给出一个很重要的 agent RL 观点：

> 当自然语言动作与环境结果之间存在严重多对一映射时，奖励设计无法独自恢复已经丢失的决策对比；必须同时设计可辨识、可执行、可比较的动作接口。

## 🎯 研究背景

### 1. 搜索智能体通常把“想搜什么”与“如何写查询”绑在一起

自由查询接口让模型同时负责两件事：

- 语义上决定下一步需要哪类证据；
- 用具体字符串表达这个检索意图。

但搜索引擎会把大量字符串映射到相同或高度重叠的结果：

- 同义改写；
- 调换词序；
- 增删不影响排序的限定词；
- 对同一个实体使用全称、缩写或别名；
- 在已有答案线索周围反复改写查询。

在监督推理时，这种冗余未必致命；在 group-relative RL 中，它会直接破坏比较信号。GRPO 希望同一问题的多个 rollout 提供不同决策及不同回报，但如果八条查询只有字符串不同、证据转移相同，组内优势就无法告诉模型哪个检索选择更好。

### 2. 终局奖励只知道“答对没有”，不知道哪一步检索真正有价值

多跳问答经常需要先找到桥接证据，再经实体或事件跳到答案证据。

例如：

- 第 1 步选中一句包含中间实体的证据；
- 第 2 步沿这个实体查到另一段文本；
- 第 3 步才得到最终答案。

第 1 步自身可能几乎不提高答案概率，但它创造了第 2 步的动作机会。只有终局 F1 时，早期桥接动作要经过长链条才能得到信用。

已有工作会增加过程奖励，但作者认为它们仍然绕不开接口问题：只要多个自由文本查询落到同一个检索结果，reward model 再精细，也是在给环境等价的动作评分。

### 3. Graph-RAG 提供结构，但不等于提供适合 RL 的决策接口

图检索系统通常用实体、关系或文本片段组织语料，有利于多跳导航。然而很多图构建方法依赖生成式 LLM 抽取关系，成本高，也可能引入不可审计的结构错误。

Harness-G 选择一个更轻量的方向：

- 不生成事实三元组；
- 不让 LLM 离线抽取关系；
- 只用段落、句子、实体及其可验证的包含或邻接关系；
- 把图首先视为约束动作空间和维护来源关系的 harness，而不是世界知识的完整符号化表示。

这里的图不是额外塞给模型的一大块知识，而是环境组织候选动作、执行确定性转移和追踪信用来源的基础设施。

## ⚠️ 问题与挑战

论文实际要同时解决三个相互关联的问题。

### 1. 如何识别“表面探索、实质坍缩”

只统计查询字符串的 distinct count 会得到错误结论。真正需要比较的是：不同 rollout 的累计证据集合是否仍属于不同的 retrieval-equivalence class。

作者观察到，在 Search-R1 训练中：

- 初期约 86% 的 rollout group 跨越多个检索等价类；
- 到第 30 个训练 step，该比例已降到 10% 以下；
- 同期查询字符串仍保持较高形式多样性。

因此，文本多样性不能作为检索探索的代理指标。

### 2. 如何让检索动作既有限，又不把必要证据排除在外

把自由查询改为菜单选择能减少 aliasing，但也引入新的风险：如果菜单没有包含正确实体或证据句，策略根本无法采取正确行动。

所以环境必须同时做好：

- 初始多通道召回；
- 句子与实体候选构造；
- 实体别名和近义连接；
- 邻接句扩展；
- 重复、已访问和低价值动作过滤；
- 有界菜单与必要 recall 之间的平衡。

### 3. 如何给早期“铺路动作”分配非短视信用

只比较某个动作执行后立即增加了多少答案概率，会偏好已经接近答案的证据，而低估用于打开新 frontier 的桥接实体。

论文因此需要同时回答：

- 当前选中的动作是否优于同状态下的其他可行动作；
- 后续有效动作中，有多少收益是由当前动作创造出来的；
- 如何在不额外采样完整 rollout 的前提下完成这种比较。

## 🔍 核心发现 Finding

### 作者明确声称的发现

作者的首要发现是：

**搜索 RL 的瓶颈不仅是奖励稀疏，还可能是动作表示使不同决策在环境中不可区分。**

具体而言，自由查询存在从字符串到检索结果的多对一映射。训练后期即使 query-form diversity 仍高，retrieval-outcome diversity 也可能已经坍缩。此时：

- 同组轨迹缺少检索层面的反事实；
- 组内回报差异变小；
- 零优势样本增多；
- 偶然出现的回报差异也更可能来自后续回答，而非查询质量。

第二个发现是：

**动作空间设计和信用设计是互补的，但受控实验里动作空间设计贡献更大。**

在 Qwen2.5-3B 的多跳实验中，把自由查询换成菜单、但不增加 SNC，F1 就从：

- 2WikiMultiHopQA：38.04 提高到 62.45；
- HotpotQA：43.84 提高到 61.32；
- MuSiQue：7.65 提高到 43.58。

尤其 MuSiQue 提升超过 35 分。这说明论文的决定性贡献首先是把检索意图变成可辨识的环境动作，而不是给原动作补一个更复杂的奖励。

第三个发现是：

**当动作能被同状态预览与比较后，结构化过程信用才真正有稳定的参照物。**

完整 SNC 在上述三个数据集进一步达到 65.53、65.87 和 46.46 F1。提升比接口重构小，但消融显示 frontier-relative credit 与 delayed enablement credit 都有独立作用。

### 我的理解

这篇论文最值得保留的思想不是“图搜索优于文本搜索”，而是：

**RL 所需要的不是表面上不同的 action token，而是能导致可区分状态转移的 intervention。**

从这个角度看，自由查询的根本问题可以写成：

```text
query string 1 ─┐
query string 2 ─┼─> nearly identical retrieved evidence
query string 3 ─┘
```

策略似乎做了三种选择，环境实际上只执行了一种干预。GRPO 对它们进行组内比较时，自然缺少有效方差。

Harness-G 改成：

```text
Select(sentence A) -> commit A
Select(sentence B) -> commit B
Lookup(entity C)   -> open a new evidence frontier
Answer             -> terminate
```

这些动作的结果由环境定义、可以提前预览，也可以判定两个动作是否导向相同上下文。于是“选 A 还是 B”才成为真正可学习的反事实。

我认为这也给 reward engineering 提醒了一条边界：

> 如果动作接口本身没有保留因果可辨识性，增加更密、更强的 reward 只能更精确地评价已经混叠的结果，不能凭空恢复缺失的反事实。

## 🔬 方法

### 1. 搜索状态

Harness-G 在第 t 步维护状态：

```text
z_t = (q, C_t, U_t, V_t, H_t)
```

其中：

- `q`：问题；
- `C_t`：已经显式提交的证据句；
- `U_t`：当前可见、可供选择的候选句；
- `V_t`：已经访问过的实体；
- `H_t`：动作与环境转移历史。

这里有一个重要区分：

- `C_t` 是策略明确承诺用于回答的证据；
- `U_t` 是环境展示的当前 frontier；
- 训练用评分上下文还可以包含所有曾出现过的证据，但不会把它们全部伪装成策略已经选中的证据。

### 2. 程序化段落—句子—实体图

图包含三类主要节点：

- paragraph node；
- sentence node；
- entity node。

边来自可直接验证的结构：

- 段落与其句子相连；
- 句子与其中提及的实体相连；
- 相邻句子通过局部上下文边相连；

此外，系统为实体添加归一化、标题锚点、缩写和可选 embedding 邻居，用于连接同义或相似实体。

与依赖 LLM 生成关系三元组的 graph-RAG 不同，Harness-G 不要求一个生成模型判断“实体 A 与实体 B 是什么关系”。其构图过程近似线性、可复用，也减少了 API 成本和关系幻觉。

### 3. 多通道初始检索

初始候选由多个检索通道融合，包括：

- paragraph-local retrieval；
- global sentence retrieval；
- entity mention retrieval。

这一步决定了有限菜单的初始 recall。如果重要实体从未进入 frontier，后续 policy 再好也无法选择它，因此作者没有把动作约束简单实现为单路 top-k。

### 4. 有限、类型化、可验证的动作菜单

策略不再输出查询字符串，而是选择菜单中的动作 ID。

主要动作包括：

#### `Select(s)`

把当前可见句子 `s` 加入 committed evidence `C_t`。

#### `Lookup(e)`

沿实体 `e` 打开新的证据 frontier。策略只决定查哪个实体，实际查询由环境确定性构造：

```text
concat(question, committed evidence text)
```

环境在提及该实体、同义实体及邻接扩展得到的句子中检索，top-k 结果成为下一步的 `U_t`。

#### `Answer`

停止搜索，基于已提交证据回答问题。

#### `Answer_With(s1, ..., sk)`

在最终菜单中，可以把若干当前可见句子一起提交并直接回答，减少“正确句子已经可见，但还要机械地多走一步”的开销。

环境同时过滤：

- 重复证据；
- 已访问实体；
- 日期与纯基数词等低价值目标；
- nationality adjective；
- 截断或不稳定别名。

这个设计让每个 action 都具有三种属性：

- **有限**：同一状态只有有界候选；
- **可验证**：非法 ID、重复选择和无效实体可由环境拒绝；
- **可预览**：环境可只读计算该动作将产生的精确转移，而不真正修改状态。

### 5. 冻结 answerer 估计证据的答案价值

SNC 使用冻结的参考回答器，给一组已观察证据 `O` 打分：

```text
g(O) = P_ref(gold answer | question, O)
```

实现中使用 teacher-forced、按答案长度归一化的 gold-answer probability，并在可接受答案别名中取最大值。

对候选动作 `a`，先预览它将加入的上下文，再定义边际增益：

```text
p_t(a) = g(O_t union preview(a)) - g(O_t)
```

冻结 answerer 只在训练时使用；推理时不需要额外 scorer 调用。

### 6. 同状态 frontier-relative credit

环境从当前可行动作构造一个类型分层、结果去重且数量有上限的备选集合 `F_t`。

选中动作的 frontier-relative credit 为：

```text
r_fr(t) = p_t(selected) - mean over a in F_t of p_t(a)
```

它不是问“这个动作有没有用”，而是问：

> 在这个状态下，它是否比当时真正可选的替代动作更好？

如果几个不同 action ID 最终产生相同上下文，它们先按转移结果去重；如果多个动作价值相近，信用也接近零。这样不会因为表面措辞或动作编号不同制造虚假优势。

### 7. 沿 provenance graph 传播 enablement credit

局部增益仍会低估桥接动作。Harness-G 因此记录来源边：如果后续第 `u` 步消费的句子或实体是由第 `t` 步引入的，就建立 provenance edge `(t, u)`。

信用按反向拓扑顺序传播：

```text
R_u    = p_u + gamma * r_en(u)
r_en(t)= sum over child u of R_u / number_of_predecessors(u)
```

论文使用 `gamma = 1`。如果一个后续动作由多个前置动作共同启用，其收益在前驱之间分摊。

最终过程信用为：

```text
r_SNC(t) = r_fr(t) + r_en(t)
```

于是一个早期实体 lookup 即使没有立即提高答案概率，只要它打开了后续高价值证据，也能收到延迟信用。

### 8. 与 GRPO 的结合

终局 outcome reward 使用可接受答案别名上的 token F1，并按 rollout group 归一化。

SNC 没有直接混入 outcome reward，而是：

1. 把每步 SNC 信用分摊给该动作对应的生成 token；
2. 用 batch-global 标准差缩放；
3. 保留符号并进行裁剪；
4. 加到 outcome advantage 上。

```text
A_token = A_outcome + lambda * A_SNC
```

环境观察与检索结果 token 会被 loss mask，只让策略为自己生成的决策 token 负责。

### 9. 训练与实现设置

主要实验使用：

- Qwen2.5-1.5B-Instruct 与 Qwen2.5-3B-Instruct；
- GRPO group size 8；
- batch size 128；
- 120 个训练 step，约等于 3 个数据 pass；
- 最多 6 个搜索 turn；
- verl 训练框架；
- 8 张 A100；
- 完整 3B 实验总计约 170 GPU-hours。

数值稳定措施包括：

- dual clip，`C = 3.0`；
- logits 用 fp32；
- 拒绝非有限梯度；
- answer score clamp；
- credit scaling floor 为 `5e-4`。

SNC 不需要为每个备选动作额外采样完整 rollout，但需要用冻结 answerer 预览菜单动作，训练单步时间增加约 9%–11%。

## 🧪 实验与结论

### 1. 数据集与指标

论文在六个开放域问答基准上评估。

多跳任务：

- 2WikiMultiHopQA；
- HotpotQA；
- MuSiQue。

单跳任务：

- Natural Questions；
- PopQA；
- TriviaQA。

指标包括：

- `EM`：答案精确匹配；
- `F1`：答案 token-overlap F1；
- `R-S`：retrieval similarity；
- `G-E`：generation evaluation。

基线覆盖 Naive Generation、Standard RAG、SFT、R1、Search-R1、IGPO、R1-Searcher、Graph-R1，以及 GraphRAG、LightRAG、PathRAG、HippoRAG2 和 HyperGraphRAG 等 prompt-only graph RAG 方法。

### 2. 六数据集主结果

在 Qwen2.5-1.5B 上：

| 方法 | 平均 EM | 平均 F1 | 平均 R-S | 平均 G-E |
|---|---:|---:|---:|---:|
| Graph-R1 | 31.90 | 40.09 | 59.35 | 64.38 |
| Harness-G | **43.10** | **50.83** | **64.53** | **73.07** |

平均 F1 提升 10.74 分。

在 Qwen2.5-3B 上：

| 方法 | 平均 EM | 平均 F1 | 平均 R-S | 平均 G-E |
|---|---:|---:|---:|---:|
| Graph-R1 | 42.45 | 51.26 | 60.19 | 72.99 |
| Harness-G | **47.14** | **55.24** | **64.55** | **77.44** |

平均 F1 提升 3.98 分。

3B 模型在三个多跳任务上的提升尤其明显：

- 2WikiMultiHopQA：57.56 → 65.53，`+7.97`；
- HotpotQA：56.75 → 65.87，`+9.12`；
- MuSiQue：40.51 → 46.46，`+5.95`。

三个多跳任务平均提升 7.68 F1。单跳任务的优势较小，其中 NQ 上 Harness-G 为 42.91，低于 Graph-R1 的 44.75；这与“结构化导航主要帮助多跳桥接”的机制预期一致，而不是所有任务无条件获益。

### 3. 受控的接口 × 信用析因实验

这是全文最关键的实验，因为它把“动作菜单”和“SNC 信用”拆开比较。

| 接口 | 信用 | 2Wiki F1 | Hotpot F1 | MuSiQue F1 |
|---|---|---:|---:|---:|
| Free query | None | 38.04 | 43.84 | 7.65 |
| Menu | None | 62.45 | 61.32 | 43.58 |
| Free query | IGPO | 42.81 | 48.52 | 12.18 |
| Menu | IGPO | 63.58 | 62.74 | 44.71 |
| Menu | SNC | **65.53** | **65.87** | **46.46** |

可以得到三点：

1. 不加过程信用，仅替换接口就产生巨大提升；
2. IGPO 在自由查询上有帮助，但无法修复 retrieval aliasing；
3. SNC 在结构化菜单上继续提升，说明好的 credit 仍有价值，但前提是动作具有可比较的环境含义。

### 4. SNC 消融

| 变体 | 2Wiki F1 | Hotpot F1 | MuSiQue F1 |
|---|---:|---:|---:|
| Full SNC | **65.53** | **65.87** | **46.46** |
| 去掉 enablement | 63.42 | 63.65 | 45.32 |
| 去掉 frontier comparison | 64.22 | 63.57 | 46.02 |
| 不使用 SNC | 62.45 | 61.32 | 43.58 |

两个部分都有效：

- frontier comparison 负责同状态相对优劣；
- enablement 负责跨步骤的桥接贡献。

完整 SNC 始终最好，但不同数据集对两类信用的敏感度不同。

### 5. 检索多样性与零优势轨迹

在 Search-R1 中，同一 rollout group 跨越多个 retrieval-equivalence class 的比例从约 86% 快速降到 10% 以下。

在匹配可行动作和环境转移的受控比较中，菜单接口更能保持 retrieval-distinct outcomes。Harness-G 的 zero-advantage rate 在约第 10 步降到 23% 左右，后期虽有回升，但分析显示主要来自组内样本都回答正确，而不是像自由查询那样大量全错或检索等价。

这一区分很重要：

- 全错导致的零优势意味着探索失败；
- 全对导致的零优势意味着任务已趋于收敛。

### 6. 稳定性、模型与 RL 算法泛化

六个 3B 训练运行中，F1 均持续提高，没有出现持久的后期坍缩，梯度范数保持有界。

在 HotpotQA 的匹配设置下：

| Backbone | F1 | EM | G-E |
|---|---:|---:|---:|
| Qwen2.5-3B | 65.9 | 59.4 | 78.5 |
| Qwen3.5-4B | **67.5** | **61.2** | **79.8** |
| Llama-3.2-3B | 63.4 | 56.6 | 75.9 |

Harness-G 也能与 GRPO、PPO、REINFORCE++ 和 DAPO 配合，说明主要收益不是绑定某一个 policy optimizer；在报告设置里 GRPO 略优于 DAPO。

### 7. 跨数据集与专业领域迁移

在 train-one/evaluate-other 的 30 个 off-diagonal 设置中，Harness-G 赢得 21 个，平均 OOD F1 从 Graph-R1 的 44.10 提高到 47.38，即 `+3.29`。

在 Medicine、Agriculture、Computer Science、Legal 和 Mix 五个专业领域零样本测试上：

- Graph-R1：平均 F1 39.14；
- Harness-G：平均 F1 42.30；
- 提升 3.16 分。

论文中最强的 prompt-only 参考 HyperGraphRAG 为 38.61，Harness-G 高 3.69 分。

迁移结果支持这样一个解释：有限动作菜单学到的是较通用的证据选择与图导航规则，而不是只记住某个数据集的查询措辞。

### 8. 效率

图构建不调用生成式 LLM。2Wiki 语料上的报告规模约为：

- 242K 节点；
- 763K 边；
- 每 1K corpus token 构图约 0.12 秒；
- 每个 query 约 5.1 秒。

在训练后期，Harness-G 平均使用 3.6 个 turn，高于 Search-R1 的 2.3 和 Graph-R1 的 2.9；但 response-side token 约为 2.5K，低于二者的 4.3K 和 3.1K。

这说明它并非单纯通过“更早停止”获得效率，而是用更多短而结构化的决策代替较长的自然语言查询与推理。

### 9. 作者结论与证据边界

论文的实验充分支持以下结论：

- 自由查询的形式多样性会掩盖检索结果坍缩；
- 有限动作菜单能显著恢复检索层面的决策对比；
- SNC 能在此基础上进一步改善同状态选择与跨步信用；
- 方法对多跳任务的帮助大于单跳任务；
- 接口重构是主要增益来源，SNC 是补充增益来源。

但实验没有证明：

- 所有开放网络搜索都应取消自由查询；
- 任意知识图都会比文本检索更好；
- SNC 可以在没有训练答案标签时原样使用；
- 当前结果已经覆盖超长 horizon、动态图或多模态环境。

## 🚧 局限与批判性分析

### 1. 有限菜单把 query aliasing 换成了 candidate recall 风险

自由查询允许策略创造新的检索表达，而菜单只能选择环境已经暴露的句子或实体。如果初始召回、实体识别、别名归一化或邻接扩展漏掉关键桥梁，正确动作就不在可行集合中。

因此 Harness-G 更准确的能力边界是：

> 在环境能够构造高 recall frontier 的前提下，学习更可辨识的选择策略。

它没有消除检索瓶颈，而是把瓶颈从查询生成转移到了候选生成。

### 2. SNC 依赖 gold answer 和白盒概率

训练评分函数使用 gold answer 的 teacher-forced likelihood。这要求：

- 训练数据有答案标签及别名；
- 冻结 answerer 能输出可用的 token probability；
- 概率变化能代表证据价值。

在开放式研究报告、无唯一答案任务或只能调用黑盒模型的环境中，这套 credit 不能直接照搬。

### 3. 当前评估仍是固定语料 QA

六个主数据集和专业领域测试都属于文本问答。论文没有覆盖：

- 动态开放网页；
- 页面失效与时间敏感信息；
- 搜索、浏览、代码执行混合工具；
- 多模态证据；
- 长篇报告中的主张级引用完整性。

作者也明确把多模态扩展列为未来工作。

### 4. 图是低成本的，也会继承实体管线偏差

relation-free graph 避免了 LLM 关系幻觉，但依赖实体识别、归一化和 mention matching。它可能不擅长：

- 没有清晰命名实体的因果或程序性问题；
- 跨语言别名；
- 隐式关系和语用指代；
- 需要数字、日期等恰被动作过滤器降权的推理。

“没有生成式 LLM”降低了成本，并不代表图结构没有误差。

### 5. 训练尺度与 horizon 仍有限

主实验集中在 1.5B、3B 模型和最多 6 个 turn。虽然补充实验覆盖 Qwen3.5-4B 与 Llama-3.2-3B，但尚不能确定：

- 更强模型是否仍会发生同等程度的 collapse；
- 更大菜单上的 preview 成本如何增长；
- 数十步以上的 provenance credit 是否仍稳定；
- 长 horizon 下环境约束是否会过早限制探索。

### 6. 评价以自动指标为主

论文同时报告 EM、token F1、检索相似度和生成质量，比只看答案 F1 更完整。但没有系统的人类评估；token F1 仍可能低估语义正确的改写，自动 generation evaluator 也可能带来偏差。

## 🔗 与 Harness-1 的关系

Harness-G 与 Harness-1 共享一个更大的观点：

**harness 不是模型外面的工程壳，而是 agent 学习问题的组成部分。**

两篇论文解决的切面不同：

| 论文 | 主要问题 | 环境外置的内容 | 策略保留的决策 |
|---|---|---|---|
| Harness-1 | 模型反复从长轨迹恢复搜索状态 | 候选池、证据集、验证记录、轻量关系图、预算 | 搜索、筛选、验证、停止 |
| Harness-G | 自由查询字符串不同但检索转移等价 | 动作菜单、确定性查询、图导航、校验、去重、来源图 | 选句子、选实体、回答 |

可以把二者概括为两类认知卸载：

- Harness-1 外置 **state bookkeeping**；
- Harness-G 外置 **action realization**。

前者让策略不必从原始 transcript 重建状态，后者让策略不必用高别名度的自然语言实现检索意图。

## 💡 对搜索 Agent 设计的启示

### 1. 先测 outcome diversity，再测语言 diversity

评估 exploration 时，不应只统计：

- distinct query；
- 编辑距离；
- embedding diversity。

还应统计：

- 检索集合 Jaccard；
- 累计证据集合的等价类数；
- 相同状态下可区分转移的数量；
- 全错、全对和环境等价分别导致的 zero-advantage rate。

### 2. Reward 之前先审计 action semantics

如果一个 agent 的多个 action 会被工具层归一化为同一转移，优先问题可能不是 reward 不够密，而是 action space 不可辨识。

可以先做一个最小析因实验：

```text
自由动作 + 终局奖励
结构化动作 + 终局奖励
自由动作 + 过程奖励
结构化动作 + 过程奖励
```

Harness-G 的结果说明，这种 `interface × credit` 对照比只比较两个 reward 更能定位增益来源。

### 3. 环境动作应当可预览、可验证、可去重

好的 agent action 不一定必须是自然语言。对于数据库、代码仓库、证据集合或视觉区域，环境都可以提供：

- 有界候选；
- 稳定 ID；
- 执行前 preview；
- 合法性检查；
- 按结果而不是按字符串去重。

这会为 credit assignment 提供更可靠的反事实单位。

### 4. 区分“当前有用”与“使后续成为可能”

搜索、代码调试和视觉检查都存在 enablement action：它本身不直接提高终局答案，却打开了下一步。

Harness-G 的 provenance graph 提供了一个通用模板：

- 记录每个新观察由哪个动作产生；
- 记录后续动作消费了哪些观察；
- 把后续收益按依赖边归还给前驱；
- 避免只奖励最后一跳。

## 📚 关键术语

### Retrieval-equivalence collapse

同一问题的 rollout 仍生成不同查询字符串，但累计检索证据逐渐落入少数相同等价类的现象。它导致组内优化缺少检索层面的有效对比。

### Retrieval aliasing

多个表面不同的自然语言查询映射到相同或高度重叠检索结果的多对一关系。

### Graph-structured harness

以段落—句子—实体图组织候选、状态转移、动作验证和来源追踪的环境层。图的作用不仅是存知识，更是定义 agent 的可行动作。

### Finite action menu

环境根据当前状态提供的有界、类型化动作集合。策略选择 action ID，而不是自由生成查询字符串。

### Previewable transition

环境在不改变实际状态的前提下，确定性计算某个动作将产生的证据和下一状态。它让同状态反事实比较成为可能。

### Frontier-relative credit

选中动作的边际答案增益相对于同状态可行备选动作平均增益的差值。

### Enablement credit

沿 provenance graph 把后续动作收益传播给创造该动作机会的早期桥接动作。

### Structured Non-myopic Credit（SNC）

由 frontier-relative credit 与 enablement credit 组成的结构化过程信用。它既比较当前备选，也考虑跨步骤的延迟贡献。

### Provenance graph

记录“哪个动作产生了哪些句子或实体，以及哪些后续动作消费了它们”的依赖图，用于非短视信用传播和轨迹审计。

### Zero-advantage group

同组 rollout 回报相同，组内归一化后优势为零的样本组。它可能来自全错、全对，也可能来自动作经环境映射后实质等价，三者需要分别诊断。

## ✅ 一句话总结

Harness-G 证明，搜索 RL 中“查询写得不一样”并不等于“检索决策不一样”；通过把自由查询重构为图上的有限可验证动作，再对同状态替代项和跨步依赖分配信用，策略才获得真正可比较的检索干预，而实验也清楚显示：**先修动作接口，再加过程奖励，比只在混叠的自由查询上继续堆 reward 更有效。**
