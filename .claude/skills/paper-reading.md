---
description: Read an academic paper from a URL, analyze it, and create a structured note with intelligent categorization
---

# Paper Reading Skill

This skill automatically reads academic papers, performs deep analysis, and creates structured notes in the Hugo site with intelligent categorization.

## Workflow

1. **Fetch Paper**: Retrieve the paper from the provided URL (arXiv, PDF link, etc.)
2. **Deep Analysis**: 
   - Read and understand the paper content
   - Identify key contributions and innovations
   - Extract methodology and experimental results
   - Note strengths and limitations
3. **Intelligent Categorization**:
   - List and analyze existing categories from `content/papers/*.md`
   - Determine paper's primary research domain
   - **If matching category exists (≥70% semantic match)**: Use existing category
   - **If no suitable match**: Create new category with appropriate name
   - Explain categorization decision
4. **Create Note**: Generate a Hugo paper note with proper front matter
5. **Verify**: Check that the note is properly formatted and categorized
6. **Deploy**: Commit and push changes to GitHub with descriptive message

## Intelligent Categorization

The skill automatically:
1. **Analyzes paper domain**: Determine research area from title, abstract, and content
2. **Checks existing categories**: 
   - List all `content/papers/*.md` files
   - Extract unique categories from front matter
   - Get category list sorted by frequency
3. **Makes categorization decision**:
   - **If good match exists (≥70% semantic similarity)**: Use existing category
   - **If no good match**: Create new appropriate category
   - Consider both Chinese and English naming conventions
4. **Documents decision**: Include categorization rationale in commit message

### Category Creation Rules

New categories are created when:
- Paper's domain doesn't match existing categories (semantic similarity < 70%)
- Paper represents a new subfield or emerging research area
- Paper is cross-disciplinary and doesn't fit existing categories
- Using a more specific category significantly improves organization

**Existing categories to check first**:
- 自然语言处理 (Natural Language Processing)
- 计算机视觉 (Computer Vision)
- 生成模型 (Generative Models)
- 视觉语言模型 (Vision Language Models)
- 强化学习 (Reinforcement Learning)
- 图神经网络 (Graph Neural Networks)
- 机器学习 (Machine Learning)
- 多模态学习 (Multimodal Learning)

**Creating new categories**:
- Use Chinese names with English clarification
- Keep names concise and descriptive
- Follow pattern: "主题领域" (English Translation)
- Document new category creation in commit message

## Usage

```
/paper-reading <paper-url>
```

## Examples

**Example 1: Using existing category**
```
/paper-reading https://arxiv.org/pdf/2503.06749
```

This will:
1. Read the Vision-R1 paper
2. Detect it's about multimodal reasoning
3. Find existing "视觉语言模型" category
4. Use that category
5. Generate notes and deploy

**Example 2: Creating new category**
```
/paper-reading https://arxiv.org/pdf/xxxx.xxxxx
```

If paper is about "Federated Learning" and no matching category exists:
1. Read the paper
2. Check existing categories
3. Determine no good match exists
4. Create new category "联邦学习 (Federated Learning)"
5. Generate notes with new category
6. Commit message includes: "Created new category: 联邦学习"

## Output

- A new paper note in `content/papers/`
- Proper categorization (existing or newly created)
- Categorization explanation and rationale
- Automatic Git commit and push with descriptive message
- Detailed paper analysis in the note content

## Implementation Steps

When processing a paper:

1. **Extract existing categories**:
   ```bash
   grep "^categories:" content/papers/*.md | sed 's/.*\[\"\(.*\)\"\].*/\1/' | sort -u
   ```

2. **Analyze paper domain**: Determine from title, abstract, methodology, and keywords

3. **Match or create**:
   - Compare paper domain with existing categories
   - If semantic match ≥70%: Use existing
   - If no match: Create new category following naming convention

4. **Generate note**: Use `hugo new papers/paper-name.md` and fill in all metadata

5. **Commit**: Include categorization info in message

## Notes

- Hugo categories are created automatically when used in front matter
- No physical directory creation needed for categories
- New categories appear in site navigation immediately after deployment
- Each paper belongs to exactly ONE category (single taxonomy system)
- Category names should be consistent (use existing when possible)
