# Commercial UVM/VIP Rules

Use these rules whenever answering architecture questions or writing SystemVerilog/UVM code for this project. The goal is not only to make tests run; the goal is a reusable, reviewable, industry-standard verification environment.

Reference basis:

- Accellera UVM / IEEE 1800.2: standard UVM component model, TLM flow, agent/driver/sequencer/monitor architecture
- lowRISC DV coding style: one class per file, one agent per DUT interface, clean agent/driver/monitor ownership
- OpenTitan DV methodology: DV plan, reusable UVCs, reference models, scoreboards, coverage, assertions, regressions
- Siemens UVMF public material: protocol agents, environments, predictors, scoreboards, sequence categories
- Cadence and Synopsys public VIP material: UVM-native reusable VIP with configuration, sequences, coverage, and example tests

## Architecture Priority

Default to the standard UVM hierarchy:

```text
test
  env
    protocol agents
    virtual sequencer
    scoreboard / predictor / reference model
    coverage
  sequences / virtual sequences
tb top
  interfaces
  DUT
```

Do not accept an architecture only because it can pass one directed smoke test. If a shortcut reduces protocol VIP reuse, hides ownership, or mixes stimulus with checking, reject it or clearly label it as a temporary debug-only deviation.

Before adding a component, classify it as one of:

```text
protocol VIP component
environment component
test component
sequence component
reference model / scoreboard component
compile/build collateral
```

If one file mixes categories, propose a cleaner split.

## Protocol VIP Ownership

A protocol VIP owns protocol-level stimulus and observation. It may contain:

```text
types/constants
transaction / sequence item
configuration object
sequencer
driver or responder
monitor
agent
protocol-level coverage/checkers
protocol sequences
```

A protocol VIP must not own DUT-specific end-to-end prediction. For this project:

```text
pcie_tlp_vip
  -> PCIe TLP request/completion protocol behavior only

axi_vip
  -> AXI protocol behavior, responder, monitor, and AXI slave memory only

pcie_axi_env
  -> bridge predictor, scoreboard, reference memory, pending-read table, virtual sequencer, env coverage
```

Do not put PCIe-to-AXI conversion checking inside `pcie_tlp_vip` or `axi_vip`.

## Agent Rules

Use one protocol agent per DUT protocol interface or protocol stream group. An interface agent should be limited to:

```text
configuration object
sequencer when active
driver/responder when active
monitor
optional protocol coverage/checker
```

Agents must be configurable as `UVM_ACTIVE` or `UVM_PASSIVE` where practical. Active agents instantiate and connect sequencer/driver; passive agents instantiate monitors only.

Do not put a scoreboard, bridge reference model, reference memory, or DUT-specific predictor inside a protocol agent.

## Driver Rules

A driver translates sequence items into signal-level bus activity. It should have:

```text
seq_item_port
virtual interface handle
configuration handle
```

For this project, `pcie_req_driver` drives request-side TLP stimulus and completion ready only:

```text
drive: rx_req_tlp_hdr/data/valid/sop/eop
drive: tx_cpl_tlp_ready
do not drive: tx_cpl_tlp_hdr/data/strb/valid/sop/eop
```

Do not add analysis ports to drivers. Do not call scoreboards from drivers. Do not maintain reference memory in drivers. Do not check DUT results in drivers. Local protocol sanity checks are acceptable, but end-to-end checking belongs in the scoreboard/checker layer.

## Monitor Rules

A monitor is passive. It samples an interface, reconstructs fresh transaction objects from bus activity, and publishes them through analysis ports.

Monitors must not drive DUT signals. Monitors must not reuse sequence item handles as actual observed transactions. They may perform local protocol checks, but end-to-end DUT correctness belongs in the environment scoreboard.

For this DUT, keep request and completion observation semantically separate:

```text
pcie_req_monitor -> accepted rx_req_tlp_* request TLPs
pcie_cpl_monitor -> accepted tx_cpl_tlp_* completion TLPs
```

One physical monitor class with two tasks is acceptable only if it still exposes separate request and completion analysis ports and preserves the same ownership boundaries.

## Sequence Rules

Sequences generate stimulus. They must not directly check DUT outputs, update scoreboard memory, or rely on hierarchical DUT access.

Use sequence constraints and configuration knobs instead of hard-coded constants. Directed sequences are acceptable for smoke tests; constrained random and stress sequences should be added only after the basic reference model is reliable.

## Scoreboard and Predictor Rules

The scoreboard/reference model receives observed transactions from monitors through TLM analysis ports or analysis FIFOs. It should not receive expected data by direct calls from sequences or drivers unless the deviation is explicitly documented as a temporary debug hook.

For this project, `pcie_axi_scoreboard` is the correct owner of:

```text
MWr -> expected AXI write and no PCIe completion
MRd -> expected AXI read and expected CplD
reference memory
pending read table keyed by requester_id/tag
requester_id/tag/tc/attr preservation checks
byte_count/lower_address/payload checks
```

Use `check_phase` to report leftover queues, unmatched completions, pending reads, or unconsumed expected transactions.

## Memory Model Rules

Memory models belong to components that respond to address-space accesses or to the environment reference model.

Requester VIPs normally do not contain target memory. Completer/responder/target VIPs may contain memory because they must return data or store writes.

For this DUT:

```text
PCIe requester VIP -> no target memory
AXI slave VIP      -> real responder memory for DUT AXI reads/writes
scoreboard         -> reference memory and expected-data model
```

## Package and Directory Rules

Prefer protocol-separated packages:

```text
axi_pkg.sv
pcie_tlp_pkg.sv
pcie_axi_pkg.sv
```

Interfaces are compiled outside packages:

```text
axi_if.sv
pcie_tlp_if.sv
```

Target directory shape for new PCIe VIP code:

```text
uvm/vip/pcie_tlp/
  pcie_tlp_if.sv
  pcie_tlp_pkg.sv
  pcie_types.sv
  pcie_tlp_transaction.sv
  pcie_tlp_configuration.sv
  pcie_tlp_sequencer.sv
  pcie_req_driver.sv
  pcie_req_monitor.sv
  pcie_cpl_monitor.sv
  pcie_tlp_agent.sv
  seq_lib/
```

Do not include interface files inside packages. Do not collapse unrelated protocol VIPs into one monolithic package.

## PCIe TLP Scope

The current PCIe VIP is `pcie_tlp_vip`, not a full PCIe VIP. First-stage scope is:

```text
MRd
MWr
Cpl
CplD
TD=0 / no Digest/ECRC
generic TLP stream interface of pcie_axi_master
```

Do not add LTSSM, PHY lanes, DLLP, replay, credit, enumeration, config space, MSI/MSI-X, or DMA subsystem behavior unless the user explicitly changes the DUT scope.

## Non-Standard Pattern Rejection List

Reject or explicitly challenge these patterns:

```text
driver calls scoreboard
driver has uvm_analysis_port
monitor drives protocol signals
sequence/test checks DUT output directly
scoreboard receives expected data directly from driver/sequence
requester VIP owns target memory
protocol VIP owns DUT-specific bridge reference model
one transaction class collapses unrelated PCIe and AXI protocols
one package contains all unrelated protocol VIP and env classes
direct hierarchical DUT peeking for normal checking
hard-coded protocol constants instead of type/config definitions
```

Temporary debug deviations must be labeled as temporary and removed or isolated before claiming the environment is standard.
