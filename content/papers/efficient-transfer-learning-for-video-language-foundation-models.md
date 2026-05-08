---
title: "Efficient Transfer Learning for Video-language Foundation Models"
date: 2026-05-08T00:00:00+08:00
draft: false

# 分类（研究领域）
categories: ["多模态学习"]

# 会议/期刊
venues: "CVPR 2025"

# 论文元数据
authors: ["Haoxing Chen", "Zizheng Huang", "Yan Hong", "Yanshuo Wang", "Zhongcai Lyu", "Zhuoer Xu", "Jun Lan", "Zhangxuan Gu"]
year: "2025"
paper_url: "https://arxiv.org/abs/2411.11223"
arxiv_url: "https://arxiv.org/pdf/2411.11223"
code_url: "https://github.com/chenhaoxing/ETL4Video"

# 阅读状态
status: "completed"
rating: 4
read_date: "2026-05-08"

summary: "这篇论文提出 MSTA，一种面向视频-语言基础模型的参数高效迁移方法。它在 ViCLIP 的高层文本和视频编码器中插入共享的多模态时空 adapter，用少量可训练参数同时保留预训练泛化能力和学习视频动作识别的任务特征，并通过 LLM 生成的时空动作描述构造一致性约束来缓解小样本迁移中的过拟合。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文讨论的是一个视频理解里很现实的问题：**已经有了强大的视频-语言基础模型，怎样把它高效迁移到下游视频动作识别任务，而不把原本的泛化能力训练坏？**

背景是 CLIP、ViCLIP 这类视觉-语言模型已经学到了很强的跨模态表示。它们能把文本描述和视觉内容投到同一个语义空间里，因此很适合做开放类别识别、少样本识别和零样本迁移。问题在于，视频动作识别不是静态图像分类。它既需要看清场景、物体和人物姿态，也需要理解动作随时间展开的过程。

已有方法通常会往 CLIP 或视频模型里加 temporal module、prompt、adapter，甚至直接 fine-tune。这样做能提高下游训练集上的表现，但代价是：

- 新增参数很多；
- 容易过拟合有限样本；
- 容易遗忘预训练模型原本学到的开放语义知识；
- 很多 CLIP-based 方法并不能直接适配 ViCLIP 这种视频-语言基础模型。

作者提出 **MSTA（Multi-modal Spatio-Temporal Adapter）**。它的核心做法是在文本分支和视频分支的高层 transformer block 中插入参数高效 adapter：视频分支有空间和时间两个 up-projection，文本和视频分支还共享一个 projection layer，让两个模态在迁移时仍然对齐。为了进一步保住泛化，作者让 LLM 根据动作类别生成空间描述和时间步骤描述，再用这些描述对训练分支和冻结预训练分支施加一致性约束。

最终，MSTA 在 base-to-novel、few-shot、zero-shot transfer 和 fully-supervised 四类设置上都表现很好，同时只训练原模型约 2-7% 的参数。

## 🎯 研究背景

这篇工作位于三个方向的交叉处。

第一是 **视频-语言基础模型**。CLIP 证明了图文对比学习可以学到强泛化视觉语义，ViCLIP 则把这个思路扩展到视频-文本对，用时空注意力让模型更适合视频理解。它们的优势不是只会识别训练集类别，而是能把视觉内容和自然语言类别描述联系起来。

第二是 **参数高效迁移学习（PEFT）**。LoRA、AdaptFormer、adapter 这类方法希望冻结大部分预训练权重，只训练很少的新增参数。这样做成本低，也能降低小样本过拟合风险。但很多 PEFT 方法原本是为单模态模型设计的，直接用在视频-语言模型上会忽视文本和视频之间的对齐关系。

第三是 **视频动作识别的开放泛化**。动作识别不是只看单帧物体。例如 “basketball dunk” 不只是有篮球和篮筐，还包含助跑、起跳、扣篮、落地等时序过程。一个好的迁移方法既要学到这些任务相关特征，又不能把预训练模型的开放类别泛化能力破坏掉。

## ⚠️ 问题与挑战

论文要解决的问题是：**如何为视频-语言基础模型设计一种参数高效的迁移方法，让它在视频动作识别中同时获得任务适配能力和开放泛化能力。**

这个问题难在几个相互牵制的地方。

### 1. 因为视频动作同时包含空间和时间信息，所以普通图像式 adapter 不够用

静态图像识别主要依赖物体、场景和局部视觉特征。但视频动作识别还依赖时间顺序。

例如 “opening a bottle” 和 “closing a bottle” 可能共享很多静态视觉元素：人、瓶子、桌面、手部动作。但关键差异在动作方向和过程。如果 adapter 只像图像模型那样处理空间特征，就很难捕捉这类时间语义。

### 2. 因为视频-语言模型依赖跨模态对齐，所以单独调文本或视频分支容易破坏语义空间

ViCLIP 的预测逻辑是比较视频 embedding 和文本类别描述 embedding。如果只在视频分支加 adapter，视频表示可能更适合训练集，但会偏离文本空间；如果只调文本分支，也可能让类别描述变得更贴合训练集，却不能改善视频表示。

这意味着迁移不是单个分支的分类问题，而是一个 **跨模态表示仍然要对齐** 的问题。

### 3. 因为下游视频数据昂贵且少样本场景常见，所以过拟合和灾难性遗忘很严重

视频数据比图像更贵，标注也更复杂。在 few-shot 或 base-to-novel 设置里，如果模型为 base classes 学得太专，就会牺牲 novel classes 的表现。

也就是说，训练越强，未必越好。关键不是最大化训练集拟合，而是找到一个平衡点：既能学新任务，又不丢掉预训练模型的泛化知识。

### 4. 因为 CLIP 迁移方法不一定适合 ViCLIP，所以需要面向视频-语言模型重新设计

论文强调，很多已有方法是围绕 CLIP 设计的，例如 ActionCLIP、XCLIP、Vita-CLIP、OST。ViCLIP 已经在视频-文本对上预训练过，并且视觉编码器包含时空注意力。直接套用 CLIP-era 的方法，未必能利用 ViCLIP 的结构优势。

## 🔍 核心发现 Finding

### 作者明确声称

作者明确主张：**在视频-语言基础模型迁移中，MSTA 可以用很少的可训练参数增强文本和视频表示对齐，并通过时空描述引导的一致性约束减少过拟合、提升泛化。**

### 我的理解

我认为这篇论文真正的 `Finding` 是：

**视频-语言模型的高效迁移，不应该被看成“给视频编码器补一个时间模块”，而应该被看成“在保留原有跨模态语义空间的前提下，轻量注入任务相关的时空偏置”。**

这和普通 adapter 的区别很关键。

如果只想提高训练集准确率，最直接的办法是多调一些参数，让模型更贴合训练视频。但 base-to-novel 和 zero-shot transfer 要求模型看见新类别也能泛化。这就要求模型不能把原来的语言-视觉对齐空间改坏。

MSTA 的思路是把“适配”和“保守”同时放进设计里：

- adapter 提供适配能力，让模型学到动作识别所需的空间和时间特征；
- shared projection 让文本和视频分支不是各学各的，而是在共享空间里协同迁移；
- consistency constraint 用冻结预训练分支和 LLM 生成的时空描述做锚点，提醒可训练分支不要偏离原有语义空间太远。

一个直观例子是 “basketball dunk”。普通文本模板只有 “a video of basketball dunk”，语义很短。LLM 生成的时空描述会补充：

- 空间上可能出现球员、篮筐、篮球、球场；
- 时间上包含起跳、举球、扣入篮筐、落地。

冻结的预训练文本分支用这些描述形成更丰富的语义参照；可训练分支虽然只输入标准模板，但会被一致性约束拉向这个时空语义区域。这样模型学到的不是某个训练类别的死记硬背，而是更接近动作概念本身的表示。

## 🔬 方法

### 输入和基础模型

论文以 **ViCLIP** 为主要基础模型。ViCLIP 类似 CLIP，有文本编码器和视频编码器，但视频编码器使用时空注意力，预训练数据来自大规模视频-文本对。

推理时，模型把视频输入编码成 video feature，把类别文本描述编码成 text feature，然后用两者的 cosine similarity 做动作类别预测。

### Step 1: 在高层 transformer block 插入 MSTA

作者没有全量 fine-tune ViCLIP，也没有在所有层都插入复杂模块，而是在若干高层 transformer block 中加入 adapter。

对于视频分支，MSTA 做三件事：

1. 用 down-projection 把特征压到较低维度，减少可训练参数；
2. 通过共享 projection layer 汇聚跨模态信息；
3. 用两个 up-projection 回到原始维度，其中一个偏空间特征，另一个偏时间特征。

这里 temporal up-projection 使用 3D convolution，目的是显式增强时间建模能力；spatial up-projection 则处理更静态的视觉信息。

对于文本分支，结构相似，但没有视频分支的空间/时间双 up-projection，而是通过同一个 shared projection layer 和视频分支发生联系。

### Step 2: 用共享投影层维持跨模态对齐

如果文本和视频分支各自独立加 adapter，它们可能都对训练集更敏感，但彼此的语义空间会漂移。MSTA 用共享 projection layer 让两个分支在微调时共同更新同一部分参数。

这相当于给两条分支一个共同的“中转语义空间”：视频分支学到的动作变化和文本分支学到的类别语义，不是完全独立优化，而是通过共享参数互相约束。

### Step 3: 用缩放系数控制新旧知识平衡

adapter 输出以残差方式加回 transformer block，并由缩放系数 `lambda` 控制强度。

这个设计的直觉是：如果 `lambda` 太小，adapter 对任务适配不够；如果 `lambda` 太大，新增参数会主导表示，预训练知识容易被覆盖。论文的消融显示 `lambda = 0.005` 的 base/novel harmonic mean 最好。

### Step 4: 生成时空描述并构造一致性约束

论文进一步提出 **spatio-temporal description-guided consistency constraint**。

具体流程是：

1. 对每个动作类别 `{cls}`，用 LLM 生成空间描述，例如该动作可能有哪些视觉外观、场景、物体。
2. 再生成时间描述，例如该动作通常按哪些步骤发生。
3. 可训练文本分支输入标准模板：`a video of {cls}`。
4. 冻结的预训练文本分支输入 LLM 生成的空间/时间描述。
5. 用 cosine distance 约束可训练分支的类别 embedding 和冻结分支的描述 embedding 保持一致。

最后训练目标是普通交叉熵分类损失加上一致性损失：

```text
L = L_CE + alpha * L_CC
```

其中 `alpha` 控制一致性约束权重。

## 📊 实验与结论

### 实验设置

论文在六个视频 benchmark 上实验：

- Kinetics-400；
- Kinetics-600；
- UCF-101；
- HMDB-51；
- Something-Something V2；
- ActivityNet。

主要评估四类设置：

- **zero-shot transfer**：在 Kinetics-400 上训练，直接迁移到其他数据集；
- **few-shot learning**：每类只给 2/4/8/16 个训练样本；
- **base-to-novel generalization**：在 base classes 训练，同时看 base 和 novel classes 的平衡；
- **fully-supervised learning**：在 Kinetics-400 上完整监督训练。

基础架构是 ViCLIP ViT-B/16。作者使用 AdamW，batch size、学习率、插入层数等随任务设置调整。论文报告所有实验在 8 张 Nvidia Tesla A100 80G 上完成。

### 1. Base-to-novel 泛化：MSTA 更好地平衡适配和泛化

base-to-novel 是最能体现这篇论文动机的设置，因为它同时看：

- base accuracy：模型对训练类别的适配能力；
- novel accuracy：模型对未见类别的泛化能力；
- harmonic mean：两者的折中。

在 Kinetics-400、HMDB-51、UCF-101、SSv2 上，`MSTA + LCC` 都取得了最好的整体平衡。

几个代表数字：

- Kinetics-400: HM 从 Zero-ViCLIP 的 65.9 提升到 72.0；
- HMDB-51: HM 从 Zero-ViCLIP 的 54.9 提升到 66.3；
- UCF-101: HM 从 Zero-ViCLIP 的 75.3 提升到 82.9；
- SSv2: HM 从 Zero-ViCLIP 的 9.1 提升到 18.9。

SSv2 的提升尤其有意义，因为它更依赖时序和动作过程，而不是单帧物体识别。

### 2. Few-shot：少量样本下仍然比重参数方法更有效

在 HMDB-51、UCF-101、SSv2 的 2/4/8/16-shot 设置下，MSTA+LCC 在 12 个比较项中拿到 9 个最佳结果。

作者特别强调，相比第二强的 MoTE，MSTA 只用了大约十分之一的参数量：8.7M vs. 88M。这说明它的收益不只是来自“多加参数”，而是来自更合适的跨模态和时空结构设计。

### 3. Zero-shot transfer：从 Kinetics-400 迁移到未见数据集更稳

zero-shot transfer 中，模型先在 Kinetics-400 上训练，再直接评估 HMDB-51、UCF-101 和 Kinetics-600。

`MSTA + LCC` 达到：

- HMDB-51: 55.8；
- UCF-101: 78.7；
- Kinetics-600: 74.5。

这些结果超过 AdaptFormer、LoRA 和 MSTA without LCC，说明一致性约束不仅是正则项装饰，而是确实改善了迁移到新数据集时的泛化。

### 4. Fully-supervised：参数少也能接近甚至超过重方法

在 Kinetics-400 完整监督设置下，`MSTA + LCC` 用 8.7M 可训练参数取得 82.2 Top-1 / 96.2 Top-5。

对比之下：

- XCLIP 用 132M 可训练参数，Top-1 为 82.3；
- OST 用 149.6M 可训练参数，Top-1 为 82.0；
- ViCLIP 全量相关设置为 124.3M 可训练参数，Top-1 为 79.9。

所以 MSTA 的价值不只是小样本泛化，在完整监督下也能用低参数量达到很强结果。

### 5. 消融实验：共享层、一致性约束、插入层数都重要

消融给了几个清楚结论：

- 只用文本 adapter 或只用视频 adapter，HM 都是 57.9；完整 MSTA 达到 60.1，说明双模态同时适配更有效。
- 去掉 shared layers 后，HM 从 60.1 降到 59.5，说明共享投影层确实帮助跨模态对齐。
- shared dimension 到 256 时较好，512 并没有继续提升 novel accuracy，说明参数太多会增加过拟合风险。
- `lambda = 0.005` 最好；`lambda = 0.05` 会让 novel accuracy 大幅下降到 40.3，说明 adapter 强度过大时会损害泛化。
- LCC 的 `alpha = 1.0` 最好，太小约束不够，太大则会压制任务适配。
- 时空描述数量 `N = 2` 最好；描述太多反而可能引入 LLM hallucination 噪声。
- MSTA 插入高层通常优于插入低层，例如 7-12 层优于 1-6 层。

### 结论

作者可以合理得出的结论是：

1. 视频-语言基础模型迁移需要同时考虑文本、视频和二者对齐，而不是只增强视觉分支。
2. MSTA 用少量参数就能为 ViCLIP 注入视频动作识别所需的时空偏置。
3. LLM 生成的时空动作描述可以作为语义锚点，通过一致性约束缓解过拟合和灾难性遗忘。
4. 该方法在 base-to-novel、few-shot、zero-shot transfer 和 fully-supervised 设置下都表现稳定。

我的保留意见：

- 论文主要围绕动作识别验证，尚未证明 MSTA 对视频问答、视频定位、长视频理解等更复杂任务同样有效。
- LLM 生成的描述质量会影响一致性约束；论文也观察到描述数量增加后可能引入 hallucination 噪声。
- 方法依赖 ViCLIP 作为基础模型，迁移到其他视频-语言模型时，最优插入层、维度和缩放系数可能需要重新搜索。
- 论文没有深入分析哪些类别或失败样本最受益于时空描述，这会影响后续复现和改进。

## 🧩 关键术语

- **Video-language Foundation Model（视频-语言基础模型）**: 在视频-文本对上预训练的跨模态模型。例子：ViCLIP 把视频和文本描述投到同一语义空间，用相似度做类别预测。

- **Efficient Transfer Learning（高效迁移学习）**: 冻结大部分预训练参数，只训练少量新增模块来适配下游任务。例子：MSTA 只训练约 2-7% 的参数。

- **MSTA, Multi-modal Spatio-Temporal Adapter（多模态时空适配器）**: 论文提出的 adapter 结构，同时作用于文本和视频分支，并通过共享投影层对齐两个模态。例子：视频分支包含空间 up-projection 和时间 up-projection。

- **Shared Projection Layer（共享投影层）**: 文本和视频 adapter 共用的中间投影层，用来让两种模态在迁移时保持联系。例子：视频动作特征和动作类别文本语义共同更新同一组共享参数。

- **Spatio-Temporal Description（时空描述）**: 由 LLM 根据动作类别生成的空间外观和时间步骤描述。例子：对 “basketball dunk” 生成球场、篮筐等空间描述，以及起跳、扣篮、落地等时间过程描述。

- **Consistency Constraint（一致性约束）**: 约束可训练分支输出不要偏离冻结预训练分支基于丰富描述得到的语义表示。例子：标准模板 `a video of basketball dunk` 的 embedding 应接近时空描述的平均 embedding。

- **Base-to-Novel Generalization（已见到未见类别泛化）**: 在 base classes 上训练，同时评估 base 和 novel classes 表现。例子：如果 base accuracy 很高但 novel accuracy 很低，说明模型过拟合训练类别。

- **Harmonic Mean（调和平均）**: 用来衡量 base accuracy 和 novel accuracy 的平衡。例子：base 很高、novel 很低时，HM 会被明显拉低。

- **Catastrophic Forgetting（灾难性遗忘）**: 微调后模型忘掉预训练阶段获得的通用知识。例子：模型在训练动作类别上变强，却在未见动作类别上明显变差。

- **Zero-shot Transfer（零样本迁移）**: 在一个数据集训练后，直接迁移到没有见过类别标注的另一个数据集评估。例子：在 Kinetics-400 上训练后直接测试 HMDB-51。

## 💡 个人评价

这篇论文的实用价值比较明确：它给视频-语言基础模型提供了一个比全量 fine-tuning 更稳、比普通 LoRA/AdaptFormer 更贴合跨模态结构的迁移方案。MSTA 的设计没有特别复杂，但抓住了视频动作识别的三个关键点：文本-视频对齐、时空特征、泛化保持。

我觉得最值得借鉴的是一致性约束的思路。LLM 生成的时空描述没有直接拿来替换类别文本，而是作为冻结预训练分支的语义锚点，让可训练分支在适配任务时不要漂移太远。这比简单 prompt augmentation 更稳，因为它把丰富描述转化成了训练约束。

后续如果要继续沿这个方向做，我会优先看三个问题：

- 能否把描述质量控制做得更强，例如过滤 hallucination 或按类别动态选择描述数；
- MSTA 是否能扩展到视频问答、时序定位、长视频检索等任务；
- 是否能把 shared projection 做成更细粒度的跨模态门控，而不是固定共享层。

## 🔗 相关论文

- CLIP: Learning Transferable Visual Models From Natural Language Supervision
- ViCLIP / InternVid: video-language pre-training for video understanding
- XCLIP: Expanding Language-Image Pretrained Models for General Video Recognition
- ViFi-CLIP: Fine-tuned CLIP Models are Efficient Video Learners
- Vita-CLIP: Video and Text Adaptive CLIP via Multimodal Prompting
- OST: Refining Text Knowledge with Optimal Spatio-Temporal Descriptor
- LoRA: Low-Rank Adaptation of Large Language Models
- AdaptFormer: Adapting Vision Transformers for Scalable Visual Recognition
