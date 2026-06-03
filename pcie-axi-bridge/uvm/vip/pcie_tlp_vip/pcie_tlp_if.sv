`ifndef PCIE_TLP_IF_SV
`define PCIE_TLP_IF_SV

//------------------------------------------------------------------------------
// PCIe TLP Interface
// Description: PCIe-side TLP interface exported by pcie_axi_master.
//------------------------------------------------------------------------------

interface pcie_tlp_if #(
    parameter int TLP_DATA_WIDTH = 256,
    parameter int TLP_STRB_WIDTH = (TLP_DATA_WIDTH/32),
    parameter int TLP_HDR_WIDTH  = 128,
    parameter int TLP_SEG_COUNT  = 1
)(
    input logic clk,
    input logic rst
);

    //--------------------------------------------------------------------------
    // TLP input request channel (host/fabric -> DUT)
    //--------------------------------------------------------------------------
    logic [TLP_DATA_WIDTH-1:0]              rx_req_tlp_data;
    logic [TLP_SEG_COUNT*TLP_HDR_WIDTH-1:0] rx_req_tlp_hdr;
    logic [TLP_SEG_COUNT-1:0]               rx_req_tlp_valid;
    logic [TLP_SEG_COUNT-1:0]               rx_req_tlp_sop;
    logic [TLP_SEG_COUNT-1:0]               rx_req_tlp_eop;
    logic                                   rx_req_tlp_ready;

    //--------------------------------------------------------------------------
    // TLP output completion channel (DUT -> host/fabric)
    //--------------------------------------------------------------------------
    logic [TLP_DATA_WIDTH-1:0]              tx_cpl_tlp_data;
    logic [TLP_STRB_WIDTH-1:0]              tx_cpl_tlp_strb;
    logic [TLP_SEG_COUNT*TLP_HDR_WIDTH-1:0] tx_cpl_tlp_hdr;
    logic [TLP_SEG_COUNT-1:0]               tx_cpl_tlp_valid;
    logic [TLP_SEG_COUNT-1:0]               tx_cpl_tlp_sop;
    logic [TLP_SEG_COUNT-1:0]               tx_cpl_tlp_eop;
    logic                                   tx_cpl_tlp_ready;

    //--------------------------------------------------------------------------
    // PCIe-side configuration and status
    //--------------------------------------------------------------------------
    logic [15:0]                            completer_id;
    logic [2:0]                             max_payload_size;
    logic                                   status_error_cor;
    logic                                   status_error_uncor;

    //--------------------------------------------------------------------------
    // Clocking Blocks
    //--------------------------------------------------------------------------

    // Host clocking block - used by active PCIe/TLP driver or responder.
    clocking host_cb @(posedge clk);
        default input #1ns output #1ns;

        // Request input driven into the DUT.
        output rx_req_tlp_data, rx_req_tlp_hdr, rx_req_tlp_valid;
        output rx_req_tlp_sop, rx_req_tlp_eop;
        input  rx_req_tlp_ready;

        // Completion output observed from the DUT.
        input  tx_cpl_tlp_data, tx_cpl_tlp_strb, tx_cpl_tlp_hdr;
        input  tx_cpl_tlp_valid, tx_cpl_tlp_sop, tx_cpl_tlp_eop;
        output tx_cpl_tlp_ready;

        // DUT configuration/status.
        output completer_id, max_payload_size;
        input  status_error_cor, status_error_uncor;
    endclocking

    // Monitor clocking block - samples all PCIe/TLP side signals.
    clocking monitor_cb @(posedge clk);
        default input #1ns output #1ns;

        input rx_req_tlp_data, rx_req_tlp_hdr, rx_req_tlp_valid;
        input rx_req_tlp_sop, rx_req_tlp_eop, rx_req_tlp_ready;

        input tx_cpl_tlp_data, tx_cpl_tlp_strb, tx_cpl_tlp_hdr;
        input tx_cpl_tlp_valid, tx_cpl_tlp_sop, tx_cpl_tlp_eop, tx_cpl_tlp_ready;

        input completer_id, max_payload_size;
        input status_error_cor, status_error_uncor;
    endclocking

    //--------------------------------------------------------------------------
    // Modports
    //--------------------------------------------------------------------------

    // Host modport - for an active PCIe/TLP sequence driver.
    modport host (
        clocking host_cb,
        input clk, rst
    );

    // Monitor modport - for passive PCIe/TLP observation.
    modport monitor (
        clocking monitor_cb,
        input clk, rst,
        input rx_req_tlp_data, rx_req_tlp_hdr, rx_req_tlp_valid,
        input rx_req_tlp_sop, rx_req_tlp_eop, rx_req_tlp_ready,
        input tx_cpl_tlp_data, tx_cpl_tlp_strb, tx_cpl_tlp_hdr,
        input tx_cpl_tlp_valid, tx_cpl_tlp_sop, tx_cpl_tlp_eop, tx_cpl_tlp_ready,
        input completer_id, max_payload_size,
        input status_error_cor, status_error_uncor
    );

    // DUT-facing modport - directions match pcie_axi_master top-level ports.
    modport dut (
        input  clk, rst,
        input  rx_req_tlp_data, rx_req_tlp_hdr, rx_req_tlp_valid,
        input  rx_req_tlp_sop, rx_req_tlp_eop,
        output rx_req_tlp_ready,
        output tx_cpl_tlp_data, tx_cpl_tlp_strb, tx_cpl_tlp_hdr,
        output tx_cpl_tlp_valid, tx_cpl_tlp_sop, tx_cpl_tlp_eop,
        input  tx_cpl_tlp_ready,
        input  completer_id, max_payload_size,
        output status_error_cor, status_error_uncor
    );

    // Passive modport - raw signal access for checkers or scoreboards.
    modport passive (
        input clk, rst,
        input rx_req_tlp_data, rx_req_tlp_hdr, rx_req_tlp_valid,
        input rx_req_tlp_sop, rx_req_tlp_eop, rx_req_tlp_ready,
        input tx_cpl_tlp_data, tx_cpl_tlp_strb, tx_cpl_tlp_hdr,
        input tx_cpl_tlp_valid, tx_cpl_tlp_sop, tx_cpl_tlp_eop, tx_cpl_tlp_ready,
        input completer_id, max_payload_size,
        input status_error_cor, status_error_uncor
    );

    //--------------------------------------------------------------------------
    // Assertions for basic ready/valid stability
    //--------------------------------------------------------------------------

    property p_rx_req_stable;
        @(posedge clk) disable iff (rst)
        ((|rx_req_tlp_valid) && !rx_req_tlp_ready) |=>
            $stable(rx_req_tlp_data)  &&
            $stable(rx_req_tlp_hdr)   &&
            $stable(rx_req_tlp_valid) &&
            $stable(rx_req_tlp_sop)   &&
            $stable(rx_req_tlp_eop);
    endproperty
    assert property (p_rx_req_stable) else
        $error("PCIe TLP Protocol Violation: RX request TLP signals must remain stable while valid is asserted and ready is low");

    property p_tx_cpl_stable;
        @(posedge clk) disable iff (rst)
        ((|tx_cpl_tlp_valid) && !tx_cpl_tlp_ready) |=>
            $stable(tx_cpl_tlp_data)  &&
            $stable(tx_cpl_tlp_strb)  &&
            $stable(tx_cpl_tlp_hdr)   &&
            $stable(tx_cpl_tlp_valid) &&
            $stable(tx_cpl_tlp_sop)   &&
            $stable(tx_cpl_tlp_eop);
    endproperty
    assert property (p_tx_cpl_stable) else
        $error("PCIe TLP Protocol Violation: TX completion TLP signals must remain stable while valid is asserted and ready is low");

    //--------------------------------------------------------------------------
    // Utility Tasks
    //--------------------------------------------------------------------------

    task automatic reset_host_signals();
        rx_req_tlp_data   <= '0;
        rx_req_tlp_hdr    <= '0;
        rx_req_tlp_valid  <= '0;
        rx_req_tlp_sop    <= '0;
        rx_req_tlp_eop    <= '0;

        tx_cpl_tlp_ready  <= '0;

        completer_id      <= '0;
        max_payload_size  <= '0;
    endtask

    task automatic wait_clks(int num);
        repeat(num) @(posedge clk);
    endtask

    task automatic assert_reset();
        force rst = 1'b1;
    endtask

    task automatic deassert_reset();
        release rst;
    endtask

    task automatic do_reset(int num_cycles = 5);
        force rst = 1'b1;
        repeat(num_cycles) @(posedge clk);
        release rst;
        @(posedge clk);
    endtask

endinterface : pcie_tlp_if

`endif
