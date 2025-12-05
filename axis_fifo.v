`timescale 1ns/1ps

module axis_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input  wire                   clk,
    input  wire                   reset_n,

    // AXIS Input (from master)
    input  wire [DATA_WIDTH-1:0]  s_tdata,
    input  wire                   s_tvalid,
    output wire                   s_tready,
    input  wire                   s_tlast,

    // AXIS Output (to slave)
    output reg  [DATA_WIDTH-1:0]  m_tdata,
    output reg                    m_tvalid,
    input  wire                   m_tready,
    output reg                    m_tlast
);

    // FIFO memory
    reg [DATA_WIDTH:0] mem [0:FIFO_DEPTH-1];  
    // Extra bit for TLAST storage

    // Read & Write pointers
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr;
    reg [$clog2(FIFO_DEPTH)-1:0] rd_ptr;

    // FIFO level counter
    reg [$clog2(FIFO_DEPTH+1)-1:0] count;

    //--------------------------
    // FIFO Status
    //--------------------------
    wire fifo_full  = (count == FIFO_DEPTH);
    wire fifo_empty = (count == 0);

    //--------------------------
    // Write Enable (Slave Side)
    //--------------------------
    assign s_tready = !fifo_full;

    //--------------------------
    // Write Logic
    //--------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            wr_ptr <= 0;
        end else begin
            if (s_tvalid && s_tready) begin
                mem[wr_ptr] <= {s_tlast, s_tdata};  // store TLAST + data
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    //--------------------------
    // Read Logic
    //--------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rd_ptr   <= 0;
            m_tvalid <= 0;
            m_tdata  <= 0;
            m_tlast  <= 0;
        end else begin
            if (!fifo_empty) begin
                m_tvalid <= 1;

                if (m_tready) begin
                    {m_tlast, m_tdata} <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                end
            end else begin
                m_tvalid <= 0;
            end
        end
    end

    //--------------------------
    // FIFO count update
    //--------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            count <= 0;
        end else begin
            case ({(s_tvalid && s_tready), (m_tvalid && m_tready)})
                2'b10: count <= count + 1;  // write only
                2'b01: count <= count - 1;  // read only
                default: count <= count;     // no change / read-write same cycle
            endcase
        end
    end

endmodule