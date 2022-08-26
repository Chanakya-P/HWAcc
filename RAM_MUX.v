
module RAM_MUX(Data0, Data1, Addr0, Addr1, Clk, we, CS, Y); //CS = Chip Select
    input [7:0] Data0,Data1;
    input [5:0] Addr0, Addr1;
    input we, CS, Clk;
    output [7:0] Y;
    reg [7:0] D_out;
    reg [7:0] M[0:63];
    always @ (posedge Clk)
    begin
        if(we && CS)
            M[Addr0] <= Data0;     //we=1 and CS=1 Data input is written in M at Addr specified
        else if(~we && CS)
            D_out <= M[Addr0];  //we=0 and CS=1 Data stored at specified Address is read from M and given as D_out
        else if(we && ~CS)
            M[Addr1] <= Data1;
        else if(~we && ~CS)
            D_out <= M[Addr1];  
        else
            D_out <= 8'bz;
        end
    assign Y = (~we) ? D_out:8'bz;
endmodule
    