---
agent: "ask"
description: "Review the architecture of the PCIe AXI bridge UVM project without rewriting it."
---

Review the current PCIe AXI bridge UVM project architecture as a DV architect.

Scope:
${input:scope:Describe the subsystem, UVM env, RTL block, or files to inspect}

Please:

1. Inspect relevant files first.
2. Summarize the DUT and testbench architecture component-by-component.
3. Identify PCIe request flow, AXI burst flow, completion flow, UVM phase flow, and scoreboard flow.
4. Explain each component's responsibility and ownership boundary.
5. Identify unclear ownership, duplicated responsibility, fragile protocol assumptions, missing TLP fields, monitor blind spots, and scoreboard gaps.
6. Recommend next steps without rewriting the architecture unless explicitly requested.

Use file paths and symbols when mapping claims to code.
