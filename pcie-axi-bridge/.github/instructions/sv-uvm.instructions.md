---
applyTo: "**/*.sv,**/*.svh,**/*.v,**/*.vh,**/*.sva,**/*.f,**/*.flist"
---

# SystemVerilog and UVM Instructions

- Follow local naming, indentation, macro, package, and filelist conventions.
- Preserve the PCIe AXI bridge UVM architecture unless a redesign is explicitly requested.
- Keep PCIe requester/completer naming precise; avoid AXI master/slave language on the PCIe side.
- Keep first-stage PCIe VIP transaction-layer only: `MRd`, `MWr`, `Cpl`, `CplD`, `TD=0`.
- Keep `TC`, `Attr`, `requester_id`, `completer_id`, and `tag` explicit in TLP transaction/header handling.
- In RTL/interface code, check reset behavior, width/sign handling, default assignments, latch risks, and handshake timing.
- In UVM, keep responsibilities separate: sequences generate intent, drivers drive pins, monitors observe pins, scoreboards check independently, coverage samples verification goals.
- Use UVM phases correctly: build/connect for structure, run for time-consuming behavior, check/report for summaries.
- Check factory registration, config_db paths, virtual interface propagation, TLM analysis connections, objections, and sequence-driver item flow.
- Do not weaken scoreboard comparisons, monitor sampling, or constraints just to make a test pass.
