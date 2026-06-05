# UVM Implementation Rules

## VIP Ownership

Use two protocol VIPs plus one DUT-specific environment. Keep protocol reuse separate from bridge checking:

```text
pcie_tlp_vip     // PCIe TLP requester/completion stream behavior only
axi_vip          // AXI protocol behavior and AXI slave memory/responder
pcie_axi_env     // DUT-specific predictor, scoreboard, reference memory, coverage
```

Use two protocol interfaces:

```text
uvm/vip/pcie_tlp_if.sv  // upstream PCIe TLP request/completion stream
uvm/vip/axi_if.sv       // downstream AXI full interface, reused from old project
```

Use two core transaction classes:

```text
pcie_tlp_transaction    // MRd, MWr, Cpl, CplD
axi_transaction         // AXI read/write burst, reused where possible
```

Do not model PCIe TLPs as raw `bit [127:0] hdr` only. Keep raw header plus decoded fields and provide `pack_header()` / `unpack_header()` helpers.

Do not put bridge prediction, AXI expected conversion logic, or PCIe-to-AXI reference memory inside either protocol VIP.

## Recommended Agent Structure

```text
pcie_tlp_agent
  pcie_tlp_configuration
  pcie_req_driver          // active, drives rx_req_tlp_*
  pcie_req_monitor         // passive, observes accepted requests
  pcie_cpl_monitor         // passive, observes tx_cpl_tlp_*
  pcie_tlp_sequencer

axi_slave_agent            // reused or adapted from AXI project
  axi_slave_responder
  axi_slave_mem
  axi_monitor

pcie_axi_scoreboard
pcie_axi_coverage
pcie_axi_virtual_sequencer
```

The PCIe side is not master/slave in AXI terms. Name active TB behavior as requester and DUT behavior as completer.

Agents must be configurable as active or passive. Active agents instantiate and connect sequencer/driver; passive agents instantiate monitors only. Do not put scoreboards or reference models inside protocol agents.

## Driver Rules

For `pcie_req_driver`:

- Drive `rx_req_tlp_hdr`, `rx_req_tlp_data`, `rx_req_tlp_valid`, `rx_req_tlp_sop`, `rx_req_tlp_eop`.
- Wait for `rx_req_tlp_ready`.
- Hold header/data/control stable while valid is asserted and ready is low.
- Drive MWr payload beats and valid strobe consistently with `length`.
- For MRd, drive no payload data.
- Do not drive `tx_cpl_tlp_*`; only drive `tx_cpl_tlp_ready`.
- Do not declare analysis ports.
- Do not call the scoreboard, update reference memory, or perform end-to-end result checking.

## Monitor Rules

For accepted request TLPs, sample when:

```text
|rx_req_tlp_valid && rx_req_tlp_ready
```

For accepted completion TLPs, sample when:

```text
|tx_cpl_tlp_valid && tx_cpl_tlp_ready
```

Monitors must reconstruct transactions independently from bus activity. Do not reuse sequence item handles directly for scoreboard actuals.

Monitors are passive. They must not drive protocol signals. If a single class monitors both request and completion streams, it must still publish separate request and completion analysis ports.

## Scoreboard and Reference Model Rules

The bridge scoreboard belongs in `pcie_axi_env`, not in `pcie_tlp_vip` or `axi_vip`.

For this DUT, the scoreboard owns:

```text
reference memory
pending PCIe read table keyed by requester_id/tag
MWr -> expected AXI write and no PCIe completion
MRd -> expected AXI read and expected CplD
CplD header/data checks
```

Scoreboards should receive observed transactions from monitors through analysis ports or analysis FIFOs. Do not pass expected data directly from sequence or driver into the scoreboard for normal checking.

## Memory Model Rules

Requester VIPs normally do not contain target memory. Completer/responder/target VIPs may contain memory because they must return read data or store writes.

For this project:

```text
PCIe TLP requester VIP -> no memory model
AXI slave VIP          -> real responder memory
pcie_axi_scoreboard    -> reference memory
```

## Transaction Rules

Prefer these field names to match DUT/source discussions:

```text
tlp_kind
tlp_fmt
tlp_type
tc
attr
address_type
lightweight_notification
tph_present
tlp_digest_present
poisoned_tlp
tlp_length_dw
requester_id
tag
first_dw_byte_enable
last_dw_byte_enable
address
processing_hint
completer_id
completion_status
byte_count_modified
byte_count
lower_address
payload_data
payload_strb
digest_ecrc
```

Avoid duplicate enums. If `pcie_types.sv` defines `pcie_tlp_kind_enum`, use that rather than defining a second incompatible `pcie_tlp_kind_e`.

## Package and Include Order

Use separate packages:

```text
axi_pkg.sv
pcie_tlp_pkg.sv
pcie_axi_pkg.sv
```

Target PCIe VIP directory for new code:

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

Expected order:

```text
pcie_types.sv
pcie_tlp_transaction.sv
pcie_tlp_sequencer.sv
pcie_req_driver.sv
pcie_req_monitor.sv
pcie_cpl_monitor.sv
pcie_tlp_agent.sv
```

Interfaces are usually compiled outside packages:

```text
uvm/vip/axi_if.sv
uvm/vip/pcie_tlp_if.sv
```

Do not include interface files inside package files.

## Testbench Migration

Replace old crossbar topology with a single DUT topology:

```text
pcie_axi_master_tb
  clk/rst
  pcie_tlp_if
  axi_if
  pcie_axi_master dut
  config_db vif sets:
    uvm_test_top.env.pcie_agent
    uvm_test_top.env.axi_slv_agent
```

Do not leave old 2x2 crossbar assumptions such as `mst_agent00`, `mst_agent01`, `slv_agent00`, `slv_agent01` unless the file still targets the old crossbar tests.

## External Reference Basis

Use these as background only; always map conclusions back to local files:

- Accellera UVM standards/downloads: https://www.accellera.org/downloads/standards
- Accellera UVM 1.2 User Guide: https://www.accellera.org/images/downloads/standards/uvm/uvm_users_guide_1.2.pdf
- lowRISC DV coding style: https://github.com/lowRISC/style-guides/blob/master/DVCodingStyle.md
- OpenTitan DV methodology: https://opentitan.org/book/doc/contributing/dv/methodology/index.html
- Siemens Verification Academy UVMF: https://verificationacademy.com/topics/uvm-universal-verification-methodology/uvmf/uvm-framework/
- verilog-pcie original repository: https://github.com/alexforencich/verilog-pcie
