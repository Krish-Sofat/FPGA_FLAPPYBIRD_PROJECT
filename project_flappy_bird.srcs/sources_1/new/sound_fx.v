`timescale 1ns / 1ps

module sound_fx(
    input clk_100MHz,
    input play_jump,
    input play_crash,
    output reg aud_pwm = 0,
    output aud_sd
);
    // The Nexys 4 has an audio amplifier. We must pull the SD (Shutdown) pin HIGH to turn it on.
    assign aud_sd = 1'b1; 

    reg [19:0] tone_counter = 0;
    reg [19:0] max_count = 0;
    reg [24:0] duration_counter = 0;

    always @(posedge clk_100MHz) begin
        
        // 1. Trigger Jump Sound (High pitch ~1000 Hz, short duration)
        if (play_jump) begin
            max_count <= 50_000; 
            duration_counter <= 10_000_000; // 0.1 seconds
        end
        // 2. Trigger Crash Sound (Low pitch ~200 Hz, longer duration)
        else if (play_crash) begin
            max_count <= 250_000; 
            duration_counter <= 30_000_000; // 0.3 seconds
        end
        // 3. Play the Sound
        else if (duration_counter > 0) begin
            duration_counter <= duration_counter - 1;
            // Toggle the audio pin to create a square wave tone
            if (tone_counter >= max_count) begin
                tone_counter <= 0;
                aud_pwm <= ~aud_pwm;
            end else begin
                tone_counter <= tone_counter + 1;
            end
        end
        // 4. Silence
        else begin
            aud_pwm <= 0;
        end
        
    end
endmodule