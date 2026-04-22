# FPGA_FLAPPYBIRD_PROJECT
A fully hardware-accelerated Flappy Bird clone written in Verilog HDL for the Xilinx Nexys 4 DDR (Artix-7) FPGA. This project bypasses traditional microprocessors, implementing game logic, physics, VGA rendering, and audio synthesis entirely through digital logic circuits.
Key Features
Hardware Physics Engine: Real-time gravity and "thruster" flight mechanics calculated at 60 FPS, synchronized with the VGA Vertical Sync (VSYNC).

VGA Graphics Controller: Custom 640x480 @ 60Hz controller rendering a stylized "smiling" bird character, scrolling obstacles, and a multi-layered background (Sun, Clouds, and Sky).

Procedural Obstacle Generation: Utilizes a Linear Feedback Shift Register (LFSR) to generate pseudorandom pipe gap heights for infinite replayability.

BCD Scoreboard: A dual-mode scoring system (Current Score & High Score) displayed via time-division multiplexing on the 8-digit 7-segment display.

Real-time Audio: PWM-based sound synthesis for jump and collision sound effects.

Hardware Architecture
The system is divided into several specialized modules:

Top Module: The central hub for state machine management and color multiplexing.

VGA Controller: Manages pixel timing, HSync/VSync pulses, and coordinate generation.

Clock Divider: Scales the 100MHz onboard crystal down to the 25.175MHz pixel clock.

Sound FX: A frequency-square-wave generator for game events.

7-Segment Control: A BCD-to-7-segment decoder with an integrated refresh counter for display multiplexing.

Technical Implementation Details
Language: Verilog HDL

Hardware: Nexys 4 DDR (Artix-7 XC7A100T-1CSG324C)

Toolchain: Vivado Design Suite

I/O Utilization: VGA Port, Mono Audio Jack, 7-Segment Display, and Pushbuttons.

How to Run
Open the project in Vivado.

Add the .v source files and the .xdc constraint file.

Generate the Bitstream.

Connect your Nexys 4 DDR and program the device.

Connect a VGA monitor and speakers/headphones to experience the game.
