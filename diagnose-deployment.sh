#!/bin/bash

echo "=========================================="
echo "  GitHub Pages 部署诊断"
echo "=========================================="
echo ""

REPO="a23wen/paper-libarary"

echo "🔍 诊断步骤："
echo ""
echo "1️⃣  检查 GitHub Pages 设置"
echo "   访问: https://github.com/$REPO/settings/pages"
echo "   确认 Source 设置为: GitHub Actions (不是 Deploy from a branch)"
echo ""

echo "2️⃣  检查 GitHub Actions 工作流"
echo "   访问: https://github.com/$REPO/actions"
echo "   查看是否有失败的工作流"
echo ""

echo "3️⃣  检查工作流权限"
echo "   访问: https://github.com/$REPO/settings/actions"
echo "   Workflow permissions 应该设为: Read and write permissions"
echo ""

echo "=========================================="
echo "📋 当前配置检查"
echo "=========================================="
echo ""

echo "✅ baseURL 配置:"
grep "^baseURL" hugo.toml
echo ""

echo "✅ GitHub Actions 工作流文件存在:"
if [ -f ".github/workflows/deploy.yml" ]; then
    echo "   ✓ .github/workflows/deploy.yml 存在"
else
    echo "   ✗ .github/workflows/deploy.yml 不存在"
fi
echo ""

echo "✅ Git 状态:"
if git diff-index --quiet HEAD --; then
    echo "   ✓ 工作区干净"
else
    echo "   ⚠ 有未提交的更改"
    git status -s
fi
echo ""

echo "=========================================="
echo "🛠️  修复步骤（按顺序执行）"
echo "=========================================="
echo ""
echo "步骤 1: 确保最新代码已推送"
echo "  git push origin main"
echo ""

echo "步骤 2: 访问 GitHub Pages 设置"
echo "  https://github.com/$REPO/settings/pages"
echo "  将 Source 从 'Deploy from a branch' 改为 'GitHub Actions'"
echo ""

echo "步骤 3: 确保工作流权限正确"
echo "  https://github.com/$REPO/settings/actions"
echo "  选择 'Read and write permissions'"
echo "  勾选 'Allow GitHub Actions to create and approve pull requests'"
echo ""

echo "步骤 4: 手动触发工作流（如果需要）"
echo "  访问: https://github.com/$REPO/actions/workflows/deploy.yml"
echo "  点击 'Run workflow' → 'Run workflow'"
echo ""

echo "步骤 5: 等待 1-2 分钟，然后访问"
echo "  https://a23wen.github.io/paper-libarary/"
echo ""

echo "=========================================="
