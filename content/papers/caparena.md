---
title: "CapArena: Benchmarking and Analyzing Detailed Image Captioning in the LLM Era"
date: 2026-05-14T00:00:00+08:00
draft: false

# 分类（研究领域）
categories: ["计算机视觉"]

# 会议/期刊
venues: "arXiv 2025"

# 论文元数据
authors: ["Kanzhi Cheng", "Wenpo Song", "Jiaxin Fan", "Zheng Ma", "Qiushi Sun", "Fangzhi Xu", "Chenyang Yan", "Nuo Chen", "Jianbing Zhang", "Jiajun Chen"]
year: "2025"
paper_url: "https://arxiv.org/abs/2503.12329"
arxiv_url: "https://arxiv.org/pdf/2503.12329"
code_url: "https://github.com/njucckevin/CapArena"

# 阅读状态
status: "completed"
rating: 4
read_date: "2026-05-14"

summary: "CapArena 针对 LLM 时代的 detailed image captioning 评测问题，构建了一个基于匿名 pairwise caption battle 的人工评测平台，收集 6522 条高质量人类偏好标注，对 14 个 VLM 和人类 caption 进行 Bradley-Terry 排名。论文发现 GPT-4o 等顶级商业模型已经达到或超过人类详细描述水平，多数开源模型仍明显落后；同时传统 caption metrics 在详细描述上存在系统性模型偏置，而 VLM-as-a-Judge 尤其是 GPT-4o with reference 能更好对齐人类排名。基于这些结论，作者发布 CapArena-Auto，用 600 张图、三档 baseline 和 VLM judge 以约 $4 成本达到 0.943 Spearman 人类排名相关。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文解决的是一个看起来基础、但长期被低估的问题：

**在现代 VLM 已经能写很长、很细的图像描述之后，我们到底怎么评测 caption 写得好不好？**

传统 image captioning 的评测体系主要围绕 MSCOCO 这类短 caption 数据集构建。典型参考描述可能只有十几个词，例如“a dog sitting on a couch”。BLEU、CIDEr、METEOR、SPICE 等指标也基本建立在短句参考答案和 n-gram / scene graph 匹配上。

但 LLM 时代的 VLM 已经变了。GPT-4o、Gemini、Claude、Qwen2-VL、InternVL 等模型可以生成很长的 detailed caption：不仅描述主体，还会写对象属性、动作、空间关系、场景背景、文字、细节和推测性语义。

这带来一个新矛盾：**模型会写得更详细了，但评测方法还停留在短 caption 时代。**

作者因此提出 CapArena：

- 用 DOCCI 的高分辨率日常场景图像；
- 收集模型生成的详细 caption 和人类长 caption；
- 让训练过的人工标注者做匿名 pairwise caption battle；
- 用 Bradley-Terry / ELO 式排名估计模型能力；
- 再用这批人类偏好数据系统分析自动指标和 VLM-as-a-Judge；
- 最后发布自动化版本 CapArena-Auto。

论文最重要的结果有两个：

1. 顶级商业 VLM，尤其 GPT-4o，在 detailed image captioning 上已经达到甚至超过人类长描述 baseline。
2. 传统 caption metrics 在详细描述上不可靠，主要问题不是单样本 agreement 永远很低，而是它们对不同模型有系统性偏置；VLM-as-a-Judge 更适合这个评测形态。

## 🎯 研究背景

这篇工作位于三个方向的交叉处。

### 1. Image Captioning

Image captioning 是视觉语言研究的老问题。早期模型主要生成一句概括性描述，评测也围绕短文本参考答案做。

但现在的 detailed captioning 不一样。一个好 caption 可能要说明：

- 图中有哪些主要对象；
- 它们的属性、颜色、姿态；
- 彼此之间的空间关系；
- 场景上下文；
- 是否有文字、标志、表情、细微动作；
- 哪些内容不能乱猜，避免 hallucination。

这使得 caption quality 从“是否像参考句”变成了“是否完整、准确、细致、无幻觉地描述图像”。

### 2. VLM 评测

当前 VLM 评测主要集中在 VQA、OCR、数学、推理、多选题等任务。这些任务相对容易构造标准答案。

captioning 更难，因为它是开放生成任务。同一张图可以有很多高质量写法。一个 caption 更简洁，另一个更详细；一个更关注人物姿态，另一个更关注背景关系。很难用单一 reference 或单一分数定义绝对好坏。

### 3. Arena-style Evaluation

Chatbot Arena 证明 pairwise battle 更适合评估开放式生成质量。CapArena 把这个思想移到 detailed image captioning：不要求标注者给单个 caption 打 1-5 分，而是让他们在同一张图的两个匿名 caption 中选择更好者。

这个转变很关键，因为 detailed caption 的绝对打分很难稳定，但 pairwise 比较更接近人的实际判断。

## ⚠️ 问题与挑战

论文要解决的问题是：**如何可靠评估现代 VLM 的详细图像描述能力，并找到能替代昂贵人工评测的自动化方法。**

这个问题难在几个层面。

### 1. 因为 detailed caption 没有唯一答案，所以传统 reference matching 会失效

同一张图可以有多个正确描述。如果一个模型写了参考答案没提到的细节，BLEU / CIDEr 可能不奖励；如果它复用了参考答案里的词，但漏掉关键动作，也可能拿到不低分。

例如图里是一只猫扑向狗。一个 caption 如果只说“猫和狗在一起”，字面上没错，但没有抓住动作；另一个 caption 描述猫跃起、爪子伸向狗脸，更有信息量。传统 n-gram 指标很难稳定捕捉这种差异。

### 2. 因为详细描述同时看准确性和信息量，所以单一评分很难一致

作者最初尝试让标注者给单个 caption 打 1-5 分，但发现一致性低。原因不是标注者不认真，而是任务本身主观：

- 有人更重视是否完整；
- 有人更重视是否无幻觉；
- 有人更重视动作和关系；
- 有人更关注文字和小物体。

所以论文转向 pairwise battle，并把评价重点明确为 precision、informativeness 和 hallucination penalty。

### 3. 因为 caption 长度会干扰判断，所以必须控制“越长越好”的偏见

详细 caption 往往更长，但更长不一定更好。一个模型可以写很多不确定、重复或无关内容，看起来详尽，实际信息质量不高。

CapArena 的标注指南要求标注者关注描述质量，而不是单纯偏好更长文本；如果两个 caption 质量接近，明显过长的一方反而不应被偏好。

### 4. 因为人工标注昂贵，所以需要自动评测，但自动评测又容易有模型偏置

CapArena 收集 6522 条人工标注，平均每条 annotation 花 142 秒。这种规模已经很有价值，但不可能每次新模型发布都重新做人类 arena。

因此自动指标必不可少。难点是，自动指标不只要在单个 pair 上判断对，还要在模型级排名上不偏向某些模型风格。论文发现这正是很多指标失败的地方。

## 🔍 核心发现 Finding

### 作者明确声称

作者明确的发现是：

**现代 VLM 的 detailed image captioning 已经进入需要 arena-style human preference evaluation 的阶段；顶级商业模型达到人类水平，而现有自动指标普遍存在系统性偏置，VLM-as-a-Judge 更能对齐人类偏好。**

### 我的理解

我认为这篇论文真正的 `Finding` 是：

**详细图像描述的评测对象已经从“生成一句像参考答案的短句”变成了“在多个合理描述之间判断哪一个更准确、更有信息量、更少幻觉”。因此，评测方法也必须从 reference matching 转向 preference ranking。**

这个 finding 改变了问题的定义。

旧的 captioning 评测像考试填空：参考答案在那里，模型越接近越好。新的 detailed captioning 更像编辑评审：两段文字可能都对，但一个更抓住图像关键细节，另一个更泛泛；一个更具体但有幻觉，另一个更保守但漏信息。此时“像不像 reference”不再等于“好不好”。

CapArena 的 insight 是：与其寻找一个绝对分数，不如直接让人比较两个 caption。然后用足够多的 pairwise battles 估计模型整体能力。这解决了两个问题：

- 对单个 caption 绝对打分太主观；
- 多模型排序需要稳定统计估计。

更进一步，论文发现 METEOR、Output Length 等指标可能在 caption-level agreement 上看起来还不错，但会系统性高估某些模型、低估另一些模型，导致最终模型排名错。这说明评测指标不能只看单样本 accuracy，还要看 model-level bias。

## 🔬 方法

### 输入数据与模型集合

CapArena 使用 **DOCCI** 数据集中的高分辨率日常场景图像。DOCCI 每张图都有人工长描述，论文把它作为 human baseline。

模型集合包含 14 个代表性 VLM，覆盖商业模型和开源模型，例如：

- GPT-4o-0806；
- GPT-4o-mini-0718；
- Gemini-2.0-flash-exp；
- Gemini-1.5-pro-002；
- Claude-3.5-Sonnet-0620；
- InternVL2-26B；
- Qwen2-VL 系列；
- Llama-3.2-90B-Vision；
- CogVLM2；
- MiniCPM-V2.6；
- LLaVA 系列。

为了减少 prompt 偏置，作者手工设计了 10 个 detailed caption prompts，并检查它们生成的描述质量和长度相近。

### CapArena 人工评测流程

CapArena 是一个匿名 pairwise battle 平台。

对同一张图，平台展示两个不同来源的 caption。标注者不知道 caption 来自哪个模型，只根据图像和文本判断哪个更好，或者是否接近。

标注指南主要看三点：

1. **Precision**  
   描述是否准确，是否和图像细节一致，包括对象、属性、关系、位置。

2. **Informativeness**  
   是否覆盖了图像中的重要信息，尤其是 salient objects 和关键细节。

3. **Hallucination penalty**  
   如果 caption 描述了图中不存在的对象或关系，要严格扣分。

作者还特别要求标注者不要被长度和写作风格干扰。

### Pair selection 与排名估计

为了更快比较水平接近的模型，CapArena 借鉴 Chatbot Arena 的采样策略，优先选择能最大缩小置信区间的模型对。

最后用 Bradley-Terry 模型估计模型得分，并通过 bootstrap 1000 次构造置信区间。

标注质量方面：

- 标注者是熟悉 NLP / image captioning 的研究生；
- 先做 100 条预标注和指南校准；
- 400 条样本被不同标注者重复标注；
- inter-annotator agreement 为 0.782；
- 总共收集 6522 条 annotation；
- 平均每条耗时 142 秒。

### 自动指标分析

作者把 CapArena 人类标注当作 golden standard，评估多类自动指标：

- 传统指标：BLEU-4、SPICE、CIDEr、METEOR；
- CLIP-based 指标：CLIPScore、LongCLIPScore、Polos、FLEUR；
- detailed caption 指标：CAPTURE、VDC-Score；
- VLM-as-a-Judge：LLaVA-OneVision、LLaVA-Critic、Qwen2.5-VL、GPT-4o、GPT-4o with reference。

评估分两层：

1. **Caption-level agreement**  
   单个 pairwise battle 上，指标判断是否和人类一致。

2. **Model-level agreement**  
   用指标替代人类标注重新跑 arena 排名，看模型排序是否和人类 ranking 一致，报告 Spearman 和 Kendall tau。

这个设计很重要，因为一个指标可以在单样本上还行，但如果持续偏爱某类模型风格，最终排行榜会错。

### CapArena-Auto

人工 CapArena 成本高，因此作者发布 **CapArena-Auto**：

- 选取 600 张 DOCCI test split 图像；
- 通过聚类和 CLIP 特征过滤保证多样性与去重；
- 使用 pairwise battle；
- 每个测试模型和三个 baseline 模型比较：GPT-4o、CogVLM-19B、MiniCPM-8B；
- 用 GPT-4o 作为 judge；
- 给 judge 提供 human reference caption 作为辅助；
- 胜 +1，负 -1，平 0，最后求总分。

CapArena-Auto 的目标不是替代所有人类评测，而是提供一个成本低、和人类 ranking 高相关的快速 benchmark。

## 📊 实验与结论

### 1. 顶级模型已经达到或超过人类 detailed caption baseline

CapArena 的排名显示，GPT-4o-0806 位于顶端，与人类 baseline 非常接近甚至略优。论文强调，这是 detailed image captioning 的一个重要里程碑：机器生成描述不再只是“够用”，在一些情况下已经能比人工长描述更全面。

作者在附录中举例说明，人类描述有时会漏掉周围环境、细小对象或上下文关系，而 GPT-4o 能覆盖更多视觉细节。

但这不意味着所有 VLM 都达到人类水平。多数开源模型仍明显落后，尤其在细粒度视觉感知、异常场景、知识关联和时钟时间识别上容易失败。

### 2. 开源模型和商业模型仍有明显差距，但 InternVL2-26B 是例外

CapArena 发现，很多在通用多模态 benchmark 上表现不错的开源模型，在 detailed captioning 上仍不稳定。

值得注意的是 **InternVL2-26B**：它作为中等规模开源模型表现突出。作者认为这可能和它的大视觉编码器 InternViT-6B 有关，说明 detailed captioning 对细粒度视觉表示能力要求很高。

这也解释了为什么 MMMU、MathVista、POPE 等通用 benchmark 分数不能完全预测 captioning 能力。一个模型会做多选推理，不代表它能稳定生成细节丰富、无幻觉的描述。

### 3. 传统指标在 detailed captioning 上整体失败

Table 2 显示，传统指标的 caption-level agreement 和 model-level agreement 都不理想。

例如：

- BLEU-4 overall caption agreement 只有 0.474；
- CIDEr 只有 0.384；
- CLIPScore 只有 0.325；
- METEOR 较高，为 0.576，但 model-level Kendall tau 只有 0.582。

这说明短 caption 时代的指标很难处理长描述中的细粒度语义。

### 4. METEOR 和长度这类指标的问题是系统性偏置

论文一个重要分析是系统性偏置。

METEOR 和 Output Length 在单个 battle 上可能和人类有一定一致性，但它们会稳定高估或低估某些模型。例如 Output Length 本质上偏好更长 caption，而更长不一定更准确。

作者通过比较各模型的指标平均胜率和人类 golden win rate，画出 bias heatmap。结果显示所有指标都有偏置，但 GPT-4o-as-a-Judge 的平均偏置低于 METEOR：4.4% vs. 8.2%。

这说明 GPT-4o judge 的错误更像独立样本上的随机偏差，而不是稳定偏向某些模型风格，因此最终模型排名更可靠。

### 5. VLM-as-a-Judge 是当前最好的自动评测方向

VLM-as-a-Judge 在 caption-level 和 model-level 上都明显优于传统指标。

Table 2 中：

- GPT-4o-as-a-Judge overall caption-level agreement 为 0.628；
- GPT-4o with reference 为 0.627；
- GPT-4o with reference 的 model-level Spearman 达到 0.943，Kendall tau 达到 0.846；
- human inter-annotator agreement 为 0.683，说明当前自动 judge 仍低于人类一致性，但已经接近可用。

参考 caption 对 model-level ranking 特别有帮助，因为它能帮助 judge 确认一些图像细节，减少对模型风格的误判。

### 6. 难区分样本仍然是自动评测瓶颈

作者把 pairwise battles 按模型排名差距分成四个难度级别。Level 1 是明显强弱对比，比如 GPT-4o vs. LLaVA-1.5；Level 4 是水平接近模型之间的比较。

在 Level 3 / Level 4 上，即使 GPT-4o judge 也明显低于人类标注者一致性。这说明当两个 caption 都不错、差异很细时，自动 judge 仍然难以稳定感知所有图像细节。

### 7. CapArena-Auto 高相关且低成本

CapArena-Auto 与人工 CapArena golden ranking 的相关性最高：

- Spearman: 0.943；
- Kendall tau: 0.824；
- 每次评测成本约 4 美元。

对比：

- DOCCI + BLEU-4 Spearman 只有 0.341；
- DOCCI + METEOR 为 0.859；
- CAPTURE 为 0.763。

这说明使用 pairwise battle + 多档 baseline + GPT-4o judge + reference caption 的组合，比单一指标更接近人类偏好。

### 结论

作者可以合理得出的结论是：

1. Detailed image captioning 需要新的评测范式，传统短 caption 指标已经不够。
2. Pairwise battle 比 1-5 分绝对评分更适合开放式详细描述。
3. GPT-4o 等顶级模型已经达到或超过人类 caption baseline，但多数开源模型仍落后。
4. 通用多模态 benchmark 分数不能完全代表 captioning 能力。
5. 自动指标的核心风险是系统性模型偏置，而不仅是单样本 agreement。
6. VLM-as-a-Judge with reference 是当前最可用的自动评测方案，CapArena-Auto 提供了低成本版本。

我的保留意见：

- CapArena 当前只覆盖 14 个代表性 VLM，模型范围仍有限，很多后续新模型没有纳入。
- 图像主要来自日常生活场景，不覆盖医学图像、艺术图像、工业检测等专业领域。
- 人类 baseline 来自 DOCCI 长描述，不等于所有人类都能写出的最优 caption，也可能遗漏细节。
- GPT-4o judge 表现最好，但 CapArena-Auto 因此依赖专有模型，复现和长期成本仍受 API 影响。
- Pairwise battle 适合排名，但不直接告诉模型应该如何改进 caption，和训练用 reward 之间还需要进一步桥接。

## 🧩 关键术语

- **Detailed Image Captioning（详细图像描述）**: 生成长而细的图像描述，覆盖对象、属性、动作、空间关系和背景细节。例子：不只说“狗和猫在一起”，而是描述猫跃起、爪子伸向狗脸、狗叼着树枝。

- **CapArena（图像描述竞技场）**: 论文提出的人类偏好评测平台，用匿名 pairwise caption battle 排名 VLM。例子：同一张图展示 GPT-4o 和 Qwen2-VL 的 caption，让标注者选更好者。

- **Pairwise Caption Battle（成对描述对战）**: 不给单个 caption 打绝对分，而是比较两个 caption 哪个更好。例子：Caption A 更完整但有幻觉，Caption B 较短但准确，标注者需要权衡。

- **Precision（精确性）**: caption 是否准确反映图像细节。例子：把猫“扑向狗”写成“站在狗旁边”就是 precision 错误。

- **Informativeness（信息量）**: caption 是否覆盖关键对象和重要细节。例子：只说“墙上有画”不如说明画中人物、服饰、光环和建筑位置。

- **Hallucination（幻觉）**: caption 写了图中不存在的对象、属性或关系。例子：图里没有人，却说“一个男人站在旁边”。

- **Bradley-Terry Model（BT 排名模型）**: 从 pairwise preference 中估计整体能力分数的模型。例子：如果 A 经常赢 B 和 C，BT 会给 A 更高 rating。

- **Caption-level Agreement（描述级一致性）**: 自动指标在单个 caption pair 上是否和人类选择一致。例子：某 pair 人类选 A，指标也选 A，则一致。

- **Model-level Agreement（模型级一致性）**: 用自动指标重新排名模型后，排名是否接近人类 arena 排名。例子：Spearman 0.943 表示模型顺序高度一致。

- **Systematic Bias（系统性偏置）**: 指标稳定偏好某类模型或输出风格。例子：Output Length 总偏好更长 caption，会高估冗长模型。

- **VLM-as-a-Judge（用视觉语言模型做评委）**: 让强 VLM 看图和两个 caption，判断哪个更好。例子：GPT-4o with reference 同时看图、人类参考描述和两个候选 caption。

- **CapArena-Auto（自动化 CapArena）**: 自动评测版本，用 600 张图、三个 baseline 和 GPT-4o judge 近似人类 arena 排名。例子：每个模型和 GPT-4o、CogVLM、MiniCPM 逐图对战后累计得分。

## 💡 个人评价

这篇论文的价值不在于提出一个新的 captioning 模型，而在于把 detailed captioning 的评测问题重新定义清楚了。它说明：当 caption 变成长文本、开放文本之后，旧指标的参考匹配思路已经跟不上了。

我认为最有启发的是 model-level bias 分析。很多指标如果只看 caption-level agreement，似乎还能用；但一旦把它们用于模型排名，就会因为稳定偏好某种文本风格而偏离人类判断。这对所有开放生成任务评测都有借鉴意义：评测指标不仅要看单例对错，还要看是否会系统性高估某些模型家族。

这篇论文也和 RubiCap、CapRL 这些训练 dense captioner 的工作形成互补。CapArena 更像“评测地基”：先告诉我们什么样的 caption 评测可信，再让后续 RL 或 SFT 方法有可靠目标。

后续我会重点关注三个方向：

- 是否能把 CapArena-Auto 的 pairwise judge 进一步转成训练 reward；
- 是否能构建开源 VLM judge，降低 GPT-4o 依赖；
- 是否能扩展到专业图像、图表、医学影像和多图场景。

## 🔗 相关论文

- DOCCI: Descriptions of Connected and Contrasting Images
- Chatbot Arena: An Open Platform for Evaluating LLMs by Human Preference
- CAPTURE: an automatic metric for detailed image captioning
- VDC-Score: evaluation for detailed video captioning
- CLIPScore / LongCLIPScore
- METEOR / CIDEr / SPICE
- RubiCap: Rubric-Guided Reinforcement Learning for Dense Image Captioning
- CapRL: Training Caption Models with Utility-Based Rewards
