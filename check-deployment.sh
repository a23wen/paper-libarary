#!/bin/bash

# GitHub Pages 部署检查脚本

echo "=========================================="
echo "  GitHub Pages 部署状态检查"
echo "=========================================="
echo ""

# 仓库信息
REPO="a23wen/paper-libarary"
SITE_URL="https://a23wen.github.io/paper-libarary/"

echo "📦 仓库: $REPO"
echo "🌐 网站地址: $SITE_URL"
echo ""

# 检查 Git 状态
echo "📋 检查本地 Git 状态..."
if git status --short | grep -q .; then
    echo "⚠️  有未提交的更改:"
    git status --short
else
    echo "✅ 工作区干净"
fi
echo ""

# 检查远程同步
echo "🔄 检查远程同步状态..."
git fetch origin >/dev/null 2>&1
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "✅ 本地与远程同步"
else
    echo "⚠️  本地与远程不同步，请运行: git pull 或 git push"
fi
echo ""

# 显示最近的提交
echo "📝 最近3次提交:"
git log --oneline -3
echo ""

# 检查配置
echo "⚙️  检查 Hugo 配置..."
BASEURL=$(grep "^baseURL" hugo.toml | cut -d"'" -f2)
echo "   baseURL: $BASEURL"

if [ "$BASEURL" = "$SITE_URL" ]; then
    echo "   ✅ baseURL 配置正确"
else
    echo "   ⚠️  baseURL 可能需要更新为: $SITE_URL"
fi
echo ""

# 检查网站可访问性
echo "🌍 检查网站可访问性..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SITE_URL" --max-time 10)

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ 网站正常访问 (HTTP $HTTP_CODE)"
    echo "   🎉 部署成功！"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "   ❌ 网站未找到 (HTTP 404)"
    echo "   💡 可能原因:"
    echo "      1. GitHub Pages 尚未启用"
    echo "      2. 首次部署还在进行中（等待 1-2 分钟）"
    echo "      3. 工作流部署失败"
elif [ "$HTTP_CODE" = "000" ]; then
    echo "   ⚠️  无法连接到网站（可能是网络问题）"
else
    echo "   ⚠️  HTTP 状态码: $HTTP_CODE"
fi
echo ""

# 提供有用的链接
echo "🔗 有用的链接:"
echo "   - Actions 工作流: https://github.com/$REPO/actions"
echo "   - Pages 设置: https://github.com/$REPO/settings/pages"
echo "   - 仓库首页: https://github.com/$REPO"
echo "   - 网站地址: $SITE_URL"
echo ""

echo "=========================================="
echo "💡 下一步操作:"
echo ""
echo "1. 访问 Actions 页面检查部署状态"
echo "2. 确保 Pages 设置中 Source 为 'GitHub Actions'"
echo "3. 等待部署完成（首次约 1-2 分钟）"
echo "4. 访问你的网站！"
echo "=========================================="
