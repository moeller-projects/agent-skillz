export interface SkillMetadata {
  name: string
  title: string
  version: string
  summary: string
}

export interface ValidatedSkill {
  dir: string
  metadata: SkillMetadata
  frontmatter: Record<string, string>
  readmeVersion: string
}
