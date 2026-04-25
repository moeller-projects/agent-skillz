import { readFile } from "node:fs/promises"
import { basename, join } from "node:path"
import { skillsDir } from "./config"
import { getSkillDirectories, readJsonFile } from "./fs-utils"
import { parseFrontmatter } from "./frontmatter"
import type { SkillMetadata, ValidatedSkill } from "./types"

const REQUIRED_FILES = ["SKILL.md", "README.md", "metadata.json"] as const
const SEMVER_PATTERN = /^\d+\.\d+\.\d+$/
const SKILL_NAME_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) {
    throw new Error(message)
  }
}

function validateMetadata(metadata: SkillMetadata, skillDirName: string): void {
  assert(SKILL_NAME_PATTERN.test(metadata.name), `Invalid skill name: ${metadata.name}`)
  assert(metadata.name === skillDirName, `Skill directory ${skillDirName} must match metadata name ${metadata.name}`)
  assert(metadata.title.trim().length > 0, "Skill title is required")
  assert(SEMVER_PATTERN.test(metadata.version), `Invalid version: ${metadata.version}`)
  assert(metadata.summary.trim().length > 0, "Skill summary is required")
}

function getReadmeVersion(content: string): string {
  const match = content.match(/^Version:\s*(.+)$/m)
  assert(match, "README.md must contain a Version: line")
  return match[1].trim()
}

async function validateSkill(dir: string): Promise<ValidatedSkill> {
  const skillDirName = basename(dir)

  for (const requiredFile of REQUIRED_FILES) {
    const filePath = join(dir, requiredFile)
    await readFile(filePath, "utf8")
  }

  const metadata = await readJsonFile<SkillMetadata>(join(dir, "metadata.json"))
  validateMetadata(metadata, skillDirName)

  const skillContent = await readFile(join(dir, "SKILL.md"), "utf8")
  const frontmatter = parseFrontmatter(skillContent)
  const readmeContent = await readFile(join(dir, "README.md"), "utf8")
  const readmeVersion = getReadmeVersion(readmeContent)

  for (const field of ["name", "title", "version", "summary"] as const) {
    assert(frontmatter[field], `SKILL.md frontmatter must include ${field}`)
    assert(frontmatter[field] === metadata[field], `Mismatch for ${field} in ${skillDirName}`)
  }

  assert(readmeVersion === metadata.version, `README.md version mismatch in ${skillDirName}`)

  return {
    dir,
    metadata,
    frontmatter,
    readmeVersion,
  }
}

export async function validateSkills(): Promise<ValidatedSkill[]> {
  const skillDirs = await getSkillDirectories(skillsDir)
  assert(skillDirs.length > 0, "At least one skill is required")

  const skills: ValidatedSkill[] = []

  for (const dir of skillDirs) {
    skills.push(await validateSkill(dir))
  }

  return skills.sort((left, right) => left.metadata.name.localeCompare(right.metadata.name))
}

async function main(): Promise<void> {
  const skills = await validateSkills()
  console.log(`Validated ${skills.length} skill${skills.length === 1 ? "" : "s"}.`)
}

if (import.meta.main) {
  await main()
}
