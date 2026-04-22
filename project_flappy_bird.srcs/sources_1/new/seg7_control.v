`timescale 1ns / 1ps

module seg7_control(
    input clk_100MHz,
    // Current Score Inputs
    input [3:0] ones,
    input [3:0] tens,
    input [3:0] hundreds,
    // NEW: High Score Inputs
    input [3:0] hi_ones,
    input [3:0] hi_tens,
    input [3:0] hi_hundreds,
    output reg [7:0] an,
    output reg [6:0] seg
);

    reg [19:0] refresh_counter = 0;
    // CHANGED: We now need 3 bits (0 to 7) to cycle through all 8 digits
    wire [2:0] digit_select = refresh_counter[19:17]; 
    reg [3:0] current_digit;

    always @(posedge clk_100MHz) begin
        refresh_counter <= refresh_counter + 1;
    end

    always @(*) begin
        an = 8'b11111111; // Turn all OFF initially
        
        case(digit_select)
            // --- Current Score (Right Side) ---
            3'b000: begin an = 8'b11111110; current_digit = ones;        end // Digit 0
            3'b001: begin an = 8'b11111101; current_digit = tens;        end // Digit 1
            3'b010: begin an = 8'b11111011; current_digit = hundreds;    end // Digit 2
            
            // --- Blank Middle Gap ---
            3'b011: begin an = 8'b11110111; current_digit = 4'hF;        end // Digit 3 (F = Blank)
            3'b100: begin an = 8'b11101111; current_digit = 4'hF;        end // Digit 4
            
            // --- High Score (Left Side) ---
            3'b101: begin an = 8'b11011111; current_digit = hi_ones;     end // Digit 5
            3'b110: begin an = 8'b10111111; current_digit = hi_tens;     end // Digit 6
            3'b111: begin an = 8'b01111111; current_digit = hi_hundreds; end // Digit 7
            default: current_digit = 4'hF; 
        endcase
    end

    // Hex to 7-Segment Decoder
    always @(*) begin
        case(current_digit)
            4'h0: seg = 7'b1000000; 
            4'h1: seg = 7'b1111001; 
            4'h2: seg = 7'b0100100; 
            4'h3: seg = 7'b0110000; 
            4'h4: seg = 7'b0011001; 
            4'h5: seg = 7'b0010010; 
            4'h6: seg = 7'b0000010; 
            4'h7: seg = 7'b1111000; 
            4'h8: seg = 7'b0000000; 
            4'h9: seg = 7'b0010000; 
            default: seg = 7'b1111111; // Blank
        endcase
    end

endmodule