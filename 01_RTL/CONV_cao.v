
`timescale 1ns/10ps

module  CONV(
	input		clk,
	input		reset,
	output reg  busy,	
	input		ready,	
			
	output[11:0]iaddr,
	input [19:0]idata,	
	
	output	 	cwr,
	output[11:0]caddr_wr,
	output[19:0]cdata_wr,
	
	output	 	crd,
	output[11:0]caddr_rd,
	input [19:0]cdata_rd,
	
	output	[2:0]csel
	);

parameter S_READY  = 2'b00;	
parameter S_LAYER0 = 2'b01;
parameter S_LAYER1 = 2'b11;
reg [1:0] c_state,n_state;


//--------reg wire declaration---------//
wire eof_L1;

wire csel_1;
wire [11:0]caddr_wr_1;
wire [19:0]cdata_wr_1;
reg [19:0]buffer_comp;


reg [2:0]state_cnt;
reg [4:0]row_cnt;
reg [4:0]col_cnt;
wire [11:0]temp;

//-------------FSM---------------------//
always@(posedge clk, posedge reset)begin
	if(reset)
		c_state <= S_READY;
	else
		c_state <= n_state;
end

always@(*)begin
	case(c_state)
	S_READY: if(ready) n_state = S_LAYER0; else n_state = S_READY;
	S_LAYER0:if(eof_L0) n_state = S_LAYER1; else n_state = S_LAYER0;
	S_LAYER1:if(eof_L1) n_state = S_READY;  else n_state = S_LAYER1;
	default: n_state = S_READY;
	endcase
end


//------------output block ----------//
always@(posedge clk, posedge reset)begin
	if(reset)
		busy <= 1'b0;
	else
		if(ready && c_state == S_READY)
			busy <= 1'b1;
		else if(c_state == S_LAYER1 && n_state = S_READY)
			busy <= 1'b0;
		else	
			busy <= busy;
end


//--------------share block -------------------------//
always@(*)begin
	case(c_state)
	S_LAYER0:csel = 3'b001;
	S_LAYER1:csel = csel_1;
	default: csel = 3'b0;
	endcase
end

always@(*)begin
	case(c_state)
	S_LAYER0:cwr = cwr_0;
	S_LAYER1:cwr = cwr_1;
	default: cwr = 1'b0;
	endcase
end

always@(*)begin
	case(c_state)
	S_LAYER0:caddr_wr = caddr_wr_0;
	S_LAYER1:caddr_wr = caddr_wr_1;
	default: caddr_wr = 12'b0;
	endcase
end

always@(*)begin
	case(c_state)
	S_LAYER0:cdata_wr = cdata_wr_0;
	S_LAYER1:cdata_wr = cdata_wr_1;
	default: cdata_wr = 20'b0;
	endcase
end

/*
reg [2:0]state_cnt;
reg [5:0]row_cnt;
reg [5:0]col_cnt;

*/

//--------------Layer 1 block -------------------------//
assign csel_1 = (state_cnt==3'd4)?3'b011:3'b001;
// read Layer 0 result
assign temp = (state_cnt[1])?12'd64: 12'd0;
assign crd = (c_state == S_LAYER1)?((state_cnt==3'd4)?1'b0:1'b1): 1'b0;
assign caddr_rd = {1'b0, (col_cnt<<6)} + {11'b0,state_cnt[0]} + temp + {6'b0, row_cnt<<1};

// write back to Layer 1 result
assign cwr_1 = (c_state == S_LAYER1)?((state_cnt==3'd4)?1'b1:1'b0): 1'b0;
assign caddr_wr_1 = {6'b0, row_cnt<<1} + {1'b0, (col_cnt<<6)};
assign cdata_wr_1 = (state_cnt==3'd4)?buffer_comp:20'b0;

assign eof_L1 = (state_cnt == 3'd4) & (col_cnt == 5'd31) & (row_cnt == 5'd31);
always@(posedge clk, posedge reset)begin
	if(reset)
		state_cnt <= 2'b0;
	else
		if(c_state == S_LAYER1)begin
			if(state_cnt == 3'd4)
				state_cnt <= 3'd0;
			else
				state_cnt <= state_cnt + 3'd1;
		end
end

// store element for compare result 
always@(posedge clk, posedge reset)begin
	if(reset)
		buffer_comp <= 2'b0;
	else
		if(c_state == S_LAYER1)begin
			if(state_cnt == 3'd4) begin
				buffer_comp <= 3'd0;
			end else begin
				if(buffer_comp < cdata_rd)
					buffer_comp <= cdata_rd;
				else
					buffer_comp <= buffer_comp;
			end
		end
end

// row counter
always@(posedge clk, posedge reset)begin
	if(reset)
		row_cnt <= 2'b0;
	else
		if(c_state == S_LAYER1)begin
			if(state_cnt == 3'd4) 
				row_cnt <= row_cnt + 5'd1;
		end
		else begin
			row_cnt <= 5'd0;
		end
end

// column counter
always@(posedge clk, posedge reset)begin
	if(reset)
		col_cnt <= 2'b0;
	else
		if(c_state == S_LAYER1)begin
			if(row_cnt == 5'd31 && state_cnt == 3'd4) 
				col_cnt <= col_cnt + 5'd1;
		end
		else begin
			col_cnt <= 5'd0;
		end
end

//------------paste -------------------------------//
/*
wire signed [39:0] sum;
wire signed [19:0] after_bias;
wire signed [19:0] Relu_result;
// kernel parameter is signed!

wire eof_L0;
assign eof_L0 = (caddr_wr == 12'hffff);  
assign after_bias = sum[35:16] + 20'h01310;
assign Relu_result = (after_bias[19])? 32'd0: after_bias;
*/
endmodule
