export function parseFrontmatter(content: string): Record<string, string | string[]> {
  const normalized = content.replace(/\r\n/g, "\n")
  const match = normalized.match(/^---\n([\s\S]*?)\n---(?:\n|$)/)

  if (!match) {
    return {}
  }

  const lines = match[1].split("\n")
  const result: Record<string, string | string[]> = {}
  let i = 0

  while (i < lines.length) {
    const line = lines[i]
    if (!line.trim()) {
      i++
      continue
    }

    const separatorIndex = line.indexOf(":")
    if (separatorIndex === -1) {
      throw new Error(`Invalid frontmatter line: ${line}`)
    }

    const key = line.slice(0, separatorIndex).trim()
    const rawValue = line.slice(separatorIndex + 1).trim()

    const inlineArrayMatch = rawValue.match(/^\[(.*)\]$/)
    if (inlineArrayMatch) {
      const inner = inlineArrayMatch[1].trim()
      result[key] = inner.length === 0 ? [] : inner.split(",").map((item) => item.trim()).filter(Boolean)
      i++
      continue
    }

    // Handle YAML block scalars (> folded, | literal)
    if (rawValue === ">" || rawValue === "|") {
      const isFolded = rawValue === ">"
      const continuationLines: string[] = []
      i++
      while (i < lines.length && /^\s/.test(lines[i])) {
        continuationLines.push(lines[i].trim())
        i++
      }
      result[key] = isFolded ? continuationLines.join(" ") : continuationLines.join("\n")
    } else if (rawValue === "") {
      const items: string[] = []
      i++
      while (i < lines.length && /^\s*- /.test(lines[i])) {
        items.push(lines[i].replace(/^\s*-\s*/, "").trim())
        i++
      }
      result[key] = items
    } else {
      result[key] = rawValue.replace(/^['\"]|['\"]$/g, "")
      i++
    }
  }

  return result
}
