# paper-libarary

基于 Hugo + PaperMod 的学术论文阅读笔记站点，用于记录论文元数据、阅读状态、评分和个人总结。

当前站点地址：

- https://a23wen.github.io/paper-libarary/

## 功能概览

- **智能论文阅读**：通过 Claude Code Skills 自动读取、分析和归档学术论文
- **智能分类**：自动匹配现有分类或创建新分类，无需手动维护
- **论文笔记**：使用 `content/papers/` 管理论文 Markdown 内容
- **分类浏览**：当前 Hugo taxonomy 只启用 `categories`，用于按研究领域组织论文
- **论文元数据卡片**：通过 `{{< paper-info >}}` shortcode 展示作者、年份、会议/期刊、链接、阅读状态和评分
- **全站搜索**：使用 PaperMod 内置 Fuse.js 搜索，依赖 Hugo 生成首页 JSON 索引
- **归档页面**：通过 PaperMod 的 `archives` layout 展示内容归档
- **自动部署**：通过 GitHub Actions 构建 Hugo 站点并部署到 GitHub Pages

## 技术栈

- **Hugo Extended**：本地和 CI 当前使用 `0.160.1`
- **主题**：PaperMod，位于 `themes/PaperMod`，以 Git submodule 管理
- **搜索**：PaperMod + Fuse.js
- **部署**：GitHub Actions + GitHub Pages
- **AI 辅助**：Claude Code Skills（智能论文阅读与分类）

## 本地开发

### 前置要求

- Hugo Extended `0.160.1` 或兼容版本
- Git
- 已初始化 PaperMod 子模块

### 克隆与初始化

```bash
git clone https://github.com/a23wen/paper-libarary.git
cd paper-libarary
git submodule update --init --recursive
```

### 启动开发服务器

```bash
hugo server -D
```

默认访问：

```text
http://localhost:1313/paper-libarary/
```

### 本地构建

```bash
hugo --gc --minify
```

构建产物会生成到 `public/`。该目录是生成物，不需要手工维护或提交。

## 项目结构

```text
.
├── .claude/                    # Claude Code 配置
│   ├── skills/
│   │   └── paper-reading.md    # 智能论文阅读 skill
│   └── CLAUDE.md               # Claude Code 项目指南
├── archetypes/                 # Hugo 内容模板
│   ├── default.md
│   ├── notes.md                # 学习笔记模板
│   └── papers.md               # 论文笔记模板
├── assets/
│   └── css/extended/custom.css # PaperMod 扩展样式
├── content/
│   ├── archives.md             # 归档页面
│   ├── search.md               # 搜索页面
│   └── papers/                 # 论文笔记内容
├── layouts/                    # 项目级模板覆盖
│   ├── categories/list.html    # 自定义分类页
│   ├── partials/rating.html    # 星级评分 partial
│   └── shortcodes/paper-info.html
├── themes/
│   └── PaperMod/               # PaperMod 主题子模块
├── .github/workflows/
│   ├── deploy.yml              # Hugo Pages 部署流程
│   └── jekyll-gh-pages.yml     # 旧 Jekyll 示例流程，建议删除或禁用
├── hugo.toml                   # Hugo 主配置
├── CLAUDE.md                   # 项目级 Claude 指南
└── README.md
```

## 内容管理

### 使用 Claude Code Skills（推荐）

本项目配置了智能论文阅读 skill，可以自动完成论文分析、分类和笔记生成：

```bash
/paper-reading <paper-url>
```

**功能特性**：
- 自动从 URL 获取并深度分析论文内容
- 智能匹配现有分类或自动创建新分类（≥70% 语义相似度阈值）
- 提取论文元数据（作者、年份、会议等）
- 生成结构化笔记，包含关键贡献、方法论和实验结果
- 自动提交并推送到 GitHub

**示例**：
```bash
# 读取并归档 arXiv 论文
/paper-reading https://arxiv.org/pdf/2503.06749

# 如果论文属于"视觉语言模型"，会自动使用现有分类
# 如果论文属于新领域（如"联邦学习"），会自动创建新分类
```

### 手动新增论文

如果需要手动创建论文笔记：

```bash
hugo new papers/your-paper-title.md
```

论文模板位于 `archetypes/papers.md`。常用 front matter 字段：

- `title`：论文标题
- `date`：笔记发布日期
- `draft`：是否为草稿
- `categories`：研究领域分类；当前项目只启用这一种 taxonomy
- `venues`：会议或期刊名称
- `authors`：作者列表
- `year`：论文发表年份
- `paper_url`、`arxiv_url`、`code_url`、`slides_url`、`video_url`：相关链接
- `status`：阅读状态，可用值为 `reading`、`completed`、`to-read`
- `rating`：评分，建议使用 `0` 到 `5`
- `read_date`：阅读日期
- `summary`：摘要，会用于列表页和搜索

在论文正文中加入元数据卡片：

```markdown
{{< paper-info >}}
```

新增普通学习笔记：

```bash
hugo new notes/your-note-title.md
```

## 配置说明

主配置文件是 `hugo.toml`。

重要配置：

- `baseURL = 'https://a23wen.github.io/paper-libarary/'`
- `theme = 'PaperMod'`
- `[outputs] home = ["HTML", "RSS", "JSON"]` 用于生成搜索索引
- `[taxonomies] category = "categories"` 表示当前只启用研究领域分类
- `[params.fuseOpts]` 控制 Fuse.js 搜索参数

自定义样式写在：

```text
assets/css/extended/custom.css
```

自定义布局优先放在项目根目录的 `layouts/` 下覆盖主题模板。除非是在更新主题子模块，否则不要直接修改 `themes/PaperMod/` 内部文件。

## 部署

推荐部署流程是 `.github/workflows/deploy.yml`：

1. push 到 `main`
2. GitHub Actions 安装 Hugo Extended
3. 拉取 PaperMod submodule
4. 执行 `hugo --gc --minify`
5. 上传 `public/` 并部署到 GitHub Pages

GitHub Pages 设置中，Source 应选择：

```text
GitHub Actions
```

注意：仓库里当前还存在 `.github/workflows/jekyll-gh-pages.yml`。这是 GitHub Pages 的 Jekyll 示例流程，也监听 `main` 分支并尝试部署 Pages。这个项目实际使用 Hugo，后续维护时建议删除或禁用 Jekyll workflow，避免和 Hugo 部署流程冲突。

## 智能分类系统

本项目使用智能分类系统，自动管理论文的研究领域分类：

### 分类决策逻辑

- **语义匹配阈值**：≥70% 相似度使用现有分类，<70% 创建新分类
- **现有分类优先**：优先匹配已有的研究领域分类
- **自动创建**：当论文属于新兴领域或跨学科研究时，自动创建新分类

### 常见分类

- 自然语言处理 (Natural Language Processing)
- 计算机视觉 (Computer Vision)
- 生成模型 (Generative Models)
- 视觉语言模型 (Vision Language Models)
- 强化学习 (Reinforcement Learning)
- 图神经网络 (Graph Neural Networks)
- 机器学习 (Machine Learning)
- 多模态学习 (Multimodal Learning)

### 分类命名规范

- 使用中文主名称
- 括号内附英文说明
- 格式：`主题领域 (English Translation)`
- 示例：`联邦学习 (Federated Learning)`

## 维护建议

- **分类体系**：当前只启用 `categories`。分类由 Claude Code Skills 智能管理，无需手动创建。
- **搜索索引**：PaperMod 默认搜索索引主要包含标题、正文、链接和摘要。如果希望搜索作者、分类、会议、年份，建议在项目根目录新增 `layouts/_default/index.json` 覆盖模板。
- **样式维护**：`layouts/categories/list.html` 里目前有部分 inline style，后续可以迁移到 `assets/css/extended/custom.css`。
- **主题升级**：通过 submodule 更新 PaperMod，升级前后都应执行本地构建检查。
- **Claude Code Skills**：`.claude/skills/` 目录包含自定义 skills，可根据需要扩展或修改。

## 常用命令

### Claude Code Skills

```bash
# 智能读取并归档论文（推荐）
/paper-reading <paper-url>

# 示例：读取 arXiv 论文
/paper-reading https://arxiv.org/pdf/2503.06749
```

### Hugo 命令

```bash
# 初始化或更新主题子模块
git submodule update --init --recursive

# 本地预览
hugo server -D

# 生产构建
hugo --gc --minify

# 查看 Hugo 识别到的页面
hugo list all

# 更新 PaperMod 主题
git submodule update --remote --merge themes/PaperMod

# 手动创建论文笔记
hugo new papers/your-paper-title.md

# 手动创建学习笔记
hugo new notes/your-note-title.md
```

## 参考资料

- [Hugo Documentation](https://gohugo.io/documentation/)
- [PaperMod Wiki](https://github.com/adityatelange/hugo-PaperMod/wiki)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
