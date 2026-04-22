`timescale 1ns / 1ps

module top(
    input clk_100MHz,
    input btn_jump,
    output [15:0] LED,
    output [6:0] seg,  
    output [7:0] an,   
    output reg [3:0] VGA_R, // Correctly declared as reg
    output reg [3:0] VGA_G, // Correctly declared as reg
    output reg [3:0] VGA_B, // Correctly declared as reg
    output VGA_HS,
    output VGA_VS,
    output AUD_PWM, 
    output AUD_SD   
);

    wire clk_25MHz;
    wire w_video_on;
    wire [9:0] w_x;
    wire [9:0] w_y;

    // --- Modules ---
    clk_divider clk_gen (.clk_100MHz(clk_100MHz), .clk_25MHz(clk_25MHz));
    
    vga_controller vga_ctrl (
        .clk_25MHz(clk_25MHz), .hsync(VGA_HS), .vsync(VGA_VS),
        .x_pos(w_x), .y_pos(w_y), .video_on(w_video_on)
    );

    reg [7:0] lfsr = 8'hA5; 
    always @(posedge clk_25MHz) begin
        lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    end

    // --- Game Logic Constants ---
    wire [9:0] bird_x = 100; 
    reg [9:0] bird_y = 232;       
    reg signed [9:0] velocity = 0; 
    wire [4:0] BIRD_SIZE = 16;

    reg [9:0] pipe_x = 640;     
    wire [6:0] PIPE_WIDTH = 64; 
    reg [9:0] gap_y = 180;      
    wire [6:0] GAP_SIZE = 120;  

    reg game_state = 0; 
    reg btn_prev = 0;   
    
    reg play_jump = 0;
    reg play_crash = 0;

    sound_fx audio_engine (
        .clk_100MHz(clk_100MHz), .play_jump(play_jump), .play_crash(play_crash),
        .aud_pwm(AUD_PWM), .aud_sd(AUD_SD)
    );
    
    reg [3:0] score_ones = 0, score_tens = 0, score_hundreds = 0;
    reg [3:0] hi_ones = 0, hi_tens = 0, hi_hundreds = 0;

    assign LED[15:0] = 16'b0; 

    seg7_control display (
        .clk_100MHz(clk_100MHz), 
        .ones(score_ones), .tens(score_tens), .hundreds(score_hundreds),
        .hi_ones(hi_ones), .hi_tens(hi_tens), .hi_hundreds(hi_hundreds),
        .an(an), .seg(seg)
    );

    // --- Game State & Physics ---
    always @(negedge VGA_VS) begin
        btn_prev <= btn_jump; 
        play_jump <= 0;
        play_crash <= 0;
        
        if (game_state == 0) begin
            if (btn_jump && !btn_prev) begin
                game_state <= 1;
                bird_y <= 232;
                velocity <= -6; 
                pipe_x <= 640;
                gap_y <= 180; 
                score_ones <= 0; score_tens <= 0; score_hundreds <= 0;
                play_jump <= 1; 
            end
        end else begin
            // Physics
            if (btn_jump) begin
                velocity <= -6;
                if (!btn_prev) play_jump <= 1; 
            end else begin
                if (velocity < 5) velocity <= velocity + 1; 
            end
            
            // Floor/Ceiling
            if ($signed({1'b0, bird_y}) + velocity <= 0) begin 
                bird_y <= 0; game_state <= 0; play_crash <= 1; 
            end else if ($signed({1'b0, bird_y}) + velocity >= 464) begin       
                bird_y <= 464; game_state <= 0; play_crash <= 1; 
            end else begin
                bird_y <= bird_y + velocity;
            end

            // Pipe Collision
            if ((pipe_x < 116) && (pipe_x > 36)) begin
                if ((bird_y < gap_y) || (bird_y + BIRD_SIZE > gap_y + GAP_SIZE)) begin
                    game_state <= 0; play_crash <= 1; 
                end
            end

            // Movement & Score
            if (pipe_x <= 3) begin
                pipe_x <= 640;
                gap_y <= 50 + lfsr; 
            end else begin
                pipe_x <= pipe_x - 3; 
            end
            
            if (pipe_x == 100) begin 
                if (score_ones == 9) begin
                    score_ones <= 0;
                    if (score_tens == 9) begin score_tens <= 0; score_hundreds <= score_hundreds + 1; end
                    else score_tens <= score_tens + 1;
                end else score_ones <= score_ones + 1;
            end

            // High Score
            if ({score_hundreds, score_tens, score_ones} > {hi_hundreds, hi_tens, hi_ones}) begin
                hi_hundreds <= score_hundreds; hi_tens <= score_tens; hi_ones <= score_ones;
            end
        end
    end

    // --- VGA Drawing Logic ---
    wire is_bird = (w_x >= bird_x) && (w_x < bird_x + BIRD_SIZE) && (w_y >= bird_y) && (w_y < bird_y + BIRD_SIZE);
    wire is_pipe = (w_x >= pipe_x) && (w_x < pipe_x + PIPE_WIDTH) && ((w_y < gap_y) || (w_y > gap_y + GAP_SIZE));
    wire is_sun  = (w_x >= 490) && (w_x < 590) && (w_y >= 30) && (w_y < 130);
    
    // Optimized Cloud Logic
    wire is_cloud = ((w_x >= 200 && w_x < 360 && w_y >= 100 && w_y < 160) || (w_x >= 240 && w_x < 320 && w_y >= 70 && w_y < 100)) ||
                    ((w_x >= 390 && w_x < 490 && w_y >= 180 && w_y < 220) || (w_x >= 410 && w_x < 460 && w_y >= 160 && w_y < 180));

    // Face Pixels
    wire eye1  = (w_x >= bird_x + 3) && (w_x < bird_x + 5) && (w_y >= bird_y + 4) && (w_y < bird_y + 6);
    wire eye2  = (w_x >= bird_x + 10)&& (w_x < bird_x + 12)&& (w_y >= bird_y + 4) && (w_y < bird_y + 6);
    wire mouth = (w_x >= bird_x + 5) && (w_x < bird_x + 11) && (w_y >= bird_y + 11) && (w_y < bird_y + 12);
    wire is_face = eye1 || eye2 || mouth;

    // Color Multiplexer
    always @(*) begin
        if (!w_video_on) begin
            VGA_R = 4'h0; VGA_G = 4'h0; VGA_B = 4'h0;
        end else if (is_bird) begin
            if (is_face) begin
                VGA_R = 4'h0; VGA_G = 4'h0; VGA_B = 4'h0; // Black eyes/mouth
            end else begin
                VGA_R = 4'hF; VGA_G = 4'hF; VGA_B = 4'h0; // Yellow body
            end
        end else if (is_pipe) begin
            VGA_R = 4'h0; VGA_G = 4'hD; VGA_B = 4'h0; // Green pipe
        end else if (is_cloud) begin
            VGA_R = 4'hE; VGA_G = 4'hE; VGA_B = 4'hE; // White cloud
        end else if (is_sun) begin
            VGA_R = 4'hF; VGA_G = 4'hD; VGA_B = 4'h0; // Orange sun
        end else begin
            VGA_R = 4'h0; VGA_G = 4'hA; VGA_B = 4'hF; // Blue sky
        end
    end

endmodule