import { access, readFile } from "node:fs/promises"
import { constants as fsConstants } from "node:fs"
import { join } from "node:path"
import { collectChangedSkills, listChangedFiles } from "./lib.mjs"

const VALID_BUMPS = new Set(["major", "minor", "patch"])

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

  return parsed
}

async function exists(path) {
  try {
    await access(path, fsConstants.F_OK)
    return true
  } catch {
    return false
  }
}

async function main() {
  const [, , baseSha, headSha] = process.argv
  if (!baseSha || !headSha) {
    throw new Error("Usage: node scripts/versioning/check-version-intents.mjs <baseSha> <headSha>")
  }

  const changedFiles = listChangedFiles(baseSha, headSha)
  const changedSkills = collectChangedSkills(changedFiles)

  if (changedSkills.length === 0) {
    console.log("No skill directory changes detected; version intent check passed.")
    return
  }

  const missing = []

  for (const skill of changedSkills) {
    const intentPath = join(".changes", "skills", `${skill}.json`)
    if (!(await exists(intentPath))) {
      missing.push(intentPath)
      continue
    }

    const intentRaw = await readFile(intentPath, "utf8")
    parseIntent(intentRaw, intentPath)
  }

  if (missing.length > 0) {
    const changedList = changedSkills.map((s) => `- ${s}`).join("\n")
    const missingList = missing.map((p) => `- ${p}`).join("\n")
    throw new Error(
      [
        "Skill changes require per-skill version intent files.",
        "Changed skills:",
        changedList,
        "Missing intent files:",
        missingList,
        "Add each required file as JSON with bump set to major, minor, or patch.",
      ].join("\n"),
    )
  }

  console.log(`Version intent check passed for ${changedSkills.length} changed skill(s).`)
}

await main()
