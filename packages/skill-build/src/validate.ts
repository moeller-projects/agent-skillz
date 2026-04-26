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
  assert(metadata.name === skillDirName, `Skill directory "${skillDirName}" must match metadata name "${metadata.name}"`)
  assert(metadata.title.trim().length > 0, `Skill title is required in ${skillDirName}`)
  assert(SEMVER_PATTERN.test(metadata.version), `Invalid version "${metadata.version}" in ${skillDirName}`)
  assert(metadata.summary.trim().length > 0, `Skill summary is required in ${skillDirName}`)
}

async function validateSkill(dir: string): Promise<ValidatedSkill> {
  const skillDirName = basename(dir)

  for (const requiredFile of REQUIRED_FILES) {
    try {
      await readFile(join(dir, requiredFile), "utf8")
    } catch {
      throw new Error(`Missing required file "${requiredFile}" in ${skillDirName}`)
    }
  }

  const metadata = await readJsonFile<SkillMetadata>(join(dir, "metadata.json"))
  validateMetadata(metadata, skillDirName)

  const skillContent = await readFile(join(dir, "SKILL.md"), "utf8")
  const frontmatter = parseFrontmatter(skillContent)
  assert(Object.keys(frontmatter).length > 0, `SKILL.md in ${skillDirName} must have frontmatter`)
  assert(frontmatter["name"] === skillDirName, `SKILL.md frontmatter name "${frontmatter["name"]}" must match folder "${skillDirName}"`)
  assert(frontmatter["version"] !== undefined, `SKILL.md in ${skillDirName} must include a version in frontmatter`)
  assert(frontmatter["version"] === metadata.version, `SKILL.md frontmatter version "${frontmatter["version"]}" must match metadata version "${metadata.version}" in ${skillDirName}`)
  return { dir, metadata, frontmatter }
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
