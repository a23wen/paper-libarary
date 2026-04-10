# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Hugo-based academic paper notes website deployed to GitHub Pages. The site manages paper metadata, reading status, ratings, and personal summaries organized by research area.

**Live Site**: https://a23wen.github.io/paper-libarary/

## Tech Stack

- **Hugo Extended 0.160.1** - Static site generator
- **PaperMod** - Hugo theme (Git submodule at `themes/PaperMod`)
- **Fuse.js** - Client-side search (built into PaperMod)
- **GitHub Actions** - Automated deployment to GitHub Pages

## Essential Commands

### Local Development

```bash
# Start development server (note: Hugo is at /opt/homebrew/bin/hugo on this Mac)
/opt/homebrew/bin/hugo server -D

# Or if Hugo is in PATH:
hugo server -D

# Access at: http://localhost:1313/paper-libarary/
```

### Build

```bash
# Clean build (recommended before commits)
rm -rf public/ resources/
/opt/homebrew/bin/hugo --gc --cleanDestinationDir

# Quick build
/opt/homebrew/bin/hugo --gc --minify
```

### Content Creation

```bash
# Create new paper note (uses archetypes/papers.md template)
/opt/homebrew/bin/hugo new papers/paper-name.md

# File will be created at: content/papers/paper-name.md
```

### Theme Management

```bash
# Update PaperMod theme
git submodule update --remote --merge
```

## Architecture

### Key Design Decisions

1. **Single Taxonomy System**: Only `categories` taxonomy is used (for research areas). Tags and research-areas were intentionally removed to simplify classification. Each paper belongs to exactly one category.

2. **Custom Category Navigation**: `layouts/categories/list.html` provides quick-switch tags between categories without returning to the category index. Uses `.Site.BaseURL` for correct URL generation in subdirectory deployment.

3. **Paper Metadata Rendering**: The `{{< paper-info >}}` shortcode in `layouts/shortcodes/paper-info.html` reads front matter fields and renders them as a styled card. It relies on `layouts/partials/rating.html` for star display.

4. **Search Index**: Hugo outputs JSON to enable Fuse.js search (configured via `[outputs] home = ["HTML", "RSS", "JSON"]`). The search keys are defined in `hugo.toml` under `params.fuseOpts.keys`.

### Front Matter Schema (Papers)

Required/common fields in `content/papers/*.md`:

```yaml
title: "Paper Title"
date: 2024-04-10
draft: false  # Must be false to publish
categories: ["研究领域"]  # Single category only

# Metadata
authors: ["Author 1", "Author 2"]
year: "2024"
venues: "Conference/Journal Name"
paper_url: "https://..."
arxiv_url: "https://..."
code_url: "https://..."

# Reading tracking
status: "completed"  # reading | completed | to-read
rating: 5  # 1-5
read_date: "2024-04-10"

summary: "Brief summary for listings"
```

### Custom Layouts and Partials

- **`layouts/categories/list.html`**: Custom category page showing quick-switch tabs. When modifying category links, always use `{{ $baseURL := .Site.BaseURL }}` and concatenate paths (e.g., `printf "%scategories/%s/" $baseURL ($name | urlize)`) to handle the `/paper-libarary/` subdirectory correctly.

- **`layouts/shortcodes/paper-info.html`**: Renders paper metadata card. Reads from `.Page.Params.*` fields.

- **`layouts/partials/rating.html`**: Renders star rating (⭐ for filled, ☆ for empty).

- **`assets/css/extended/custom.css`**: Extends PaperMod styles. Includes `.paper-metadata`, `.rating`, `.status-badge`, and `.category-tag` classes.

### Deployment Flow

1. Push to `main` branch triggers `.github/workflows/deploy.yml`
2. GitHub Actions installs Hugo 0.160.1, checks out code with submodules
3. Runs `hugo --gc --minify --baseURL "${{ steps.pages.outputs.base_url }}/"`
4. Uploads `public/` artifact and deploys to GitHub Pages
5. Site is accessible at `https://a23wen.github.io/paper-libarary/`

**Important**: `baseURL` in `hugo.toml` must match the GitHub Pages URL. Relative links in layouts should use `relURL` or concatenate with `.Site.BaseURL` to handle the subdirectory path.

## Common Pitfalls

### URL Generation in Custom Layouts

**Problem**: Using `/categories/...` in custom layouts breaks on subdirectory deployments.

**Solution**: Always use one of these approaches:
- Concatenate with `baseURL`: `{{ printf "%scategories/%s/" .Site.BaseURL ($name | urlize) }}`
- Use `relURL` with path without leading slash: `{{ printf "categories/%s/" ($name | urlize) | relURL }}`

**Why**: This site deploys to `/paper-libarary/` not `/`, so absolute paths like `/categories/` resolve to `https://a23wen.github.io/categories/` instead of `https://a23wen.github.io/paper-libarary/categories/`.

### Hugo Build Cache

**Problem**: After taxonomy or layout changes, old pages may persist.

**Solution**: Clean build before testing:
```bash
rm -rf public/ resources/ .hugo_build.lock
hugo --gc --cleanDestinationDir
```

### Draft Status

**Problem**: New papers created with `hugo new` have `draft: true` by default and won't appear in production builds.

**Solution**: Change `draft: false` in front matter before committing.

## Content Organization

Papers are organized by **research area** via the `categories` taxonomy. Common categories include:
- 自然语言处理 (Natural Language Processing)
- 计算机视觉 (Computer Vision)
- 生成模型 (Generative Models)
- 机器学习 (Machine Learning)
- 强化学习 (Reinforcement Learning)

Each paper should belong to exactly one category representing its primary research domain.

## Documentation

- `README.md` - Quick start and project structure
- `USAGE_GUIDE.md` - Detailed usage instructions for content creation
- `CLASSIFICATION_GUIDE.md` - Guidelines for choosing categories
- `NAVIGATION_UPDATE.md` - Explanation of category quick-switch feature

## Local Environment Notes

On this macOS system, Hugo is installed at `/opt/homebrew/bin/hugo` and may not be in the default PATH. Commands should use the full path or add `/opt/homebrew/bin` to PATH.
