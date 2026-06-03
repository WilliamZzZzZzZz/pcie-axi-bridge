`ifndef AXI_TRANSACTION_SV
`define AXI_TRANSACTION_SV

class axi_transaction extends uvm_sequence_item;

    //--------------------------------------------------------------------------
    // Current DUT downstream AXI configuration
    //--------------------------------------------------------------------------
    localparam int DUT_AXI_DATA_WIDTH  = 256;
    localparam int DUT_AXI_ADDR_WIDTH  = 64;
    localparam int DUT_AXI_ID_WIDTH    = 8;
    localparam int DUT_AXI_STRB_WIDTH  = (DUT_AXI_DATA_WIDTH/8);
    localparam int DUT_AXI_BURST_SIZE  = $clog2(DUT_AXI_STRB_WIDTH);

    localparam bit [DUT_AXI_ID_WIDTH-1:0] DUT_AXI_ID     = '0;
    localparam bit [2:0]                  DUT_AXI_SIZE   = DUT_AXI_BURST_SIZE;
    localparam bit [1:0]                  DUT_AXI_BURST  = 2'b01;
    localparam bit                        DUT_AXI_LOCK   = 1'b0;
    localparam bit [3:0]                  DUT_AXI_CACHE  = 4'b0011;
    localparam bit [2:0]                  DUT_AXI_PROT   = 3'b010;

    //--------------------------------------------------------------------------
    // Transaction type: WRITE or READ
    //--------------------------------------------------------------------------
    rand trans_type_enum trans_type;

    int current_wbeat_count;
    int current_rbeat_count;
    int wbeat_finish;
    int b_finish;
    int rbeat_finish;

    // Pipeline mode: driver checks this flag before sending response back.
    bit response_requested = 1;

    //--------------------------------------------------------------------------
    // Write Address Channel (AW)
    //--------------------------------------------------------------------------
    rand bit [DUT_AXI_ID_WIDTH-1:0]       awid;
    rand bit [DUT_AXI_ADDR_WIDTH-1:0]     awaddr;
    rand bit [7:0]                        awlen;
    rand bit [2:0]                        awsize;
    rand bit [1:0]                        awburst;
    rand bit                              awlock;
    rand bit [3:0]                        awcache;
    rand bit [2:0]                        awprot;

    //--------------------------------------------------------------------------
    // Write Data Channel (W)
    //--------------------------------------------------------------------------
    rand bit [DUT_AXI_DATA_WIDTH-1:0]     wdata[];
    rand bit [DUT_AXI_STRB_WIDTH-1:0]     wstrb[];

    //--------------------------------------------------------------------------
    // Write Response Channel (B)
    //--------------------------------------------------------------------------
    bit [DUT_AXI_ID_WIDTH-1:0]            bid;
    bit [1:0]                             bresp;

    //--------------------------------------------------------------------------
    // Read Address Channel (AR)
    //--------------------------------------------------------------------------
    rand bit [DUT_AXI_ID_WIDTH-1:0]       arid;
    rand bit [DUT_AXI_ADDR_WIDTH-1:0]     araddr;
    rand bit [7:0]                        arlen;
    rand bit [2:0]                        arsize;
    rand bit [1:0]                        arburst;
    rand bit                              arlock;
    rand bit [3:0]                        arcache;
    rand bit [2:0]                        arprot;

    //--------------------------------------------------------------------------
    // Read Data Channel (R)
    //--------------------------------------------------------------------------
    bit [DUT_AXI_ID_WIDTH-1:0]            rid;
    bit [DUT_AXI_DATA_WIDTH-1:0]          rdata[];
    bit [1:0]                             rresp[];
    bit                                   rlast;

    //--------------------------------------------------------------------------
    // Constraints
    //--------------------------------------------------------------------------
    constraint c_len {
        awlen inside {[0:255]};
        arlen inside {[0:255]};
    }

    // pcie_axi_master drives fixed AXI sideband values on AW/AR.
    constraint c_dut_fixed_axi_outputs {
        awid    == DUT_AXI_ID;
        awsize  == DUT_AXI_SIZE;
        awburst == DUT_AXI_BURST;
        awlock  == DUT_AXI_LOCK;
        awcache == DUT_AXI_CACHE;
        awprot  == DUT_AXI_PROT;

        arid    == DUT_AXI_ID;
        arsize  == DUT_AXI_SIZE;
        arburst == DUT_AXI_BURST;
        arlock  == DUT_AXI_LOCK;
        arcache == DUT_AXI_CACHE;
        arprot  == DUT_AXI_PROT;
    }

    // AXI4 protocol: actual burst beat count is AxLEN + 1.
    constraint c_data_size {
        if (trans_type == WRITE) {
            wdata.size() == int'(awlen) + 1;
            wstrb.size() == int'(awlen) + 1;
        } else {
            wdata.size() == 0;
            wstrb.size() == 0;
        }
    }

    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_enum(trans_type_enum, trans_type, UVM_ALL_ON)
        `uvm_field_int(awid, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(awaddr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(awlen, UVM_ALL_ON)
        `uvm_field_int(awsize, UVM_ALL_ON)
        `uvm_field_int(awburst, UVM_ALL_ON)
        `uvm_field_int(awlock, UVM_ALL_ON)
        `uvm_field_int(awcache, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(awprot, UVM_ALL_ON)
        `uvm_field_array_int(wdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(wstrb, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(bid, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(bresp, UVM_ALL_ON)
        `uvm_field_int(arid, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(araddr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(arlen, UVM_ALL_ON)
        `uvm_field_int(arsize, UVM_ALL_ON)
        `uvm_field_int(arburst, UVM_ALL_ON)
        `uvm_field_int(arlock, UVM_ALL_ON)
        `uvm_field_int(arcache, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(arprot, UVM_ALL_ON)
        `uvm_field_int(rid, UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(rdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_array_int(rresp, UVM_ALL_ON)
        `uvm_field_int(rlast, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

    //--------------------------------------------------------------------------
    // Post-randomize
    //--------------------------------------------------------------------------
    function void post_randomize();
        if (trans_type == READ) begin
            rdata = new[int'(arlen) + 1];
            rresp = new[int'(arlen) + 1];
        end else begin
            rdata = new[0];
            rresp = new[0];
        end
    endfunction

endclass

`endif
