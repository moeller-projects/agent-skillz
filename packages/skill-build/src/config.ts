import { dirname, join, resolve } from "node:path"
import { fileURLToPath } from "node:url"

const currentDir = dirname(fileURLToPath(import.meta.url))

export const repoRoot = resolve(currentDir, "../../..")
export const skillsDir = join(repoRoot, "skills")
export const artifactsDir = join(repoRoot, "artifacts")
