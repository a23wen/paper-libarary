---
title: "注意力机制综述"
date: 2024-01-20T16:00:00+08:00
draft: false
tags: ["attention", "deep-learning", "survey"]
categories: ["学习笔记"]
research-areas: ["注意力机制"]

summary: "总结注意力机制的发展历程、核心原理和各种变体，从早期的 Bahdanau Attention 到现代的 Transformer。"
---

## 概述

注意力机制（Attention Mechanism）是深度学习中的重要概念，允许模型在处理输入时动态地关注不同部分。本笔记总结注意力机制的核心思想和主要变体。

## 发展历程

### 1. 早期注意力（2014-2015）

**Bahdanau Attention (2014)**
- 用于机器翻译的编码器-解码器架构
- 解码器在每个时间步计算对编码器所有隐藏状态的加权和
- 首次解决了固定长度上下文向量的瓶颈问题

**Luong Attention (2015)**
- 提出多种注意力打分函数（dot, general, concat）
- 区分全局注意力和局部注意力

### 2. 自注意力时代（2017-至今）

**Transformer (2017)**
- 提出 Self-Attention 机制
- 完全抛弃循环结构
- 成为现代 NLP 的基石

**后续发展**
- BERT、GPT：基于 Transformer 的预训练模型
- Vision Transformer：将注意力应用于视觉
- Efficient Transformers：降低计算复杂度

## 核心原理

### 注意力的通用形式

```
Attention(Q, K, V) = Σ α_i · v_i
```

其中：
- **Q (Query)**：查询向量，表示"我想关注什么"
- **K (Key)**：键向量，表示"我是什么"
- **V (Value)**：值向量，表示"我提供什么信息"
- **α_i**：注意力权重，通过 Q 和 K 计算得到

### 计算步骤

1. **计算相似度**：Score(Q, K_i) = f(Q, K_i)
2. **归一化**：α = softmax(Score)
3. **加权求和**：Output = Σ α_i · V_i

## 主要变体

### 1. 按计算方式分类

| 类型 | 公式 | 特点 |
|------|------|------|
| **点积注意力** | Q · K^T | 最简单，计算快 |
| **缩放点积** | (Q · K^T) / √d | Transformer 使用，防止梯度消失 |
| **加性注意力** | W[Q; K] | Bahdanau 使用，参数更多 |
| **双线性** | Q · W · K^T | 可学习的相似度度量 |

### 2. 按应用范围分类

- **全局注意力**：关注所有位置
- **局部注意力**：只关注窗口内的位置
- **自注意力**：序列对自身的注意力
- **交叉注意力**：两个不同序列之间的注意力

### 3. 高效注意力变体

解决 Transformer O(n²) 复杂度问题：

- **Linformer**：低秩近似，O(n)
- **Performer**：核化注意力，O(n)
- **Longformer**：稀疏注意力，O(n)
- **Flash Attention**：IO 优化，不改变算法但加速显著

## 直观理解

### 类比：图书馆找书

1. **Query（查询）**：你想找"机器学习相关的书"
2. **Key（索引）**：每本书的关键词标签
3. **Value（内容）**：书的实际内容
4. **Attention**：根据你的查询和书的标签计算相关性，重点阅读最相关的书

### 为什么有效？

- **动态选择**：根据当前任务动态关注相关信息
- **长距离依赖**：直接建模任意距离的关系
- **可解释性**：注意力权重提供了一定的可解释性

## 实现要点

### PyTorch 简单实现

```python
import torch
import torch.nn.functional as F

def scaled_dot_product_attention(Q, K, V, mask=None):
    """
    Q, K, V: shape [batch, seq_len, d_model]
    """
    d_k = Q.size(-1)
    
    # 计算注意力分数
    scores = torch.matmul(Q, K.transpose(-2, -1)) / math.sqrt(d_k)
    
    # 应用掩码（如果有）
    if mask is not None:
        scores = scores.masked_fill(mask == 0, -1e9)
    
    # Softmax 归一化
    attention_weights = F.softmax(scores, dim=-1)
    
    # 加权求和
    output = torch.matmul(attention_weights, V)
    
    return output, attention_weights
```

### 多头注意力

```python
class MultiHeadAttention(nn.Module):
    def __init__(self, d_model, num_heads):
        super().__init__()
        self.num_heads = num_heads
        self.d_k = d_model // num_heads
        
        self.W_q = nn.Linear(d_model, d_model)
        self.W_k = nn.Linear(d_model, d_model)
        self.W_v = nn.Linear(d_model, d_model)
        self.W_o = nn.Linear(d_model, d_model)
    
    def forward(self, Q, K, V, mask=None):
        batch_size = Q.size(0)
        
        # 线性投影并分头
        Q = self.W_q(Q).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        K = self.W_k(K).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        V = self.W_v(V).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        
        # 计算注意力
        output, attn = scaled_dot_product_attention(Q, K, V, mask)
        
        # 合并多头
        output = output.transpose(1, 2).contiguous().view(batch_size, -1, self.num_heads * self.d_k)
        
        # 最终线性层
        return self.W_o(output)
```

## 应用场景

### NLP
- 机器翻译
- 文本摘要
- 问答系统
- 预训练语言模型

### CV
- 图像分类（Vision Transformer）
- 目标检测（DETR）
- 图像生成（DALL-E）

### 其他
- 语音识别
- 推荐系统
- 图神经网络
- 强化学习

## 常见问题

**Q: 注意力和卷积有什么区别？**

A: 
- 卷积：固定的局部感受野，参数共享
- 注意力：动态的全局感受野，数据依赖

**Q: 为什么需要多头？**

A: 不同的头可以关注不同类型的信息（局部/全局、语法/语义等），类似卷积中的多个滤波器。

**Q: 如何选择注意力类型？**

A:
- 短序列 → 标准注意力
- 长序列 → 高效注意力变体
- 需要局部性 → 局部注意力或卷积
- 需要全局 → 自注意力

## 参考资料

### 必读论文
1. [Attention Is All You Need](https://arxiv.org/abs/1706.03762) - Transformer
2. [Neural Machine Translation by Jointly Learning to Align and Translate](https://arxiv.org/abs/1409.0473) - Bahdanau Attention
3. [Effective Approaches to Attention-based Neural Machine Translation](https://arxiv.org/abs/1508.04025) - Luong Attention

### 推荐资源
- [The Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/)
- [Attention? Attention!](https://lilianweng.github.io/posts/2018-06-24-attention/)
- [Stanford CS224N 课程](http://web.stanford.edu/class/cs224n/)

---

**更新时间**：2024-01-20  
**下次更新**：添加最新的高效注意力机制（2024年新进展）
