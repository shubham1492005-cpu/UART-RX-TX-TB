module uart_rx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,

    output reg [7:0]  data_out,
    output reg        data_valid
);

    // Number of clock cycles per UART bit
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // Half bit time for center sampling of start bit
    localparam integer HALF_BIT = CLKS_PER_BIT / 2;

    // FSM states
    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;

    reg [2:0] state;

    reg [15:0] baud_counter;
    reg [3:0]  bit_counter;

    reg [7:0] rx_data;

    // Synchronizer for asynchronous RX input
    reg rx_sync1;
    reg rx_sync2;


    always @(posedge clk) begin

        if (rst) begin

            state        <= IDLE;

            baud_counter <= 0;
            bit_counter  <= 0;

            rx_data      <= 0;
            data_out     <= 0;
            data_valid   <= 0;

            rx_sync1     <= 1'b1;
            rx_sync2     <= 1'b1;

        end

        else begin

            // Synchronize RX signal
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;

            // Default: data_valid is only one clock pulse
            data_valid <= 1'b0;


            case (state)

                // =================================
                // IDLE
                // =================================
                IDLE: begin

                    baud_counter <= 0;
                    bit_counter  <= 0;

                    // Detect start bit
                    if (rx_sync2 == 1'b0) begin
                        state <= START;
                    end

                end


                // =================================
                // START BIT
                // =================================
                START: begin

                    // Move to center of start bit
                    if (baud_counter == HALF_BIT - 1) begin

                        baud_counter <= 0;

                        // Confirm start bit
                        if (rx_sync2 == 1'b0) begin
                            state <= DATA;
                        end
                        else begin
                            state <= IDLE;
                        end

                    end

                    else begin
                        baud_counter <= baud_counter + 1;
                    end

                end


                // =================================
                // DATA BITS
                // =================================
                DATA: begin

                    // Wait one complete bit period
                    if (baud_counter == CLKS_PER_BIT - 1) begin

                        baud_counter <= 0;

                        // Receive LSB first
                        rx_data[bit_counter] <= rx_sync2;

                        if (bit_counter == 7) begin

                            bit_counter <= 0;
                            state <= STOP;

                        end

                        else begin

                            bit_counter <= bit_counter + 1;

                        end

                    end

                    else begin
                        baud_counter <= baud_counter + 1;
                    end

                end


                // =================================
                // STOP BIT
                // =================================
                STOP: begin

                    if (baud_counter == CLKS_PER_BIT - 1) begin

                        baud_counter <= 0;

                        // Stop bit must be HIGH
                        if (rx_sync2 == 1'b1) begin

                            data_out   <= rx_data;
                            data_valid <= 1'b1;

                        end

                        state <= IDLE;

                    end

                    else begin
                        baud_counter <= baud_counter + 1;
                    end

                end


                // =================================
                // DEFAULT
                // =================================
                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule
