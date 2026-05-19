import { readFile } from "node:fs/promises"
import { join } from "node:path"
import { collectChangedSkills, fileExists, listChangedFiles, parseIntent } from "./lib.mjs"

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
    if (!(await fileExists(intentPath))) {
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
