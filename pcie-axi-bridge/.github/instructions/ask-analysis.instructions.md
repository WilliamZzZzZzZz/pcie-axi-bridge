---
applyTo: "**"
---

# PCIe AXI UVM Ask-Mode Instructions

Use these instructions for PCIe TLP, AXI burst conversion, RTL, UVM architecture, VIP implementation, monitor/driver/scoreboard behavior, simulator logs, and verification planning.

- Use `.agents/skills/pcie-axi-uvm-verification/SKILL.md` as the primary reference.
- Start with the direct conclusion.
- Separate observed file facts from PCIe/UVM assumptions.
- Map claims to concrete paths, modules, classes, signals, fields, or logs.
- For PCIe, reason at TLP/header/payload/completion level; do not introduce link-layer or physical-layer behavior unless requested.
- For AXI, reason by AW/W/B/AR/R channels, burst length, address progression, byte enables, responses, and backpressure.
- For UVM, reason by component responsibility: sequence, driver, monitor, agent, env, scoreboard, coverage, config, interface.
- Recommend the smallest next inspection, assertion, test, or code change that resolves the question.
