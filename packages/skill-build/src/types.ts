export interface SkillActivation {
  use_when?: string[]
  avoid_when?: string[]
}

export interface SkillMetadata {
  name: string
  title: string
  version: string
  summary: string
  type: string
  activation?: SkillActivation
  compatibility?: string[]
  risk_level?: string
  requires_network?: boolean
  maintainer?: string
}

export interface ValidatedSkill {
  dir: string
  metadata: SkillMetadata
  frontmatter: Record<string, string>
}
