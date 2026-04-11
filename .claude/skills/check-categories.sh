#!/bin/bash
# Helper script to check existing paper categories in the Hugo site

echo "=== 现有论文分类 ==="
echo ""

# 方法 1：从现有论文中提取分类
echo "📂 从已发布论文中提取的分类："
grep -h "^categories:" content/papers/*.md 2>/dev/null | \
    sed 's/categories: \["\(.*\)"\]/\1/' | \
    sort -u | \
    while read category; do
        count=$(grep -l "categories: \[\"$category\"\]" content/papers/*.md 2>/dev/null | wc -l | tr -d ' ')
        echo "  - $category ($count 篇)"
    done

echo ""

# 方法 2：查看 Hugo 生成的分类页面
if [ -d "public/categories" ]; then
    echo "📊 Hugo 生成的分类页面："
    ls -1 public/categories/ 2>/dev/null | grep -v "index\|\.xml" | \
        while read dir; do
            echo "  - $dir"
        done
else
    echo "⚠️  public/ 目录不存在，请先运行 hugo 构建"
fi

echo ""
echo "=== 分类统计 ==="
total_papers=$(ls -1 content/papers/*.md 2>/dev/null | wc -l | tr -d ' ')
echo "总论文数: $total_papers"
