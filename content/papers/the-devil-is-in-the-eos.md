---
title: "The Devil is in the EOS: Sequence Training for Detailed Image Captioning"
date: 2026-04-21T16:44:42+08:00
draft: false

# 分类（研究领域）
categories: ["计算机视觉"]

# 会议/期刊
venues: "COLM 2025"

# 论文元数据
authors: ["Abdelrahman Mohamed", "Yova Kementchedjhieva"]
year: "2025"
paper_url: "https://arxiv.org/abs/2507.20077"
arxiv_url: "https://arxiv.org/pdf/2507.20077"
code_url: ""

# 阅读状态
status: "completed"
rating: 4
read_date: "2026-04-21"

summary: "这篇论文提出一个很反直觉的观点：详细图像描述能力并不一定需要额外监督数据或复杂 reward，很多时候它早就潜伏在预训练 VLM 里，只是被 EOS token 偏置压住了。作者通过 sequence training 直接压低 EOS 的提前预测概率，在 BLIP-2 和 PaliGemma 上显著拉长 caption、提高 CAPTURE 和检索表现，并在可接受的 hallucination 代价下逼近专门为 dense captioning 训练的 TinyLLaVA。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文想解决的问题很具体：**为什么很多视觉语言模型明明“看得见”，却总是只说一句很短、很泛的 caption？**

比如一张复杂图片里可能有：

- 前景主体；
- 背景环境；
- 多个属性；
- 空间关系；
- 场景氛围；

但基础 caption model 往往只会给出类似：

- “A person standing outside.”
- “A dog on the grass.”

这种短而泛的描述。

直觉上，大家往往会说：要想让模型写得更详细，就得：

- 收集更长、更密集的人工 caption；
- 或者用更强的 teacher model 造详细数据；
- 或者设计复杂 reward / RL 流程。

这篇论文的核心主张恰恰相反：

**问题不一定出在“模型不会详细描述”，而可能出在“模型太早停了”。**

作者认为，在标准交叉熵训练和 teacher forcing 下，模型会学到一种对 **EOS（end-of-sequence）token** 的偏置：它过早地认为“该结束了”。于是，本来可能已经学到的细节描述能力，被提前终止的生成过程压制住了。

所以他们提出一个非常简单的无监督方法：  
**用 sequence training 直接压低 EOS token 的生成倾向，让模型不要太早结束。**

## 🎯 研究背景

这篇工作位于两个研究方向之间：

- **Vision-Language Modeling**：像 BLIP-2、PaliGemma 这类 VLM 已经具备很强的视觉编码和语言生成能力。
- **Detailed / Dense Image Captioning**：近年来，评测从 COCO 这类短 caption 逐渐扩展到 FineCapEval、DCI、DOCCI 这种更强调细粒度和场景完整性的基准。

此前改进 detailed captioning 的路线大致有两类：

1. **Fully supervised methods**
   用人工长 caption 或闭源大模型合成 caption 做监督。

2. **Weakly supervised methods**
   用 QA 系统、检索系统、CLIP 奖励等作为外部 reward，做 sequence training 或 RL。

这些方法都有效，但代价也很明显：

- 要么依赖昂贵的长 caption 数据；
- 要么依赖额外 reward model；
- 要么 reward hacking 风险高；
- 要么强依赖 reference wording。

作者的背景判断是：  
**如果基础 VLM 其实已经从大规模视觉-语言预训练中学到不少细节知识，那也许不需要再“教它新东西”，而是只需要解除一个让它过早停止的训练偏置。**

## ⚠️ 问题与挑战

论文要解决的问题是：**如何在不引入额外监督数据和复杂 reward 的情况下，让预训练 VLM 产出更详细的 caption。**

这个问题难，不是简单一句“模型偏好短句”就能说清，而是有几层因果关系：

### 1. 因为多模态 finetuning 数据普遍更短、更窄，所以模型会把“短文本分布”学成默认输出模式

作者指出，VLM 的语言骨干最初来自大规模文本预训练，本来具备丰富语言能力；但在多模态阶段，它看到的 caption 往往短得多、分布也窄得多。  
于是模型学到的不是“怎么更完整地描述”，而是“视觉任务通常到这里就该结束”。

### 2. 因为 teacher forcing 中每条训练 caption 都带 EOS，所以模型会形成“长度计数器”式偏置

这篇论文借鉴了关于 EOS 的已有理论：EOS token 不只是一个普通 token，它还会隐式让模型学会“生成到这个长度附近就结束”。  
因为在训练数据里，每条样本都有 EOS，模型就更容易把“在这一带结束”当成概率很高的行为。

所以问题不是模型缺知识，而是：

**因为 EOS 偏置，模型没来得及把已有知识说出来。**

### 3. 因为详细 caption 本质上是更长序列，所以一旦过早结束，能力就被系统性压制

如果模型在第 10 个词附近就停掉，那后面原本可能会补充的：

- 颜色；
- 背景；
- 相对位置；
- 文本内容；
- 场景氛围；

就永远不会出现。  
这意味着 detailed captioning 的关键瓶颈未必是“语言质量”，而是**终止策略**。

### 4. 因为没有正向 supervision，单纯压低 EOS 可能也会走向无意义长文本

这是这篇方法最大的风险：  
如果你只是让模型“不许停”，它完全可能：

- 重复；
- 胡说；
- 在结尾机械补垃圾内容；

所以真正的问题变成了：

**为什么单纯压低 EOS，不会导向无意义废话，而会导向更多相关细节？**

这正是作者要证明的核心挑战。

## 🔍 核心发现 Finding

### 作者明确声称

作者的核心发现是：**在预训练 VLM 中，详细图像描述能力很大程度上已经存在，只是被 EOS 偏置抑制了；通过 sequence training 逐步压低 EOS 概率，可以在无需额外监督的情况下释放这部分能力。**

### 我的理解

我认为这篇论文真正重要的 `Finding` 不是“惩罚 EOS 会让 caption 变长”，而是下面这个更深的判断：

**详细 captioning 不是一个必须重新灌输的新能力，而更像是一个被现有训练目标压制住的生成模式。**

这和很多工作默认的叙事不同。很多方法默认认为：

- 模型写不出细节；
- 所以必须额外给它很多细节 supervision；
- 或者必须构造复杂奖励，告诉它什么是“更详细”。

这篇论文则说：

- 基础模型本来就可能“知道更多”；
- 只是标准训练目标鼓励它太早收尾；
- 一旦把“早点停”这件事削弱，模型会自然沿着已有视觉 grounding 和语言能力继续展开。

这个 insight 为什么能解决前面的挑战？因为它把问题从：

- “如何教模型新知识”

改写成了：

- “如何不要过早截断模型已有知识的外显过程”。

举个直观例子：

- 旧做法像老师觉得学生不会写作文，于是不断给他范文；
- 这篇论文更像是发现：学生其实会写，但每次只写到第三句就被铃声打断。

那么解决方式就不是“补更多范文”，而是“别让他这么早停笔”。

## 🔬 方法

### 整体思路

方法非常简洁，核心是两步：

1. 用标准 next-token prediction 先完成普通 caption finetuning；
2. 再进行 **sequence training with EOS debiasing**，逐步压低 EOS token 的生成概率。

作者强调，这其实是一个 **两阶段训练**：

- 第一阶段：标准 caption finetuning，学基本图像到文本映射；
- 第二阶段：EOS debiasing，让模型从“短 caption 分布”泛化到“更长、更细节的 caption 分布”。

### Sequence Training

作者回顾了 image captioning 中常见的 sequence training 做法：  
输入图像后，生成整段 caption `S=[t1, t2, ..., tn]`，然后基于整个序列的 reward 做 REINFORCE。

但传统 sequence training 需要外部 reward，比如：

- CIDEr；
- QA-based reward；
- CLIP similarity；
- retrieval reward。

这些都要额外系统。

### EOS Debiasing

作者的做法更极端，也更简单：

对每条生成 caption，只优化一个东西：

- **最小化末尾 EOS token 的概率**

也就是论文中的式 (2)：

- 不给正向奖励；
- 不定义“好 caption 长什么样”；
- 只通过负反馈压低 EOS。

作者认为，这相当于用一个“零成本信号”抑制模型在预训练和多模态 finetuning 中学来的早停倾向。

### 这个方法依赖什么前提

论文很诚实地说，这种方法不是万能的，它依赖两个前提：

1. **语言骨干本身已经很强**
   新增文本必须还遵守自然语言规律，而不是乱写。

2. **视觉-语言预训练已经学到图像 grounding**
   继续生成的文本必须仍然跟图像相关，而不是脱离视觉内容自由发散。

换句话说，这个方法不是“从零造能力”，而是“解锁已有能力”。  
所以它**不适合初始预训练阶段**，而更适合作为现成 VLM 的后续阶段。

### 训练设置

作者实验了三种模型：

- `BLIP-2 OPT 2.7B`
- `BLIP-2 FlanT5-XL`
- `PaliGemma 3B`

都从 COCO-caption finetuned checkpoint 出发，以确保：

- 原始模型已经具备 captioning 能力；
- 又仍然处在“短 caption 分布”里。

训练细节包括：

- 只微调 cross-modal bridge  
  `BLIP-2` 微调 Q-former / linear projection  
  `PaliGemma` 微调线性层
- 其余参数全部冻结
- 学习率：`1e-7`
- batch size：`8`
- gradient accumulation：`3`
- 训练硬件：单张 `A100 80GB`
- 训练时使用 contrastive decoding 增加探索
- 训练到生成长度达到 `60` 为止
- 推理时用：
  - beam size `5`
  - repetition penalty `1.5`
  - no-repeat-ngram `3`

这个设置说明作者并没有用大规模工程堆料，而是刻意把方法做成一个可附着在已有 VLM 上的轻量后处理步骤。

## 📊 实验与结论

### 评测数据与指标

评测数据包括：

- **FineCapEval**
  - `1,000` 张图
  - 平均 caption 长度 `26`
- **DCI**
  - `7,805` 张图
  - 平均长度 `45`
- **DOCCI**
  - `5,000` 张图
  - 平均长度 `136`
- **Urban-1k**
  - 用于 image-text retrieval

主要指标包括：

- **CAPTURE**
  - 更适合 detailed caption，关注 objects / attributes / relations 的匹配
- **CIDEr**
  - 传统 caption 指标，但作者明确说它在 detailed captioning 上“不可靠”
- **GPT-4 coherence**
  - 评估文本是否连贯
- **Recall@1 retrieval**
  - 用 LongCLIP embeddings 测 caption 是否有利于检索
- **CHAIR_i / Recall_i / ALOHa**
  - 测 hallucination 与 completeness

### 主结果一：EOS debiasing 能显著拉长 caption，并提高 detail-related 指标

作者在三个模型上都观察到了共同趋势：

- caption 长度显著增加；
- CAPTURE 提升；
- retrieval 变好；
- 多数情况下 coherence 保持稳定甚至提升。

例如在 `BLIP-2 OPT` 上，EOS debiasing 后：

- FineCapEval 上 CIDEr 从 `21.86` 提升到 `24.87`
- DCI 上 CAPTURE 从 `35.42` 提升到 `44.23`
- DOCCI 上 CAPTURE 从 `32.44` 提升到 `45.23`

更关键的是，长度增长不是无意义膨胀。作者结合 Recall 和 hallucination 的权衡分析认为：

**新增加的文本大部分是相关细节，而不是纯噪声。**

### 主结果二：BLIP-2 T5 的提升尤其明显，说明“被压住的能力”在不同架构里程度不同

论文特别指出：

- `BLIP-2 T5` 的 base CAPTURE 最低；
- 但经过 EOS debiasing 后，它在 `DCI` 和 `DOCCI` 上反而变成最强；
- 而且 CIDEr 和 coherence 也一起改善。

这个结果很有意思，因为它说明：

**某些模型不是缺能力，而是被更强地锁在短输出分布里。**

也就是说，EOS 偏置对不同模型的压制程度不一样。  
EOS debiasing 某种意义上是在释放这些模型的“被抑制潜力”。

### 主结果三：简单的 inference-time EOS blocking 不行

作者专门做了一个 trivial baseline：

- 推理时直接禁止 EOS，强迫模型继续写。

直觉上这很像“既然是 EOS 的问题，那我不让它输出 EOS 就好了”。  
但实验显示这种方案虽然也会拉长文本，却会严重伤害 coherence。

论文结论是：

- 简单 blocking 只是机械延长；
- EOS debiasing 则是通过 sequence training 逐步移动生成分布。

作者把两者差异归因于：

- sequence training 允许模型在更长输出空间里重新组织 token 概率；
- 而不是只在末尾硬塞更多词。

换句话说，**EOS blocking 是“别停”，EOS debiasing 是“学会更晚、也更合理地停”。**

### 主结果四：和 TinyLLaVA 的对比说明，这个方法能在无监督条件下逼近大量 supervised finetuning 的效果

作者用 `TinyLLaVA` 作为强对手，它是一个 3B VLM，而且显式为 detailed captioning 等任务做过 instruction tuning。

结果显示，简单的 EOS debiasing：

- 已经能弥合相当一部分和 TinyLLaVA 的性能差距；
- 尤其在 CAPTURE 和 recall 相关指标上表现接近。

这支持了作者的整体论点：

**很多 detailed captioning 所需能力，本来就存在于基础 vision encoder 和 language backbone 中，只是没有被释放。**

### 主结果五：hallucination 会上升，但上升是“可解释的代价”，而且和显式监督方法接近

作者并没有回避问题。  
他们明确承认，随着 caption 变长：

- hallucination 会增加；
- repetition 也会在长时间训练后变明显。

不过他们有两个重要观察：

1. 在 CHAIR/Recall 配对下，hallucination 的增加伴随着 recall 增加，说明不是纯胡说，而是“更敢说细节”的代价。
2. 用 ALOHa 看 open-vocabulary hallucination 时，三种模型与 TinyLLaVA 落在相近区间，说明这种副作用和显式 detailed caption finetuning 大体同级。

也就是说，这个方法并不是“为了拉长文本而完全牺牲真实性”，而是进入了一个和强监督方法相似的 trade-off 区域。

### 主结果六：训练过程本身揭示了一个“长度-细节”渐进释放曲线

在 BLIP-2 T5 的训练曲线上，作者观察到：

- 一开始长度增长较慢；
- 大约到 epoch 后段，长度明显跳升；
- recall 会紧跟长度一起增长。

而且后期 checkpoint 对比显示：

- 从 base 到第一个 checkpoint，caption 长度和 recall 大幅提升；
- 后续 checkpoint 持续提升 descriptiveness；
- 同时 hallucination 逐渐增加。

这个现象很重要，因为它说明：

**EOS debiasing 不是一下子把模型打乱，而是沿着一个连续分布缓慢地释放更长、更细的生成能力。**

### 主结果七：方法背后的机制不是“把细节简单接到尾巴上”，而是重塑整条序列的概率分布

作者专门讨论了一个可能的质疑：

“你压低 EOS，是不是只是让模型在原来 caption 后面随便再补几句？”

作者的回答是否定的。  
他们认为，由于 sequence training 作用于整个序列分布，压制 EOS 实际上是在压制“一整类倾向于提前终止的序列子空间”。

因此模型学到的不是：

- “最后再多补一点”

而是：

- “重写整条序列的生成组织方式”

这也是为什么论文在定性分析里看到：

- 细节会被加到 caption 的不同位置；
- 长度增长是非线性的；
- 新加细节很多甚至不在参考 caption 中。

## 🧠 关键术语

- **EOS (End-of-Sequence) Token（序列结束标记）**：模型生成时用于表示“该结束了”的 token。例子：如果模型过早预测 EOS，就会在很多细节还没说出来前停止。
- **Teacher Forcing（教师强制）**：训练时总是喂真实前文，而不是模型自己生成的前文。例子：这会让模型在训练中习惯固定长度分布，但推理时未必适应更长序列。
- **Sequence Training（序列训练）**：不再只优化单步 next-token，而是针对整段输出做优化。例子：图像 caption 生成完后，再基于整条 caption 的目标更新模型。
- **Exposure Bias（暴露偏差）**：训练时看真实 token，推理时看自己生成 token，两者不一致带来的误差累积。例子：模型一旦前面说偏，后面会越偏越多。
- **EOS Debiasing（EOS 去偏）**：通过 sequence training 直接压低 EOS 概率，减少模型提前结束倾向。例子：不是告诉模型该说什么，而是让它不要太早停。
- **CAPTURE（场景图式详细 caption 指标）**：先从 caption 提取 objects / attributes / relations，再做匹配计算 F1。例子：比 CIDEr 更适合衡量 detailed caption 的完整性和准确性。
- **CHAIR_i（幻觉指标）**：统计 caption 里提到但参考中没有的对象。例子：图里没有狗，caption 却说有狗，就会增加 hallucination。
- **ALOHa（开放词表 hallucination 评测）**：用 LLM 和检测器共同判断 caption 中的对象是否真的出现在图像里。例子：比只依赖 COCO 80 类词表更宽泛。

## 💭 个人评价

### ✅ 优点

- **问题切得非常准**：它没有再卷数据规模或奖励设计，而是直接找到一个更基础的训练偏置问题。
- **方法极简但有效**：只靠 EOS 去偏就能在多个模型上稳定提升 detailed caption 质量，这一点很有说服力。
- **解释力强**：论文不仅报告结果，还解释了为什么 trivial EOS blocking 不行、为什么 sequence training 可以。
- **工程成本低**：只微调 cross-modal bridge，其余参数冻结，单卡 A100 就能做实验。

### ⚠️ 局限

- **hallucination 会增加**：这是明确且不可忽视的代价。
- **能力释放有上限**：作者自己承认，纯 EOS debiasing 最终无法完全替代真正的大规模 supervised finetuning。
- **依赖现有模型已具备潜在能力**：如果 base model 根本没有相关能力，这个方法不会凭空创造出来。
- **主要适用于“训练数据短、任务本身需要更长输出”的场景**：并不是所有生成任务都适合直接套用。

### 💡 启发

- 对很多生成任务来说，问题未必是“模型不会”，而可能是“训练目标把它压住了”。
- 在视觉语言任务里，长度控制和终止策略可能是和内容质量同等重要的优化维度。
- 这篇论文还提示一个更一般的方向：**在没有额外监督数据时，先解锁已有能力，再做监督精修，可能比直接堆数据更高效。**

## 🔗 相关论文

- SMILE
- Fine-grained Image Captioning with CLIP Reward
- DOCCI
- DCI
- CAPTURE
- TinyLLaVA

---

**阅读时间**：约 2.5 小时  
**推荐指数**：⭐⭐⭐⭐  
**适合读者**：计算机视觉、视觉语言模型、image captioning、弱监督训练、sequence training 方向研究者

**一句话总结**：这篇论文最重要的不是提出了一个更复杂的 reward，而是指出：很多 detailed captioning 能力其实早就在预训练 VLM 里，只是被 EOS 偏置压制住了；只要通过 sequence training 有控制地削弱“过早停止”的倾向，模型就能在无需额外监督的情况下，把更多真实细节说出来。  
