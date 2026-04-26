export function parseFrontmatter(content: string): Record<string, string> {
  const normalized = content.replace(/\r\n/g, "\n")
  const match = normalized.match(/^---\n([\s\S]*?)\n---(?:\n|$)/)

  if (!match) {
    return {}
  }

  return Object.fromEntries(
    match[1]
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean)
      .map((line) => {
        const separatorIndex = line.indexOf(":")

        if (separatorIndex === -1) {
          throw new Error(`Invalid frontmatter line: ${line}`)
        }

        const key = line.slice(0, separatorIndex).trim()
        const value = line.slice(separatorIndex + 1).trim().replace(/^['\"]|['\"]$/g, "")

        return [key, value]
      }),
  )
}
