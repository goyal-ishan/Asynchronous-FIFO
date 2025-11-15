`timescale 1ns/1ps
module tb_async_fifo;
    reg wr_clk = 0;
    reg rd_clk = 0;
    reg wr_rst_n = 0;
    reg rd_rst_n = 0;
    reg wr_en = 0;
    reg rd_en = 0;
    reg [7:0] wr_data = 0;
    wire [7:0] rd_data;
    wire full, empty;

    async_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(3)) dut (
        .wr_clk(wr_clk), .wr_rst_n(wr_rst_n), .wr_en(wr_en), .wr_data(wr_data), .full(full),
        .rd_clk(rd_clk), .rd_rst_n(rd_rst_n), .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
    );

    // 10 ns write clock and 14 ns read clock.
    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;

    integer i;
    reg [7:0] expected [0:31];
    integer wcount, rcount;

    initial begin
        wcount = 0;
        rcount = 0;
        #30;
        wr_rst_n = 1;
        rd_rst_n = 1;

        // Fill FIFO. Eight entries should be accepted.
        for (i=0; i<8; i=i+1) begin
            @(negedge wr_clk);
            if (!full) begin
                wr_en   = 1;
                wr_data = 8'hA0 + i;
                expected[wcount] = 8'hA0 + i;
                wcount = wcount + 1;
            end
        end
        @(negedge wr_clk); wr_en = 0;

        // Read all entries back in order.
        for (i=0; i<8; i=i+1) begin
            wait(!empty);
            @(negedge rd_clk);
            rd_en = 1;
            @(posedge rd_clk);
            #1;
            if (rd_data !== expected[rcount])
                $display("FAIL: read=%h expected=%h", rd_data, expected[rcount]);
            else
                $display("PASS: read=%h", rd_data);
            rcount = rcount + 1;
            rd_en = 0;
        end

        // Mismatched-clock stress: concurrent writes and reads.
        fork
            begin
                for (i=0; i<20; i=i+1) begin
                    @(negedge wr_clk);
                    if (!full) begin
                        wr_en   = 1;
                        wr_data = 8'h30 + i;
                        @(negedge wr_clk);
                        wr_en = 0;
                    end
                end
            end
            begin
                repeat (20) begin
                    wait(!empty);
                    @(negedge rd_clk); rd_en = 1;
                    @(negedge rd_clk); rd_en = 0;
                end
            end
        join

        $display("Async FIFO test complete. wr_clk=10 ns, rd_clk=14 ns.");
        #50 $finish;
    end
endmodule
