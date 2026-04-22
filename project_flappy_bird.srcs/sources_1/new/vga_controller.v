`timescale 1ns / 1ps

module vga_controller(
    input clk_25MHz,
    output reg hsync,
    output reg vsync,
    output reg [9:0] x_pos = 0,
    output reg [9:0] y_pos = 0,
    output video_on
);

    // Standard VGA 640x480 @ 60Hz timing constants
    localparam H_DISPLAY       = 640;
    localparam H_FRONT_PORCH   = 16;
    localparam H_SYNC_PULSE    = 96;
    localparam H_BACK_PORCH    = 48;
    localparam H_TOTAL         = 800;

    localparam V_DISPLAY       = 480;
    localparam V_FRONT_PORCH   = 10;
    localparam V_SYNC_PULSE    = 2;
    localparam V_BACK_PORCH    = 33;
    localparam V_TOTAL         = 525;

    // Pixel Counters (Horizontal and Vertical)
    always @(posedge clk_25MHz) begin
        if (x_pos == H_TOTAL - 1) begin
            x_pos <= 0;
            if (y_pos == V_TOTAL - 1) begin
                y_pos <= 0;
            end else begin
                y_pos <= y_pos + 1;
            end
        end else begin
            x_pos <= x_pos + 1;
        end
    end

    // Sync Signal Generation (Active Low)
    always @(posedge clk_25MHz) begin
        hsync <= ~(x_pos >= (H_DISPLAY + H_FRONT_PORCH) && x_pos < (H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE));
        vsync <= ~(y_pos >= (V_DISPLAY + V_FRONT_PORCH) && y_pos < (V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE));
    end

    // video_on tells us when we are in the visible 640x480 screen area
    assign video_on = (x_pos < H_DISPLAY) && (y_pos < V_DISPLAY);

endmodule
