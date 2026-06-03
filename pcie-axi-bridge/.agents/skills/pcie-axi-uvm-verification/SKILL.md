---
name: pcie-axi-uvm-verification
description: Develop, review, debug, or migrate the WilliamZzZzZzZz PCIe AXI bridge UVM verification project. Use when working on /Users/williamzzz/Desktop/pcie/pcie-axi-bridge, pcie_axi_master, PCIe TLP VIP, AXI VIP reuse, SystemVerilog UVM agents/drivers/monitors/scoreboards/sequences, PCIe TLP header fields, AXI burst conversion, VCS/Makefile simulation, or migration from the older axi-crossbar UVM project.
---

# PCIe AXI UVM Verification

## Start Here

Treat this as a SystemVerilog/UVM digital verification project, not a generic software project. Preserve the user's old AXI crossbar UVM architecture unless the user explicitly asks for a redesign.

Before editing, inspect the real files. Prefer:

```bash
python3 ~/.codex/skills/pcie-axi-uvm-verification/scripts/check_pcie_axi_uvm_project.py /Users/williamzzz/Desktop/pcie/pcie-axi-bridge
```

Then read only the reference needed for the task:

- `references/project-map.md`: project paths, existing architecture, migration status
- `references/pcie-dut-model.md`: DUT model, PCIe TLP subset, header mapping, scoreboard expectations
- `references/uvm-implementation-rules.md`: UVM coding rules, VIP ownership, file/package migration workflow
- `references/agent-discipline.md`: Karpathy-inspired agent discipline adapted to this PCIe/UVM project

## Non-Negotiable Model

Use this model unless source inspection proves it changed:

```text
TB PCIe requester VIP
  -> rx_req_tlp_* request TLP stream
  -> DUT pcie_axi_master as PCIe completer-side bridge
  -> m_axi_* AXI full master interface
  -> TB AXI slave VIP + memory model

Read return:
TB AXI slave R channel
  -> DUT
  -> tx_cpl_tlp_* completion TLP stream
  -> TB PCIe completion monitor/sink
```

The DUT is a generic PCIe TLP-to-AXI bridge. It is not a full PCIe controller, PHY, LTSSM, DLLP/replay/credit engine, config-space model, or commercial PCIe VIP replacement.

## Work Rules

- Distinguish facts observed in files from PCIe/UVM inferences.
- Apply the Karpathy-inspired discipline in `references/agent-discipline.md`: surface assumptions, prefer simple code, keep diffs surgical, and define verification criteria before claiming completion.
- Do not add full PCIe physical link behavior unless the user asks for a different DUT.
- Keep PCIe side transaction-layer only: `MRd`, `MWr`, `Cpl`, `CplD`, optional unsupported-request checks.
- Keep Digest/ECRC disabled in first-stage VIP: `TD=0`.
- Keep `TC`, `Attr`, `requester_id`, and `tag` as real header fields; do not collapse them into informal metadata.
- Reuse the existing AXI VIP for the downstream AXI slave/memory side when possible.
- When changing code, make small reviewable diffs and run the available compile/smoke path if practical.

## Validation Priority

For implementation tasks, validate in this order:

1. Static project check script above
2. SystemVerilog compile/package include order
3. DUT/interface port connection sanity
4. Smoke test for one MWr and one MRd
5. Scoreboard checks for MWr-to-AXI write and MRd-to-AXI read-to-CplD

Report any simulator/license blocker directly. Do not invent passing validation.
