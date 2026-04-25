import { join } from "node:path"

export const repoRoot = process.cwd().split("packages")[0]
export const skillsDir = join(repoRoot, "skills")
export const distDir = join(repoRoot, "dist")
export const artifactsDir = join(repoRoot, "artifacts")
