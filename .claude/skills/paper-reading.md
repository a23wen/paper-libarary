---
description: Read an academic paper from a URL, summarize it, and create a Hugo paper note
---

# Paper Reading Skill

This skill helps you read an academic paper, analyze it, and create a structured note in the Hugo site.

## Workflow

1. **Fetch Paper**: Retrieve the paper from the provided URL (arXiv, PDF link, etc.)
2. **Deep Analysis**: 
   - Read and understand the paper content
   - Identify key contributions and innovations
   - Extract methodology and experimental results
   - Note strengths and limitations
3. **Create Note**: Generate a Hugo paper note using the papers archetype
4. **Categorize**: Place the paper in the appropriate research area category
5. **Deploy**: Commit and push changes to GitHub

## Usage

```
/paper-reading <paper-url>
```

## Example

```
/paper-reading https://arxiv.org/pdf/2503.06749
```

## Output

- A new paper note in `content/papers/`
- Proper categorization by research area
- Automatic Git commit and push
- Detailed explanation of the paper's content
