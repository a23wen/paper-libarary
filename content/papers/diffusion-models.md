---
title: "Denoising Diffusion Probabilistic Models"
date: 2024-03-01T09:00:00+08:00
draft: false

# 分类（研究领域）
categories: ["生成模型"]

# 会议/期刊
venues: "NeurIPS 2020"

# 论文元数据
authors: ["Jonathan Ho", "Ajay Jain", "Pieter Abbeel"]
year: "2020"
paper_url: "https://arxiv.org/abs/2006.11239"
arxiv_url: "https://arxiv.org/abs/2006.11239"
code_url: "https://github.com/hojonathanho/diffusion"

# 阅读状态
status: "to-read"
rating: 0
read_date: ""

summary: "提出去噪扩散概率模型（DDPM），通过逐步添加和去除噪声的过程实现高质量图像生成，为后续 Stable Diffusion 等模型奠定基础。"
---

{{< paper-info >}}

## 📋 论文概述

这是扩散模型（Diffusion Models）的奠基性工作之一。论文提出了去噪扩散概率模型（DDPM），通过学习逆向去噪过程来生成高质量图像。

扩散模型在图像生成质量上已经超越了 GAN，并且训练更稳定。这篇论文是理解现代生成模型（如 DALL-E 2、Stable Diffusion、Imagen）的关键。

## 🎯 研究动机

- **GAN 的问题**：训练不稳定、模式崩溃、生成多样性受限
- **VAE 的问题**：生成质量不如 GAN
- **目标**：找到训练稳定、生成质量高的生成模型

## 🔬 主要方法

### 核心思想

**前向过程（扩散）**：逐步向数据添加高斯噪声，直到变成纯噪声  
**反向过程（去噪）**：学习从噪声中逐步恢复数据

（待详细阅读后补充）

## 📝 阅读计划

- [ ] 理解扩散过程的数学推导
- [ ] 学习训练目标和损失函数
- [ ] 对比与 Score-based Models 的关系
- [ ] 实现简单的 DDPM 模型
- [ ] 阅读后续改进工作（DDIM、Stable Diffusion）

## 🔗 相关论文

**需要先读的论文**：
- Score Matching
- Langevin Dynamics

**后续发展**：
- DDIM (2020) - 加速采样
- Stable Diffusion (2022) - 潜在空间扩散
- DALL-E 2 (2022) - 文本到图像生成

---

**预计阅读时间**：4-5 小时（包括数学推导）  
**优先级**：高  
**阅读前准备**：复习概率论、变分推断基础
