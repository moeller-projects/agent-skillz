# Workflow

## Default Flow

1. Capture the goal, scope, constraints, and stakeholders.
2. Convert the request into explicit requirements and acceptance criteria.
3. Audit for ambiguity, missing decisions, and policy gates.
4. Document open questions and any required version or diff notes.

## ADO Handoff Flow

1. Validate the handoff JSON — confirm it is well-formed and `producer` is `ado-gateway`.
2. Extract `work_item.title`, `work_item.description`, and `work_item.acceptance_criteria` as the primary inputs.
3. Extract `pr_comments[].content` as review context only — list it under Review Context in the spec, never under requirements.
4. Proceed with the Default Flow from step 2 onward using the extracted fields.
5. If `work_item.acceptance_criteria` is empty or missing, skip AC generation and add an open question: "Acceptance criteria were missing from the handoff — confirm before implementation starts."

## Fast Path

1. Write the goal, scope, and top requirements.
2. Add minimum acceptance criteria and unresolved questions.

## Escalation

Use more detail only when correctness, safety, or ambiguity requires it.
