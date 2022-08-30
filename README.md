Name	Type	Width	Direction	Description
i_clk	wire	1	input	Main system clock (note: not the actual I2C SCL)
i_rst	wire	1	input	Active high reset
i_enable	wire	1	input	Active high enable signal that begins a transaction if master is not busy
i_rw	wire	1	input	i_rw = 0 will signify a WRITE request. i_rw = 1 will signify a READ request.
i_mosi_data	wire	DATA_WIDTH	input	Data to be written to a register during an I2C write transaction
i_reg_addr	wire	REG_WIDTH	input    	Register where data is read/written during an I2C transaction
i_device_addr 	wire	ADDR_WIDTH 	input	Target slave address
i_divider	wire	16	input	Divider value used to calculate the I2C clock rate. 
o_miso_data	reg	DATA_WIDTH	output	Data read during a READ operation.
o_busy	reg	1	output	When high master is busy with a READ/WRITE transaction.
io_sda	wire	1	inout	SDA conenction for I2C bus
io_scl	wire	1	inout	SCL connection for I2C bus
