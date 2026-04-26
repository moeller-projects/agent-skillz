import { readFile } from "node:fs/promises"
import { basename, join } from "node:path"
import { skillsDir } from "./config"
import { getSkillDirectories, readJsonFile } from "./fs-utils"
import { parseFrontmatter } from "./frontmatter"
import type { SkillMetadata, ValidatedSkill } from "./types"

const REQUIRED_FILES = ["SKILL.md", "README.md", "metadata.json"] as const
const SEMVER_PATTERN = /^\d+\.\d+\.\d+$/
const SKILL_NAME_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/
const VALID_TYPES = ["prompt", "rule", "script", "hybrid"] as const
const MIN_DESCRIPTION_LENGTH = 10

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) {
    throw new Error(message)
  }
}

function assertNonEmptyString(value: unknown, message: string): asserts value is string {
  assert(typeof value === "string", message)
  assert(value.trim().length > 0, message)
}

function validateMetadata(metadata: SkillMetadata, skillDirName: string): void {
  assertNonEmptyString(metadata.name, `Skill name is required in ${skillDirName}`)
  assert(SKILL_NAME_PATTERN.test(metadata.name), `Invalid skill name: ${metadata.name}`)
  assert(metadata.name === skillDirName, `Skill directory "${skillDirName}" must match metadata name "${metadata.name}"`)
  assertNonEmptyString(metadata.title, `Skill title is required in ${skillDirName}`)
  assertNonEmptyString(metadata.version, `Skill version is required in ${skillDirName}`)
  assert(SEMVER_PATTERN.test(metadata.version), `Invalid version "${metadata.version}" in ${skillDirName}`)
  assertNonEmptyString(metadata.summary, `Skill summary is required in ${skillDirName}`)
  assert(
    VALID_TYPES.includes(metadata.type as (typeof VALID_TYPES)[number]),
    `Invalid skill type "${metadata.type}" in ${skillDirName}; expected one of: ${VALID_TYPES.join(", ")}`,
  )
  assert(
    metadata.activation !== null && typeof metadata.activation === "object",
    `Skill activation is required and must be an object in ${skillDirName}`,
  )
  assert(
    Array.isArray(metadata.activation.use_when) &&
      metadata.activation.use_when.every((v) => typeof v === "string"),
    `activation.use_when must be an array of strings in ${skillDirName}`,
  )
  assert(
    metadata.activation.use_when.length > 0,
    `activation.use_when must contain at least one entry in ${skillDirName}`,
  )
  assert(
    Array.isArray(metadata.activation.avoid_when) &&
      metadata.activation.avoid_when.every((v) => typeof v === "string"),
    `activation.avoid_when must be an array of strings in ${skillDirName}`,
  )
  assert(
    metadata.activation.avoid_when.length > 0,
    `activation.avoid_when must contain at least one entry in ${skillDirName}`,
  )
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
  assert(
    typeof frontmatter["description"] === "string" &&
      frontmatter["description"].length >= MIN_DESCRIPTION_LENGTH,
    `SKILL.md must include a meaningful description in ${skillDirName}`,
  )
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
