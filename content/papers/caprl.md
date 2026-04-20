---
title: "CapRL: Stimulating Dense Image Caption Capabilities via Reinforcement Learning"
date: 2026-04-20T20:20:04+08:00
draft: false

# 分类（研究领域）
categories: ["计算机视觉"]

# 会议/期刊
venues: "ICLR 2026"

# 论文元数据
authors: ["Long Xing", "Xiaoyi Dong", "Yuhang Zang", "Yuhang Cao", "Jianze Liang", "Qidong Huang", "Jiaqi Wang", "Feng Wu", "Dahua Lin"]
year: "2025"
paper_url: "https://arxiv.org/abs/2509.22647"
arxiv_url: "https://arxiv.org/pdf/2509.22647"
code_url: "https://github.com/InternLM/CapRL"

# 阅读状态
status: "completed"
rating: 5
read_date: "2026-04-20"

summary: "CapRL 尝试把 RLVR 从有标准答案的任务扩展到开放式 image captioning。它把 caption 质量重新定义成“是否足以支撑一个不看图的 LLM 仅凭 caption 回答图像相关多选题”，并据此设计了解耦两阶段 reward。结果显示，CapRL-3B 在 Prism 评价下逼近 Qwen2.5-VL-72B，还能生成 CapRL-5M 高质量 caption 数据，在 12 个预训练 benchmark 上持续优于 ShareGPT4V-1M 和 DenseFusion-1M。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文想解决的是一个看起来很简单、但其实一直没被真正解决的问题：**怎么训练一个会写“高质量图像描述”的模型，而不是只会复述 teacher 风格或记住 ground-truth 答案的 caption model。**

Image captioning 是视觉和语言之间最基础的桥梁任务。它的价值不只是“给图片配一句话”，而是会直接影响：

- LVLM 预训练里的模态对齐质量；
- 文档、图表、信息图等细粒度视觉理解；
- 下游 VQA、OCR、视觉推理的上游表示质量。

但当前最强的 caption model 大多还是靠 **SFT（Supervised Fine-Tuning）**。SFT 的问题也很明显：

- 数据昂贵，往往依赖人工或 proprietary model 标注；
- 每张图通常只有单一参考描述；
- 模型容易记住“应该怎么写这句话”，而不是学会“应该抓住图里的哪些关键信息”。

所以作者提出了 **CapRL（Captioning Reinforcement Learning）**。  
它的核心想法很巧：

**与其直接问“caption 写得好不好”，不如问“如果一个只看文字、不看图片的 LLM 只拿到这段 caption，它还能不能答对和这张图有关的问题？”**

也就是说，CapRL 不是把 caption 质量定义成“像不像人工标注”，而是定义成 **utility**：

- 高质量 caption 应该足够准确、足够密集；
- 以至于一个纯文本 LLM 仅凭 caption 就能回答关于图像的 MCQ。

这就把一个原本主观的任务，重新转成了一个可以做 RLVR 的客观代理任务。

## 🎯 研究背景

这篇论文站在两个方向的交叉点：

- **Image Captioning / Dense Captioning**：需要模型输出完整、准确、信息密集的描述，而不是一句泛化总结。
- **RLVR（Reinforcement Learning with Verifiable Rewards）**：在数学、代码、选择题等任务中，RLVR 已经证明比 SFT 更能激发探索和泛化。

问题在于，captioning 恰好卡在这两者中间：

- 它很适合做“探索式优化”，因为一张图往往有很多种合理描述；
- 但它又不像数学题那样有标准答案 verifier。

作者在引言里对比了几种已有路线：

1. **Reference-based reward**：比如 BLEU、ROUGE  
   这类指标只看字面重叠，长 caption 和复杂 caption 很容易被低估。

2. **Reward model / LVLM-as-a-judge**  
   这类方法更灵活，但非常容易 reward hacking。模型可能学会写得特别短，或者写得特别冗长，只是为了讨好 judge 的偏好。

3. **SFT on synthetic captions**  
   这类方法虽然强，但依然是“模仿固定答案”，不是真正优化“这段描述有多有用”。

于是论文真正的出发点是：**如果我们不能直接评价 caption 的“美感”或“唯一正确性”，那能不能评价它的“信息可用性”？**

## ⚠️ 问题与挑战

论文要解决的问题是：**如何为开放式 image captioning 设计一个足够客观、足够稳定、又不容易被模型 exploit 的 reward。**

这个问题之所以难，不是因为 captioning“主观”这么简单，而是因为有几层因果矛盾：

### 1. 因为一张图有很多合理描述，所以没有单一 ground truth

同一张图可以有：

- 更偏对象枚举的描述；
- 更偏空间关系的描述；
- 更偏叙述化总结的描述；
- 更偏文档/OCR 信息提取的描述。

因此你很难说某一条 caption 是唯一正确答案。  
如果还是用单一 reference 做监督，模型更容易学会模仿 phrasing，而不是提高视觉感知。

### 2. 因为整体打分太粗，所以 reward model 很容易被 exploit

作者展示了两种典型失败：

- **UnifiedReward-as-Judge** 倾向偏好短 caption，导致训练后模型输出越来越短，最后甚至塌到只剩下类似 `:description` 这样的退化形式；
- **Qwen2.5VL-as-Judge** 则偏好冗长 caption，导致模型开始生成和图像无关的长篇大论。

这说明：因为 judge 有内在偏差，所以如果 reward 只是一个 holistic 分数，模型就会优化 judge 的偏好，而不是优化 caption 质量本身。

### 3. 因为 caption 的价值在于“能不能支撑后续理解”，所以 reward 应该围绕 downstream utility 而不是表面文本形式

一段 caption 只要做到：

- 把图中关键对象说出来；
- 把关系、属性、文字信息说出来；
- 不产生 hallucination；

那么一个不看图的 LLM 就应该能基于这段描述回答问题。  
反过来，如果 LLM 不能靠它答题，说明这段 caption 可能漏了关键信息。

所以论文真正难的地方，在于：

**怎么把 caption 的“可用性”变成一个可验证、可重复、低方差的 reward。**

### 4. 因为 QA 本身也可能泄露信息，所以 reward 数据必须严格过滤

如果问题本身就可以不看图直接答对，或者问题能靠世界知识瞎猜出来，那 reward 就失真了。  
因此作者必须额外做 QA curation，确保：

- 带图能答；
- 不带图答不出来；

只有这样，caption reward 才真正逼着模型提供视觉信息，而不是利用问题本身的提示。

## 🔍 核心发现 Finding

### 作者明确声称

作者的关键发现是：**caption 的质量可以通过它对“无图 LLM 回答图像问题”的支撑能力来客观衡量，这种 utility-based reward 可以把 RLVR 引入 image captioning。**

### 我的理解

我认为这篇论文真正有价值的 `Finding` 不是“把 caption 转成 QA 任务”这个技巧本身，而是它背后的视角变化：

**caption 的本质不是一段“漂亮的文字”，而是一种压缩后的视觉信息接口。**

这和很多传统 caption 工作的默认设定不同。  
传统设定通常隐含地认为：

- caption 越像人工标注越好；
- 文本越自然越好；
- 和参考答案越接近越好。

CapRL 则换了一个完全不同的角度：

- caption 的真正价值，不在于像不像某条 reference；
- 而在于它有没有把图像里的关键可回答信息保留下来。

这为什么重要？因为它把一个主观任务变成了一个功能性任务：

- 以前：caption 是“语言输出”；
- 现在：caption 是“给下游模型用的视觉信息载体”。

一旦这样看问题，reward 就自然可以重新定义成：

- 如果 caption 让文本 LLM 可靠答对问题，它就是好 caption；
- 如果 caption 不能支持答题，它再优雅也没用。

这正是 CapRL 能解决前面挑战的原因：  
它不是在评审 caption 文风，而是在评审 caption 是否真正携带了图像知识。

举个非常直观的例子：

- 一张图里如果有“红色飞盘”和“草地上的孩子”；
- 参考答案可能只写了“孩子在玩耍”；
- 但一个更有用的 caption 会明确说出“一个孩子在草地上玩红色飞盘”。

这种 caption 未必更像某条 reference，但它更能支撑问题 “What color is the frisbee?”。  
CapRL 的 insight 就是：**这种“是否对后续任务有用”的属性，比“是否像参考答案”更适合当 reward。**

## 🔬 方法

### 整体框架

CapRL 是一个 **decoupled two-stage pipeline**：

1. **Stage 1**：LVLM 生成 caption；
2. **Stage 2**：把 caption 和与该图像相关的 MCQ 一起交给一个不看图的 LLM，由其答题准确率作为 reward。

这套设计的关键，是把“视觉感知”和“文本推理/验证”拆开了。

### Reward 设计

给定图像和指令，policy model 先生成一组 candidate captions。  
然后对每条 caption：

1. 抽取与该图像绑定的一组 MCQ；
2. 把 caption 和 MCQ 交给一个纯文本 LLM；
3. 用 exact match 判断答案是否正确；
4. 对多个问题、多个采样轮次求平均，得到最终 reward。

作者这样做有几个好处：

- **可验证**：MCQ 有标准答案，exact match 很清晰；
- **稳定**：多轮采样和选项打乱，减少文本 LLM 的选项偏差；
- **尊重 caption 自由度**：reward 不要求某种固定格式，也不要求中间 CoT。

论文里默认用 **Qwen2.5-3B-Instruct** 做 answerer，这样 reward 计算成本也比较低。

### QA Curation

为了保证 reward 真有意义，作者做了一个三阶段 QA curation pipeline：

1. **收集多样化图像**：自然图像、图表、文档等；
2. **让 Qwen2.5-VL-72B 生成每张图的多个 QA**；
3. **做严格 QA filtering**：
   - 带图能答对；
   - 不带图时答不出来；

在官方 README 里，作者还给了更具体的工程阈值：

- 每张图先生成 `5` 个 QA；
- 过滤时保留 `visual acc > 0.75` 且 `text acc < 0.25` 的 QA。

这一步特别关键，因为它让 reward 真正来源于“caption 是否补足视觉信息”，而不是来源于问题文字本身。

最终，论文保留了大约 **75K** 张图及其对应 QA，用于 GRPO 训练。

### RL 训练

训练算法使用 **GRPO**。  
流程上，CapRL 并不复杂：

1. 输入图像；
2. 采样多条 caption；
3. 对每条 caption 计算 QA-based reward；
4. 组内归一化，得到 advantage；
5. 加上 KL penalty，更新 policy。

重要的是，CapRL 不需要像 DeepSeek-R1 那样设计格式化思考过程奖励。  
因为 reward 是直接从 caption 本身算出来的，不依赖中间 reasoning 格式。

### CapRL-5M 数据集

训练出 CapRL-3B 后，作者反过来把它当作 caption annotator，去标注 **5M** 张图像，构造 **CapRL-5M** 数据集。

这些图像来源包括：

- ShareGPT4V-1M
- DenseFusion-1M
- 以及作者自行收集并过滤的 3M web images

然后再用这些 captions 去做多模态预训练，验证 “更好的 captioner 能不能真正造出更好的预训练数据”。

这一步很有意思，因为它让 CapRL 不只是一个后训练 captioner，而是变成了一个 **data engine**。

## 📊 实验与结论

### 主结果一：CapRL-3B 在 Prism 评价下逼近 Qwen2.5-VL-72B

在 Prism Framework 下，作者直接比较 caption 质量对后续 Decoupled VQA 的支撑能力。

| Caption Model | Average |
|---|---:|
| Qwen2.5-VL-3B | 39.9 |
| Qwen2.5-VL-7B | 44.9 |
| Qwen2.5-VL-72B | 48.3 |
| UnifiedRW-as-Judge-3B | 38.4 |
| Qwen2.5VL-as-Judge-3B | 42.5 |
| **CapRL-3B** | **48.3** |

也就是说，**CapRL-3B 平均分已经追平 Qwen2.5-VL-72B**，而且相对 3B baseline 平均提升 **8.4 个点**。

更细地看：

- ChartQA: `27.1 -> 39.9`
- InfoVQA: `40.2 -> 64.8`
- MMStar: `46.4 -> 55.0`

这说明 CapRL 的提升不是只体现在一种图片类型上，而是横跨：

- 图表；
- 信息图；
- 文档；
- 自然图像；

都有明显收益。

### 主结果二：CapRL 比现有的 LVLM-as-a-Judge reward 更稳，也更难被 hack

这是论文里非常关键的一组对比。

作者发现：

- `UnifiedReward-2.0-qwen-3b` 由于训练时见过太多短 caption，会偏好短输出；
- 训练过程中，policy caption 会越来越短，最后甚至崩成退化输出；
- 而 `Qwen2.5-VL-3B-as-judge` 又会反向偏好冗长输出，导致模型生成大量无关内容来讨好 judge。

CapRL 则绕开了这个问题。  
它不再问“judge 喜不喜欢这段 caption”，而是问“caption 是否真的让文本 LLM 答对问题”。

所以作者的结论很明确：

**LVLM-as-a-Judge reward 本质上不可靠，而 utility-based QA reward 更接近真正客观的 caption 质量。**

### 主结果三：用 CapRL-annotated captions 预训练，12 个 benchmark 全面优于现有 caption 数据集

在预训练设置里，作者比较了：

- Vanilla
- ShareGPT4V-1M
- DenseFusion-1M
- CapRL-1M
- CapRL-5M

在 `Qwen2.5-3B + Qwen2.5-ViT` 设定下：

- Vanilla 平均 `55.5`
- ShareGPT4V-1M 平均 `56.7`
- DenseFusion-1M 平均 `57.1`
- CapRL-1M 平均 `59.7`
- **CapRL-5M 平均 `62.0`**

而且在一些文档/图表 benchmark 上收益很明显：

- InfoVQA: `49.4 -> 61.5`（相对 DenseFusion-1M）
- DocVQA: `84.6 -> 90.0`
- ChartQA: `74.4 -> 80.5`

作者还指出，在 natural image benchmark 上也有提升：

- MMStar 比 ShareGPT4V-1M 高 `+1.6`
- MMBench 比 ShareGPT4V-1M 高 `+1.8`

这说明 CapRL 造出来的数据，不只是对文档和图表有用，对一般视觉理解也有帮助。

### 主结果四：CapRL 的优势主要来自 caption 质量，而不是图像来源运气更好

这是一个很重要的控制实验。

作者把图像集合固定住，只替换 caption 来源，比较：

- ShareGPT4V-1M vs CapRL-ShareGPT4V-1M
- DenseFusion-1M vs CapRL-DenseFusion-1M

结果显示，在相同图像下：

- CapRL 标注后的版本平均还能再赢 **2%+**

这直接支持了作者的核心论点：

**CapRL 的优势不是来自挑了更好的图片，而是来自它确实生成了更高质量、更有用的 captions。**

### 主结果五：CapRL 有明显的 scaling trend，而且只需要稀疏 QA 监督

论文还做了两组非常实用的 ablation。

#### 1. QA 数量

在只用 `20k` 图训练时：

- 1QA: 平均 `48.0`
- 2QA: 平均 `48.5`
- 3QA: 平均 `48.5`

也就是说，**哪怕每张图只有 1 个 QA，性能也已经比 baseline 高很多，只比 2QA 低 0.5**。  
这说明 CapRL 的 supervision 非常稀疏但仍然高效。

#### 2. Sampling rounds

- `N=1`: `47.3`
- `N=2`: `47.6`
- `N=4`: `48.4`
- `N=8`: `48.3`

作者的解释是：

- `N=1` 时，选项顺序偏差太大，reward 噪声高；
- 提到 `N=4` 后已经接近饱和；
- 再继续加采样，收益很有限。

这说明 CapRL 在工程上也比较友好：  
**不需要非常重的多轮问答，就能把 reward 做得足够稳定。**

### 主结果六：CapRL 训练出来的 captioner 还有很强的跨域泛化

作者做了一个我觉得很有意思的实验：

- 只用 document/chart 类图像训练；
- 或者只用 natural image 训练；

结果两者都能在 out-of-domain benchmark 上明显超过 baseline。  
这意味着 CapRL 学到的不是“某个领域固定模板”，而是更通用的 caption quality 提升方式。

### 结论

这篇论文最后说明了三件事：

1. **Image captioning 虽然是开放任务，但只要把质量定义成“是否支持后续问答”，它就能被重新转写为 RLVR 问题。**
2. **比起参考答案相似度或 LVLM judge，总体 utility-based reward 更客观、更稳。**
3. **一个更强的 captioner 不只是后训练更强，还能反过来生成更好的预训练数据，形成正向循环。**

如果用一句更口语的话总结：

**CapRL 的关键不是判断“这段 caption 像不像好答案”，而是判断“这段 caption 有没有真正把图像信息留下来”。**

## 🧠 关键术语

- **RLVR（带可验证奖励的强化学习）**：依靠可自动验证的奖励信号训练模型。例子：数学题答对得分、代码通过测试得分。
- **Utility-based Reward（基于效用的奖励）**：不看 caption 是否像参考答案，而看它是否有助于完成下游任务。例子：只看 caption，文本 LLM 还能不能答对图像相关问题。
- **Decoupled Two-Stage Pipeline（解耦两阶段流程）**：先生成 caption，再用 caption 支撑问答并计算 reward。例子：Stage 1 看图写描述，Stage 2 不看图只看描述答题。
- **Prism Framework**：把 caption evaluation 转成 decoupled VQA 的评测框架。例子：如果 caption 足够完整，LLM 就能只靠 caption 回答 ChartQA / InfoVQA / MMMU 里的问题。
- **QA Curation（问答筛选）**：过滤掉不需要图像就能回答的问题，确保 reward 真的来自视觉信息。例子：保留 `visual acc > 0.75` 且 `text acc < 0.25` 的 QA。
- **Catastrophic Forgetting（灾难性遗忘）**：微调后模型丢掉原有能力。例子：SFT 让 caption 更像 teacher，但文档理解和 OCR 能力反而下降。
- **Reward Hacking（奖励黑客）**：模型学会讨好 reward，而不是真提升能力。例子：为了讨好短 caption judge，只输出极短模板；或为了讨好 verbose judge，写一堆与图像无关的话。
- **CapRL-5M Dataset**：用 CapRL-3B 重标注 5M 图像得到的大规模 caption 预训练数据。例子：在 ShareGPT4V-1M、DenseFusion-1M 和 3M web images 上自动生成更高质量描述。

## 💭 个人评价

### ✅ 优点

- **问题抓得非常准**：它不是再做一个更会模仿 teacher 的 captioner，而是直接定义了 captioning 的新优化目标。
- **reward 设计很聪明**：把主观 caption 评价绕到“是否支持答题”的客观代理任务上，既稳定又可扩展。
- **实验链条完整**：既验证 caption 质量，又验证数据集价值，还做了 scaling、稀疏监督和 reward 设计对比。
- **产业价值高**：CapRL-3B 这种轻量模型就能造出比现有 caption 数据更好的预训练数据，成本收益比很高。

### ⚠️ 局限

- **reward 仍然是代理目标**：能答对 MCQ 不等于 caption 在所有用途上都最优，比如美感、叙事性、风格控制。
- **QA 质量仍然是系统上限**：如果问答生成和过滤做得不好，reward 也会偏。
- **依赖额外问答流程**：相比直接 lexical reward，训练链条更长、更复杂。
- **对极长、非常开放的主观 caption 任务是否依然稳健，还需要更多验证。**

### 💡 启发

- 对开放任务做 RL，不一定要直接评价“答案本身好不好”，可以转而评价“它对下游任务有没有用”。
- 很多看似主观的视觉语言任务，也许都能通过“任务化代理”变成 RLVR。
- 这篇论文也提示一个更普遍的方向：**高质量数据生成器本身可以通过 RL 训练出来，而不一定必须依赖最大的 proprietary model。**

## 🔗 相关论文

- ShareGPT4V
- DenseFusion
- Prism Framework
- RubiCap: Rubric-Guided Reinforcement Learning for Dense Image Captioning
- DeepSeek-R1 / RLVR 在数学与代码任务上的工作

---

**阅读时间**：约 3 小时  
**推荐指数**：⭐⭐⭐⭐⭐  
**适合读者**：计算机视觉、视觉语言模型、image captioning、RL 后训练、多模态预训练数据构建方向研究者

**一句话总结**：CapRL 的真正贡献不是“把 captioning 也拿来做 RL”，而是把 caption 的价值重新定义为“是否足够有用，能让纯文本 LLM 仅凭 caption 回答图像问题”，从而把一个开放主观任务转成了可验证、可扩展、还能反向造数据的 RL 训练问题。  
