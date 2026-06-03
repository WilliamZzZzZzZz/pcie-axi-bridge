# Agent Discipline

This reference adapts the community `multica-ai/andrej-karpathy-skills` / former `forrestchang/andrej-karpathy-skills` guidelines to this PCIe AXI UVM verification project.

Source context:

- GitHub repo: https://github.com/multica-ai/andrej-karpathy-skills
- Skill file: https://github.com/multica-ai/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md
- Background claim from the repo: the rules are derived from Andrej Karpathy's public observations on LLM coding-agent failure modes

Treat that repo as a community-derived behavior guide, not an official Karpathy project.

## 1. Think Before Coding

For PCIe/UVM work, do not silently choose an interpretation when the task is ambiguous.

Before editing, state or infer explicitly:

- whether the user is asking for analysis, prompt generation, or code changes
- whether the target is `pcie_types.sv`, `pcie_tlp_transaction.sv`, interface wiring, agent code, scoreboard code, tests, or Makefile migration
- whether the expected PCIe behavior is from the spec, from `pcie_axi_master` source, or from a verification-model decision
- what is assumed about `TLP_DATA_WIDTH`, `TLP_HDR_WIDTH`, `TLP_SEG_COUNT`, `AXI_DATA_WIDTH`, and `TLP_FORCE_64_BIT_ADDR`

Ask a concise question only when the missing answer changes the architecture or could cause broad rework. For small implementation choices, make the conservative choice and document it.

## 2. Simplicity First

Build only the verification layer needed for the current DUT stage.

Prefer:

```text
pcie_tlp_transaction
pcie_tlp_if
pcie_req_driver
pcie_req_monitor
pcie_cpl_monitor
pcie_tlp_agent
pcie_axi_scoreboard
```

Avoid first-stage overreach:

```text
full PCIe PHY model
LTSSM
DLLP/replay/credits
configuration-space enumeration
commercial-grade PCIe VIP completeness
multi-BAR endpoint subsystem
DMA subsystem
MSI/MSI-X
```

Add those only after the basic `MRd/MWr -> AXI -> CplD` bridge project works.

## 3. Surgical Changes

Make each change traceable to the current request.

When editing:

- do not reformat unrelated SystemVerilog files
- do not rename broad AXI VIP classes just because PCIe files are being added
- do not delete old crossbar files unless the user asks for cleanup
- do not weaken scoreboard checks to make a test pass
- remove only unused code introduced by the current edit
- mention unrelated dead code or stale files separately

For this project, a good diff usually touches one layer:

```text
types/transaction only
interface only
driver/monitor only
env/package/testbench only
scoreboard only
Makefile/compile list only
```

If a task requires multiple layers, explain the dependency order and validate after each layer when possible.

## 4. Goal-Driven Execution

Convert every implementation request into verifiable outcomes.

Examples:

```text
"fix pcie_tlp_transaction"
-> pack_header/unpack_header compile
-> MWr header fields match DUT mapping
-> MRd header fields match DUT mapping
-> CplD header fields parse correctly

"add pcie_tlp_if"
-> all DUT-side ports are represented
-> host and monitor clocking blocks exist
-> valid/ready stability assertions compile

"add request driver"
-> drives one legal MWr
-> drives one legal MRd
-> holds stable under backpressure
-> never drives tx_cpl_tlp_* except ready

"add scoreboard"
-> MWr predicts AXI write and no PCIe completion
-> MRd predicts AXI read and CplD
-> requester_id/tag/tc/attr are preserved in completion
```

When simulator execution is unavailable, use source inspection, static checks, and compile-order review; state that dynamic simulation was not run.

## Project-Specific Success Signals

The discipline is working if:

- agents ask fewer unnecessary architecture questions after reading the skill
- generated PCIe VIP code uses DUT-compatible header mapping
- changes remain small enough to review manually
- the AXI VIP is reused instead of rewritten
- failures are reported as concrete compile, protocol, or scoreboard mismatches
- "done" always includes what was checked and what remains unchecked

