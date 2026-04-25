import { spawnSync } from "node:child_process"
import { basename, join } from "node:path"
import { artifactsDir, distDir } from "./config"
import { buildSkills } from "./build"
import { emptyDir } from "./fs-utils"
import { validateSkills } from "./validate"

function packDirectory(sourceDir: string, outputFile: string, cwd: string): void {
  const result = spawnSync(
    "tar",
    [
      "--sort=name",
      "--mtime=UTC 1970-01-01",
      "--owner=0",
      "--group=0",
      "--numeric-owner",
      "-czf",
      outputFile,
      sourceDir,
    ],
    {
      cwd,
      stdio: "inherit",
    },
  )

  if (result.status !== 0) {
    throw new Error(`tar failed while creating ${outputFile}`)
  }
}

export async function packSkills(): Promise<void> {
  const skills = await validateSkills()

  await buildSkills()
  await emptyDir(artifactsDir)

  for (const skill of skills) {
    const archiveName = `${skill.metadata.name}-${skill.metadata.version}.tgz`
    const sourceDir = join("skills", basename(skill.dir))
    const outputFile = join(artifactsDir, archiveName)
    packDirectory(sourceDir, outputFile, distDir)
  }

  console.log(`Packed ${skills.length} skill${skills.length === 1 ? "" : "s"} into ${artifactsDir}.`)
}

if (import.meta.main) {
  await packSkills()
}
