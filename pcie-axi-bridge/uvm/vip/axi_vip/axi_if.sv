`ifndef AXI_IF_SV
`define AXI_IF_SV

//------------------------------------------------------------------------------
// AXI4 Interface
// Description: AXI4 master interface exported by pcie_axi_master.
//------------------------------------------------------------------------------

interface axi_if #(
    parameter int DATA_WIDTH = 256,
    parameter int ADDR_WIDTH = 64,
    parameter int ID_WIDTH   = 8,
    parameter int STRB_WIDTH = (DATA_WIDTH/8)
)(
    input logic clk,
    input logic rst
);

    // Backward-compatible aliases for existing VIP code.
    wire aclk = clk;
    wire arst = rst;

    //--------------------------------------------------------------------------
    // Write Address Channel (AW)
    //--------------------------------------------------------------------------
    logic [ID_WIDTH-1:0]        awid;
    logic [ADDR_WIDTH-1:0]      awaddr;
    logic [7:0]                 awlen;
    logic [2:0]                 awsize;
    logic [1:0]                 awburst;
    logic                       awlock;
    logic [3:0]                 awcache;
    logic [2:0]                 awprot;
    logic                       awvalid;
    logic                       awready;

    //--------------------------------------------------------------------------
    // Write Data Channel (W)
    //--------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0]      wdata;
    logic [STRB_WIDTH-1:0]      wstrb;
    logic                       wlast;
    logic                       wvalid;
    logic                       wready;

    //--------------------------------------------------------------------------
    // Write Response Channel (B)
    //--------------------------------------------------------------------------
    logic [ID_WIDTH-1:0]        bid;
    logic [1:0]                 bresp;
    logic                       bvalid;
    logic                       bready;

    //--------------------------------------------------------------------------
    // Read Address Channel (AR)
    //--------------------------------------------------------------------------
    logic [ID_WIDTH-1:0]        arid;
    logic [ADDR_WIDTH-1:0]      araddr;
    logic [7:0]                 arlen;
    logic [2:0]                 arsize;
    logic [1:0]                 arburst;
    logic                       arlock;
    logic [3:0]                 arcache;
    logic [2:0]                 arprot;
    logic                       arvalid;
    logic                       arready;

    //--------------------------------------------------------------------------
    // Read Data Channel (R)
    //--------------------------------------------------------------------------
    logic [ID_WIDTH-1:0]        rid;
    logic [DATA_WIDTH-1:0]      rdata;
    logic [1:0]                 rresp;
    logic                       rlast;
    logic                       rvalid;
    logic                       rready;

    //--------------------------------------------------------------------------
    // Clocking Blocks for Master and Slave
    //--------------------------------------------------------------------------

    // Master clocking block - used by master driver
    clocking master_cb @(posedge clk);
        default input #1ns output #1ns;

        // AW
        output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awvalid;
        input  awready;
        // W
        output wdata, wstrb, wlast, wvalid;
        input  wready;
        // B
        input  bid, bresp, bvalid;
        output bready;
        // AR
        output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arvalid;
        input  arready;
        // R
        input  rid, rdata, rresp, rlast, rvalid;
        output rready;
    endclocking

    // Slave clocking block - used by slave responder
    clocking slave_cb @(posedge clk);
        default input #1ns output #1ns;

        // AW
        input  awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awvalid;
        output awready;
        // W
        input  wdata, wstrb, wlast, wvalid;
        output wready;
        // B
        output bid, bresp, bvalid;
        input  bready;
        // AR
        input  arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arvalid;
        output arready;
        // R
        output rid, rdata, rresp, rlast, rvalid;
        input  rready;
    endclocking

    // Monitor clocking block - used by monitor
    clocking monitor_cb @(posedge clk);
        default input #1ns output #1ns;

        // AW
        input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awvalid, awready;
        // W
        input wdata, wstrb, wlast, wvalid, wready;
        // B
        input bid, bresp, bvalid, bready;
        // AR
        input arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arvalid, arready;
        // R
        input rid, rdata, rresp, rlast, rvalid, rready;
    endclocking

    //--------------------------------------------------------------------------
    // Modports
    //--------------------------------------------------------------------------

    // Master modport - for active AXI master driver
    modport master (
        clocking master_cb,
        input clk, rst,
        input aclk, arst
    );

    // Slave modport - for active AXI slave responder
    modport slave (
        clocking slave_cb,
        input clk, rst,
        input aclk, arst
    );

    // Monitor modport - for monitor
    modport monitor (
        clocking monitor_cb,
        input clk, rst,
        input aclk, arst,
        input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot,
        input awvalid, awready,
        input wdata, wstrb, wlast, wvalid, wready,
        input bid, bresp, bvalid, bready,
        input arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot,
        input arvalid, arready,
        input rid, rdata, rresp, rlast, rvalid, rready
    );

    // Passive monitor modport - for passive monitoring
    modport passive (
        input clk, rst,
        input aclk, arst,
        input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot,
        input awvalid, awready,
        input wdata, wstrb, wlast, wvalid, wready,
        input bid, bresp, bvalid, bready,
        input arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot,
        input arvalid, arready,
        input rid, rdata, rresp, rlast, rvalid, rready
    );

    // DUT-facing AXI master modport - directions are from pcie_axi_master.
    modport dut_master (
        input  clk, rst,
        output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awvalid,
        input  awready,
        output wdata, wstrb, wlast, wvalid,
        input  wready,
        input  bid, bresp, bvalid,
        output bready,
        output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arvalid,
        input  arready,
        input  rid, rdata, rresp, rlast, rvalid,
        output rready
    );

    //--------------------------------------------------------------------------
    // Assertions for Protocol Checking
    //--------------------------------------------------------------------------

    // Write address channel stability
    property p_awvalid_stable;
        @(posedge clk) disable iff (rst)
        (awvalid && !awready) |=>
            $stable(awid)    &&
            $stable(awaddr)  &&
            $stable(awlen)   &&
            $stable(awsize)  &&
            $stable(awburst) &&
            $stable(awlock)  &&
            $stable(awcache) &&
            $stable(awprot)  &&
            $stable(awvalid);
    endproperty
    assert property (p_awvalid_stable) else
        $error("AXI Protocol Violation: Write address channel signals must remain stable when awvalid is high and awready is low");

    // Write data channel stability
    property p_wvalid_stable;
        @(posedge clk) disable iff (rst)
        (wvalid && !wready) |=>
            $stable(wdata)  &&
            $stable(wstrb)  &&
            $stable(wlast)  &&
            $stable(wvalid);
    endproperty
    assert property (p_wvalid_stable) else
        $error("AXI Protocol Violation: Write data channel signals must remain stable when wvalid is high and wready is low");

    // Read address channel stability
    property p_arvalid_stable;
        @(posedge clk) disable iff (rst)
        (arvalid && !arready) |=>
            $stable(arid)    &&
            $stable(araddr)  &&
            $stable(arlen)   &&
            $stable(arsize)  &&
            $stable(arburst) &&
            $stable(arlock)  &&
            $stable(arcache) &&
            $stable(arprot)  &&
            $stable(arvalid);
    endproperty
    assert property (p_arvalid_stable) else
        $error("AXI Protocol Violation: Read address channel signals must remain stable when arvalid is high and arready is low");

    // Write response channel stability
    property p_bvalid_stable;
        @(posedge clk) disable iff (rst)
        (bvalid && !bready) |=>
            $stable(bid)    &&
            $stable(bresp)  &&
            $stable(bvalid);
    endproperty
    assert property (p_bvalid_stable) else
        $error("AXI Protocol Violation: Write response channel signals must remain stable when bvalid is high and bready is low");

    // Read data channel stability
    property p_rvalid_stable;
        @(posedge clk) disable iff (rst)
        (rvalid && !rready) |=>
            $stable(rid)    &&
            $stable(rdata)  &&
            $stable(rresp)  &&
            $stable(rlast)  &&
            $stable(rvalid);
    endproperty
    assert property (p_rvalid_stable) else
        $error("AXI Protocol Violation: Read data channel signals must remain stable when rvalid is high and rready is low");

    //--------------------------------------------------------------------------
    // Utility Tasks and Functions
    //--------------------------------------------------------------------------

    // Reset all master-driven signals
    task automatic reset_master_signals();
        awid     <= '0;
        awaddr   <= '0;
        awlen    <= '0;
        awsize   <= '0;
        awburst  <= '0;
        awlock   <= '0;
        awcache  <= '0;
        awprot   <= '0;
        awvalid  <= '0;

        wdata    <= '0;
        wstrb    <= '0;
        wlast    <= '0;
        wvalid   <= '0;

        bready   <= '0;

        arid     <= '0;
        araddr   <= '0;
        arlen    <= '0;
        arsize   <= '0;
        arburst  <= '0;
        arlock   <= '0;
        arcache  <= '0;
        arprot   <= '0;
        arvalid  <= '0;

        rready   <= '0;
    endtask

    // Reset all slave-driven signals
    task automatic reset_slave_signals();
        awready  <= '0;
        wready   <= '0;

        bid      <= '0;
        bresp    <= '0;
        bvalid   <= '0;

        arready  <= '0;

        rid      <= '0;
        rdata    <= '0;
        rresp    <= '0;
        rlast    <= '0;
        rvalid   <= '0;
    endtask

    // Wait for specified number of clock cycles
    task automatic wait_clks(int num);
        repeat(num) @(posedge clk);
    endtask

    // Force reset HIGH; it can override the external reset driver.
    task automatic assert_reset();
        force rst = 1'b1;
    endtask

    // Release reset back to the external reset driver.
    task automatic deassert_reset();
        release rst;
    endtask

    task automatic do_reset(int num_cycles = 5);
        force rst = 1'b1;
        repeat(num_cycles) @(posedge clk);
        release rst;
        @(posedge clk);
    endtask

endinterface : axi_if

`endif
