`timescale 1ns/1ps

module tb_uart_tx;

    // --------------------------------
    // Simulation parameters
    // --------------------------------
    parameter CLK_FREQ  = 1_000_000;
    parameter BAUD_RATE = 10_000;

    parameter CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;


    // --------------------------------
    // Signals
    // --------------------------------
    reg clk;
    reg rst;

    reg [7:0] data_in;
    reg       tx_start;

    wire tx;
    wire tx_busy;


    // --------------------------------
    // DUT
    // --------------------------------
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy)
    );


    // --------------------------------
    // Clock generation
    // 10 ns clock period
    // --------------------------------
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // --------------------------------
    // Test
    // --------------------------------
    initial begin

        // Initial values
        rst      = 1'b1;
        data_in  = 8'h00;
        tx_start = 1'b0;


        // Reset
        repeat(5)
            @(posedge clk);

        rst = 1'b0;


        // =================================
        // Test 1 : Send A5
        // =================================

        data_in  = 8'hA5;
        tx_start = 1'b1;

        @(posedge clk);

        tx_start = 1'b0;

        wait(tx_busy == 1'b1);

        wait(tx_busy == 1'b0);

        $display("TX TEST 1 PASSED : DATA = A5");


        // =================================
        // Test 2 : Send 55
        // =================================

        repeat(10)
            @(posedge clk);

        data_in  = 8'h55;
        tx_start = 1'b1;

        @(posedge clk);

        tx_start = 1'b0;

        wait(tx_busy == 1'b1);

        wait(tx_busy == 1'b0);

        $display("TX TEST 2 PASSED : DATA = 55");


        // =================================
        // Test 3 : Send F0
        // =================================

        repeat(10)
            @(posedge clk);

        data_in  = 8'hF0;
        tx_start = 1'b1;

        @(posedge clk);

        tx_start = 1'b0;

        wait(tx_busy == 1'b1);

        wait(tx_busy == 1'b0);

        $display("TX TEST 3 PASSED : DATA = F0");


        // =================================
        // Finish simulation
        // =================================

        repeat(20)
            @(posedge clk);

        $display("--------------------------------");
        $display("UART TX TEST COMPLETED");
        $display("--------------------------------");

        $finish;

    end


    // --------------------------------
    // Monitor
    // --------------------------------
    always @(posedge clk) begin

        if (tx_busy) begin

            $display(
                "TIME=%0t | TX=%b | BUSY=%b",
                $time,
                tx,
                tx_busy
            );

        end

    end

endmodule
