// Parameterized dual-clock asynchronous FIFO.
// CDC-safe pointer transfer uses Gray coding and 2-FF synchronizers.
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 3       // DEPTH = 2^ADDR_WIDTH, default 8
) (
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output reg                   full,

    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output reg                   empty
);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam DEPTH     = (1 << ADDR_WIDTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    reg [PTR_WIDTH-1:0] wr_ptr_bin, wr_ptr_gray;
    reg [PTR_WIDTH-1:0] rd_ptr_bin, rd_ptr_gray;
    reg [PTR_WIDTH-1:0] rd_gray_sync1, rd_gray_sync2;
    reg [PTR_WIDTH-1:0] wr_gray_sync1, wr_gray_sync2;

    wire wr_accept = wr_en && !full;
    wire rd_accept = rd_en && !empty;

    wire [PTR_WIDTH-1:0] wr_ptr_bin_next  = wr_ptr_bin + wr_accept;
    wire [PTR_WIDTH-1:0] rd_ptr_bin_next  = rd_ptr_bin + rd_accept;
    wire [PTR_WIDTH-1:0] wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;
    wire [PTR_WIDTH-1:0] rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

    wire full_next = (wr_ptr_gray_next ==
                      {~rd_gray_sync2[PTR_WIDTH-1:PTR_WIDTH-2],
                       rd_gray_sync2[PTR_WIDTH-3:0]});
    wire empty_next = (rd_ptr_gray_next == wr_gray_sync2);

    // Synchronize read pointer into write clock domain.
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_gray_sync1 <= {PTR_WIDTH{1'b0}};
            rd_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            rd_gray_sync1 <= rd_ptr_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end

    // Synchronize write pointer into read clock domain.
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            wr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            wr_gray_sync1 <= wr_ptr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end

    // Write-domain pointer and full flag.
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= {PTR_WIDTH{1'b0}};
            wr_ptr_gray <= {PTR_WIDTH{1'b0}};
            full        <= 1'b0;
        end else begin
            if (wr_accept)
                mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
            full        <= full_next;
        end
    end

    // Read-domain pointer, data, and empty flag.
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= {PTR_WIDTH{1'b0}};
            rd_ptr_gray <= {PTR_WIDTH{1'b0}};
            rd_data     <= {DATA_WIDTH{1'b0}};
            empty       <= 1'b1;
        end else begin
            if (rd_accept)
                rd_data <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
            empty       <= empty_next;
        end
    end
endmodule
