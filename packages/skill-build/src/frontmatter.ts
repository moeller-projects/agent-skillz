export function parseFrontmatter(content: string): Record<string, string> {
  const normalized = content.replace(/\r\n/g, "\n")
  const match = normalized.match(/^---\n([\s\S]*?)\n---(?:\n|$)/)

  if (!match) {
    return {}
  }

  const lines = match[1].split("\n")
  const result: Record<string, string> = {}
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
    } else {
      result[key] = rawValue.replace(/^['\"]|['\"]$/g, "")
      i++
    }
  }

  return result
}
