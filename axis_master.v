`timescale 1ns/1ps

module axis_master #(
    parameter DATA_WIDTH = 8,
    parameter PACKET_SIZE = 16
)(
    input  wire                   clk,
    input  wire                   reset_n,

    // AXI-Stream Master Interface
    output reg  [DATA_WIDTH-1:0]  m_tdata,
    output reg                    m_tvalid,
    input  wire                   m_tready,
    output reg                    m_tlast
);

    reg [$clog2(PACKET_SIZE):0] counter;   // Counts beats in a packet
    reg sending;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter   <= 0;
            m_tdata   <= 0;
            m_tvalid  <= 0;
            m_tlast   <= 0;
            sending   <= 0;
        end else begin
            
            // Start sending immediately after reset
            if (!sending) begin
                m_tvalid <= 1;
                sending  <= 1;
            end

            // Hold TVALID high until handshake occurs
            if (m_tvalid && m_tready) begin
                m_tdata <= counter;

                // TLAST logic
                if (counter == PACKET_SIZE-1) begin
                    m_tlast <= 1;
                    counter <= 0;        // wrap to next packet
                end else begin
                    m_tlast <= 0;
                    counter <= counter + 1;
                end
            end
        end
    end

endmodule