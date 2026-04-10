# paper-libarary
awen's paper libarary


## ✨ 功能特性

- 📄 **论文管理**：结构化的论文笔记模板，包含完整元数据
- 🏷️ **多维度分类**：支持标签、分类、研究领域、会议/期刊等多种分类方式
- 🔍 **全站搜索**：基于 Fuse.js 的客户端搜索，快速查找论文和笔记
- ⭐ **阅读追踪**：记录阅读状态（已读/在读/待读）和星级评分
- 📱 **响应式设计**：支持桌面、平板和移动设备
- 🚀 **自动部署**：通过 GitHub Actions 自动部署到 GitHub Pages

## 🚀 快速开始

### 前置要求

- [Hugo Extended](https://gohugo.io/installation/) v0.120.0 或更高版本
- Git

### 本地开发

1. **克隆仓库**

```bash
git clone <your-repo-url>
cd paper_web
```

2. **更新主题子模块**

```bash
git submodule update --init --recursive
```

3. **启动本地服务器**

```bash
hugo server -D
```

访问 `http://localhost:1313` 查看网站。

### 添加新论文笔记

使用 Hugo 命令创建新论文笔记：

```bash
hugo new papers/your-paper-title.md
```

这会在 `content/papers/` 目录下创建一个新文件，包含完整的模板结构。

**模板字段说明：**

- `title`：论文标题
- `tags`：关键词标签（如 "transformer", "deep-learning"）
- `categories`：大类别（如 "自然语言处理", "计算机视觉"）
- `research-areas`：研究领域（如 "序列建模", "图像识别"）
- `venues`：会议/期刊名称（如 "NeurIPS 2023"）
- `authors`：作者列表
- `year`：发表年份
- `paper_url`、`arxiv_url`、`code_url` 等：相关链接
- `status`：阅读状态（`reading`、`completed`、`to-read`）
- `rating`：1-5 星评分
- `read_date`：阅读日期

### 添加学习笔记

```bash
hugo new notes/your-note-title.md
```

学习笔记模板更灵活，适合总结概念、方法等。

## 📁 项目结构

```
.
├── archetypes/          # 内容模板
│   ├── papers.md        # 论文笔记模板
│   └── notes.md         # 学习笔记模板
├── assets/              # 资源文件
│   └── css/extended/    # 自定义样式
├── content/             # 内容目录
│   ├── papers/          # 论文笔记
│   ├── notes/           # 学习笔记
│   ├── search.md        # 搜索页面
│   └── archives.md      # 归档页面
├── layouts/             # 自定义布局
│   ├── shortcodes/      # 短代码
│   └── partials/        # 部分模板
├── themes/              # 主题目录
│   └── PaperMod/        # PaperMod 主题（Git 子模块）
├── .github/
│   └── workflows/
│       └── deploy.yml   # GitHub Actions 部署配置
├── hugo.toml            # Hugo 配置文件
└── README.md
```

## 🎨 自定义配置

### 修改网站信息

编辑 `hugo.toml` 文件：

```toml
title = '你的网站标题'
[params]
  author = "你的名字"
  description = "网站描述"
```

### 修改 baseURL

部署到 GitHub Pages 前，需要更新 `baseURL`：

```toml
baseURL = 'https://<username>.github.io/<repo-name>/'
```

如果使用自定义域名：

```toml
baseURL = 'https://your-custom-domain.com/'
```

### 自定义样式

在 `assets/css/extended/custom.css` 中添加你的自定义 CSS。

## 🚢 部署到 GitHub Pages

### 1. 创建 GitHub 仓库

在 GitHub 上创建新仓库（公开或私有均可）。

### 2. 推送代码

```bash
git remote add origin https://github.com/<username>/<repo-name>.git
git branch -M main
git add .
git commit -m "Initial commit: Hugo paper notes site"
git push -u origin main
```

### 3. 配置 GitHub Pages

1. 进入仓库的 **Settings** → **Pages**
2. 在 **Source** 下选择 **GitHub Actions**
3. 推送代码后，GitHub Actions 会自动构建和部署

### 4. 访问网站

部署完成后，访问：
- `https://<username>.github.io/<repo-name>/`（默认）
- 或你配置的自定义域名

## 📝 使用技巧

### 在论文笔记中显示元数据卡片

在 Markdown 内容中添加：

```markdown
{{< paper-info >}}
```

这会自动显示一个包含论文信息的卡片。

### 使用标签过滤

访问 `/tags/` 查看所有标签，点击标签查看相关文章。

### 使用搜索

访问 `/search/` 或点击导航栏的"搜索"，支持搜索标题、内容、标签等。

### 查看归档

访问 `/archives/` 查看按时间排序的所有文章。

## 🔧 常见问题

### Hugo 命令找不到

如果终端提示 `hugo: command not found`，需要将 Hugo 添加到 PATH：

```bash
# 对于 Homebrew 安装（macOS）
export PATH="/opt/homebrew/bin:$PATH"

# 或使用完整路径
/opt/homebrew/bin/hugo server -D
```

### 主题未加载

确保主题子模块已正确初始化：

```bash
git submodule update --init --recursive
```

### 本地预览正常但部署后样式丢失

检查 `hugo.toml` 中的 `baseURL` 是否正确设置为 GitHub Pages URL。

### 搜索功能不工作

确保 `hugo.toml` 中配置了：

```toml
[outputs]
  home = ["HTML", "RSS", "JSON"]
```

## 🔄 更新主题

更新 PaperMod 主题到最新版本：

```bash
git submodule update --remote --merge
git add themes/PaperMod
git commit -m "Update PaperMod theme"
```

## 📚 参考资源

- [Hugo 官方文档](https://gohugo.io/documentation/)
- [PaperMod 主题文档](https://github.com/adityatelange/hugo-PaperMod/wiki)
- [GitHub Pages 文档](https://docs.github.com/en/pages)

## 📄 许可证

本项目采用 MIT 许可证。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**快乐阅读，快乐记笔记！📖✨**
