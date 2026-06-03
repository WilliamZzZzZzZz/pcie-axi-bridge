`ifndef PCIE_TYPES_SV
`define PCIE_TYPES_SV

    //--------------------------------------------------------------------------
    // PCIe TLP interface defaults
    //--------------------------------------------------------------------------
    localparam int PCIE_TLP_DATA_WIDTH = 256;
    localparam int PCIE_TLP_HDR_WIDTH  = 128;
    localparam int PCIE_TLP_STRB_WIDTH = PCIE_TLP_DATA_WIDTH / 32;
    localparam int PCIE_TLP_SEG_COUNT  = 1;

    //--------------------------------------------------------------------------
    // Current DUT verification defaults
    //--------------------------------------------------------------------------
    localparam bit [15:0] PCIE_DEFAULT_REQUESTER_ID      = 16'h0001;
    localparam bit [15:0] PCIE_DEFAULT_COMPLETER_ID      = 16'h0100;
    localparam bit [2:0]  PCIE_DEFAULT_TC                = 3'b000;
    localparam bit [2:0]  PCIE_DEFAULT_ATTR              = 3'b000;
    localparam bit [2:0]  PCIE_DEFAULT_MAX_PAYLOAD_SIZE  = 3'd0;

    //--------------------------------------------------------------------------
    // TLP Fmt, Type, and Completion Status encodings
    //--------------------------------------------------------------------------
    typedef enum bit [2:0] {
        PCIE_FMT_3DW      = 3'b000,
        PCIE_FMT_4DW      = 3'b001,
        PCIE_FMT_3DW_DATA = 3'b010,
        PCIE_FMT_4DW_DATA = 3'b011,
        PCIE_FMT_PREFIX   = 3'b100
    } pcie_tlp_fmt_enum;

    typedef enum bit [4:0] {
        PCIE_TYPE_MEM_REQ = 5'b00000,
        PCIE_TYPE_CPL     = 5'b01010,
        PCIE_TYPE_CPL_LK  = 5'b01011
    } pcie_tlp_type_enum;

    typedef enum bit [2:0] {
        PCIE_CPL_STATUS_SC  = 3'b000,
        PCIE_CPL_STATUS_UR  = 3'b001,
        PCIE_CPL_STATUS_CRS = 3'b010,
        PCIE_CPL_STATUS_CA  = 3'b100
    } pcie_cpl_status_enum;

    typedef enum int {
        PCIE_TLP_MEM_READ,
        PCIE_TLP_MEM_WRITE,
        PCIE_TLP_CPL,
        PCIE_TLP_CPLD,
        PCIE_TLP_UNSUPPORTED
    } pcie_tlp_kind_enum;

    //--------------------------------------------------------------------------
    // Byte Enable defaults
    //--------------------------------------------------------------------------
    localparam bit [3:0] PCIE_BE_NONE = 4'b0000;
    localparam bit [3:0] PCIE_BE_ALL  = 4'b1111;

    //--------------------------------------------------------------------------
    // Common 128-bit TLP header field positions
    //--------------------------------------------------------------------------
    localparam int PCIE_TLP_HDR_FMT_MSB              = 127;
    localparam int PCIE_TLP_HDR_FMT_LSB              = 125;
    localparam int PCIE_TLP_HDR_TYPE_MSB             = 124;
    localparam int PCIE_TLP_HDR_TYPE_LSB             = 120;
    localparam int PCIE_TLP_HDR_TAG_9_BIT            = 119;
    localparam int PCIE_TLP_HDR_TC_MSB               = 118;
    localparam int PCIE_TLP_HDR_TC_LSB               = 116;
    localparam int PCIE_TLP_HDR_TAG_8_BIT            = 115;
    localparam int PCIE_TLP_HDR_ATTR_2_BIT           = 114;
    localparam int PCIE_TLP_HDR_LN_BIT               = 113;
    localparam int PCIE_TLP_HDR_TH_BIT               = 112;
    localparam int PCIE_TLP_HDR_TD_BIT               = 111;
    localparam int PCIE_TLP_HDR_EP_BIT               = 110;
    localparam int PCIE_TLP_HDR_ATTR_1_0_MSB         = 109;
    localparam int PCIE_TLP_HDR_ATTR_1_0_LSB         = 108;
    localparam int PCIE_TLP_HDR_AT_MSB               = 107;
    localparam int PCIE_TLP_HDR_AT_LSB               = 106;
    localparam int PCIE_TLP_HDR_LENGTH_MSB           = 105;
    localparam int PCIE_TLP_HDR_LENGTH_LSB           = 96;

    //--------------------------------------------------------------------------
    // Request header field positions
    //--------------------------------------------------------------------------
    localparam int PCIE_REQ_HDR_REQUESTER_ID_MSB     = 95;
    localparam int PCIE_REQ_HDR_REQUESTER_ID_LSB     = 80;
    localparam int PCIE_REQ_HDR_TAG_MSB              = 79;
    localparam int PCIE_REQ_HDR_TAG_LSB              = 72;
    localparam int PCIE_REQ_HDR_LAST_BE_MSB          = 71;
    localparam int PCIE_REQ_HDR_LAST_BE_LSB          = 68;
    localparam int PCIE_REQ_HDR_FIRST_BE_MSB         = 67;
    localparam int PCIE_REQ_HDR_FIRST_BE_LSB         = 64;
    localparam int PCIE_REQ_HDR_4DW_ADDR_MSB         = 63;
    localparam int PCIE_REQ_HDR_4DW_ADDR_LSB         = 2;
    localparam int PCIE_REQ_HDR_4DW_PH_MSB           = 1;
    localparam int PCIE_REQ_HDR_4DW_PH_LSB           = 0;
    localparam int PCIE_REQ_HDR_3DW_ADDR_MSB         = 63;
    localparam int PCIE_REQ_HDR_3DW_ADDR_LSB         = 34;
    localparam int PCIE_REQ_HDR_3DW_PH_MSB           = 33;
    localparam int PCIE_REQ_HDR_3DW_PH_LSB           = 32;

    //--------------------------------------------------------------------------
    // Completion header field positions
    //--------------------------------------------------------------------------
    localparam int PCIE_CPL_HDR_FMT_MSB              = PCIE_TLP_HDR_FMT_MSB;
    localparam int PCIE_CPL_HDR_FMT_LSB              = PCIE_TLP_HDR_FMT_LSB;
    localparam int PCIE_CPL_HDR_TYPE_MSB             = PCIE_TLP_HDR_TYPE_MSB;
    localparam int PCIE_CPL_HDR_TYPE_LSB             = PCIE_TLP_HDR_TYPE_LSB;
    localparam int PCIE_CPL_HDR_TAG_9_BIT            = PCIE_TLP_HDR_TAG_9_BIT;
    localparam int PCIE_CPL_HDR_TC_MSB               = PCIE_TLP_HDR_TC_MSB;
    localparam int PCIE_CPL_HDR_TC_LSB               = PCIE_TLP_HDR_TC_LSB;
    localparam int PCIE_CPL_HDR_TAG_8_BIT            = PCIE_TLP_HDR_TAG_8_BIT;
    localparam int PCIE_CPL_HDR_ATTR_2_BIT           = PCIE_TLP_HDR_ATTR_2_BIT;
    localparam int PCIE_CPL_HDR_ATTR_1_0_MSB         = PCIE_TLP_HDR_ATTR_1_0_MSB;
    localparam int PCIE_CPL_HDR_ATTR_1_0_LSB         = PCIE_TLP_HDR_ATTR_1_0_LSB;
    localparam int PCIE_CPL_HDR_LENGTH_MSB           = PCIE_TLP_HDR_LENGTH_MSB;
    localparam int PCIE_CPL_HDR_LENGTH_LSB           = PCIE_TLP_HDR_LENGTH_LSB;
    localparam int PCIE_CPL_HDR_COMPLETER_ID_MSB     = 95;
    localparam int PCIE_CPL_HDR_COMPLETER_ID_LSB     = 80;
    localparam int PCIE_CPL_HDR_STATUS_MSB           = 79;
    localparam int PCIE_CPL_HDR_STATUS_LSB           = 77;
    localparam int PCIE_CPL_HDR_BCM_BIT              = 76;
    localparam int PCIE_CPL_HDR_BYTE_COUNT_MSB       = 75;
    localparam int PCIE_CPL_HDR_BYTE_COUNT_LSB       = 64;
    localparam int PCIE_CPL_HDR_REQUESTER_ID_MSB     = 63;
    localparam int PCIE_CPL_HDR_REQUESTER_ID_LSB     = 48;
    localparam int PCIE_CPL_HDR_TAG_MSB              = 47;
    localparam int PCIE_CPL_HDR_TAG_LSB              = 40;
    localparam int PCIE_CPL_HDR_LOWER_ADDR_MSB       = 38;
    localparam int PCIE_CPL_HDR_LOWER_ADDR_LSB       = 32;

`endif
