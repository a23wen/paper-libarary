---
title: "MedAgentGym: A Scalable Agentic Training Environment for Code-Centric Reasoning in Biomedical Data Science"
date: 2026-05-20T00:00:00+08:00
draft: false

# 分类（研究领域）
categories: ["自然语言处理"]

# 会议/期刊
venues: "arXiv 2025"

# 论文元数据
authors: ["Ran Xu", "Yuchen Zhuang", "Yishan Zhong", "Yue Yu", "Zifeng Wang", "Xiangru Tang", "Hang Wu", "May D. Wang", "Peifeng Ruan", "Donghan Yang", "Tao Wang", "Guanghua Xiao", "Xin Liu", "Carl Yang", "Yang Xie", "Wenqi Shi"]
year: "2025"
paper_url: "https://arxiv.org/abs/2506.04405"
arxiv_url: "https://arxiv.org/pdf/2506.04405"
code_url: "https://github.com/wshi83/MedAgentGym"

# 阅读状态
status: "completed"
rating: 4
read_date: "2026-05-20"

summary: "MedAgentGym 提出一个面向生物医学数据科学的代码型 LLM agent 训练环境，覆盖 12 个真实生物医学场景、129 个类别、72,413 个任务实例。它把临床数据库查询、医学计算、生物信息学、EHR 预测建模等任务封装为可执行 Docker sandbox，提供可验证 ground truth、交互式反馈、调试信息和大规模轨迹采样。论文用 MedAgentGym benchmark 评测 29 个商业和开源 LLM，发现开源模型在生物医学代码推理上明显落后；随后用采样轨迹训练 Med-Copilot，Qwen2.5-7B 在 SFT 后再经 DPO / GRPO 分别获得 +43.02% / +45.28% 平均分提升，证明可执行环境和轨迹级训练能显著增强轻量开源医学 coding agent。"
---

{{< paper-info >}}

## 📋 论文概述

这篇论文解决的是一个很具体、但实际价值很高的问题：

**生物医学研究里的很多问题不是问答题，而是要写代码、查数据、跑统计、调试程序，最后得到一个可验证的结果。我们该如何评测和训练这样的 LLM agent？**

现有医疗 LLM benchmark 大多关注医学知识问答、诊断推理或单轮选择题。可真实生物医学数据科学工作流更像这样：

- 从 EHR 数据库里按时间条件查患者记录；
- 根据临床规则计算风险分数或药物剂量；
- 写 bioinformatics 脚本处理基因组序列；
- 基于纵向 EHR 做预测建模；
- 调试依赖包、文件路径、数据格式和执行错误。

这些任务要求模型同时具备医学知识、数据科学能力、代码生成能力和交互式调试能力。论文提出 **MedAgentGym**，把这些任务统一成一个可执行、可交互、可训练的 agent 环境。

MedAgentGym 的核心规模是：

- `72,413` 个任务实例；
- `129` 个类别；
- `12` 个真实生物医学场景；
- 覆盖 EHR 表格、临床笔记、基因组、药物、生物序列等数据；
- 提供 Docker sandbox、ground truth、执行反馈和轨迹采样；
- 开源 GitHub 和 Hugging Face 资源。

论文还训练了 **Med-Copilot**。它不是只做 prompt engineering，而是用 MedAgentGym 采样的成功轨迹、失败轨迹和环境反馈做 SFT、DPO、PPO、GRPO 等训练。结果显示，轻量开源模型可以被显著拉近到商业模型水平。

## 🎯 研究背景

这篇工作位于三个方向的交叉处。

### 1. Biomedical Data Science

生物医学数据科学不是普通医学问答。很多任务的答案必须通过计算得到，例如：

- 用 SQL 查询 ICU 患者某段时间内的实验室指标；
- 根据临床评分公式计算风险；
- 对单细胞或基因组数据写分析脚本；
- 用 EHR 训练一个预测模型；
- 检查临床 note 和结构化表格是否一致。

这类任务的关键不是背医学知识，而是把医学问题转成可执行计算流程。

### 2. LLM Coding Agents

CodeAct、SWE-bench、SWE-gym 等工作说明，LLM agent 需要通过终端、文件系统、解释器和错误反馈来完成真实代码任务。医学场景也需要这种能力，但多了隐私、数据访问、医学依赖包、统计规范和临床安全要求。

因此普通代码 benchmark 不能直接覆盖 biomedical coding agents。

### 3. Agentic RL 与可执行训练环境

RLHF / DPO / GRPO 等后训练方法需要可验证 reward。数学和代码任务天然适合，因为答案可以验证。生物医学数据科学如果被封装成“写代码 -> 执行 -> 比较输出”，就能转成可训练的 agentic RL 环境。

MedAgentGym 的贡献在于把这一点系统化：它不只是 benchmark，而是同时提供环境、轨迹采样、验证器和训练数据。

## ⚠️ 问题与挑战

论文要解决的问题是：**如何为生物医学数据科学构建一个既能评测 LLM coding agent，又能支持规模化训练的可执行环境。**

这个问题难在几个层面。

### 1. 因为真实任务需要代码执行，所以单轮 QA 评测不够

如果问题是“哪些 ICU 患者在入院后 24 小时内乳酸升高并符合某个 sepsis 条件”，模型不能只给一段解释。它必须：

1. 理解临床条件；
2. 找到正确表格；
3. 写 SQL 或 Python；
4. 处理时间窗口；
5. 执行代码；
6. 输出可验证结果。

传统医学 QA benchmark 只看最后文本答案，无法评估这种执行链。

### 2. 因为医学数据敏感，所以不能随便调用商业 API 或外部环境

论文指出，临床和生物医学场景有严格隐私要求。直接把 credentialed EHR 数据发给第三方模型服务通常不可行，成本也高。

这使得开源、可本地部署、隐私可控的 biomedical coding agent 很重要。但开源模型在这类任务上明显弱于商业模型。

### 3. 因为代码可以有多种正确实现，所以验证应该看执行结果而不是代码文本

同一个生物信息学任务可能有很多种写法。硬比较 reference code 没意义。MedAgentGym 选择比较 execution output 或 test cases，这更符合代码任务本质。

例如两个脚本都能正确计算 clinical score，即使变量名、函数结构完全不同，也应该算正确。

### 4. 因为 agent 会失败，所以失败轨迹也应该成为训练信号

真实 coding agent 不只是一次生成代码。它会遇到 import error、runtime error、数据列名错误、循环卡住、逻辑错等问题。

MedAgentGym 把正轨迹和负轨迹都保存下来。成功轨迹用于 SFT，成功与失败对比用于 DPO / GRPO，错误信息用于训练 agent 调试。

## 🔍 核心发现 Finding

### 作者明确声称

作者明确的发现是：**MedAgentGym 可以作为可扩展、可交互、可验证的训练环境，显著提升开源 LLM agent 在生物医学代码推理任务上的能力；Med-Copilot 通过 offline 和 online RL 分别获得 +43.02% 和 +45.28% 的性能增益。**

### 我的理解

我认为这篇论文真正的 `Finding` 是：

**生物医学 LLM agent 的瓶颈不只是医学知识不足，也不是单纯代码能力不足，而是缺少一个能把医学任务、数据访问、代码执行、错误反馈和可验证 reward 连接起来的训练环境。**

这个 finding 很关键，因为它解释了为什么专门的 coding LLM 和 medical LLM 在 MedAgentGym 上都表现不理想。

coding LLM 会写代码，但可能不知道医学数据的语义。例如它可能能写 pandas，却不知道如何按临床时间窗处理 ICU 事件。

medical LLM 知道医学概念，但可能不会把问题转成可执行 SQL、Python 或统计脚本。

MedAgentGym 把任务重新定义为“医学知识 + 代码执行 + 环境交互 + 可验证输出”的组合能力。它的价值不只是测模型，而是让模型在环境里反复试错，把错误转成训练信号。

一个直观例子是 BioCoder 里的基因组 copy number 任务。基线模型可能写出能运行但语义错误的代码，例如把女性 X 染色体 copy number 硬编码成 2，忽略肿瘤细胞 ploidy。MedAgentGym 的执行和调试环境能暴露这种“代码看起来对，但领域约束错了”的问题。

## 🔬 方法

### 任务形式化

论文把 coding-based biomedical reasoning 定义为：

给定问题描述 `x`，agent 生成代码 `c`，代码执行得到输出 `y`，再和 ground truth `y*` 比较。

正确性函数是 `E(c, y) -> {0, 1}`。关键点是验证执行结果，而不是验证代码长得像不像 reference。

MedAgentGym 允许同一个任务采样多条轨迹：

- 成功轨迹：最终输出正确；
- 失败轨迹：输出错误、执行报错、逻辑错误或中途卡住；
- 单轮或多轮轨迹：取决于任务复杂度和 agent 是否需要调试。

这些轨迹可以直接服务训练。

### 数据构造

MedAgentGym 整合 12 个真实数据源或任务场景，分为 internal 和 external 两部分。

internal 部分包括：

- MIMIC-III；
- eICU；
- TREQS；
- MedCalcBench；
- MedAgentBench；
- BioCoder；
- EHRSHOT；
- BioDSBench。

external OOD 部分包括：

- EHR-SeqSQL；
- EHRCon；
- MIMIC-Extract；
- N-PowerAI。

总计 `72,413` 个 task instances，其中 `59,175` 个 train、`13,238` 个 test；leaderboard 子集有 `11,997` 个任务。

任务领域覆盖：

- clinical database querying；
- clinical note analysis；
- medical computation；
- health information technology；
- biomedical software engineering；
- biomedical data analysis；
- biostatistics；
- ML-based predictive modeling。

### 可执行 Sandbox

每个任务被封装在隔离 Docker 环境中，带有预装依赖、数据资源、可执行接口和验证逻辑。

环境支持四类主要 action：

1. **request_info**：查询 EHR、元数据或任务相关信息；
2. **terminal**：管理依赖、查看文件、操作本地环境；
3. **code_execution**：执行模型生成的代码；
4. **debugging**：把执行错误转成 LLM 更容易理解的自然语言反馈。

这种设计让 benchmark 从静态题库变成 agent 可以探索的训练场。

### 轨迹采样与 Med-Copilot

作者使用 Ray 和 Joblib 做多线程、多轮轨迹采样。训练 Med-Copilot 时，默认 backbone 是 Qwen2.5-Instruct-7B 和 14B，并使用 CodeAct 风格 scaffold。

轨迹来源包括：

- `2,137` 条 gpt-4.1-mini 成功轨迹，用于 SFT warm-up；
- `1,646` 对 offline DPO 轨迹；
- `2,939` 对 online 轨迹；
- 总计释放约 6K 训练轨迹。

训练方法包括：

- SFT：模仿成功轨迹；
- DPO：偏好成功 final code，压低失败或中间错误尝试；
- PPO / GRPO：让 agent 在线探索并根据环境 reward 优化；
- verifier：训练 outcome-supervised reward model 判断轨迹是否成功；
- rejection sampling 和 iDPO：使用自身 rollout 做自我改进。

## 🧪 实验与结论

### 1. Benchmark 结果：商业模型明显领先，开源模型短板清楚

论文评测了 29 个模型，包括 gpt-4o、gpt-4.1、o4-mini、codex-mini、Qwen3、Qwen2.5、DeepSeek-R1-Distill、Llama、medical reasoning models 和 coding models。

主观察是：

- 商业 API 模型整体领先；
- 开源模型在结构化任务上尚可，在 open-ended data analysis 和 ML predictive modeling 上更弱；
- 纯 coding LLM 和纯 medical LLM 都不能自动解决 biomedical coding reasoning；
- `gpt-4.1` 平均分 70.15，`o4-mini` 65.67，`codex-mini` 65.38；
- 多数 7B 到 14B 开源模型平均分明显低很多，例如 Qwen2.5-7B-Instruct 17.43。

这个结果说明，生物医学代码推理是独立能力，不是“会医学”或“会写代码”之一能单独覆盖的。

### 2. Med-Copilot 训练显著提升 7B 和 14B 模型

在 Qwen2.5-7B-Instruct 上：

- base 平均 16.89；
- SFT 到 53.87，提升 +36.98；
- DPO 到 59.90，提升 +43.02；
- PPO 到 57.96，提升 +41.07；
- GRPO 到 62.17，提升 +45.28。

在 Qwen2.5-14B-Instruct 上：

- base 平均 20.12；
- SFT 到 63.92；
- DPO 到 66.37；
- PPO 到 69.56；
- GRPO 到 71.42，提升 +51.30。

这组实验是论文最强证据：环境不是只用来打分，它真的能产出训练信号，让开源模型学会更稳地写和调试生物医学代码。

### 3. Offline RL 与 Online RL 的区别

SFT 主要学习成功 coding pattern，对结构化任务提升很大。DPO 特别有利于 open-ended 任务，因为它能通过成功与失败的对比，让模型减少看似合理但最终错误的策略。

Online RL，尤其 GRPO，允许模型在环境中主动探索，用 correctness reward 和 format reward 共同优化。论文结果显示 GRPO 总体最强，说明交互式探索能带来更好的泛化。

### 4. Inference-time 和 training-time scaling

论文训练了一个 verifier，用于判断轨迹是否成功。随着 rollout 数增加：

- Pass@K 从 K=1 的约 17.0% 提升到 K=16 的 45.0%；
- Best@K 从约 17.0% 提升到 41.7%。

这说明多采样 + verifier 选择能明显提高解题成功率。训练数据量增加时，SFT 表现也持续提升，表明更多轨迹采样仍可能带来收益。

### 5. External OOD 评估与错误分析

在 EHR-SeqSQL、EHRCon、MIMIC-Extract、N-PowerAI 等 OOD 任务上，GRPO 版 Med-Copilot 也能提升泛化表现。

消融显示，去掉 debugging 功能会显著降低表现，说明交互式错误反馈不是装饰，而是 agent 成功的关键。

错误分析中，最强模型 gpt-4.1 的错误里约 50.39% 是 stuck in the loop，也就是 agent 在最后几轮重复同类动作，无法切换策略。这提示未来训练不仅要提高代码正确率，也要训练探索策略和失败恢复能力。

## 🔑 关键术语

- **MedAgentGym（医学智能体训练环境）**: 论文提出的可执行 benchmark 和训练环境。例子：给 agent 一个 EHR 查询任务，让它请求表结构、写 SQL、执行代码并根据结果判断是否正确。

- **Code-Centric Biomedical Reasoning（代码型生物医学推理）**: 需要通过代码执行得到可验证结果的医学数据科学任务。例子：从 ICU 数据中计算某类患者的临床评分。

- **Med-Copilot（医学代码智能体）**: 作者基于 Qwen2.5-Instruct 训练出的轻量开源 biomedical coding agent，通过 SFT、DPO、PPO、GRPO 等方法在 MedAgentGym 上提升。

- **Executable Sandbox（可执行沙箱）**: 每个任务独立运行的 Docker 环境，包含依赖、数据和验证逻辑。例子：BioCoder 任务预装 AlignIO，agent 可以直接执行 bioinformatics 代码。

- **Trajectory（轨迹）**: agent 完成任务时的观测、动作、代码、错误和结果序列。例子：先 request_info 看表结构，再写 Python，遇到 KeyError 后 debug，最后改代码得到正确输出。

- **Outcome Verifier（结果验证器）**: 判断一条轨迹是否成功的模型或规则。例子：比较执行输出与 ground truth，或让 verifier 从完整轨迹预测 YES / NO。

- **Pass@K / Best@K**: 多次 rollout 下的推理时扩展指标。Pass@K 看 K 次中是否至少一次成功，Best@K 看 verifier 能否选中成功轨迹。

- **GRPO（Group Relative Policy Optimization）**: 一种在线 RL 方法，用同组样本相对表现优化策略。例子：让 Med-Copilot 在多个候选代码轨迹中偏向执行正确且格式合规的输出。

## 🧭 评价与启发

这篇论文的价值在于，它把 biomedical LLM agent 的问题从“模型答不答得对”推进到“模型能不能在安全环境里执行真实数据科学工作流，并把执行反馈转成训练信号”。

它和普通医疗问答 benchmark 的差别很大。MedAgentGym 更像医学版 SWE-gym 或 code-agent gym，只是任务对象换成了 EHR、临床计算、生物信息学和预测建模。

我认为最值得借鉴的是三点：

1. **验证执行结果，而不是验证代码文本。** 这让 benchmark 更接近真实 coding。
2. **失败轨迹同样有价值。** 报错、错误输出和中间尝试可以直接变成 DPO / GRPO 训练信号。
3. **隐私和可复现需要环境级设计。** Docker sandbox、credentialed data policy、不可外传 PHI，都不是医学任务里的附属问题，而是系统设计的一部分。

局限也明确：

- 轨迹采样、微调和自我改进需要大量计算资源；
- 数据和轨迹规模仍受 compute budget 限制，没有完全探索 scaling law；
- 当前主要覆盖文本和结构化数据，尚未纳入医学影像、EEG、音频、视频等多模态数据；
- 使用公开或 credentialed 数据可能继承数据代表性偏差；
- 论文强调这些是研究工具，不能直接用于诊断或治疗决策。

## 💡 可借鉴点

1. **要训练领域 agent，先把领域任务变成可执行、可验证、可交互的环境。**
2. **医学代码推理需要同时评估 domain knowledge、data access、code execution 和 debugging。**
3. **开源模型要追上商业模型，单靠 prompt 不够，需要轨迹级 SFT 和 RL。**
4. **在隐私敏感领域，benchmark 设计必须同时考虑数据许可、容器隔离和 API 使用边界。**
5. **未来可以把 MedAgentGym 思路扩展到医学影像、多组学、多模态临床决策和科研工作流自动化。**

**适合读者**：自然语言处理、LLM agent、医学 AI、生物医学数据科学、代码生成与 RL 后训练方向研究者

**一句话总结**：MedAgentGym 的关键不是再做一个医学问答榜单，而是把生物医学数据科学任务封装成可执行、可交互、可验证的 agent 训练场，让轻量开源模型能通过真实环境反馈学习写代码、查数据、调试并完成医学计算任务。
