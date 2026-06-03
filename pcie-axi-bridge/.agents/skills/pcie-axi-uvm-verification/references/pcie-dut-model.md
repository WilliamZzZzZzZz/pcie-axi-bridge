# PCIe DUT Model

## Scope

`pcie_axi_master` is a PCIe TLP request to AXI full master bridge. It accepts PCIe request TLPs through a generic TLP stream and emits AXI bursts. For reads, it returns PCIe completion TLPs.

It does not model the PCIe physical link, lanes, LTSSM, DLLP, replay, credits, config space, enumeration, MSI/MSI-X, or a root complex.

## Verification Topology

```text
TB pcie_tlp_requester
  -> pcie_tlp_if.rx_req_tlp_*
  -> DUT pcie_axi_master
  -> axi_if.m_axi_*
  -> TB axi_slave_agent + axi_slave_mem

DUT read completion:
axi_slave_mem/read responder
  -> AXI R beats
  -> DUT
  -> pcie_tlp_if.tx_cpl_tlp_*
  -> TB pcie_completion_monitor
```

## Request Types

For first-stage positive verification, TB input requests are only:

```text
Fmt=000 Type=00000 -> 3DW Memory Read Request
Fmt=001 Type=00000 -> 4DW Memory Read Request
Fmt=010 Type=00000 -> 3DW Memory Write Request
Fmt=011 Type=00000 -> 4DW Memory Write Request
```

`Type=00000` means Memory Request. It does not by itself mean read or write. In this subset:

```text
Fmt[1] = 0 -> MRd, no payload
Fmt[1] = 1 -> MWr, with payload
Fmt[0] = 0 -> 3DW address format
Fmt[0] = 1 -> 4DW address format
```

MWr is posted: do not expect a PCIe completion for a normal memory write. MRd is non-posted: expect a `CplD`.

## Completion Types

Expected DUT outputs:

```text
Fmt=010 Type=01010 -> CplD, successful read completion with data
Fmt=000 Type=01010 -> Cpl, unsupported request or no-data completion case
```

Read completion must preserve requester identity fields from the original request:

```text
requester_id
tag
tc
attr
```

`completer_id` is a DUT configuration input used in completion headers. It is not carried in the request TLP and is not an AXI-style transaction ID.

## 128-bit Header Mapping

Use the DUT mapping, not a generic external layout, when writing pack/unpack code.

Common request fields:

```text
fmt              hdr[127:125]
type             hdr[124:120]
tag[9]           hdr[119]
tc               hdr[118:116]
tag[8]           hdr[115]
attr[2]          hdr[114]
ln               hdr[113]
th               hdr[112]
td               hdr[111]
ep               hdr[110]
attr[1:0]        hdr[109:108]
at               hdr[107:106]
length           hdr[105:96]   // 0 encodes 1024 DW
requester_id     hdr[95:80]
tag[7:0]         hdr[79:72]
last_be          hdr[71:68]
first_be         hdr[67:64]
4DW address      {hdr[63:2], 2'b00}
4DW ph           hdr[1:0]
3DW address      {32'd0, hdr[63:34], 2'b00}
3DW ph           hdr[33:32]
```

Completion fields:

```text
fmt              hdr[127:125]
type             hdr[124:120]
tag[9]           hdr[119]
tc               hdr[118:116]
tag[8]           hdr[115]
attr[2]          hdr[114]
attr[1:0]        hdr[109:108]
length           hdr[105:96]
completer_id     hdr[95:80]
cpl_status       hdr[79:77]
bcm              hdr[76]
byte_count       hdr[75:64]
requester_id     hdr[63:48]
tag[7:0]         hdr[47:40]
lower_address    hdr[38:32]
```

## Scoreboard Rules

For MWr:

```text
input pcie_tlp_transaction MWr
  -> expected AXI write address burst
  -> expected AXI write data/strobes
  -> expect AXI B response
  -> expect no PCIe completion
```

For MRd:

```text
input pcie_tlp_transaction MRd
  -> expected AXI read address burst
  -> AXI slave returns data
  -> expected PCIe CplD header/data
```

Do not weaken the scoreboard to match DUT bugs. If DUT behavior differs from PCIe or from source-derived expectations, report the mismatch and isolate whether the cause is VIP packing, driver timing, AXI responder behavior, or DUT logic.

