import { writeFile } from "node:fs/promises"
import { join } from "node:path"
import { skillsDir } from "./config"
import { validateSkills } from "./validate"

function buildIndexMarkdown(skills: Awaited<ReturnType<typeof validateSkills>>): string {
  const header = [
    "# Skills Index",
    "Generated file. Do not edit manually.",
    "| Skill | Version | Type | Summary |",
    "|---|---:|---|---|",
  ]

  const rows = skills.map(
    (s) => `| \`${s.metadata.name}\` | ${s.metadata.version} | ${s.metadata.type} | ${s.metadata.summary} |`,
  )

  return [...header, ...rows, ""].join("\n")
}

export async function buildSkills(): Promise<void> {
  const skills = await validateSkills()

  const indexPath = join(skillsDir, "INDEX.md")
  await writeFile(indexPath, buildIndexMarkdown(skills), "utf8")

  console.log(`Built index for ${skills.length} skill${skills.length === 1 ? "" : "s"} → skills/INDEX.md`)
}

if (import.meta.main) {
  await buildSkills()
}
