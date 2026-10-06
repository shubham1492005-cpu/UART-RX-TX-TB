`timescale 1ns/1ps

module tb_uart_rx;

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
    reg rx;

    wire [7:0] data_out;
    wire       data_valid;


    // --------------------------------
    // DUT
    // --------------------------------
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .data_out(data_out),
        .data_valid(data_valid)
    );


    // --------------------------------
    // Clock Generation
    // 10 ns period
    // --------------------------------
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // --------------------------------
    // UART Send Task
    // --------------------------------
    task send_byte;

        input [7:0] data;
        integer i;

        begin

            // -------------------------
            // Start bit
            // -------------------------
            rx = 1'b0;

            repeat(CLKS_PER_BIT)
                @(posedge clk);


            // -------------------------
            // Data bits
            // LSB first
            // -------------------------
            for(i = 0; i < 8; i = i + 1) begin

                rx = data[i];

                repeat(CLKS_PER_BIT)
                    @(posedge clk);

            end


            // -------------------------
            // Stop bit
            // -------------------------
            rx = 1'b1;

            repeat(CLKS_PER_BIT)
                @(posedge clk);

        end

    endtask


    // --------------------------------
    // Test
    // --------------------------------
    initial begin

        // Initial values
        rx  = 1'b1;
        rst = 1'b1;


        // Reset
        repeat(5)
            @(posedge clk);

        rst = 1'b0;


        // =================================
        // TEST 1 : A5
        // =================================

        send_byte(8'hA5);

        wait(data_valid == 1'b1);

        if(data_out == 8'hA5)
            $display("RX TEST 1 PASSED : DATA = %h", data_out);
        else
            $display("RX TEST 1 FAILED : DATA = %h", data_out);


        repeat(10)
            @(posedge clk);


        // =================================
        // TEST 2 : 55
        // =================================

        send_byte(8'h55);

        wait(data_valid == 1'b1);

        if(data_out == 8'h55)
            $display("RX TEST 2 PASSED : DATA = %h", data_out);
        else
            $display("RX TEST 2 FAILED : DATA = %h", data_out);


        repeat(10)
            @(posedge clk);


        // =================================
        // TEST 3 : F0
        // =================================

        send_byte(8'hF0);

        wait(data_valid == 1'b1);

        if(data_out == 8'hF0)
            $display("RX TEST 3 PASSED : DATA = %h", data_out);
        else
            $display("RX TEST 3 FAILED : DATA = %h", data_out);


        // =================================
        // Finish
        // =================================

        repeat(20)
            @(posedge clk);

        $display("--------------------------------");
        $display("UART RX TEST COMPLETED");
        $display("--------------------------------");

        $finish;

    end


    // --------------------------------
    // Monitor
    // --------------------------------
    always @(posedge clk) begin

        if(data_valid) begin

            $display(
                "TIME=%0t | RX DATA=%h | VALID=%b",
                $time,
                data_out,
                data_valid
            );

        end

    end

endmodule
