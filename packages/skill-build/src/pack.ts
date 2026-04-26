import { mkdir, rm } from "node:fs/promises"
import { spawnSync } from "node:child_process"
import { basename, join } from "node:path"
import { artifactsDir, skillsDir } from "./config"
import { validateSkills } from "./validate"

function createZip(skillName: string, outputPath: string, cwd: string): void {
  const result = spawnSync(
    "zip",
    [
      "-X",   // exclude extra file attributes (UID/GID)
      "-r",   // recurse into directories
      outputPath,
      skillName,
      "--exclude", `${skillName}/INDEX.md`,
      "--exclude", `${skillName}/*.zip`,
    ],
    { cwd, stdio: "inherit" },
  )

  if (result.status !== 0) {
    throw new Error(`zip failed while creating ${outputPath}`)
  }
}

export async function packSkills(): Promise<void> {
  const skills = await validateSkills()
  const outputDir = join(artifactsDir, "skills")
  await mkdir(outputDir, { recursive: true })

  for (const skill of skills) {
    const skillName = basename(skill.dir)
    const outputPath = join(outputDir, `${skillName}.zip`)
    await rm(outputPath, { force: true })
    createZip(skillName, outputPath, skillsDir)
  }

  console.log(`Packed ${skills.length} skill${skills.length === 1 ? "" : "s"} into artifacts/skills/`)
}

if (import.meta.main) {
  await packSkills()
}
