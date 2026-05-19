import { rm, access, readFile, writeFile } from "node:fs/promises"
import { constants as fsConstants } from "node:fs"
import { join } from "node:path"
import { bumpVersion, collectChangedSkills, listChangedFiles } from "./lib.mjs"

const VALID_BUMPS = new Set(["major", "minor", "patch"])

async function exists(path) {
  try {
    await access(path, fsConstants.F_OK)
    return true
  } catch {
    return false
  }
}

function parseIntent(raw, intentPath) {
  let parsed
  try {
    parsed = JSON.parse(raw)
  } catch {
    throw new Error(`Intent file ${intentPath} is not valid JSON`)
  }

  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error(`Intent file ${intentPath} must contain a JSON object`)
  }

  if (!VALID_BUMPS.has(parsed.bump)) {
    throw new Error(`Intent file ${intentPath} must define bump as one of: major, minor, patch`)
  }

  if (parsed.summary !== undefined && (typeof parsed.summary !== "string" || parsed.summary.trim().length === 0)) {
    throw new Error(`Intent file ${intentPath} summary must be a non-empty string when provided`)
  }

  return {
    bump: parsed.bump,
    summary: parsed.summary?.trim(),
  }
}

function updateSkillMarkdownVersion(skillMarkdown, nextVersion, skill) {
  const newline = skillMarkdown.includes("\r\n") ? "\r\n" : "\n"
  const normalized = skillMarkdown.replace(/\r\n/g, "\n")

  if (!normalized.startsWith("---\n")) {
    throw new Error(`SKILL.md for ${skill} must start with frontmatter`) 
  }

  const endFrontmatter = normalized.indexOf("\n---\n", 4)
  if (endFrontmatter === -1) {
    throw new Error(`SKILL.md for ${skill} must contain a closing frontmatter marker`) 
  }

  const frontmatter = normalized.slice(0, endFrontmatter + 5)
  const body = normalized.slice(endFrontmatter + 5)

  if (!/^version:\s*.+$/m.test(frontmatter)) {
    throw new Error(`SKILL.md frontmatter for ${skill} must contain a version line`) 
  }

  const updatedFrontmatter = frontmatter.replace(/^version:\s*.+$/m, `version: ${nextVersion}`)
  return `${updatedFrontmatter}${body}`.replace(/\n/g, newline)
}

function updateReadmeVersion(readme, nextVersion, skill) {
  if (!/^Version:\s*.+$/m.test(readme)) {
    throw new Error(`README.md for ${skill} must contain a Version: line`)
  }
  return readme.replace(/^Version:\s*.+$/m, `Version: ${nextVersion}`)
}

function prependChangelog(existing, nextVersion, summary) {
  const date = new Date().toISOString().slice(0, 10)
  const entry = `## ${nextVersion} - ${date}\n\n- ${summary}\n\n`
  const normalized = existing.replace(/\r\n/g, "\n")

  if (normalized.startsWith("# Changelog")) {
    const remainder = normalized.replace(/^# Changelog\s*\n*/m, "")
    return `# Changelog\n\n${entry}${remainder.trimStart()}`
  }

  const prefix = normalized.trim().length > 0 ? `${normalized}\n\n` : ""
  return `# Changelog\n\n${entry}${prefix}`
}

async function main() {
  const [, , baseSha, headSha] = process.argv
  if (!baseSha || !headSha) {
    throw new Error("Usage: node scripts/versioning/apply-skill-releases.mjs <baseSha> <headSha>")
  }

  const changedFiles = listChangedFiles(baseSha, headSha)
  const changedSkills = collectChangedSkills(changedFiles)
  const releases = []

  for (const skill of changedSkills) {
    const skillDir = join("skills", skill)
    if (!(await exists(skillDir))) {
      continue
    }

    const intentPath = join(".changes", "skills", `${skill}.json`)
    if (!(await exists(intentPath))) {
      throw new Error(`Missing required version intent file: ${intentPath}`)
    }

    const intent = parseIntent(await readFile(intentPath, "utf8"), intentPath)

    const metadataPath = join(skillDir, "metadata.json")
    const skillMdPath = join(skillDir, "SKILL.md")
    const readmePath = join(skillDir, "README.md")
    const changelogPath = join(skillDir, "CHANGELOG.md")

    const metadata = JSON.parse(await readFile(metadataPath, "utf8"))
    const previousVersion = metadata.version
    const nextVersion = bumpVersion(previousVersion, intent.bump)
    metadata.version = nextVersion

    const skillMarkdown = await readFile(skillMdPath, "utf8")
    const readme = await readFile(readmePath, "utf8")
    const existingChangelog = (await exists(changelogPath)) ? await readFile(changelogPath, "utf8") : ""

    await writeFile(metadataPath, `${JSON.stringify(metadata, null, 2)}\n`, "utf8")
    await writeFile(skillMdPath, updateSkillMarkdownVersion(skillMarkdown, nextVersion, skill), "utf8")
    await writeFile(readmePath, updateReadmeVersion(readme, nextVersion, skill), "utf8")

    const summary = intent.summary ?? `Version bump (${intent.bump}) from merged pull request changes.`
    await writeFile(changelogPath, prependChangelog(existingChangelog, nextVersion, summary), "utf8")

    await rm(intentPath)

    releases.push({
      skill,
      bump: intent.bump,
      previousVersion,
      newVersion: nextVersion,
      tag: `skill/${skill}/v${nextVersion}`,
    })
  }

  process.stdout.write(`${JSON.stringify(releases, null, 2)}\n`)
}

await main()
