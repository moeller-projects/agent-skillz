import { basename, join } from "node:path"
import { distDir } from "./config"
import { copyDir, emptyDir, writeJsonFile } from "./fs-utils"
import { validateSkills } from "./validate"

export async function buildSkills(): Promise<void> {
  const skills = await validateSkills()
  const outputSkillsDir = join(distDir, "skills")

  await emptyDir(distDir)

  for (const skill of skills) {
    const outputDir = join(outputSkillsDir, basename(skill.dir))
    await copyDir(skill.dir, outputDir)
    await writeJsonFile(join(outputDir, "skill.json"), {
      metadata: skill.metadata,
      files: {
        skill: "SKILL.md",
        readme: "README.md",
        metadata: "metadata.json",
      },
    })
  }

  await writeJsonFile(join(distDir, "index.json"), {
    generatedAt: "1970-01-01T00:00:00.000Z",
    skills: skills.map((skill) => skill.metadata),
  })

  console.log(`Built ${skills.length} skill${skills.length === 1 ? "" : "s"} into ${distDir}.`)
}

if (import.meta.main) {
  await buildSkills()
}
