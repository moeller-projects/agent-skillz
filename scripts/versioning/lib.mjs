import { execFileSync } from "node:child_process"

function runGit(args) {
  return execFileSync("git", ["--no-pager", ...args], { encoding: "utf8" }).trim()
}

export function listChangedFiles(baseSha, headSha) {
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

export function collectChangedSkills(files) {
  const skills = new Set()

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

export function bumpVersion(version, bumpType) {
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
  if (bumpType === "patch") {
    return `${major}.${minor}.${patch + 1}`
  }

  throw new Error(`Unsupported bump type: ${bumpType}`)
}
