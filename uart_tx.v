module uart_tx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data_in,
    input  wire       tx_start,
    output reg        tx,
    output reg        tx_busy
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;

    reg [2:0] state;
    reg [15:0] baud_counter;
    reg [2:0] bit_counter;
    reg [7:0] tx_data;

    always @(posedge clk) begin

        if (rst) begin
            state        <= IDLE;
            baud_counter <= 0;
            bit_counter  <= 0;
            tx_data      <= 0;
            tx           <= 1'b1;
            tx_busy      <= 1'b0;
        end

        else begin

            case (state)

                IDLE: begin
                    tx           <= 1'b1;
                    tx_busy      <= 1'b0;
                    baud_counter <= 0;
                    bit_counter  <= 0;

                    if (tx_start) begin
                        tx_data <= data_in;
                        tx_busy <= 1'b1;
                        state   <= START;
                    end
                end

                START: begin
                    tx <= 1'b0;

                    if (baud_counter == CLKS_PER_BIT - 1) begin
                        baud_counter <= 0;
                        state <= DATA;
                    end
                    else begin
                        baud_counter <= baud_counter + 1;
                    end
                end

                DATA: begin
                    tx <= tx_data[bit_counter];

                    if (baud_counter == CLKS_PER_BIT - 1) begin
                        baud_counter <= 0;

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

                STOP: begin
                    tx <= 1'b1;

                    if (baud_counter == CLKS_PER_BIT - 1) begin
                        baud_counter <= 0;
                        tx_busy <= 1'b0;
                        state <= IDLE;
                    end
                    else begin
                        baud_counter <= baud_counter + 1;
                    end
                end

                default: begin
                    state <= IDLE;
                    tx <= 1'b1;
                end

            endcase

        end

    end

endmodule
