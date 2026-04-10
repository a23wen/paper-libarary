# 📘 使用指南

## 🚀 快速开始

### 启动本地服务器

```bash
# 方式 1: 使用完整路径（推荐）
/opt/homebrew/bin/hugo server -D

# 方式 2: 如果 Hugo 在 PATH 中
hugo server -D
```

访问 http://localhost:1313 查看网站。

**参数说明：**
- `-D` 或 `--buildDrafts`：显示草稿文章（draft: true）
- `--disableFastRender`：禁用快速渲染，每次完整重建

### 添加 Hugo 到 PATH（可选）

编辑 `~/.zshrc` 文件：

```bash
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

之后就可以直接使用 `hugo` 命令。

## 📝 内容创建

### 添加新论文笔记

```bash
# 创建新论文笔记
/opt/homebrew/bin/hugo new papers/bert-pretraining.md

# 或使用短名称
/opt/homebrew/bin/hugo new papers/bert.md
```

这会创建文件：`content/papers/bert-pretraining.md`

### 添加学习笔记

```bash
/opt/homebrew/bin/hugo new notes/transformer-architecture.md
```

### 编辑内容

使用任何文本编辑器或 Markdown 编辑器：

```bash
# 使用系统默认编辑器
open content/papers/bert-pretraining.md

# 或使用 VS Code
code content/papers/bert-pretraining.md
```

## 📋 Front Matter 字段详解

### 论文笔记必填字段

```yaml
---
title: "论文标题"          # 论文完整标题
date: 2024-04-10          # 创建日期
draft: false              # 是否为草稿（false=发布，true=草稿）
summary: "简要概述"       # 显示在列表页的摘要
---
```

### 推荐填写字段

```yaml
# 分类
tags: ["transformer", "NLP"]              # 细粒度标签
categories: ["自然语言处理"]              # 大类别
research-areas: ["预训练"]                # 研究领域
venues: "NeurIPS 2023"                   # 会议/期刊

# 论文元数据
authors: ["作者1", "作者2"]              # 作者列表
year: "2023"                             # 发表年份

# 链接
paper_url: "https://..."                 # 论文PDF链接
arxiv_url: "https://arxiv.org/abs/..."  # arXiv链接
code_url: "https://github.com/..."      # 代码仓库
slides_url: "https://..."                # 幻灯片链接
video_url: "https://..."                 # 视频链接

# 阅读状态
status: "completed"                      # reading / completed / to-read
rating: 5                                # 1-5星评分
read_date: "2024-04-10"                 # 阅读日期
```

### 状态说明

- **to-read**：待阅读，计划阅读的论文
- **reading**：正在阅读
- **completed**：已完成阅读

## 🎨 使用 Shortcode

### 显示论文信息卡片

在论文笔记中，Front Matter 之后添加：

```markdown
{{< paper-info >}}
```

这会自动显示包含所有元数据的精美卡片。

## 🗂️ 分类和标签建议

### Tags（标签）- 细粒度

技术性、具体的关键词：
- 算法：`transformer`, `resnet`, `diffusion`
- 技术：`attention`, `self-supervised`, `reinforcement-learning`
- 任务：`classification`, `generation`, `detection`

### Categories（分类）- 粗粒度

研究大方向：
- `自然语言处理`
- `计算机视觉`
- `深度学习`
- `机器学习`
- `强化学习`

### Research Areas（研究领域）

更具体的研究子领域：
- `序列建模`
- `图像识别`
- `文本生成`
- `目标检测`

### Venues（会议/期刊）

学术发表场所：
- `NeurIPS 2023`
- `CVPR 2024`
- `ICML 2023`
- `Nature`
- `arXiv`

## 🔍 搜索和筛选

### 使用搜索

1. 访问 http://localhost:1313/search/
2. 输入关键词搜索
3. 支持搜索：标题、内容、标签、分类

### 按标签筛选

- 访问 `/tags/` 查看所有标签
- 点击标签查看相关文章
- 例如：`/tags/transformer/`

### 按分类筛选

- 访问 `/categories/` 查看所有分类
- 例如：`/categories/自然语言处理/`

### 按会议筛选

- 访问 `/venues/` 查看所有会议
- 例如：`/venues/neurips-2023/`

### 按研究领域筛选

- 访问 `/research-areas/` 查看所有领域
- 例如：`/research-areas/序列建模/`

## 📅 内容组织建议

### 命名规范

**论文笔记文件名：**
- 使用小写字母和连字符
- 简短但能识别
- 例如：
  - `attention-is-all-you-need.md`
  - `bert.md`
  - `resnet.md`
  - `stable-diffusion.md`

**学习笔记文件名：**
- 描述性命名
- 例如：
  - `attention-mechanism-overview.md`
  - `optimization-techniques.md`
  - `cnn-architectures.md`

### 目录结构建议

```
content/
├── papers/                    # 论文阅读笔记
│   ├── attention-is-all-you-need.md
│   ├── bert.md
│   └── resnet.md
│
└── notes/                     # 学习笔记
    ├── attention-mechanism-overview.md
    ├── deep-learning-basics.md
    └── research-tools.md
```

## 🎯 工作流程示例

### 场景 1：阅读新论文

1. **创建笔记**
```bash
/opt/homebrew/bin/hugo new papers/new-paper.md
```

2. **设置元数据**
- 修改 `title`、`authors`、`year`
- 添加 `tags` 和 `categories`
- 设置 `status: "reading"`
- 添加链接（`paper_url`、`arxiv_url` 等）

3. **边读边记**
- 填写各个章节（概述、动机、方法、结果）
- 添加个人评价

4. **完成阅读**
- 更新 `status: "completed"`
- 设置 `rating` (1-5星)
- 填写 `read_date`
- 将 `draft: false` 发布

### 场景 2：添加待读论文

```yaml
---
title: "Paper Title"
status: "to-read"
draft: false
paper_url: "https://..."
---

## 📋 论文概述

简要说明为什么想读这篇论文。

## 📝 阅读计划

- [ ] 快速浏览
- [ ] 精读方法部分
- [ ] 查看实验结果
```

### 场景 3：创建主题综述

在 `notes/` 下创建综述笔记：

```bash
/opt/homebrew/bin/hugo new notes/attention-mechanisms-survey.md
```

可以链接到多篇相关论文。

## 🌐 部署到 GitHub Pages

### 步骤 1：创建 GitHub 仓库

1. 访问 https://github.com/new
2. 创建新仓库（例如：`paper-notes`）
3. 可以选择公开或私有

### 步骤 2：更新配置

编辑 `hugo.toml`，修改 `baseURL`：

```toml
baseURL = 'https://a23wen.github.io/paper-notes/'
```

如果使用自定义域名：
```toml
baseURL = 'https://your-domain.com/'
```

### 步骤 3：推送代码

```bash
git remote add origin https://github.com/a23wen/paper-notes.git
git push -u origin main
```

### 步骤 4：配置 GitHub Pages

1. 进入仓库 **Settings** → **Pages**
2. **Source** 选择 **GitHub Actions**
3. 等待部署完成（约1-2分钟）

### 步骤 5：访问网站

访问：`https://a23wen.github.io/paper-notes/`

## 🔄 日常维护

### 更新主题

```bash
git submodule update --remote --merge
git add themes/PaperMod
git commit -m "Update PaperMod theme"
git push
```

### 备份内容

定期推送到 GitHub：

```bash
git add .
git commit -m "Add new papers and notes"
git push
```

### 本地预览

在修改后推送前，先本地预览：

```bash
/opt/homebrew/bin/hugo server -D
```

确认无误后再提交。

## 💡 高级技巧

### 1. 批量创建论文笔记

创建脚本 `new-paper.sh`：

```bash
#!/bin/bash
/opt/homebrew/bin/hugo new papers/$1.md
open content/papers/$1.md
```

使用：
```bash
chmod +x new-paper.sh
./new-paper.sh my-new-paper
```

### 2. 使用 Git 钩子自动推送

创建 `.git/hooks/post-commit`：

```bash
#!/bin/bash
git push origin main
```

### 3. 自定义样式

编辑 `assets/css/extended/custom.css` 添加你的样式。

### 4. 添加评论系统

在 `hugo.toml` 中配置 utterances 或 giscus。

## ❓ 常见问题

### Q1: Hugo 命令找不到

**A:** 使用完整路径 `/opt/homebrew/bin/hugo`，或将其添加到 PATH。

### Q2: 本地预览正常，部署后样式丢失

**A:** 检查 `hugo.toml` 中的 `baseURL` 是否正确。

### Q3: 搜索功能不工作

**A:** 确保配置了 JSON 输出：
```toml
[outputs]
  home = ["HTML", "RSS", "JSON"]
```

### Q4: 图片如何添加

**A:** 
- 放在 `static/images/` 目录
- 引用：`![描述](/images/picture.png)`

### Q5: 如何更改主题配色

**A:** 编辑 `assets/css/extended/custom.css`，覆盖 CSS 变量。

## 📚 参考资源

- [Hugo 官方文档](https://gohugo.io/documentation/)
- [PaperMod Wiki](https://github.com/adityatelange/hugo-PaperMod/wiki)
- [Markdown 语法](https://www.markdownguide.org/)

---

**祝你论文阅读愉快！📖✨**
