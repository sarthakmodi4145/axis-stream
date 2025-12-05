`timescale 1ns/1ps

module axis_master_tb;

    reg clk;
    reg reset_n;
    reg m_tready;

    wire [7:0] m_tdata;
    wire       m_tvalid;
    wire       m_tlast;

    // DUT
    axis_master #(
        .DATA_WIDTH(8),
        .PACKET_SIZE(8)      // use smaller size to test faster
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .m_tdata(m_tdata),
        .m_tvalid(m_tvalid),
        .m_tready(m_tready),
        .m_tlast(m_tlast)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0;
        reset_n = 0;
        m_tready = 0;

        // Apply reset
        #20 reset_n = 1;

        // Dummy TREADY behavior:
        // Sometimes ready, sometimes not
        forever begin
            #15 m_tready = 1;   // ready
            #20 m_tready = 0;   // not ready (introduces stalls)
        end
    end

    // Monitor output
    initial begin
        $display("TIME   VALID READY DATA LAST");
        $monitor("%4t   %b      %b     %d    %b",
                  $time, m_tvalid, m_tready, m_tdata, m_tlast);
    end

    // Simulation duration
    initial begin
        #300 $finish;
    end

endmodule