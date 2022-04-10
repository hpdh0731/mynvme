module tlp_tx_engine (
	input pcie_clk, //125Mhz
	input pcie_reset_n,
	
	output reg   [127:0]	s_axis_tx_tdata,
	output reg				s_axis_tx_tvalid,
	input					s_axis_tx_tready,
	output  reg  [15:0]		s_axis_tx_tkeep,
	output 				s_axis_tx_tlast,
	output  [3:0]		s_axis_tx_tuser,
	
	output mem_read_o,
	output [63:0] mem_addr_o,
	input [31:0] mem_data_i,
	input mem_ack_i,
	
	input [15:0] completer_id,
	input [127:0] tlp_header,
	input tx_req,
	output tx_ack,
	
	input pcie_send_req,
	input pcie_send_rw,
	input [63:0] pcie_send_addr,
	input [127:0] pcie_send_data,
	input [9:0] pcie_send_len,
	input [7:0] pcie_send_tag,
	output reg pcie_send_ack,
	
	output [3:0] state_o,
	output pcie_send_end,
	//input fc_grant,
	
	input mrd_resend_req,
	input [63:0] mrd_resend_addr,
	input [9:0] mrd_resend_len,
	input [7:0] mrd_resend_tag,
	output reg mrd_resend_ack,
	
	input [31:0] mem_req_delay,
	
	output rx_np_ok,
	output rx_np_req,
	
	input fc_cpl_grant,
	input fc_mrd_grant,
	input fc_mwr_grant,
	
	output msi_permitted,
	input msi_idle,
	
	output reg mrd_req_tick,
	output reg [15:0] mrd_data_inc,
	output reg mwr_req_tick,
	output reg [15:0] mwr_data_inc
);

/*assign s_axis_tx_tuser[2:0] = 3'b100;
assign s_axis_tx_tuser[3] = s_axis_tx_tlast;*/
//assign s_axis_tx_tuser[3:0] = 4'b0001;
assign s_axis_tx_tuser[3:0] = 4'b0000;

reg s_axis_tx_tlast_r;
assign s_axis_tx_tlast = s_axis_tx_tlast_r & s_axis_tx_tvalid & s_axis_tx_tready;

reg [7:0] tx_state;

reg [3:0] data_loc;
reg [9:0] data_index;

reg [127:0] tlp_data;

wire [9:0]   payload_length;
wire [1:0]   attr;
wire         poisoned_data; //EP
wire         tlp_digest;
wire [2:0]   traffic_class;
wire [7:0]	 tlp_type;
wire [7:0]   byte_enable;
wire [7:0]   tag;
wire [15:0]  requestor_id;
wire [61:0]  address;

reg [11:0] byte_count;
reg [2:0] first_byte_disable_count;
reg [2:0] last_byte_disable_count;
reg [6:0] lower_addr;

reg [127:0] tx_data_buf;
reg [3:0] pcie_send_req_ff;
reg [2:0] pcie_resend_req_ff;
reg pcie_send_req_flag;
reg pcie_resend_req_flag;

reg [15:0] mem_req_delay_cnt_r;
reg [15:0] mem_req_delay_cnt_w;

reg sync_permitted;

assign payload_length = tlp_header[9:0];
assign attr = tlp_header[13:12];
assign poisoned_data = tlp_header[14];
assign tlp_digest = tlp_header[15];
assign traffic_class = tlp_header[22:20];
assign tlp_type = tlp_header[31:24];
assign byte_enable = tlp_header[39:32];
assign tag = tlp_header[47:40];
assign requestor_id = tlp_header[63:48];
assign address = (tlp_type[5] == 1'b0) ? {32'b0,tlp_header[95:66]} : tlp_header[127:66]; //if 3DW Address


always@* begin
	casez(byte_enable[3:0])
		4'b0000: first_byte_disable_count=3'd4;
		4'b0001: first_byte_disable_count=3'd3;
		4'b0010: first_byte_disable_count=3'd3;
		4'b0100: first_byte_disable_count=3'd3;
		4'b1000: first_byte_disable_count=3'd3;
		4'b0011: first_byte_disable_count=3'd2;
		4'b0101: first_byte_disable_count=3'd2;
		4'b1001: first_byte_disable_count=3'd2;
		4'b0110: first_byte_disable_count=3'd2;
		4'b1010: first_byte_disable_count=3'd2;
		4'b1100: first_byte_disable_count=3'd2;
		4'b0111: first_byte_disable_count=3'd1;
		4'b1011: first_byte_disable_count=3'd1;
		4'b1101: first_byte_disable_count=3'd1;
		4'b1110: first_byte_disable_count=3'd1;
		default: first_byte_disable_count=3'd0;
	endcase
	
	casez(byte_enable[7:4])
		4'b0000: last_byte_disable_count=3'd4;
		4'b0001: last_byte_disable_count=3'd3;
		4'b0010: last_byte_disable_count=3'd3;
		4'b0100: last_byte_disable_count=3'd3;
		4'b1000: last_byte_disable_count=3'd3;
		4'b0011: last_byte_disable_count=3'd2;
		4'b0101: last_byte_disable_count=3'd2;
		4'b1001: last_byte_disable_count=3'd2;
		4'b0110: last_byte_disable_count=3'd2;
		4'b1010: last_byte_disable_count=3'd2;
		4'b1100: last_byte_disable_count=3'd2;
		4'b0111: last_byte_disable_count=3'd1;
		4'b1011: last_byte_disable_count=3'd1;
		4'b1101: last_byte_disable_count=3'd1;
		4'b1110: last_byte_disable_count=3'd1;
		default: last_byte_disable_count=3'd0;
	endcase
	
	casez ({!tlp_header[30], byte_enable[3:0]})
       5'b1_0000 : lower_addr = {address[4:0], 2'b00};
       5'b1_???1 : lower_addr = {address[4:0], 2'b00};
       5'b1_??10 : lower_addr = {address[4:0], 2'b01};
       5'b1_?100 : lower_addr = {address[4:0], 2'b10};
       5'b1_1000 : lower_addr = {address[4:0], 2'b11};
       default: lower_addr = 7'h0;
    endcase
end

always@(posedge pcie_clk) begin
	if(payload_length <= 10'd1)
		byte_count[11:0] <= {payload_length[9:0],2'b00}-{9'b0,first_byte_disable_count[2:0]};
	else
		byte_count[11:0] <= {payload_length[9:0],2'b00}-{9'b0,first_byte_disable_count[2:0]}-{9'b0,last_byte_disable_count[2:0]};
end

assign mem_read_o = (tx_state == 8'd1 || tx_state == 8'd3) ? 1'b1 : 1'b0;
assign mem_addr_o = {address,2'b0} + {32'b0,data_index,2'b00};		

assign tx_ack = s_axis_tx_tready && (tx_state == 8'd2 || (tx_state == 8'd4 && data_index == payload_length) );
assign pcie_send_end = s_axis_tx_tlast_r && tx_state == 8'd9 && pcie_send_rw;

assign rx_np_req = 1'b1;
//assign rx_np_ok = (tx_state < 8'd5 && ( ((!pcie_resend_req_flag) && (!pcie_send_req_flag)) || (!fc_grant) ) );
assign rx_np_ok = 1'b1;

assign msi_permitted = fc_mwr_grant & (mem_req_delay_cnt_w == 0) & (pcie_send_req_flag == 0 || pcie_send_rw == 0);

always@(posedge pcie_clk) begin

	if(~pcie_reset_n) begin
		tx_state <= 8'd0;
		s_axis_tx_tvalid <= 1'b0;
		s_axis_tx_tlast_r <= 1'b0;
		pcie_send_req_ff <= 4'b000;
		pcie_resend_req_ff <= 3'b000;
		pcie_send_ack <= 1'b0;
		pcie_send_req_flag <= 1'b0;
		pcie_resend_req_flag <= 1'b0;
		mem_req_delay_cnt_r <= 16'h0;
		mem_req_delay_cnt_w <= 16'h0;
		sync_permitted <= 1'b0;
	end else begin
	
		pcie_send_req_ff <= {pcie_send_req_ff[2:0],pcie_send_req};
		pcie_resend_req_ff <= {pcie_resend_req_ff[1:0],mrd_resend_req};
		
		if(pcie_send_req_ff[2] ^ pcie_send_req_ff[3])
			pcie_send_req_flag <= 1'b1;
		else if(tx_state == 8'd9)
			pcie_send_req_flag <= 1'b0;
			
		if(pcie_resend_req_ff[1] & ~pcie_resend_req_ff[2])
			pcie_resend_req_flag <= 1'b1;
		else if(tx_state == 8'd10)
			pcie_resend_req_flag <= 1'b0;
			
		if(tx_state > 8'd8 && !pcie_send_rw)
			mem_req_delay_cnt_r <= mem_req_delay[15:0];
		else if(|mem_req_delay_cnt_r)
			mem_req_delay_cnt_r <= mem_req_delay_cnt_r - 16'd1;
			
		if((tx_state > 8'd8 && pcie_send_rw) || !msi_idle)
			mem_req_delay_cnt_w <= mem_req_delay[31:16];
		else if(|mem_req_delay_cnt_w)
			mem_req_delay_cnt_w <= mem_req_delay_cnt_w - 16'd1;	

		casez(tx_state)
			8'd0: begin
				s_axis_tx_tvalid <= 1'b0;
				s_axis_tx_tlast_r <= 1'b0;
				data_index <= 10'd0;
				mrd_resend_ack <= 1'b0;
				//s_axis_tx_tuser <= 4'b0000;
				
				if(tx_req & fc_cpl_grant) begin
					if(tlp_header[30])  //IO Write, Config Write
						tx_state <= 8'd2;
					else   //Memory Read, IO Read, Config Read, Message Read
						tx_state <= 8'd1;
				
				end else if(pcie_resend_req_flag & fc_mrd_grant) begin
					if( mem_req_delay_cnt_r == 0 )
						tx_state <= 8'd10;
				end else if(pcie_send_req_flag) begin
					if( pcie_send_rw ? (mem_req_delay_cnt_w == 0 && fc_mwr_grant) : (mem_req_delay_cnt_r == 0 && fc_mrd_grant) )
						tx_state <= 8'd5;
				end
			end
			
			8'd1: begin
				if(mem_ack_i) begin
					tx_data_buf[31:0] <= mem_data_i;
					tx_state <= 8'd2;
					data_index <= data_index + 9'd1;
				end
			end
			8'd2: begin
				//s_axis_tx_tuser <= 4'b0100;
				s_axis_tx_tvalid  <= !(s_axis_tx_tready & s_axis_tx_tvalid);
				s_axis_tx_tlast_r   <= payload_length == 10'd1 || tlp_header[30] ? 1'b1 : 1'b0;
				s_axis_tx_tdata   <= {
									  tx_data_buf[31:0],                  // 32
									  
									  requestor_id,                  // 16
									  tag,                  //  8
									  {1'b0},                   //  1
									  lower_addr,               //  7
									  
									  completer_id,             // 16
									  {3'b0},                   //  3
									  {1'b0},                   //  1
									  byte_count,               // 12
									  
									  {tlp_header[30] ? 8'b000_01010 : 8'b010_01010}, //cpl : cpld
									  {1'b0},                   //  1
									  traffic_class,                   //  3
									  {4'b0},                   //  4
									  1'b0,                   //  1
									  poisoned_data,                   //  1
									  attr,                 //  2
									  {2'b0},                   //  2
									  payload_length            //10
									  };
				if(tlp_header[30])  //IO Write, Config Write
					s_axis_tx_tkeep <= 16'h0FFF;
				else   //Memory Read, IO Read, Config Read, Message Read
					s_axis_tx_tkeep <= 16'hFFFF;
					
				
				if(s_axis_tx_tready)
					tx_state <= payload_length == 10'd1 || tlp_header[30] ? 8'd0 : 8'd3;
			end
			8'd3: begin
				s_axis_tx_tvalid <= 1'b0;
				s_axis_tx_tlast_r <= 1'b0;
				if(mem_ack_i) begin
					casez(data_index[1:0])
						2'b01: tx_data_buf[31:0] <= mem_data_i;
						2'b10: tx_data_buf[63:32] <= mem_data_i;
						2'b11: tx_data_buf[95:64] <= mem_data_i;
						default: tx_data_buf[127:96] <= mem_data_i;
					endcase
					data_index <= data_index + 9'd1;
					if(data_index + 9'd1 == payload_length || (data_index[1:0]==2'b00) )
						tx_state <= 8'd4;
				end
			end
			8'd4: begin
				s_axis_tx_tvalid  <= !(s_axis_tx_tvalid & s_axis_tx_tready);
				s_axis_tx_tlast_r   <= (data_index == payload_length) ? 1'b1 : 1'b0;
				s_axis_tx_tdata   <= tx_data_buf[127:0];
				casez(data_index[1:0])
					2'b01: s_axis_tx_tkeep   <= 16'hFFFF;
					2'b00: s_axis_tx_tkeep   <= 16'h0FFF;
					2'b11: s_axis_tx_tkeep   <= 16'h00FF;
					default: s_axis_tx_tkeep   <= 16'h000F;
				endcase
				
				if(s_axis_tx_tready)
					tx_state <= (data_index == payload_length) ? 8'd0 : 8'd3;
			end
			8'd5: begin
				//s_axis_tx_tuser <= 4'b0100;
				s_axis_tx_tvalid  <= !(s_axis_tx_tready & s_axis_tx_tvalid);
				s_axis_tx_tlast_r   <= pcie_send_rw ? 1'b0 : 1'b1;
				s_axis_tx_tdata   <= {
									  pcie_send_addr[31:0],           // 32
									  pcie_send_addr[63:32],           // 32
									  
									  completer_id,             // 16
									  pcie_send_tag,                   //  8
									  {pcie_send_len > 10'd1 ? 8'hFF : 8'h0F},               // 8
									  
									  {pcie_send_rw ? 8'b011_00000 : 8'b001_00000}, //MWr64 : MRd64
									  {1'b0},                   //  1
									  3'b0,                   //  3
									  {4'b0},                   //  4
									  1'b0,                   //  1
									  1'b0,                   //  1
									  2'b0,                 //  2
									  {2'b0},                   //  2
									  pcie_send_len            //10
									  };
				s_axis_tx_tkeep <= 16'hFFFF;
				
				if(s_axis_tx_tready)
					tx_state <= pcie_send_rw ? 8'd6 : 8'd9;
					
				mrd_req_tick <= mrd_req_tick ^ (s_axis_tx_tready & !pcie_send_rw);
				mrd_data_inc <= {pcie_send_len,2'b00};
				mwr_req_tick <= mwr_req_tick ^ (s_axis_tx_tready & pcie_send_rw);
				mwr_data_inc <= {pcie_send_len,2'b00};
			end
			8'd6: begin
				s_axis_tx_tvalid <= 1'b0;
				tx_state <= 8'd7;
			end
			8'd7: begin
				s_axis_tx_tvalid  <= !(s_axis_tx_tready & s_axis_tx_tvalid);
				s_axis_tx_tlast_r   <= pcie_send_len <= 10'd4 ? 1'b1 : 1'b0;
				s_axis_tx_tdata   <= pcie_send_data;
				
				if(|pcie_send_len[9:2])
					s_axis_tx_tkeep <= 16'hFFFF;
				else begin
					casez(pcie_send_len[1:0])
						2'd1: s_axis_tx_tkeep <= 16'h000F;
						2'd2: s_axis_tx_tkeep <= 16'h00FF;
						default: s_axis_tx_tkeep <= 16'h0FFF;
					endcase
				end
				
				if(s_axis_tx_tready)
					tx_state <= 8'd9;
			end
			8'd8: begin
				if(pcie_send_req_ff[2] ^ pcie_send_req_ff[3])
				//if(pcie_send_req_flag & fc_grant)
					//if( mem_req_delay_cnt_w == 0 )
						tx_state <= 8'd7;
			end
			8'd9: begin
				s_axis_tx_tvalid <= 1'b0;
				pcie_send_ack <= ~pcie_send_ack;
				
				if(s_axis_tx_tlast_r)
					tx_state <= 8'd0;
				else
					tx_state <= 8'd8;
			end
			8'd10: begin
				s_axis_tx_tvalid  <= !(s_axis_tx_tready & s_axis_tx_tvalid);
				s_axis_tx_tlast_r <= 1'b1;
				s_axis_tx_tdata   <= {
									  mrd_resend_addr[31:0],           // 32
									  mrd_resend_addr[63:32],           // 32
									  
									  completer_id,             // 16
									  mrd_resend_tag,                   //  8
									  {mrd_resend_len > 10'd1 ? 8'hFF : 8'h0F},               // 8
									  
									  8'b001_00000, //MRd64
									  {1'b0},                   //  1
									  3'b0,                   //  3
									  {4'b0},                   //  4
									  1'b0,                   //  1
									  1'b0,                   //  1
									  2'b0,                 //  2
									  {2'b0},                   //  2
									  mrd_resend_len            //10
									  };
				s_axis_tx_tkeep <= 16'hFFFF;
				
				mrd_req_tick <= mrd_req_tick ^ s_axis_tx_tready;
				
				if(s_axis_tx_tready) begin
					tx_state <= 8'd0;
					mrd_resend_ack <= 1'b1;
				end
			end
			default: begin
				tx_state <= 8'd0;
			end
		endcase
	end

end

assign state_o = tx_state[3:0];

endmodule