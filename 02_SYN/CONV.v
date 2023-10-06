
`timescale 1ns/10ps

module  CONV(
	input		clk,
	input		reset,
	output reg  busy,	
	input		ready,	
			
	output reg [11:0]iaddr,
	input [19:0]idata,	
	
	output reg	cwr,
	output reg [11:0]caddr_wr,
	output reg [19:0]cdata_wr,
	
	output	 	crd,
	output[11:0]caddr_rd,
	input [19:0]cdata_rd,
	
	output reg [2:0]csel
);

// --------------------------------------------------------
// share data
// --------------------------------------------------------
//reg cwr_0;
wire [11:0] caddr_wr_0;
wire [19:0] cdata_wr_0;
wire cwr_0, cwr_1;
//reg [2:0] csel_0;

wire eof_L1;
wire [2:0] csel_1;
wire [11:0]caddr_wr_1;
wire [19:0]cdata_wr_1;
reg [19:0]buffer_comp;

// -------------------------------------------------------
// reg & wire
// -------------------------------------------------------
reg signed [19:0] window[8:0];
wire signed [19:0]window_0[2:0];
wire signed [19:0]window_L[2:0]; //last
wire signed [42:0] sum;
wire signed [42:0] after_bias;
wire signed [42:0] Relu_result;
wire signed [19:0]final_result;

wire [11:0] offset;
wire [11:0] iaddr_temp;
reg  signed [39:0] sum_reg[8:0]; 

// cao
reg [2:0]state_cnt;
reg [4:0]row_cnt;
reg [4:0]col_cnt;
wire [11:0]temp;

// henry
reg [2:0] cnt;
reg [12:0] iaddr_cnt;

wire   eof_L0;
// -------------------------------------------------------
// parameter & genvar
// -------------------------------------------------------
parameter S_READY  = 2'b00;
parameter S_LAYER0 = 2'b01;
parameter S_LAYER1 = 2'b11;

parameter signed kernel_0 = 20'h0A89E;
parameter signed kernel_1 = 20'h092D5;
parameter signed kernel_2 = 20'h06D43;
parameter signed kernel_3 = 20'h01004;
parameter signed kernel_4 = 20'hF8F71;
parameter signed kernel_5 = 20'hF6E54;
parameter signed kernel_6 = 20'hFA6D7;
parameter signed kernel_7 = 20'hFC834;
parameter signed kernel_8 = 20'hFAC19;


reg [1:0] c_state,n_state;

genvar i;


// -------------------------------------------------------
// Design 
// -------------------------------------------------------
assign window_0[0] = (iaddr_cnt[5:0] == 'd0) ? 20'd0 :  window[0];
assign window_0[1] = (iaddr_cnt[5:0] == 'd0) ? 20'd0 :  window[3];
assign window_0[2] = (iaddr_cnt[5:0] == 'd0) ? 20'd0 :  window[6];

assign window_L[0] = (iaddr_cnt[5:0] == 'd63) ? 20'd0 :  window[2];
assign window_L[1] = (iaddr_cnt[5:0] == 'd63) ? 20'd0 :  window[5];
assign window_L[2] = (iaddr_cnt[5:0] == 'd63) ? 20'd0 :  window[8];

// =============================================================================
assign eof_L0 = (iaddr_cnt == 13'h0fff && cnt == 3'd4);  
assign after_bias = sum + {4'd0,20'h01310,16'd0}; 
assign Relu_result = (after_bias[42])? 43'd0: after_bias;
assign final_result = $signed(Relu_result[35:16]) + {19'd0,Relu_result[15]};
// =============================================================================
assign cwr_0 = (cnt == 3'd4) ? 1'b1 : 1'b0;
assign cdata_wr_0 = final_result;
assign caddr_wr_0 = iaddr_cnt;

wire [19:0] window_w[8:0];

assign {window_w[8],window_w[7],window_w[6],window_w[5],window_w[4],window_w[3],window_w[2],window_w[1],window_w[0]} = {window_L[2],window[7],window_0[2],window_L[1],window[4],window_0[1],window_L[0],window[1],window_0[0]};


assign sum = sum_reg[0] + sum_reg[1] + sum_reg[2]+ sum_reg[3]+ sum_reg[4]+ sum_reg[5]+ sum_reg[6]+ sum_reg[7]+ sum_reg[8];

always @(posedge clk or posedge reset) begin
    if (reset) begin
        sum_reg[0] <= 40'd0;       
        sum_reg[1] <= 40'd0;       
        sum_reg[2] <= 40'd0;       
        sum_reg[3] <= 40'd0;       
        sum_reg[4] <= 40'd0;       
        sum_reg[5] <= 40'd0;       
        sum_reg[6] <= 40'd0;       
        sum_reg[7] <= 40'd0;       
        sum_reg[8] <= 40'd0;       
    end
    else begin
        sum_reg[0] <= window_0[0]*kernel_0;
        sum_reg[1] <= window[1]*kernel_1;             
        sum_reg[2] <= window_L[0]*kernel_2; 
        sum_reg[3] <= window_0[1]*kernel_3; 
        sum_reg[4] <= window[4]*kernel_4; 
        sum_reg[5] <= window_L[1]*kernel_5; 
        sum_reg[6] <= window_0[2]*kernel_6;  
        sum_reg[7] <= window[7]*kernel_7; 
        sum_reg[8] <= window_L[2]*kernel_8; 
    end     
end


                                 
generate                         
for (i = 0; i < 9; i = i + 1) begin
    if (i == 2 || i == 5 || i == 8) begin
        always @(posedge clk or posedge reset) begin
            if (reset) window[i] <=  20'd0;
            else begin
                if (i == 2) begin
                    if (cnt != 2'd0) window[i] <= window[i];
                    else if (iaddr_temp < 12'd64) window[i] <= 20'd0;
                    else window[i] <= idata;
                end
                else if (i == 5) begin
                    if (cnt != 2'd1) window[i] <= window[i];
                    else window[i] <= idata;
                end 
                else if (i == 8) begin
                    if (cnt != 2'd2) window[i] <= window[i];
                    else if (iaddr_temp >= 12'd4032) window[i] <= 20'd0;
                    else window[i] <= idata;
                end
            end
        end
    end 
    else begin
        always @(posedge clk or posedge reset) begin
            if (reset) window[i] <=  20'd0;
            else if (cnt == 3'd4) window[i] <= window[i + 1];
            else window[i] <= window[i];
        end
    end
end
endgenerate 

always @(posedge clk or posedge reset) begin
    if (reset) cnt <= 3'd0;
    else begin
        case (c_state) 
            S_LAYER0 : cnt <= (cnt == 3'd4) ? 3'd0 : cnt + 3'd1;
            default : cnt <= 3'd0;
        endcase 
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) iaddr_cnt <= 13'b111_1111_11_1110;
    else begin
        if (c_state == S_LAYER0) iaddr_cnt <= iaddr_cnt + {12'd0, cnt[2]};
        else iaddr_cnt <= 13'b111_1111_11_1110;
    end
end
//--------error-------------------------------------------

assign iaddr_temp = iaddr_cnt + 12'd1;
assign offset = (cnt[1]) ? 12'd64 : (cnt[0]) ? 12'd0: -12'd64;
always @(*) begin
    if (c_state == S_LAYER0) iaddr = iaddr_temp + offset; 
    else iaddr = 12'd0;
end


// -------------------------------------------------------
// Output 
// -------------------------------------------------------




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
		else if(c_state == S_LAYER1 && n_state == S_READY)
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
//wire [11:0] temp_rd;
//wire [5:0] temp_col;
//wire [5:0] temp_row;
//assign temp_col = col_cnt<<1;
//assign temp_row = row_cnt<<1;
//assign temp_rd = {temp_col,temp_row};
//assign temp_rd = {col_cnt,1'b0,row_cnt,1'b0};
assign caddr_rd = {col_cnt,1'b0,row_cnt,1'b0} + {11'b0,state_cnt[0]} + temp  ; //temp_rd + {11'b0,state_cnt[0]} + temp

// write back to Layer 1 result
assign cwr_1 = (c_state == S_LAYER1)?((state_cnt==3'd4)?1'b1:1'b0): 1'b0;
assign caddr_wr_1 = {1'b0, col_cnt, row_cnt};
assign cdata_wr_1 = (state_cnt==3'd4)?buffer_comp:20'b0;

assign eof_L1 = (state_cnt == 3'd4) & (col_cnt == 5'd31) & (row_cnt == 5'd31);
always@(posedge clk, posedge reset)begin
	if(reset)
		state_cnt <= 3'd0;
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
		row_cnt <= 5'd0;
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
		col_cnt <= 5'd0;
	else
		if(c_state == S_LAYER1)begin
			if(row_cnt == 5'd31 && state_cnt == 3'd4) 
				col_cnt <= col_cnt + 5'd1;
		end
		else begin
			col_cnt <= 5'd0;
		end
end




endmodule




