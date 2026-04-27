import { spawnSync } from "node:child_process"
import { basename, join } from "node:path"
import { artifactsDir, skillsDir } from "./config"
import { emptyDir } from "./fs-utils"
import { validateSkills } from "./validate"

function createZip(entries: string[], outputPath: string, cwd: string): void {
  const args = [
    "-X", // exclude extra file attributes (UID/GID)
    "-r", // recurse into directories
    outputPath,
    ...entries,
  ]

  for (const entry of entries) {
    args.push("--exclude", `${entry}/INDEX.md`)
    args.push("--exclude", `${entry}/*.zip`)
  }

  const result = spawnSync(
    "zip",
    args,
    { cwd, stdio: "inherit" },
  )

  if (result.status !== 0) {
    throw new Error(`zip failed while creating ${outputPath}`)
  }
}

export async function packSkills(): Promise<void> {
  const skills = await validateSkills()
  const outputDir = join(artifactsDir, "skills")
  await emptyDir(outputDir)
  const skillNames = skills.map((skill) => basename(skill.dir))

  createZip(skillNames, join(outputDir, "skills.zip"), skillsDir)

  for (const skillName of skillNames) {
    createZip([skillName], join(outputDir, `${skillName}.zip`), skillsDir)
  }

  console.log(
    `Packed ${skills.length} skill${skills.length === 1 ? "" : "s"} into artifacts/skills/ (skills.zip + individual skill zips)`,
  )
}

if (import.meta.main) {
  await packSkills()
}
