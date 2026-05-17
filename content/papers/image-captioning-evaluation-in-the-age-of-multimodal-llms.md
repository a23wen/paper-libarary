---
title: "Image Captioning Evaluation in the Age of Multimodal LLMs: Challenges and Future Perspectives"
date: 2026-05-17T00:00:00+08:00
draft: false

# 分类（研究领域）
categories: ["计算机视觉"]

# 会议/期刊
venues: "IJCAI 2025"

# 论文元数据
authors: ["Sara Sarto", "Marcella Cornia", "Rita Cucchiara"]
year: "2025"
paper_url: "https://arxiv.org/abs/2503.14604"
arxiv_url: "https://arxiv.org/pdf/2503.14604"
code_url: "https://github.com/aimagelab/awesome-captioning-evaluation"

# 阅读状态
status: "completed"
rating: 4
read_date: "2026-05-17"

summary: "这篇 IJCAI 2025 survey 系统梳理了 image captioning evaluation 在 MLLM 时代面临的新问题。论文把评测指标分为 rule-based、learnable、LLM-based 和 hallucination-oriented 等类别，比较它们在 human judgment correlation、pairwise ranking、object hallucination sensitivity 和 MLLM 长 caption system-level evaluation 上的表现。核心结论是：传统 BLEU / CIDEr / SPICE 等 reference overlap 指标仍能服务短 COCO 风格 caption，但面对 MLLM 生成的长而细的描述会明显失真；结合图像输入、预训练表征、细粒度结构或 LLM 解释能力的现代指标更稳，但仍需要更贴近长 caption、幻觉、多样化用户偏好的新 benchmark。"
---

{{< paper-info >}}

## 📋 论文概述

这是一篇关于 **image captioning evaluation** 的综述。它关注的不是如何生成 caption，而是一个更基础的问题：

**当 MLLM 已经能生成很长、很细、风格多样的图像描述时，我们还应该怎么判断一个 caption 好不好？**

传统 caption 评测长期围绕 COCO 风格短句展开。BLEU、METEOR、ROUGE、CIDEr、SPICE 等指标主要比较候选 caption 和参考 caption 的文本重合或语义结构。但现在的 MLLM caption 可能是几句话甚至一段文字，包含对象属性、空间关系、背景信息、推断性描述和细节解释。

这会让旧指标遇到两个问题：

- reference caption 太短，不能覆盖长 caption 里的合理细节；
- 文字重合不等于视觉忠实，尤其无法可靠处理幻觉。

论文因此系统梳理了多类指标，并做实验比较它们在四个维度上的表现：

1. 与人类判断的相关性；
2. pairwise ranking 能力；
3. 对对象幻觉的敏感性；
4. 对现代 MLLM 短 caption 与长 caption 的 system-level 评价稳定性。

最终结论很清楚：**传统 rule-based metrics 在短 caption 上仍有历史价值，但 MLLM 时代的 caption evaluation 必须更依赖图像输入、可学习视觉语言表征、细粒度语义检查、可解释评估和幻觉敏感 benchmark。**

## 🎯 研究背景

这篇工作位于三个方向的交叉处。

### 1. Image Captioning 的任务形态变化

早期 image captioning 模型通常输出一句简短描述。COCO 参考答案也很短，例如“a man riding a horse”。这种设置下，评测可以近似看候选句和多条参考句是否重合。

但 MLLM 改变了 caption 的形态。LLaVA、IDEFICS、Llama 3.2 Vision 等模型可以生成更长、更开放的描述。一个 caption 可能同时描述主体、背景、关系、文本、动作、场景风格和不确定性。

这使得“像不像参考答案”不再等于“好不好”。

### 2. Caption Metric 的演化

论文把指标演化分成几条线：

- **rule-based metrics**：BLEU、METEOR、ROUGE、CIDEr、SPICE；
- **learnable unsupervised metrics**：BERT-S、CLIPScore、PAC-S、InfoMetIC 等；
- **supervised metrics**：Polos、DENEB 等；
- **fine-grained oriented metrics**：BRIDGE、HICE-S、HiFi-S 等；
- **LLM-based metrics**：CLAIR、FLEUR 等；
- **hallucination-oriented metrics**：CHAIR、ALOHa 等。

这条演化线的共同方向是：从只看文本重合，逐渐转向看图像-文本对齐、局部语义、错误定位和解释能力。

### 3. MLLM 时代的评测断层

现代 caption 更长、更细，但许多 benchmark 和指标仍建立在短参考句上。结果是，指标可能惩罚“合理但参考句没写”的细节，也可能无法惩罚“流畅但图里没有”的幻觉。

这正是 CapArena、ScaleCap、CapRL、RubiCap 这些工作都绕不开的问题：caption 的训练、生成和评测已经一起进入长文本、开放文本、多维质量判断阶段。

## ⚠️ 问题与挑战

论文要解决的问题是：**现有 caption evaluation metrics 在 MLLM 时代是否仍可靠，以及未来评测体系应该往哪里走。**

这个问题难在几个层面。

### 1. 因为 reference caption 过短，所以长 caption 会被错误惩罚

COCO 参考句通常只覆盖主体事件。一个 MLLM caption 如果写出更多真实细节，BLEU / CIDEr 可能因为 n-gram 不匹配而扣分。

例如参考句是“a cat sitting on a car”。候选 caption 写“a black cat stands on the hood of a car, looking into the engine compartment”。这显然更细，但传统 overlap 指标可能不一定给高分。

### 2. 因为 fluency 不等于 faithfulness，所以纯文本语义相似不够

一个 caption 可以写得自然、完整、像人话，但仍然包含图里没有的对象或关系。只看 candidate 和 reference 的文本相似度，无法判断这些新增细节是否视觉真实。

这也是为什么论文反复强调图像输入的重要性：caption evaluation 不是普通文本相似度任务，而是视觉-语言对齐任务。

### 3. 因为 MLLM 输出风格差异大，所以单一 benchmark 很容易偏

短 caption、长 caption、dense caption、用户偏好的简洁描述、面向 VQA 的信息密集描述，对“好”的定义都不完全一样。

一个指标如果只在 COCO 风格上训练，遇到 MLLM 默认 prompt 生成的长描述时，可能会把长度和风格差异误判成质量差异。

### 4. 因为幻觉越来越复杂，所以 FOIL 式简单替换不够

FOIL 通过替换一个对象词制造错误，例如把 dog 换成 cat。这能测试简单对象幻觉，但 MLLM 的错误更复杂：

- 属性错；
- 空间关系错；
- 动作错；
- 推断不存在；
- 把背景常识当成图像事实。

评测指标如果只会发现单词级错误，就无法覆盖现代 caption 幻觉。

## 🔍 核心发现 Finding

### 作者明确声称

作者明确的发现是：**传统 rule-based metrics 难以评估 MLLM 生成的长而详细 caption；learnable metrics 在长度和风格变化下更稳，但 caption evaluation 仍需要更健壮、更上下文感知、更可解释的未来框架。**

### 我的理解

我认为这篇综述真正的 `Finding` 是：

**MLLM 时代的 caption evaluation 已经从“候选句是否匹配参考句”转变为“候选描述是否在图像证据约束下满足具体使用目标”。**

这个 finding 的关键在于，它把评测目标从单一相似度变成多维判断。

旧范式像对答案：参考句写了什么，候选句越接近越好。新范式更像审稿：

- 它是否覆盖关键对象？
- 是否保留空间关系？
- 是否有幻觉？
- 是否足够详细但不过度臆测？
- 是否适合当前任务，是 VQA、检索、重建，还是人类阅读？

这解释了为什么没有一个指标能在所有数据集和任务上持续最优。caption 质量不是单一标量天然能完全表达的东西，尤其当输出从短句变成长文本后，评估必须同时考虑 reference、image、human preference、hallucination 和任务偏好。

## 🔬 方法与综述框架

### 指标分类

论文首先建立了一个 taxonomy，按是否使用 reference captions、是否使用 image input、是否依赖学习模型来组织指标。

**Rule-based metrics** 主要包括 BLEU、METEOR、ROUGE、CIDEr、SPICE。它们的优点是简单、可复现、历史对比多；缺点是依赖 reference，且大多不直接看图。

**Learnable metrics** 使用预训练语言模型或视觉语言模型。BERT-S 类指标关注文本语义相似；CLIP-S、PAC-S、PAC-S++ 等用图像和文本 embedding 评估对齐；InfoMetIC 进一步尝试定位错误词和未描述区域。

**Supervised metrics** 如 Polos、DENEB 直接利用人类评价数据训练。它们更贴近人类判断，但会受数据域、标注风格和模型容量影响。

**Fine-grained metrics** 如 BRIDGE、HICE-S、HiFi-S 试图从局部区域、层级结构或解析图角度捕捉细节，不只看全局图文相似。

**LLM-based metrics** 如 CLAIR、FLEUR 借助 LLM / MLLM 的推理与解释能力评估 caption。它们潜力大，但成本、稳定性和模型依赖也更强。

**Hallucination-oriented metrics** 如 CHAIR、ALOHa 等聚焦对象或细节幻觉，适合补足通用指标对 factuality 的盲区。

### 实验维度

论文做了四类实验分析。

第一，与 human judgment 的相关性。数据集包括 Flickr8k-Expert、Flickr8k-CF、Composite、Polaris、Nebula，使用 Kendall correlation 等指标衡量 metric 与人类评分的一致性。

第二，pairwise ranking。使用 Pascal-50S，判断指标是否能在两条 caption 中选出人类更偏好的那条。

第三，对 object hallucination 的敏感性。使用 FOIL，测试指标能否给原始正确 caption 高于被替换对象词的错误 caption。

第四，system-level correlation。论文在 COCO test set 上比较传统 captioning models 和 general-purpose MLLMs，同时区分 MLLM 短 caption 与长 caption，观察指标是否受长度和风格影响。

## 🧪 实验与结论

### 1. 与人类判断相关性：现代指标整体优于 rule-based

在 human correlation 实验中，CIDEr 是 rule-based 方法里较强的指标，但整体上现代 learnable / supervised / LLM-based 指标更有优势。

论文指出，reference-based metrics 往往比 reference-free counterparts 表现更好，因为参考句仍提供了有用监督。但在没有参考的场景下，InfoMetIC 和 PAC-S 系列表现相对突出，说明经过针对性训练或微调的视觉语言 embedding 对 caption evaluation 很有价值。

一个重要观察是：FLEUR 这类 MLLM-based metric 能达到强表现，但不一定压倒更小的专用 CLIP-based metric。这说明在 caption evaluation 这种具体任务上，**专门校准过的表征空间可能比更大的通用模型更有效率。**

### 2. Pairwise ranking：不同维度会改变指标排序

在 Pascal-50S 的 pairwise ranking 中，METEOR 是 rule-based 指标里最强的，略优于 CIDEr。learnable 指标的排序则和 human correlation 不完全一致，InfoMetIC 作为 reference-free metric 表现突出。

这说明 metric 的“好”不是单维的。一个指标在全局相关性上强，不代表它一定最擅长 pairwise preference；反过来，能定位错误词和遗漏区域的指标，在二选一判断中可能更有优势。

### 3. 幻觉检测：只看文本重合不够

在 FOIL 上，CIDEr 是 rule-based 指标里表现较好的，但现代 multimodal metrics 明显更强。论文提到，RefPAC-S、RefFLEUR 等能利用图像-文本对齐能力检测细微错误，明显优于传统方法。

这支持一个很直接的结论：**caption hallucination evaluation 必须看图。** 如果一个指标不知道图像内容，就很难判断新增对象或关系到底是真实细节还是编造内容。

### 4. MLLM 长 caption：CIDEr 等 rule-based 指标会失真

system-level 实验最贴近 MLLM 时代的问题。

对传统 captioning models，例如 M2 Transformer、BLIP-2 这类 COCO 风格输出，CIDEr 等指标仍然能识别质量差异。因为候选 caption 和 reference caption 在长度、语气和信息密度上接近。

但当 MLLM 生成长描述时，rule-based metrics 会明显崩。论文给出的例子是：LLaVA-1.5 生成明显更长的 caption 时，CIDEr 分数会降到非常低，原因不是 caption 一定差，而是它和短 reference 的 n-gram overlap 太低。

相比之下，PAC-S++ 等结合视觉输入和预训练表征的指标对长度变化更稳。论文也指出，reference-free metrics 通常比 reference-based metrics 更适合长 caption，因为它们不那么受短 reference 风格牵制。

## 🚧 Future Directions

论文提出了几个未来方向。

### 1. Benchmark Evolution

现有 benchmark 大多还是短 COCO 风格。未来需要专门面向 MLLM 长 caption 的 benchmark，覆盖同义改写、长文本细节、领域术语和复杂视觉关系。

### 2. Explainability in Metrics

很多指标只给分，不解释为什么。对模型改进来说，这不够。未来指标应该能指出问题，例如“漏掉了左侧小孩”“把杯子误写成碗”“空间关系反了”。

### 3. Detecting Hallucinations

需要更复杂的 hallucination benchmark，而不是只做对象词替换。现代 MLLM 的幻觉可能是属性、关系、动作、场景推断，甚至是整体叙事层面的错误。

### 4. Metrics Personalization

不同用户对 caption 的偏好不同。检索任务可能偏好关键词覆盖，VQA 预训练可能偏好信息密度，辅助无障碍阅读可能偏好清楚、准确和不过度推断。未来 metric 需要支持用户或任务自定义权重。

## 🔑 关键术语

- **Rule-based Metrics（规则指标）**: 基于文本重合或手工结构的指标。例子：CIDEr 用 TF-IDF 加权 n-gram，SPICE 把 caption 转成 scene graph。

- **Reference-based Metrics（参考答案指标）**: 需要人类参考 caption 的指标。例子：BLEU 比较候选句和多个参考句的 n-gram overlap。

- **Reference-free Metrics（无参考指标）**: 不依赖参考 caption，通常直接评估图像和候选 caption 是否匹配。例子：CLIPScore 用 CLIP 图文 embedding 相似度。

- **PAC-S / PAC-S++**: 基于 CLIP embedding 空间并针对 caption evaluation 做改进的 learnable metrics。例子：相比原始 CLIPScore，它更适合评价生成 caption。

- **Polos**: 使用人类评价数据监督训练的 multimodal metric，用图像和文本预测 caption 质量。

- **DENEB**: 面向 hallucination robustness 的 supervised evaluation metric，并引入 Nebula 数据扩展视觉多样性。

- **FLEUR**: MLLM-based caption evaluation metric，利用多模态模型的判断和解释能力。

- **CHAIR**: 用于衡量 caption 中对象幻觉的指标。例子：图里没有“horse”，caption 却写了 horse，就会被计入幻觉。

- **FOIL**: 通过替换 caption 中对象词构造错误样本的数据集，用来测试指标是否能发现对象级错误。

## 🧭 评价与启发

这篇 survey 的价值在于，它把 caption evaluation 的历史路径和 MLLM 时代的新断层放在一起看。它不是简单说“旧指标没用”，而是说明旧指标适用的前提变了：

- 如果 caption 是 COCO 风格短句，CIDEr / SPICE 仍有参考意义；
- 如果 caption 是 MLLM 风格长描述，reference overlap 会把风格差异误当质量差异；
- 如果关心 hallucination，指标必须利用图像输入；
- 如果关心模型改进，指标最好能解释错误，而不是只给一个分数。

这对读 CapArena、ScaleCap、CapRL、RubiCap 这类论文很有帮助。它提供了一个评测地图，让我们知道为什么这些新工作不再满足于 BLEU / CIDEr，而是转向 pairwise preference、Prism、VQA utility、rubric 或 reconstruction。

局限也存在：

- 作为 survey，它没有提出新的 metric；
- 长 caption benchmark 的讨论更多是方向性建议，实证仍受现有数据集限制；
- 对中文、多语言 caption、专业领域 caption 的评测讨论较少；
- personalization 很重要，但论文没有给出具体可操作框架。

## 💡 可借鉴点

1. **评估 detailed caption 时不要只报 CIDEr，至少补充 multimodal 或 reference-free metric。**
2. **长 caption 不能直接拿短 reference overlap 分数下结论。**
3. **幻觉评估需要图像输入和细粒度错误定位。**
4. **caption metric 的选择应该和任务目标绑定：预训练、VQA、检索、人类阅读可能需要不同偏好。**
5. **未来高质量 caption benchmark 应该覆盖长文本、复杂关系、幻觉、解释和用户偏好。**

**适合读者**：计算机视觉、图像描述、MLLM 评测、多模态 benchmark、caption reward 设计方向研究者

**一句话总结**：这篇综述的核心提醒是，MLLM 时代的 image caption evaluation 不能继续把“像不像短参考句”当成全部答案；真正可靠的评测必须看图、看细节、看幻觉、看任务目标，并能解释为什么一个 caption 更好。
