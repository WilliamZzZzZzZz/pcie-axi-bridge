---
agent: "ask"
description: "Analyze a PCIe TLP, pcie_axi_master, or PCIe-to-AXI bridge verification question."
---

Analyze this PCIe AXI bridge question as a digital verification reviewer.

Scenario, code, waveform, or file references:
${input:scenario:Describe the PCIe TLP, DUT behavior, UVM component, or referenced files/signals}

Please answer using this structure:

1. **Direct Conclusion**
   - State the answer first.
   - Separate observed facts from assumptions.

2. **Relevant PCIe/TLP Rule**
   - Identify the relevant TLP type, Fmt/Type meaning, header fields, payload rule, completion behavior, or ordering rule.
   - Keep the scope at transaction layer unless the question explicitly asks for link/physical layer behavior.

3. **DUT Mapping**
   - Map the rule to `pcie_axi_master`, `rx_req_tlp_*`, `tx_cpl_tlp_*`, and `m_axi_*`.
   - Identify which side is TB requester, DUT completer-side bridge, and TB AXI slave/memory.

4. **Verification Impact**
   - State what the driver, monitor, scoreboard, sequence, or coverage should check.
   - Mention likely corner cases and constraints.

5. **Minimal Next Step**
   - Give the smallest file inspection, test, assertion, or implementation step.
