---
agent: "ask"
description: "Debug a PCIe AXI bridge UVM compile, config_db, sequence-driver, monitor, scoreboard, interface, or simulation issue."
---

Analyze this PCIe AXI bridge UVM/debug issue as a verification debug reviewer.

Issue, log, code, or file references:
${input:issue:Paste the error/log, describe the symptom, or reference relevant files/classes}

Please answer:

1. **Failure Classification**
   - Classify as compile/elaboration, package include order, factory, config_db, build/connect, run phase, sequence-driver handshake, TLM connection, interface connection, monitor sampling, scoreboard mismatch, reset/clock sync, or transaction consistency.

2. **Likely Root Cause**
   - Explain the most likely mechanism.
   - Separate evidence from assumptions.

3. **Evidence Needed**
   - List the exact files, classes, methods, signals, fields, or log lines to inspect.

4. **Code Paths to Inspect**
   - Identify likely components such as PCIe agent, AXI agent, env, driver, monitor, scoreboard, sequence, interface, config object, or test.

5. **Minimal Debug Experiment**
   - Propose the smallest print, assertion, waveform check, phase check, or focused simulation to confirm the hypothesis.

6. **Likely Fix Strategy**
   - Describe the smallest likely correction.
   - Do not rewrite architecture unless the evidence proves an ownership problem.
