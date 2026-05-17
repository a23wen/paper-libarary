---
title: "ScaleCap: Inference-Time Scalable Image Captioning via Dual-Modality Debiasing"
date: 2026-05-17T00:00:00+08:00
draft: false

# 分类（研究领域）
categories: ["计算机视觉"]

# 会议/期刊
venues: "arXiv 2025"

# 论文元数据
authors: ["Long Xing", "Qidong Huang", "Xiaoyi Dong", "Pan Zhang", "Yuhang Zang", "Yuhang Cao", "Jinsong Li", "Shuangrui Ding", "Weiming Zhang", "Nenghai Yu", "Jiaqi Wang", "Feng Wu", "Dahua Lin"]
year: "2025"
paper_url: "https://arxiv.org/abs/2506.19848"
arxiv_url: "https://arxiv.org/pdf/2506.19848"
code_url: "https://github.com/Cooperx521/ScaleCap"

# 阅读状态
status: "completed"
rating: 4
read_date: "2026-05-17"

summary: "ScaleCap 提出一种 inference-time scalable 的详细图像描述生成策略。论文认为开源 LVLM 的 detailed caption 主要受两类偏置限制：多模态偏置让模型只细写显著物体、忽略其他区域；语言偏置让模型凭语言先验产生幻觉。ScaleCap 用 heuristic question answering 反复追问物体属性和空间关系，再用 sentence-level offline contrastive rating 过滤更依赖语言先验的句子。基于 ScaleCap 标注的 450K 图像用于 LVLM 预训练后，在 11 个多模态 benchmark 上整体优于 ShareGPT4V-450K 和 DenseFusion-450K；Prism 与重建实验也显示它生成的 caption 更有信息量。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文讨论的是 detailed image captioning 里的一个很实际的问题：

**如果我们想大规模构造高质量、细粒度、低幻觉的图像文本数据，能不能不依赖人工标注、专有 API 或一堆专家检测器，而是在推理时把已有开源 LVLM 的感知能力更充分地挖出来？**

作者提出的答案是 **ScaleCap**。它不是训练一个新的 captioner，而是一个推理时可扩展的 caption 生成流程：

1. 先让 LVLM 生成初始 caption；
2. 用 contrastive sentence rating 挑出更有视觉依据的 golden sentences；
3. 让 LLM 根据这些句子提出物体级和位置级 follow-up questions；
4. 让轻量 LVLM 回答这些问题，补充遗漏细节；
5. 再用 sentence-level contrastive rating 过滤幻觉内容；
6. 最后让强 LLM 把零散物体细节和空间细节整合成完整 caption。

论文最重要的结论不是“更长 caption 更好”，而是：**很多细节遗漏并不是 7B LVLM 看不见，而是原始 caption 生成过程没有把它问出来。** 只要用合适的问题驱动信息抽取，再用句子级过滤压住语言幻觉，较小模型也能生成更丰富、更平衡、更忠实的描述。

## 🎯 研究背景

这篇工作处在三个方向的交叉处。

### 1. LVLM 预训练数据构造

多模态大模型依赖大量 image-text pairs 做视觉语言对齐。早期 alt-text 或 COCO caption 往往很短，只能提供粗粒度语义，例如“a dog on a beach”。但现代 LVLM 需要理解对象属性、空间关系、OCR、动作、材质和上下文，训练数据也需要更细、更长、更结构化的 caption。

人工标注和 GPT-4o 这类专有模型都能生成高质量描述，但成本高、扩展性受限。开源 LVLM 更便宜，但直接生成时容易漏细节和产生幻觉。

### 2. Detailed Image Captioning

Detailed captioning 的目标不是一句话概括，而是尽可能完整、准确地描述图像。它直接影响：

- 图文预训练的 modality alignment；
- VQA 中模型能否从 caption 找到细节；
- text-to-image reconstruction 中 caption 是否保留足够视觉信息；
- 后续 captioner 训练和评测的 reward 设计。

CapArena、CapRL、RubiCap 等近期工作都在说明同一件事：caption 已经从“短句生成任务”变成了视觉理解和数据构造的核心接口。

### 3. 幻觉抑制与推理时扩展

很多 LVLM 幻觉来自语言先验。例如模型看到厨房，容易补出“桌上有咖啡杯”，即使图里没有。传统 contrastive decoding 往往在 token 级在线干预，会影响句子流畅性。

ScaleCap 的做法更保守：先生成完整句子，再比较有图和无图条件下 token 概率差异，用句子级策略保留视觉 grounding 更强的内容。

## ⚠️ 问题与挑战

论文要解决的问题是：**如何用开源模型低成本生成可扩展的高质量 detailed captions，并让这些 captions 对 LVLM 预训练真的有用。**

这个问题难在几个层面。

### 1. 因为 caption 细节分布不均，所以模型会过度描述显著物体

训练数据里的描述通常偏向图像中心或最显眼的对象。模型学到这种分布后，生成时也会把主体写得很细，却忽略背景、小物体、空间关系或文字。

例如一张机场照片里，模型可能详细写飞机机身颜色，却不写登机桥、跑道标线、远处车辆和人与飞机的位置关系。这不是完全看不见，而是生成目标没有迫使模型逐项检查。

### 2. 因为 LVLM 继承 LLM 的语言习惯，所以越详细越容易幻觉

详细 caption 鼓励模型写更多内容，但更多内容也增加了凭语言先验补全的机会。模型可能根据常见共现关系写出不存在的物体、属性或动作。

所以 detailed captioning 有一个内在张力：**要更丰富，就必须问更多细节；但问得越多，越需要可靠过滤机制。**

### 3. 因为专家工具覆盖有限，所以不能只靠 detector / tagger 解决

目标检测器、OCR、tagger 可以补充信息，但它们受类别空间、检测精度和场景覆盖限制。现实世界对象和属性组合太多，完全依赖人工设计的工具链不够通用。

ScaleCap 因此选择用通用 LVLM 自己回答细节问题，把工具依赖转成“问题驱动的信息抽取”。

### 4. 因为长上下文整合很难，所以最后的 caption integration 需要强 LLM

ScaleCap 的中间信息可能达到上万 token，包括对象细节和位置细节。论文发现 7B LLM 在整合阶段明显弱于 72B LLM，说明瓶颈不只是视觉提取，也包括长上下文信息组织。

## 🔍 核心发现 Finding

### 作者明确声称

作者明确的发现是：**ScaleCap 通过 heuristic question answering 和 contrastive sentence rating，可以随着推理预算增加持续丰富并校准 caption；用 ScaleCap-450K 做预训练能稳定提升多个 LVLM 架构在 11 个 benchmark 上的表现。**

### 我的理解

我认为这篇论文真正的 `Finding` 是：

**detailed caption 的瓶颈不只是“模型看不看得见”，而是“生成过程有没有把模型已经看见的东西系统性地问出来，并过滤掉语言先验带来的假细节”。**

这改变了 caption 生成的思路。

传统做法像一次性写作文：给图像和 prompt，让模型直接输出一段描述。问题是模型会沿着最自然的语言路径写下去，优先覆盖显著主体和常见搭配。

ScaleCap 把它改成一次检查流程：

- 先写出一个初稿；
- 从初稿里找视觉依据强的句子作为骨架；
- 围绕骨架里的对象逐个追问属性；
- 围绕对象逐个追问位置关系；
- 每次回答后判断这句话到底是不是依赖图像；
- 最后再整合成自然 caption。

这个流程的关键是把“看图描述”拆成了两个更可控的子问题：

1. **信息覆盖**：通过问题增加 inference budget，让模型不断检查遗漏区域；
2. **事实性控制**：通过有图/无图概率对比，把语言先验太强的句子降权或丢弃。

一个直观例子是：初始 caption 写“a plane is on the runway”。ScaleCap 会继续问“Describe more details about the airplane”和“Describe more details about the position of the airplane”。如果回答中某句“passengers are boarding through a jet bridge”在无图条件下也很容易生成，而图像条件没有明显提高其概率，它就可能被判作语言偏置更强的句子。

## 🔬 方法

### 整体流程

ScaleCap 的输入是一张图像，输出是一段完整 detailed caption。流程分成四步。

第一步，LVLM 生成初始 caption。作者随后用 contrastive sentence rating 从中抽取 golden sentences，这些句子构成后续扩展的骨架。

第二步，LLM 根据 golden sentences 生成两类 heuristic instructions：

- **object instructions**：追问每个对象的外观、属性和细节，例如“Describe more details about the airplane”；
- **position instructions**：追问对象的位置和空间关系，例如“Describe more details about the position of the airplane”。

第三步，轻量 LVLM 回答这些问题。作者默认使用 Qwen2-VL-7B，因为论文实验认为这一级别模型已经足够承担直接视觉信息抽取，继续放大 LVLM 对纯识别类信息帮助有限。

第四步，强 LLM 整合信息。ScaleCap 先分别汇总 object-level details 和 position-level details，再结合 golden sentences 生成最终 caption。论文默认使用 Qwen2-72B 做问题生成和整合，其中真正拉开差距的是长上下文整合能力。

### Contrastive Sentence Rating

这个模块用于减少幻觉。核心思想是比较一句话在两种条件下的 token 概率：

- 有图像输入时，模型生成这句话的概率；
- 没有图像输入、只靠文本上下文时，模型生成这句话的概率。

如果某些关键 token 主要靠图像条件提升概率，说明它们更可能来自视觉 grounding；如果无图条件下也很容易生成，说明它们可能只是语言先验。

ScaleCap 不在 token 级在线改写生成过程，而是生成后做句子级过滤。这样可以避免 online contrastive decoding 破坏流畅性，也更适合 detailed caption 这种长文本输出。

### ScaleCap-450K 数据集

作者用 ScaleCap 标注 450,000 张图像，构成 ScaleCap-450K：

- 100K 来自 ShareGPT4V-100K，保证类别多样性；
- 350K 来自 LAION-5B，经过高分辨率和适中复杂度筛选；
- 默认 LVLM 为 Qwen2-VL-7B；
- 默认 LLM 为 Qwen2-72B。

这个数据集的目标不是作为单独 benchmark，而是验证：如果 caption 更细、更平衡、更低幻觉，是否能在进一步预训练中带来更好的视觉语言对齐。

## 🧪 实验与结论

### 主实验：ScaleCap-450K 提升 LVLM 预训练

作者基于 LLaVA-NeXT 风格架构做三阶段训练：

1. BLIP-558K 初始预训练；
2. 使用不同 caption 数据做 further pretraining；
3. 用 Open-LLaVA-NeXT-Instruct-1M 做 instruction tuning。

比较数据包括 Vanilla、ShareGPT4V-450K、DenseFusion-450K 和 ScaleCap-450K。模型配置包括 Qwen2.5-7B + Qwen2.5-ViT、Qwen2.5-3B + Qwen2.5-ViT、InternLM2.5-7B + CLIP-ViT-L。

结果显示，ScaleCap-450K 在 11 个 benchmark 的平均分上都最好：

- Qwen2.5-7B 设置下平均分从 DenseFusion-450K 的 63.0 提升到 64.7；
- Qwen2.5-3B 设置下从 58.9 提升到 60.1；
- InternLM2.5-7B 设置下从 59.1 提升到 60.2。

作者特别强调，在 Qwen2.5-7B 设置中，ScaleCap-450K 相比 ShareGPT4V-450K 在 InfoVQA 上高 4.3 分，在 MMVet 上高 7 分；相比 DenseFusion-450K 也分别高 2.4 分和 3.5 分。

这说明 ScaleCap 的 caption 不只是看起来更长，而是确实改善了预训练中的 modality alignment。

### Prism 验证：caption 本身更有信息量

Prism 框架把视觉感知和文本推理拆开：先让 captioner 把图像转成文字，再让固定 LLM 只看 caption 回答视觉问题。如果回答更好，说明 caption 携带的信息更多。

在 Prism 设置下：

- Qwen2-VL-7B 直接 caption 平均 54.1；
- Qwen2-VL-72B 直接 caption 平均 56.0；
- ScaleCap + Qwen2-VL-7B 平均 58.2。

这支持了论文的关键判断：**7B 模型在被正确追问时，可以提取出比 72B 直接 caption 更多的有效视觉信息。**

### 重建实验：caption 覆盖更多视觉语义

作者随机选 50 张图，用 ScaleCap、GPT-4o、Qwen2-VL-72B 生成 caption，再用 FLUX 根据 caption 重建图像。25 名志愿者比较重建图和原图的相似度。

ScaleCap 的重建图更接近原图，说明它保留了更多对象、属性和空间关系。这是一个很直观的验证：如果 caption 真能把图讲清楚，那么 text-to-image 模型就更容易把图还原出来。

### 消融与分析

论文做了几组关键消融。

第一，推理预算有 scaling 行为。增加 heuristic questions 会提高 MMVet 和 MMStar 表现，但超过约 20 个问题后开始趋于平台，说明主要 VQA 相关对象已经覆盖。

第二，7B LVLM 已经足够做视觉提取。Qwen2-VL 从 2B 到 7B 有明显提升，但 72B 继续提升有限；大模型更多带来 world knowledge，而不是纯视觉识别优势。

第三，LLM 整合能力很重要。Qwen2-7B 做 summarization 时 MMVet / MMStar 明显低于 Qwen2-72B，原因是中间细节可能达到 20K token，小模型容易漏掉重要信息。

第四，object instructions 和 position instructions 都重要。只保留任一类都会降低 TextVQA、MMVet、ChartQA 的平均表现。

第五，contrastive sentence rating 可以减少幻觉。在 CHAIR 上，LLaVA-v1.5 7B 的 CHAIR-S 从 48.8 降到 33.6，Qwen2-VL 7B 从 44.2 降到 25.8，优于 VCD 和 OPERA 等基线。

## 🔑 关键术语

- **ScaleCap（推理时可扩展图像描述）**: 论文提出的 caption 生成流程，通过增加追问数量提升细节覆盖。例子：从“一架飞机在跑道上”扩展到飞机颜色、机翼标志、登机桥位置、跑道标线和背景车辆。

- **Heuristic Question Answering（启发式问答）**: 让 LLM 根据初始 caption 自动提出对象级和位置级问题，再由 LVLM 回答。例子：针对“airplane”生成“Describe more details about the airplane”和“Describe more details about the position of the airplane”。

- **Contrastive Sentence Rating（对比式句子评分）**: 比较有图和无图条件下生成句子的概率，筛掉更像语言先验的句子。例子：如果“a cup of coffee”在厨房图像里无图也很容易出现，就可能被判为幻觉风险。

- **Golden Sentences（黄金句子）**: 初始 caption 中通过对比评分保留下来的视觉依据较强的句子，作为后续追问和整合的骨架。

- **Prism Framework（感知-推理解耦评测）**: 先把图像转成 caption，再让固定 LLM 根据 caption 回答视觉问题，用 VQA 表现衡量 caption 信息量。

- **CHAIR（Caption Hallucination Assessment with Image Relevance）**: 评估 image caption 中对象幻觉的指标。例子：图里没有狗，caption 写了 dog，就会增加 hallucination 计数。

## 🧭 评价与启发

这篇论文的价值在于，它把 detailed captioning 从“一次性生成”重新定义成“可扩展的信息抽取流程”。这和 CapRL、RubiCap、CapArena 形成了很清晰的互补关系：

- CapArena 解决 detailed caption 怎么评；
- CapRL / RubiCap 解决 captioner 怎么训练；
- ScaleCap 解决大规模高质量 caption 数据怎么低成本生成。

论文最有启发的地方是 7B LVLM 的发现。很多时候我们会把 caption 不够细归因于模型感知能力不足，但 ScaleCap 说明：如果问题足够具体，小模型已经能回答很多细节。真正困难的是怎么系统地问、怎么筛、怎么整合。

局限也比较明显：

- Contrastive sentence rating 主要基于概率差异，不能直接识别有害、偏见或语义层面的内容风险；
- 流程依赖较强 LLM 做长上下文整合，成本没有完全消失；
- 推理时多轮问答适合离线造数据，但不一定适合低延迟在线 captioning；
- 评估集中在 caption 用于预训练、Prism 和重建，对人工偏好或真实应用的验证还可以更充分。

## 💡 可借鉴点

1. **不要只把 caption 变长，要让它变得可追问、可过滤、可整合。**
2. **细粒度视觉信息抽取可以通过 inference budget 扩展，而不一定只能靠更大 LVLM。**
3. **训练数据质量可以通过下游预训练收益验证，而不是只看 caption 本身。**
4. **对开放式多模态数据构造来说，句子级后验过滤比 token 级在线干预更稳。**
5. **ScaleCap 可以和 RL captioner 结合：用它生成高质量 seed data，再用 CapArena / RubiCap / CapRL 式目标进一步优化。**

**适合读者**：计算机视觉、多模态预训练、image captioning、数据合成、幻觉抑制方向研究者

**一句话总结**：ScaleCap 的关键不是“用更大的模型写更长的 caption”，而是发现 detailed caption 的许多遗漏来自信息抽取过程没有被系统追问；通过推理时问题扩展和句子级幻觉过滤，小模型也能低成本产出对预训练有实际帮助的高质量图像描述。
