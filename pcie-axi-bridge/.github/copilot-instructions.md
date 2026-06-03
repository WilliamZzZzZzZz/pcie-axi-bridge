# Copilot Instructions

Use `AGENTS.md` and the embedded project skill as the authoritative guidance:

```text
.agents/skills/pcie-axi-uvm-verification/SKILL.md
```

This repository is a PCIe TLP-to-AXI bridge UVM verification project centered on `pcie_axi_master`, not the old AXI crossbar project.

Default to digital verification reasoning. Inspect relevant files before answering code-dependent questions. Preserve the existing UVM migration structure unless the user explicitly asks for a redesign.

For PCIe-side work, keep the first-stage VIP at transaction-layer scope: `MRd`, `MWr`, `Cpl`, `CplD`, `TD=0`, and no LTSSM/DLLP/replay/config-space modeling unless explicitly requested.

For AXI-side work, reuse the existing AXI VIP and memory model where possible. Treat the downstream interface as an AXI slave model receiving the DUT's AXI master bursts.

When editing, make the smallest reviewable change and run the available static check, compile, or smoke path when practical.
