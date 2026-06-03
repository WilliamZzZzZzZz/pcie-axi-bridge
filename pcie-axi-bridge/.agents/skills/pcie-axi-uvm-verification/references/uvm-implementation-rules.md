# UVM Implementation Rules

## VIP Ownership

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

## Recommended Agent Structure

```text
pcie_tlp_agent
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

## Driver Rules

For `pcie_req_driver`:

- Drive `rx_req_tlp_hdr`, `rx_req_tlp_data`, `rx_req_tlp_valid`, `rx_req_tlp_sop`, `rx_req_tlp_eop`.
- Wait for `rx_req_tlp_ready`.
- Hold header/data/control stable while valid is asserted and ready is low.
- Drive MWr payload beats and valid strobe consistently with `length`.
- For MRd, drive no payload data.
- Do not drive `tx_cpl_tlp_*`; only drive `tx_cpl_tlp_ready`.

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

- OpenAI skills catalog: https://github.com/openai/skills
- Agent Skills format: https://github.com/agentskills/agentskills
- Accellera UVM standards/downloads: https://www.verilog.org/downloads/standards/uvm
- verilog-pcie original repository: https://github.com/alexforencich/verilog-pcie

