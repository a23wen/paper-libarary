# paper-libarary

基于 Hugo + PaperMod 的学术论文阅读笔记站点，用于记录论文元数据、阅读状态、评分和个人总结。

当前站点地址：

- https://a23wen.github.io/paper-libarary/

## 功能概览

- 论文笔记：使用 `content/papers/` 管理论文 Markdown 内容。
- 分类浏览：当前 Hugo taxonomy 只启用 `categories`，用于按研究领域组织论文。
- 论文元数据卡片：通过 `{{< paper-info >}}` shortcode 展示作者、年份、会议/期刊、链接、阅读状态和评分。
- 全站搜索：使用 PaperMod 内置 Fuse.js 搜索，依赖 Hugo 生成首页 JSON 索引。
- 归档页面：通过 PaperMod 的 `archives` layout 展示内容归档。
- 自动部署：通过 GitHub Actions 构建 Hugo 站点并部署到 GitHub Pages。

## 技术栈

- Hugo Extended：本地和 CI 当前使用 `0.160.1`
- 主题：PaperMod，位于 `themes/PaperMod`，以 Git submodule 管理
- 搜索：PaperMod + Fuse.js
- 部署：GitHub Actions + GitHub Pages

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
└── README.md
```

## 内容模型

新增论文：

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

## 维护建议

- 分类体系：当前只启用 `categories`。如果需要标签、会议、阅读状态等多维筛选，需要在 `hugo.toml` 中补充对应 taxonomies，并同步更新内容模板和页面入口。
- 搜索索引：PaperMod 默认搜索索引主要包含标题、正文、链接和摘要。如果希望搜索作者、分类、会议、年份，建议在项目根目录新增 `layouts/_default/index.json` 覆盖模板。
- 样式维护：`layouts/categories/list.html` 里目前有部分 inline style，后续可以迁移到 `assets/css/extended/custom.css`。
- 主题升级：通过 submodule 更新 PaperMod，升级前后都应执行本地构建检查。

## 常用命令

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
```

## 参考资料

- [Hugo Documentation](https://gohugo.io/documentation/)
- [PaperMod Wiki](https://github.com/adityatelange/hugo-PaperMod/wiki)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
