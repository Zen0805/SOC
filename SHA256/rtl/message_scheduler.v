//-----------------------------------------------------------------------------
// Module: message_scheduler
// Author: ThgLeTuan
// Description: Implements the SHA-256 message scheduler based on Fig. 5 and Table 2.
//              Generates W[t] for rounds t = 0 to 63.
//-----------------------------------------------------------------------------
module message_scheduler (
    input wire clk,         // Clock signal
    input wire rst_n,       // Asynchronous reset (active low)
    input wire load_en,     // Enable signal to load the initial message block
    input wire [511:0] message_block, // 512-bit message block input (M0 to M15)
    input wire next_round,  // Signal to advance to the next round's W calculation

    output wire [31:0] W_out,       // Scheduled word W[t] for the current round
    output wire        valid_out    // Indicates W_out is valid for the current round
);

    parameter WORD_WIDTH = 32;
    parameter NUM_WORDS  = 16; // Number of words in the internal buffer (W[t-16] to W[t-1])

    // Internal register file to hold the last 16 W values
    reg [WORD_WIDTH-1:0] W_reg [0:NUM_WORDS-1];

    // Round counter (0 to 63)
    reg [5:0] round_idx; // Needs 6 bits for 0-63

    // Wires for intermediate calculations (t >= 16)
    wire [WORD_WIDTH-1:0] w_im2;   // W[t-2]
    wire [WORD_WIDTH-1:0] w_im7;   // W[t-7]
    wire [WORD_WIDTH-1:0] w_im15;  // W[t-15]
    wire [WORD_WIDTH-1:0] w_im16;  // W[t-16]

    wire [WORD_WIDTH-1:0] s0_out;   // Output of sigma0(W[t-15])
    wire [WORD_WIDTH-1:0] s1_out;   // Output of sigma1(W[t-2])

    wire [WORD_WIDTH-1:0] W_calculated; // Result of W calculation for t >= 16

    // Indices for accessing W_reg (using modulo arithmetic implicitly)
    // These indices point to the required past W values RELATIVE to the *current* round_idx
    // Note: Verilog % operator behavior with negative numbers might differ, use explicit calculation.
    // The index calculation depends on how W_reg stores W[t].
    // Let W_reg[k] store W[t] where k = t mod 16.
    // Then W[t-2] is at index (t-2) mod 16 = (round_idx - 2) % 16
    //      W[t-7] is at index (t-7) mod 16 = (round_idx - 7) % 16
    //      W[t-15] is at index (t-15) mod 16 = (round_idx - 15) % 16
    //      W[t-16] is at index (t-16) mod 16 = (round_idx - 16) % 16 = round_idx % 16

    // Use intermediate signals for indices for clarity
    wire [3:0] idx_im2  = (round_idx - 2) % NUM_WORDS;
    wire [3:0] idx_im7  = (round_idx - 7) % NUM_WORDS;
    wire [3:0] idx_im15 = (round_idx - 15) % NUM_WORDS;
    wire [3:0] idx_im16 = round_idx % NUM_WORDS; // W[t-16] is overwritten by W[t]

    // Read values from the register file based on indices
    assign w_im2  = W_reg[idx_im2];
    assign w_im7  = W_reg[idx_im7];
    assign w_im15 = W_reg[idx_im15];
    assign w_im16 = W_reg[idx_im16];

    // Instantiate sigma functions
    sigma0_func_schedule s0_inst (
        .data_in (w_im15),
        .data_out(s0_out)
    );

    sigma1_func_schedule s1_inst (
        .data_in (w_im2),
        .data_out(s1_out)
    );

    // Calculate W[t] for t >= 16 according to the formula:
    // W[t] = sigma1(W[t-2]) + W[t-7] + sigma0(W[t-15]) + W[t-16]
    // Use non-blocking assignments inside always block for additions if pipelining is desired,
    // or combinational logic here assumes adder can complete in one cycle.
    assign W_calculated = s1_out + w_im7 + s0_out + w_im16;

    // State update logic (registers and round counter)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous reset
            round_idx <= 6'd0;
            // Optionally clear W_reg on reset
             for (int i = 0; i < NUM_WORDS; i = i + 1) begin
                 W_reg[i] <= {WORD_WIDTH{1'b0}};
             end
        end else begin
            if (load_en) begin
                // Load initial message block (M0 to M15) into W_reg (W0 to W15)
                round_idx <= 6'd0;
                for (int i = 0; i < NUM_WORDS; i = i + 1) begin
                    W_reg[i] <= message_block[(NUM_WORDS-1-i)*WORD_WIDTH +: WORD_WIDTH]; // M0 in W_reg[0], M1 in W_reg[1], ..., M15 in W_reg[15]
                    // Correct indexing might depend on message_block endianness assumption
                    // Assuming message_block[511:480] is M0, [479:448] is M1, ... [31:0] is M15
                    // W_reg[0] <= message_block[511:480];
                    // W_reg[1] <= message_block[479:448]; ...
                    W_reg[i] <= message_block[WORD_WIDTH*(NUM_WORDS-i)-1 -: WORD_WIDTH];
                end
            end else if (next_round && round_idx < 64) begin
                // Advance to the next round if enabled and not finished
                if (round_idx >= 15) begin // Start calculating and updating W from round 16 onwards
                    // Calculate W[t] (where t = round_idx + 1, starting from t=16)
                    // Store the newly calculated W[t] into the register file, overwriting W[t-16]
                    // The calculation itself (W_calculated) is done combinationally outside this block
                    // We store the result for the *next* round index 'round_idx + 1'
                    // The index to write is (round_idx + 1) mod 16, which simplifies to idx_im16 of the *next* cycle.
                    // Or simply, W_calculated is for round t=round_idx, store it at index round_idx % 16.
                    W_reg[round_idx % NUM_WORDS] <= W_calculated;
                end
                // Increment round index only if not finished (prevents wrap around beyond 63)
                 if (round_idx < 63) begin
                    round_idx <= round_idx + 1;
                 end
            end
        end
    end

    // Output logic: Provide the W value for the current round_idx
    // For t < 16, W[t] = M[t] (already loaded into W_reg)
    // For t >= 16, W[t] was calculated in the previous cycle and stored in W_reg[t mod 16]
    assign W_out = (round_idx < NUM_WORDS) ? W_reg[round_idx] : W_reg[round_idx % NUM_WORDS];
                // For round 16, W_out should be the calculated W[16] which replaced W[0].
                // The current implementation calculates W[t] combinationally based on W_reg state *before* the clock edge,
                // and stores it on the clock edge. The output reflects the W for the current `round_idx`.

    // Valid signal - High when the scheduler is not being reset or loaded and within rounds 0-63
    assign valid_out = (rst_n && !load_en && round_idx < 64);

endmodule
