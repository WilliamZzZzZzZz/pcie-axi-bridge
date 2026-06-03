# PCIe AXI Bridge UVM Agent Rules

## Authoritative Skill

Use the embedded project skill as the primary instruction source:

```text
.agents/skills/pcie-axi-uvm-verification/SKILL.md
```

This project is no longer an AXI crossbar verification project. Any old AXI crossbar, generic DV, or `dv-ask-engineering-analysis` guidance is not authoritative for this repository.

## Project Role

Treat this repository as a SystemVerilog/UVM verification project for the `pcie_axi_master` DUT from `alexforencich/verilog-pcie`.

The expected model is:

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

The DUT is a transaction-layer PCIe TLP-to-AXI bridge. It is not a full PCIe controller, PHY, LTSSM, DLLP/replay/credit engine, config-space model, or commercial PCIe VIP replacement.

## Required Startup

Before code changes, inspect the real files and run the project check when practical:

```bash
python3 .agents/skills/pcie-axi-uvm-verification/scripts/check_pcie_axi_uvm_project.py .
```

Then read only the relevant reference:

- `.agents/skills/pcie-axi-uvm-verification/references/project-map.md`
- `.agents/skills/pcie-axi-uvm-verification/references/pcie-dut-model.md`
- `.agents/skills/pcie-axi-uvm-verification/references/uvm-implementation-rules.md`
- `.agents/skills/pcie-axi-uvm-verification/references/agent-discipline.md`

## Work Rules

- Distinguish facts observed in files from PCIe/UVM inferences.
- Preserve the migrated AXI VIP architecture unless the user explicitly requests redesign.
- Keep PCIe VIP transaction-layer only for the first stage: `MRd`, `MWr`, `Cpl`, `CplD`, optional unsupported-request checks.
- Keep Digest/ECRC disabled in first-stage VIP: `TD=0`.
- Treat `TC`, `Attr`, `requester_id`, `completer_id`, and `tag` as real TLP header fields.
- Reuse the existing AXI VIP for the downstream AXI slave and memory model where possible.
- Make small reviewable diffs and run available compile/smoke checks when practical.

## Validation Priority

Validate in this order:

1. Static project check script
2. SystemVerilog compile/package include order
3. DUT/interface port connection sanity
4. Smoke test for one MWr and one MRd
5. Scoreboard checks for MWr-to-AXI write and MRd-to-AXI read-to-CplD

If simulator or license setup blocks validation, state that directly.
