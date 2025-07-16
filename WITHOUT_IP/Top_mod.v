`timescale 1ps/1fs
module m_cordic (
    input clock,
    input signed [31:0] angle,
    input signed [15:0] Xin,  // Scaled by K_inv
    input signed [15:0] Yin,
    output reg signed [16:0] Xout,
    output reg signed [16:0] Yout
);
    parameter STG = 10;
    

    // Arctangent table
    wire signed [31:0] atan_table [0:STG-1];
    assign atan_table[0]  = 32'h20000000; // arctan(2^-0)
    assign atan_table[1]  = 32'h12E4051E; // arctan(2^-1)
    assign atan_table[2]  = 32'h09FB385B; // arctan(2^-2)
    assign atan_table[3]  = 32'h051111D4; // arctan(2^-3)
    assign atan_table[4]  = 32'h028B0D43; // arctan(2^-4)
    assign atan_table[5]  = 32'h0145D7E1; // arctan(2^-5)
    assign atan_table[6]  = 32'h00A2F61E; // arctan(2^-6)
    assign atan_table[7]  = 32'h00517C55; // arctan(2^-7)
    assign atan_table[8]  = 32'h0028BE53; // arctan(2^-8)
    assign atan_table[9]  = 32'h00145F2F; // arctan(2^-9)

    // Pipeline registers
    reg signed [16:0] X [0:STG];
    reg signed [16:0] Y [0:STG];
    reg signed [31:0] Z [0:STG];

    // Initial rotation based on quadrant
    wire [1:0] quadrant = angle[31:30];
    always @(posedge clock) begin
        case (quadrant)
            2'b00, 2'b11: begin
                X[0] <= Xin;
                Y[0] <= Yin;
                Z[0] <= angle;
            end
            2'b01: begin
                X[0] <= -Yin;
                Y[0] <= Xin;
                Z[0] <= {2'b00, angle[29:0]};
            end
            2'b10: begin
                X[0] <= Yin;
                Y[0] <= -Xin;
                Z[0] <= {2'b11, angle[29:0]};
            end
        endcase
    end

    // CORDIC rotation stages
    genvar i;
    generate
        for (i = 0; i < STG; i = i + 1) begin: cordic_stage
            always @(posedge clock) begin
                if (Z[i][31] == 1'b1) begin
                    X[i+1] <= X[i] + (Y[i] >>> i);
                    Y[i+1] <= Y[i] - (X[i] >>> i);
                    Z[i+1] <= Z[i] + atan_table[i];
                end else begin
                    X[i+1] <= X[i] - (Y[i] >>> i);
                    Y[i+1] <= Y[i] + (X[i] >>> i);
                    Z[i+1] <= Z[i] - atan_table[i];
                end
            end
        end
    endgenerate

    always@(posedge clock)
    begin
        #2 Xout = X[STG];
        #2 Yout = Y[STG];
    end
//    assign #10 Xout = X[STG];
//    assign #10 Yout = Y[STG];
endmodule
