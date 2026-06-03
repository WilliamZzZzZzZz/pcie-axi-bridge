`ifndef PCIE_TLP_TRANSACTION_SV
`define PCIE_TLP_TRANSACTION_SV

typedef enum bit [2:0] {
    PCIE_TLP_MEM_RD,
    PCIE_TLP_MEM_WR,
    PCIE_TLP_CPL,
    PCIE_TLP_CPLD,
    PCIE_TLP_OTHER
} pcie_tlp_kind_e;

class pcie_tlp_transaction extends uvm_sequence_item;
    `uvm_object_utils(pcie_tlp_transaction)

    localparam int TLP_DATA_WIDTH  = 256;
    localparam int TLP_STRB_WIDTH  = (TLP_DATA_WIDTH/32);
    localparam int TLP_HDR_WIDTH   = 128;
    localparam int TLP_DATA_DWORDS = (TLP_DATA_WIDTH/32);

    localparam bit [2:0] TLP_FMT_3DW      = 3'b000;
    localparam bit [2:0] TLP_FMT_4DW      = 3'b001;
    localparam bit [2:0] TLP_FMT_3DW_DATA = 3'b010;
    localparam bit [2:0] TLP_FMT_4DW_DATA = 3'b011;
    localparam bit [4:0] TLP_TYPE_MEM     = 5'b00000;
    localparam bit [4:0] TLP_TYPE_CPL     = 5'b01010;

    //--------------------------------------------------------------------------
    // Transaction metadata
    //--------------------------------------------------------------------------
    rand pcie_tlp_kind_e                 tlp_kind;

    //--------------------------------------------------------------------------
    // TLP Header: raw 3DW/4DW header image plus decoded header fields.
    //--------------------------------------------------------------------------
    bit [TLP_HDR_WIDTH-1:0]              tlp_hdr;
    rand bit [2:0]                       tlp_fmt;       //000: 3DW no Data|001: 4DW no Data|010:3DW Data|011: 4DW Data
    rand bit [4:0]                       tlp_type;      //00000: Memory Request
    rand bit [2:0]                       tc;            //tc(priority), set default:000
    rand bit [2:0]                       attr;          //attr
    rand bit [1:0]                       address_type;
    rand bit                             lightweight_notification;
    rand bit                             tph_present;
    rand bit                             tlp_digest_present;
    rand bit                             poisoned_tlp;
    rand bit [10:0]                      tlp_length_dw;  // 0 is valid only for Cpl without data.
    rand bit [15:0]                      requester_id;
    rand bit [9:0]                       tag;
    rand bit [3:0]                       first_dw_byte_enable;
    rand bit [3:0]                       last_dw_byte_enable;
    rand bit [63:0]                      address;
    rand bit [1:0]                       processing_hint;
    rand bit [15:0]                      completer_id;
    rand bit [2:0]                       completion_status;
    rand bit                             byte_count_modified;
    rand bit [11:0]                      byte_count;
    rand bit [6:0]                       lower_address;

    //--------------------------------------------------------------------------
    // TLP Payload: data DWs carried after the header.
    //--------------------------------------------------------------------------
    rand bit [TLP_DATA_WIDTH-1:0]        payload_data[];
    rand bit [TLP_STRB_WIDTH-1:0]        payload_strb[];

    //--------------------------------------------------------------------------
    // TLP Digest: optional ECRC DW. Presence is indicated by header TD bit above.
    //--------------------------------------------------------------------------
    rand bit [31:0]                      digest_ecrc;

    constraint c_kind_header {
        (tlp_kind == PCIE_TLP_MEM_RD) -> (tlp_type == TLP_TYPE_MEM && tlp_fmt inside {TLP_FMT_3DW, TLP_FMT_4DW});
        (tlp_kind == PCIE_TLP_MEM_WR) -> (tlp_type == TLP_TYPE_MEM && tlp_fmt inside {TLP_FMT_3DW_DATA, TLP_FMT_4DW_DATA});
        (tlp_kind == PCIE_TLP_CPL)    -> (tlp_type == TLP_TYPE_CPL && tlp_fmt == TLP_FMT_3DW);
        (tlp_kind == PCIE_TLP_CPLD)   -> (tlp_type == TLP_TYPE_CPL && tlp_fmt == TLP_FMT_3DW_DATA);
    }

    constraint c_length {
        if (tlp_kind == PCIE_TLP_CPL)
            tlp_length_dw == 0;
        else
            tlp_length_dw inside {[1:1024]};
    }

    constraint c_addr_fmt {
        if (tlp_kind inside {PCIE_TLP_MEM_RD, PCIE_TLP_MEM_WR} && tlp_fmt inside {TLP_FMT_3DW, TLP_FMT_3DW_DATA})
            address[63:32] == 32'd0;
    }

    constraint c_payload_beats {
        if (tlp_kind inside {PCIE_TLP_MEM_WR, PCIE_TLP_CPLD})
            payload_data.size() == ((int'(tlp_length_dw) + TLP_DATA_DWORDS - 1) / TLP_DATA_DWORDS);
        else
            payload_data.size() == 0;
        payload_strb.size() == payload_data.size();
    }

    constraint c_digest {
        if (!tlp_digest_present)
            digest_ecrc == 32'd0;
    }

    function new(string name = "pcie_tlp_transaction");
        super.new(name);
    endfunction

    function void post_randomize();
        pack_header();
    endfunction

    function void unpack_header();
        bit [9:0] raw_length;

        tlp_fmt              = tlp_hdr[127:125];
        tlp_type                = tlp_hdr[124:120];
        tc           = tlp_hdr[118:116];
        attr              = {tlp_hdr[114], tlp_hdr[109:108]};
        address_type            = tlp_hdr[107:106];
        lightweight_notification = tlp_hdr[113];
        tph_present             = tlp_hdr[112];
        tlp_digest_present      = tlp_hdr[111];
        poisoned_tlp            = tlp_hdr[110];
        raw_length              = tlp_hdr[105:96];

        if (tlp_type == TLP_TYPE_CPL) begin
            tlp_kind            = tlp_fmt[1] ? PCIE_TLP_CPLD : PCIE_TLP_CPL;
            tlp_length_dw       = tlp_fmt[1] && raw_length == 10'd0 ? 11'd1024 : {1'b0, raw_length};
            completer_id        = tlp_hdr[95:80];
            completion_status   = tlp_hdr[79:77];
            byte_count_modified = tlp_hdr[76];
            byte_count          = tlp_hdr[75:64];
            requester_id        = tlp_hdr[63:48];
            tag                 = {tlp_hdr[119], tlp_hdr[115], tlp_hdr[47:40]};
            lower_address       = tlp_hdr[38:32];
        end else begin
            tlp_kind             = (tlp_type == TLP_TYPE_MEM) ? (tlp_fmt[1] ? PCIE_TLP_MEM_WR : PCIE_TLP_MEM_RD) : PCIE_TLP_OTHER;
            tlp_length_dw        = (raw_length == 10'd0) ? 11'd1024 : {1'b0, raw_length};
            requester_id         = tlp_hdr[95:80];
            tag                  = {tlp_hdr[119], tlp_hdr[115], tlp_hdr[79:72]};
            last_dw_byte_enable  = tlp_hdr[71:68];
            first_dw_byte_enable = tlp_hdr[67:64];
            address              = tlp_fmt[0] ? {tlp_hdr[63:2], 2'b00} : {32'd0, tlp_hdr[63:34], 2'b00};
            processing_hint      = tlp_fmt[0] ? tlp_hdr[1:0] : tlp_hdr[33:32];
        end
    endfunction

    function void pack_header();
        tlp_hdr = '0;
        tlp_hdr[127:125] = tlp_fmt;
        tlp_hdr[124:120] = tlp_type;
        tlp_hdr[119]     = tag[9];
        tlp_hdr[118:116] = tc;
        tlp_hdr[115]     = tag[8];
        tlp_hdr[114]     = attr[2];
        tlp_hdr[113]     = lightweight_notification;
        tlp_hdr[112]     = tph_present;
        tlp_hdr[111]     = tlp_digest_present;
        tlp_hdr[110]     = poisoned_tlp;
        tlp_hdr[109:108] = attr[1:0];
        tlp_hdr[107:106] = address_type;
        tlp_hdr[105:96]  = tlp_length_dw[9:0];

        if (tlp_kind inside {PCIE_TLP_CPL, PCIE_TLP_CPLD}) begin
            tlp_hdr[95:80] = completer_id;
            tlp_hdr[79:77] = completion_status;
            tlp_hdr[76]    = byte_count_modified;
            tlp_hdr[75:64] = byte_count;
            tlp_hdr[63:48] = requester_id;
            tlp_hdr[47:40] = tag[7:0];
            tlp_hdr[38:32] = lower_address;
        end else begin
            tlp_hdr[95:80] = requester_id;
            tlp_hdr[79:72] = tag[7:0];
            tlp_hdr[71:68] = last_dw_byte_enable;
            tlp_hdr[67:64] = first_dw_byte_enable;
            if (tlp_fmt[0]) begin
                tlp_hdr[63:2] = address[63:2];
                tlp_hdr[1:0]  = processing_hint;
            end else begin
                tlp_hdr[63:34] = address[31:2];
                tlp_hdr[33:32] = processing_hint;
            end
        end
    endfunction
endclass

`endif
