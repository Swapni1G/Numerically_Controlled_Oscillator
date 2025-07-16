`timescale 1ps/1fs
module tb_cordic;
    reg clk = 0;
    reg signed [31:0] angle = 0;
    reg signed [15:0] Xin = 16'd19998;  // ≈ 0.607253 * 2^15
    reg signed [15:0] Yin = 0;

    wire signed [16:0] sin_out, cos_out;

    m_cordic dut (
        .clock(clk),
        .angle(angle),
        .Xin(Xin),
        .Yin(Yin),
        .Xout(cos_out),
        .Yout(sin_out)
    );

    always #1 clk = ~clk;
    reg [2:0] count=0;
    reg slow_clk=0;
    always @(posedge clk)
    begin
        if(count!=5)    
            count<=count+1;
        else
            begin
                count<=0;
                slow_clk=~slow_clk;
            end    
    end
    
    localparam PHASE_INC = 32'h088F5C28; 
    integer i;

    initial begin

        #10;

        for (i = 0; i < 100; i = i + 1) begin
            @(posedge slow_clk);
            angle = angle + PHASE_INC;
        end

        $finish;
    end


endmodule
