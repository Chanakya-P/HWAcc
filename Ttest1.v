`timescale 1us / 1us
`include "i2c_master.v"
`include "i2c_slave.v"
`include "RAM_MUX.v"
`include "my8085.v"

module Ttest1();

output reg RST_, READY, HOLD, SID, INTR, TRAP, RST75, RST65, RST55;
wire [7:0] ADDRDATA;
input wire [15:8] ADDR;
input wire CLK_OUT, RST_OUT, IOM_, S1, S0, INTA_, WR_, RD_, ALE, HLDA, SOD;
integer i;
reg [7:0] memory [65535:0];


/*RAM_64x8bit ram(
               // Inouts
               .Data                    (ADDRDATA[7:0]),
               // Inputs
               .Addr                    (ADDR[15:0]),
               .Clk                     (CLK),
               .CS                    (IOM_),
               .we                    (WR_),
               .q());
*/

    real clockDelay50 = ((1/ (50e9))/2)*(1e9);
    reg main_clk = 0;
    reg rst = 1;
		 
    //clock gen
	always begin
	  #clockDelay50;
	  main_clk = ~main_clk;
	end

    wire scl;
    wire sda;
	 
	pullup p1(scl); // pullup scl line
	pullup p2(sda); // pullup sda line
	
	reg enable = 0;
	reg rw = 0;
	reg [7:0] mosi = 0;
	reg [7:0] reg_addr = 0;
    reg [6:0] device_addr = 7'b001_0001;       
    reg [15:0] divider = 16'h0003;
    
    wire [7:0] miso;
    wire       busy;

	 
	 
/*
RAM_64x8bit ram(
               // Inouts
               .Data                    (miso[7:0]),
               // Inputs
               .Addr                    (reg_addr[7:0]),
               .Clk                     (i_clk),
               .CS                    (1),
               .we                    (~rw),
               .q());
*/

    reg  [7:0] read_data = 0;
    wire [7:0] data_to_write_1 = 8'hDC;
    wire [7:0] data_to_write_2 = 8'hAB;
    wire [7:0] data_to_write_3 = 8'hEF;
    reg  [7:0] proc_cntr = 0;	 


    i2c_slave i2c_slave_model_inst(
        .scl(scl),
        .sda(sda)
    );

	i2c_master #(.DATA_WIDTH(8),.REG_WIDTH(8),.ADDR_WIDTH(7)) 
        i2c_master_inst(
            .i_clk(main_clk),
            .i_rst(rst),
            .i_enable(enable),
            .i_rw(rw),
            .i_mosi_data(mosi),
            .i_reg_addr(reg_addr),
            .i_device_addr(device_addr),
            .i_divider(divider),
            .o_miso_data(miso),
            .o_busy(busy),
            .io_sda(sda),
            .io_scl(scl)
    );

RAM_MUX ram(
               // Inouts
               .Data0                    (miso[7:0]),
               .Data1                    (ADDRDATA[7:0]),
               // Inputs
               .Addr0                    (reg_addr[7:0]),
               .Addr1                    (reg_addr[7:0]), 
               .Clk                     (main_clk),
               .CS                    (busy),
               .we                    (~rw),
               .Y());

my8085 uut(main_clk, ADDRDATA, ADDR, INTA, INTR, RST55, RST65, RST75, TRAP, SID, SOD, RST_OUT, HOLD, HLDA, CLK_OUT, RST_, READY, IOM_, S1, RD_, WR_, S0, ALE, miso[7:0]);

initial begin
	$readmemh("mem.txt",memory);
end

initial begin
	$dumpfile("dumpfile1.vcd");
	$dumpvars(0, Ttest1);
end

/*
initial begin CLK <= 0;
	RST_ <= 1;
	for(i=0;i<480;i=i+1)
		#5 CLK <= ~CLK;
end
*/

reg [7:0] data;
reg [15:0] addr;
always @(posedge main_clk) begin
	if(ALE)
	begin
		addr[15:8] <= ADDR [15:8];
		addr[7:0] <= ADDRDATA [7:0];
	end
end

always @(RD_) begin
	if(~RD_ && ~IOM_)
	begin
		data <= memory[addr];
	end
end

always @(posedge main_clk) begin
	if(~WR_ && ~IOM_)
	begin
		memory[addr] <= ADDRDATA;
	end
end


initial begin
	addr <= 16'h0000;
	RST_ <= 0;
#10
	RST_ <= 1;
end

assign ADDRDATA = (~RD_) ? data : 8'bz;


	always@(posedge main_clk)begin
        if(proc_cntr < 20 && proc_cntr > 13)begin
            proc_cntr <= proc_cntr + 1;
        end
        case (proc_cntr)
            0: begin
                rst <= 1;
                proc_cntr <= proc_cntr + 1;
            end
            1: begin
                rst <= 0;
                proc_cntr <= proc_cntr + 1;
            end
            //set configration first
            2: begin
                rw <= 0; //write operation
                reg_addr <= 8'h00; //writing to slave register 0
                mosi <= data_to_write_1; //data to be written
                device_addr = 7'b001_0001; //slave address
                divider = 16'hFFFF; //divider value for i2c serial clock
                proc_cntr <= proc_cntr + 1;
            end
            3: begin
                //if master is not busy set enable high
                if(busy == 0)begin
                    enable <= 1;
                    $display("Enabled write");
                    proc_cntr <= proc_cntr + 1;
                end
            end
            4: begin
                //once busy set enable low
                if(busy == 1)begin
                    enable <= 0;
                    proc_cntr <= proc_cntr + 1;
                end
            end
            
            //set configration first
            5: begin
                //as soon as busy is low again an operation has been completed
                if(busy == 0) begin
                    proc_cntr <= proc_cntr + 1;
                    end
            end
            6: begin
                rw <= 0; //write operation
                reg_addr <= 8'h01; //writing to slave register 1
                mosi <= data_to_write_2; //data to be written
                device_addr = 7'b001_0001; //slave address
                divider = 16'hFFFF; //divider value for i2c serial clock
                proc_cntr <= proc_cntr + 1;
            end
            7: begin
                //if master is not busy set enable high
                if(busy == 0)begin
                    enable <= 1;
                    $display("Enabled write");
                    proc_cntr <= proc_cntr + 1;
                end
            end
            8: begin
                //once busy set enable low
                if(busy == 1)begin
                    enable <= 0;
                    proc_cntr <= proc_cntr + 1;
                end
            end
            
            //set configration first
            9: begin
                //as soon as busy is low again an operation has been completed
                if(busy == 0) begin
                    proc_cntr <= proc_cntr + 1;
                end
            end
            10: begin
                rw <= 0; //write operation
                reg_addr <= 8'h02; //writing to slave register 1
                mosi <= data_to_write_3; //data to be written
                device_addr = 7'b001_0001; //slave address
                divider = 16'hFFFF; //divider value for i2c serial clock
                proc_cntr <= proc_cntr + 1;
            end
            11: begin
                //if master is not busy set enable high
                if(busy == 0)begin
                    enable <= 1;
                    $display("Enabled write");
                    proc_cntr <= proc_cntr + 1;
                end
            end
            12: begin
                //once busy set enable low
                if(busy == 1)begin
                    enable <= 0;
                    proc_cntr <= proc_cntr + 1;
                end
            end
            
            //set configration first
            13: begin
                //as soon as busy is low again an operation has been completed
                if(busy == 0) begin
                    proc_cntr <= proc_cntr + 1;
                    $display("Master done writing");
                end
            end
            20: begin
                rw <= 1; //read operation
                reg_addr <= 8'h00; //writing to slave register 0
                mosi <= data_to_write_1; //data to be written
                device_addr = 7'b001_0001; //slave address
                divider = 16'hFFFF; //divider value for i2c serial clock
                proc_cntr <= proc_cntr + 1;
            end
            21: begin
                if(busy == 0)begin
                    enable <= 1;
                    $display("Enabled read");
                    proc_cntr <= proc_cntr + 1;
                end
            end
            22: begin
                if(busy == 1)begin
                    enable <= 0;
                    proc_cntr <= proc_cntr + 1;
                end
            end
            23: begin
                if(busy == 0)begin
                    read_data <= miso;
                    proc_cntr <= proc_cntr + 1;
                    $display("Master done reading");
                end
            end
            24: begin
                if(read_data == data_to_write_1)begin
                    $display("Read back correct data!");
                end
                else begin
                    $display("Read back incorrect data!");
                end
proc_cntr <= proc_cntr + 1;

            end
            25: begin
                rw <= 1; //read operation
                reg_addr <= 8'h01; //writing to slave register 0
                mosi <= data_to_write_2; //data to be written
                device_addr = 7'b001_0001; //slave address
                divider = 16'hFFFF; //divider value for i2c serial clock
                proc_cntr <= proc_cntr + 1;
            end
            26: begin
                if(busy == 0)begin
                    enable <= 1;
                    $display("Enabled read");
                    proc_cntr <= proc_cntr + 1;
                end
            end
            27: begin
                if(busy == 1)begin
                    enable <= 0;
                    proc_cntr <= proc_cntr + 1;
                end
            end
            28: begin
                if(busy == 0)begin
                    read_data <= miso;
                    proc_cntr <= proc_cntr + 1;
                    $display("Master done reading");
                end
            end
            29: begin
                if(read_data == data_to_write_2)begin
                    $display("Read back correct data!");

                end
                else begin
                    $display("Read back incorrect data!");

                end
proc_cntr <= proc_cntr + 1;

            end
            30: begin
                rw <= 1; //read operation
                reg_addr <= 8'h02; //writing to slave register 0
                mosi <= data_to_write_3; //data to be written
                device_addr = 7'b001_0001; //slave address
                divider = 16'hFFFF; //divider value for i2c serial clock
                proc_cntr <= proc_cntr + 1;
            end
            31: begin
                if(busy == 0)begin
                    enable <= 1;
                    $display("Enabled read");
                    proc_cntr <= proc_cntr + 1;
                end
            end
            32: begin
                if(busy == 1)begin
                    enable <= 0;
                    proc_cntr <= proc_cntr + 1;
                end
            end
            33: begin
                if(busy == 0)begin
                    read_data <= miso;
                    proc_cntr <= proc_cntr + 1;
                    $display("Master done reading");
                end
            end
            34: begin
                if(read_data == data_to_write_3)begin
                    $display("Read back correct data!");
                end
                else begin
                    $display("Read back incorrect data!");
                end
              $stop;
            end

        endcase 
	
	end

endmodule


