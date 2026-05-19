import { execFileSync } from "node:child_process"
import { constants as fsConstants } from "node:fs"
import { access } from "node:fs/promises"

function runGit(args: string[]): string {
  return execFileSync("git", ["--no-pager", ...args], { encoding: "utf8" }).trim()
}

export const VALID_BUMPS = new Set(["major", "minor", "patch"] as const)

export async function fileExists(path: string): Promise<boolean> {
  try {
    await access(path, fsConstants.F_OK)
    return true
  } catch {
    return false
  }
}

export interface ParsedIntent {
  bump: "major" | "minor" | "patch"
  summary?: string
}

export function parseIntent(raw: string, intentPath: string): ParsedIntent {
  let parsed: unknown
  try {
    parsed = JSON.parse(raw)
  } catch {
    throw new Error(`Intent file ${intentPath} is not valid JSON`)
  }

  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error(`Intent file ${intentPath} must contain a JSON object`)
  }

  const bump = (parsed as { bump?: unknown }).bump
  if (typeof bump !== "string" || !VALID_BUMPS.has(bump as "major" | "minor" | "patch")) {
    throw new Error(`Intent file ${intentPath} must define bump as one of: major, minor, patch`)
  }

  const summary = (parsed as { summary?: unknown }).summary
  if (summary !== undefined && (typeof summary !== "string" || summary.trim().length === 0)) {
    throw new Error(`Intent file ${intentPath} summary must be a non-empty string when provided`)
  }

  return {
    bump: bump as ParsedIntent["bump"],
    summary: summary !== undefined ? summary.trim() : undefined,
  }
}

export function listChangedFiles(baseSha: string, headSha: string): string[] {
  if (!baseSha || !headSha) {
    throw new Error("Both baseSha and headSha are required")
  }

  const isZeroSha = /^0+$/.test(baseSha)

  if (isZeroSha) {
    const output = runGit(["ls-tree", "-r", "--name-only", headSha])
    return output ? output.split("\n").filter(Boolean) : []
  }

  const output = runGit(["diff", "--name-only", baseSha, headSha])
  return output ? output.split("\n").filter(Boolean) : []
}

export function collectChangedSkills(files: string[]): string[] {
  const skills = new Set<string>()

  for (const file of files) {
    const match = /^skills\/([^/]+)\//.exec(file)
    if (!match) {
      continue
    }

    const skill = match[1]
    if (skill.startsWith(".") || skill.startsWith("_")) {
      continue
    }

    skills.add(skill)
  }

  return [...skills].sort((a, b) => a.localeCompare(b))
}

export function bumpVersion(version: string, bumpType: ParsedIntent["bump"]): string {
  const match = /^(\d+)\.(\d+)\.(\d+)$/.exec(version)
  if (!match) {
    throw new Error(`Invalid semver version: ${version}`)
  }

  const major = Number.parseInt(match[1], 10)
  const minor = Number.parseInt(match[2], 10)
  const patch = Number.parseInt(match[3], 10)

  if (bumpType === "major") {
    return `${major + 1}.0.0`
  }
  if (bumpType === "minor") {
    return `${major}.${minor + 1}.0`
  }
  return `${major}.${minor}.${patch + 1}`
}
