import { rm, readFile, writeFile } from "node:fs/promises"
import { join } from "node:path"
import { bumpVersion, collectChangedSkills, fileExists, listChangedFiles, parseIntent } from "./lib"

function updateSkillMarkdownVersion(skillMarkdown: string, nextVersion: string, skill: string): string {
  const newline = skillMarkdown.includes("\r\n") ? "\r\n" : "\n"
  const normalized = skillMarkdown.replace(/\r\n/g, "\n")

  if (!normalized.startsWith("---\n")) {
    throw new Error(`SKILL.md for ${skill} must start with YAML frontmatter (---)`)
  }

  const endFrontmatter = normalized.indexOf("\n---\n", 4)
  if (endFrontmatter === -1) {
    throw new Error(`SKILL.md for ${skill} must contain a closing frontmatter marker (---)`)
  }

  const frontmatter = normalized.slice(0, endFrontmatter + 5)
  const body = normalized.slice(endFrontmatter + 5)

  if (!/^version:\s*.+$/m.test(frontmatter)) {
    throw new Error(`SKILL.md frontmatter for ${skill} must contain a 'version:' line`)
  }

  const updatedFrontmatter = frontmatter.replace(/^version:\s*.+$/m, `version: ${nextVersion}`)
  return `${updatedFrontmatter}${body}`.replace(/\n/g, newline)
}

function updateReadmeVersion(readme: string, nextVersion: string, skill: string): string {
  if (!/^Version:\s*.+$/m.test(readme)) {
    throw new Error(`README.md for ${skill} must contain a Version: line`)
  }
  return readme.replace(/^Version:\s*.+$/m, `Version: ${nextVersion}`)
}

function prependChangelog(existing: string, nextVersion: string, summary: string): string {
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

interface ReleaseRecord {
  skill: string
  bump?: "major" | "minor" | "patch"
  version?: string
  previousVersion: string
  newVersion: string
  tag: string
}

async function main(): Promise<void> {
  const [, , baseSha, headSha] = process.argv
  if (!baseSha || !headSha) {
    throw new Error("Usage: bun run version:apply -- <baseSha> <headSha>")
  }

  const changedFiles = listChangedFiles(baseSha, headSha)
  const changedSkills = collectChangedSkills(changedFiles)
  const releases: ReleaseRecord[] = []

  for (const skill of changedSkills) {
    const skillDir = join("skills", skill)
    if (!(await fileExists(skillDir))) {
      continue
    }

    const intentPath = join(".changes", "skills", `${skill}.json`)
    if (!(await fileExists(intentPath))) {
      throw new Error(`Missing required version intent file: ${intentPath}`)
    }

    const intent = parseIntent(await readFile(intentPath, "utf8"), intentPath)

    const metadataPath = join(skillDir, "metadata.json")
    const skillMdPath = join(skillDir, "SKILL.md")
    const readmePath = join(skillDir, "README.md")
    const changelogPath = join(skillDir, "CHANGELOG.md")

    const metadata = JSON.parse(await readFile(metadataPath, "utf8")) as { version: string }
    const previousVersion = metadata.version
    const nextVersion = intent.version ?? bumpVersion(previousVersion, intent.bump!)
    metadata.version = nextVersion

    const skillMarkdown = await readFile(skillMdPath, "utf8")
    const readme = await readFile(readmePath, "utf8")
    const existingChangelog = (await fileExists(changelogPath)) ? await readFile(changelogPath, "utf8") : ""

    await writeFile(metadataPath, `${JSON.stringify(metadata, null, 2)}\n`, "utf8")
    await writeFile(skillMdPath, updateSkillMarkdownVersion(skillMarkdown, nextVersion, skill), "utf8")
    await writeFile(readmePath, updateReadmeVersion(readme, nextVersion, skill), "utf8")

    const summary =
      intent.summary ??
      (intent.version
        ? `Version set to ${intent.version} from merged pull request changes.`
        : `Version bump (${intent.bump}) from merged pull request changes.`)
    await writeFile(changelogPath, prependChangelog(existingChangelog, nextVersion, summary), "utf8")

    await rm(intentPath)

    releases.push({
      skill,
      bump: intent.bump,
      version: intent.version,
      previousVersion,
      newVersion: nextVersion,
      tag: `skill/${skill}/v${nextVersion}`,
    })
  }

  process.stdout.write(`${JSON.stringify(releases, null, 2)}\n`)
}

if (import.meta.main) {
  await main()
}
