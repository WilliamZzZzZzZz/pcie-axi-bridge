# Project Map

## Expected Local Paths

- Project root: `/Users/williamzzz/Desktop/pcie/pcie-axi-bridge`
- PCIe 4.0 reference PDF: `/Users/williamzzz/Desktop/pcie/PCI_Express_Base_4.0.pdf`
- Old architecture source: `WilliamZzZzZzZz/axi-crossbar`

Always verify paths with `ls`, `find`, or `rg --files` before relying on them.

## Current DUT Files

The expected DUT set is:

```text
dut/pcie_axi_master.v
dut/pcie_axi_master_rd.v
dut/pcie_axi_master_wr.v
dut/pcie_tlp_demux.v
dut/pcie_tlp_fifo.v
dut/pcie_tlp_fifo_raw.v
dut/pulse_merge.v
```

`pcie_tlp_fifo.v` and `pcie_tlp_fifo_raw.v` may be optional for the current `FIFO_ENABLE=0` path, but keep them in the DUT folder to support future FIFO-enabled testing.

## Existing UVM Heritage

The project is migrated from an AXI crossbar UVM project. Expect these old structures:

```text
uvm/vip/axi_types.sv
uvm/vip/axi_if.sv
uvm/vip/axi_transaction.sv
uvm/vip/axi_pkg.sv
uvm/vip/axi_slave_agent.sv
uvm/vip/axi_slave_mem.sv
uvm/env/axicb_pkg.sv
uvm/env/axi_crossbar_env.sv
uvm/testbench/axi_crossbar_tb.sv
uvm/sim/Makefile
```

Do not assume old `axicb_*` files are already correct for PCIe. Treat them as migration templates.

## Current PCIe VIP Seed Files

Expected early PCIe files:

```text
uvm/vip/pcie_types.sv
uvm/vip/pcie_tlp_transaction.sv
uvm/vip/pcie_tlp_if.sv
```

## Package Direction

The clean target is usually:

```text
uvm/vip/axi_pkg.sv          // existing AXI VIP
uvm/vip/pcie_tlp_pkg.sv     // new PCIe TLP VIP
uvm/env/pcie_axi_pkg.sv     // new project env/test package
uvm/testbench/pcie_axi_master_tb.sv
```

Avoid mixing all PCIe classes into `axi_pkg.sv`. Keep protocol VIPs separate.
