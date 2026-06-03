---
agent: "ask"
description: "Review selected RTL, SystemVerilog, UVM, PCIe TLP, AXI bridge, monitor, driver, sequence, or scoreboard logic."
---

Review this PCIe AXI bridge verification code as a digital verification reviewer.

Code, intent, or file references:
${input:code_or_intent:Paste selected code, describe intended behavior, or reference files/signals/classes}

Please answer:

1. **Current Behavior**
   - Explain what the code currently does.

2. **Intended Behavior Match**
   - Compare it against the PCIe TLP-to-AXI bridge model.
   - State any assumptions needed.

3. **Corner Cases**
   - Check reset, handshake timing, packet boundaries, TLP header fields, payload length, byte enables, AXI burst conversion, ordering, backpressure, and X/Z behavior.

4. **Verification Risks**
   - Identify protocol risks, monitor sampling risks, scoreboard false positives/negatives, race conditions, and coverage/assertion gaps.

5. **Minimal Correction Strategy**
   - If a bug is proven, propose the smallest correction strategy.
   - Do not rewrite architecture unless the evidence proves an ownership problem.
