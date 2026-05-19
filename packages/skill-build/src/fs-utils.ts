import { cp, mkdir, readdir, readFile, rm, writeFile } from "node:fs/promises"
import type { Dirent } from "node:fs"
import { dirname, join } from "node:path"

function isSkillDirectory(entry: Dirent): boolean {
  return entry.isDirectory() && !entry.name.startsWith("_") && !entry.name.startsWith(".")
}

export async function ensureDir(path: string): Promise<void> {
  await mkdir(path, { recursive: true })
}

export async function emptyDir(path: string): Promise<void> {
  await rm(path, { recursive: true, force: true })
  await ensureDir(path)
}

export async function readJsonFile<T>(path: string): Promise<T> {
  return JSON.parse(await readFile(path, "utf8")) as T
}

export async function writeJsonFile(path: string, value: unknown): Promise<void> {
  await ensureDir(dirname(path))
  await writeFile(path, `${JSON.stringify(value, null, 2)}\n`, "utf8")
}

export async function getSkillDirectories(skillsDir: string): Promise<string[]> {
  const entries = await readdir(skillsDir, { withFileTypes: true })

  return entries
    .filter(isSkillDirectory)
    .map((entry) => join(skillsDir, entry.name))
    .sort((left, right) => left.localeCompare(right))
}

export async function copyDir(source: string, target: string): Promise<void> {
  await ensureDir(dirname(target))
  await cp(source, target, { recursive: true })
}
