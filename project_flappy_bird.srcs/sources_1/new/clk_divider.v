`timescale 1ns / 1ps

module clk_divider(
    input clk_100MHz,
    output reg clk_25MHz = 0
);

    reg [1:0] counter_val = 0;

    always @(posedge clk_100MHz) begin
        if (counter_val == 1) begin
            clk_25MHz <= ~clk_25MHz; // Toggle the clock
            counter_val <= 0;        // Reset the counter
        end else begin
            counter_val <= counter_val + 1;
        end
    end

endmodule
