#!/usr/bin/env python3
"""Static sanity checks for the local PCIe AXI UVM project."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys


EXPECTED_DUT_FILES = [
    "dut/pcie_axi_master.v",
    "dut/pcie_axi_master_rd.v",
    "dut/pcie_axi_master_wr.v",
    "dut/pcie_tlp_demux.v",
    "dut/pcie_tlp_fifo.v",
    "dut/pcie_tlp_fifo_raw.v",
    "dut/pulse_merge.v",
]

EXPECTED_PCIE_VIP_FILES = [
    "uvm/vip/pcie_types.sv",
    "uvm/vip/pcie_tlp_transaction.sv",
    "uvm/vip/pcie_tlp_if.sv",
]

EXPECTED_TYPE_TOKENS = [
    "PCIE_FMT_3DW",
    "PCIE_FMT_4DW",
    "PCIE_FMT_3DW_DATA",
    "PCIE_FMT_4DW_DATA",
    "PCIE_TYPE_MEM_REQ",
    "PCIE_TYPE_CPL",
    "PCIE_CPL_STATUS_SC",
    "PCIE_CPL_STATUS_UR",
    "PCIE_TLP_HDR_FMT_MSB",
    "PCIE_REQ_HDR_REQUESTER_ID_MSB",
    "PCIE_CPL_HDR_COMPLETER_ID_MSB",
]

EXPECTED_IF_SIGNALS = [
    "rx_req_tlp_data",
    "rx_req_tlp_hdr",
    "rx_req_tlp_valid",
    "rx_req_tlp_sop",
    "rx_req_tlp_eop",
    "rx_req_tlp_ready",
    "tx_cpl_tlp_data",
    "tx_cpl_tlp_strb",
    "tx_cpl_tlp_hdr",
    "tx_cpl_tlp_valid",
    "tx_cpl_tlp_sop",
    "tx_cpl_tlp_eop",
    "tx_cpl_tlp_ready",
    "completer_id",
    "max_payload_size",
    "status_error_cor",
    "status_error_uncor",
]


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")


def has_declared_identifier(text: str, name: str) -> bool:
    pattern = rf"\b(?:rand\s+)?(?:bit|logic|int|integer|pcie_\w+)\b(?:\s*\[[^\]]+\])?\s+{re.escape(name)}\b"
    return re.search(pattern, text) is not None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "project_root",
        nargs="?",
        default="/Users/williamzzz/Desktop/pcie/pcie-axi-bridge",
        help="Path to the pcie-axi-bridge project root",
    )
    args = parser.parse_args()

    root = Path(args.project_root).expanduser().resolve()
    errors: list[str] = []
    warnings: list[str] = []

    if not root.exists():
        print(f"ERROR: project root does not exist: {root}")
        return 2

    for rel in EXPECTED_DUT_FILES + EXPECTED_PCIE_VIP_FILES:
        if not (root / rel).exists():
            errors.append(f"missing expected file: {rel}")

    pcie_types = root / "uvm/vip/pcie_types.sv"
    if pcie_types.exists():
        text = read_text(pcie_types)
        for token in EXPECTED_TYPE_TOKENS:
            if token not in text:
                warnings.append(f"pcie_types.sv does not contain expected token: {token}")

    pcie_if = root / "uvm/vip/pcie_tlp_if.sv"
    if pcie_if.exists():
        text = read_text(pcie_if)
        for signal in EXPECTED_IF_SIGNALS:
            if not re.search(rf"\b{re.escape(signal)}\b", text):
                errors.append(f"pcie_tlp_if.sv missing signal: {signal}")
        if "modport dut" not in text:
            warnings.append("pcie_tlp_if.sv has no DUT-facing modport")
        if "modport host" not in text:
            warnings.append("pcie_tlp_if.sv has no host/requester modport")

    pcie_tr = root / "uvm/vip/pcie_tlp_transaction.sv"
    if pcie_tr.exists():
        text = read_text(pcie_tr)
        for name in ("traffic_class", "attributes"):
            if re.search(rf"\b{name}\b", text) and not has_declared_identifier(text, name):
                errors.append(
                    f"pcie_tlp_transaction.sv uses '{name}' but no matching field declaration was found"
                )
        if "function void pack_header" not in text:
            errors.append("pcie_tlp_transaction.sv missing pack_header()")
        if "function void unpack_header" not in text:
            errors.append("pcie_tlp_transaction.sv missing unpack_header()")
        if "tlp_digest_present" in text and "constraint c_digest" not in text:
            warnings.append("digest field exists but no c_digest constraint was found")

    dut = root / "dut/pcie_axi_master.v"
    if dut.exists():
        text = read_text(dut)
        for signal in EXPECTED_IF_SIGNALS:
            if signal.startswith("status_") or signal in ("completer_id", "max_payload_size"):
                expected = signal
            else:
                expected = signal
            if expected not in text:
                warnings.append(f"pcie_axi_master.v does not mention expected signal: {expected}")
        if "TLP_HDR_WIDTH = 128" not in text:
            warnings.append("pcie_axi_master.v does not show default TLP_HDR_WIDTH = 128")

    print(f"Project root: {root}")
    if errors:
        print("\nErrors:")
        for item in errors:
            print(f"  - {item}")
    if warnings:
        print("\nWarnings:")
        for item in warnings:
            print(f"  - {item}")
    if not errors and not warnings:
        print("\nOK: no static issues found by this skill checker.")
    elif not errors:
        print("\nOK with warnings.")
    else:
        print("\nFAILED: fix errors before relying on the project state.")

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

