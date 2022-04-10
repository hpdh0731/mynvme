module tlp_rx_engine (
	input pcie_clk, //125Mhz
	input pcie_reset_n,

	//input [31:0] pcie_recv_to_ddr_addr,

	input  [127:0]	    m_axis_rx_tdata,
	input               m_axis_rx_tvalid,
	output          	m_axis_rx_tready,
	input  [15:0]       m_axis_rx_tkeep,
	//input               m_axis_rx_tlast,
	input  [21:0]       m_axis_rx_tuser,
	
	output reg [127:0] tlp_header,
	output tx_req,
	input tx_ack,
	
	output mem_write_o,
	input mem_ack_i,
	output [63:0] mem_addr_o,
	output reg [31:0] mem_data_o,
	
	output reg init_end,
	//output reg [31:0] bar0,
	
	input [31:0] cfg_mgmt_do,
	input cfg_mgmt_rd_wr_done,
	output reg [9:0] cfg_mgmt_dwaddr,
	output reg cfg_mgmt_rd_en,
	
	output reg dram_write_req,
	output reg [31:0] dram_write_addr,
	output reg [127:0] dram_write_data,
	output reg [3:0] dram_write_sel,
	input dram_write_ack,
	
	output dram_write_complete,
	output reg [7:0] pcie_recv_tag_free,

	
	input [63:0] mrd_resend0_addr,
	input [63:0] mrd_resend1_addr,
	input [63:0] mrd_resend2_addr,
	input [63:0] mrd_resend3_addr,
	input [63:0] mrd_resend4_addr,
	input [63:0] mrd_resend5_addr,
	input [63:0] mrd_resend6_addr,
	input [63:0] mrd_resend7_addr,
	
	input [31:0] cpld_recv0_addr,
	input [31:0] cpld_recv1_addr,
	input [31:0] cpld_recv2_addr,
	input [31:0] cpld_recv3_addr,
	input [31:0] cpld_recv4_addr,
	input [31:0] cpld_recv5_addr,
	input [31:0] cpld_recv6_addr,
	input [31:0] cpld_recv7_addr,
	
	input [31:0] cpld_recv0_len,
	input [31:0] cpld_recv1_len,
	input [31:0] cpld_recv2_len,
	input [31:0] cpld_recv3_len,
	input [31:0] cpld_recv4_len,
	input [31:0] cpld_recv5_len,
	input [31:0] cpld_recv6_len,
	input [31:0] cpld_recv7_len,
	
	input [31:0] req_flag0_addr,
	input [31:0] req_flag1_addr,
	input [31:0] req_flag2_addr,
	input [31:0] req_flag3_addr,
	input [31:0] req_flag4_addr,
	input [31:0] req_flag5_addr,
	input [31:0] req_flag6_addr,
	input [31:0] req_flag7_addr,
	
	output [3:0] state_o,
	
	output reg [2:0] tlp_poisoned_edge,
	
	output [31:0] cpld_recv0_count,
	
	output reg mrd_resend_req,
	output reg [63:0] mrd_resend_addr,
	output reg [9:0] mrd_resend_len,
	output reg [7:0] mrd_resend_tag,
	input mrd_resend_ack,
	
	output reg cpl_recv_end_tick,
	output reg cpl_recv_tick,
	output reg [15:0] cpl_data_inc,
	
	input [6:0] pcie_params,
	
	output reg [31:0] mrd_fail_count,
	
	output [15:0] debug_o
);


reg [7:0] rx_state;
reg [7:0] rx_state_r;

wire sof_present = m_axis_rx_tuser[14];
wire [3:0] sof_loc = m_axis_rx_tuser[13:10];
wire eof_present = m_axis_rx_tuser[21];


reg [3:0] sof_loc_r;
reg [3:0] sof_loc_r2;
reg sof_present_r;
reg eof_present_r;
reg [127:0] m_axis_rx_tdata_r;
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
wire [11:0]  byte_count;
wire [6:0]   lower_addr;
wire [2:0]	 compl_status;

wire RCB;
wire [2:0] MPS;
wire [2:0] MRRS;

reg posted;
reg [2:0] dram_write_ack_ff;

reg [1:0] send_block_num_done_ff;
reg [5:0] send_block_num_r;

//reg [5:0] cpld_recv_cnt [7:0];
reg [7:0] tag_r;
reg [11:0] desired_total_len;
reg [11:0] cpld_start_offset;


reg [31:0] cpld_recv_count [7:0];
wire [31:0] cpld_recv_len_arr [7:0];

assign payload_length = tlp_header[9:0];
assign attr = tlp_header[13:12];
assign poisoned_data = tlp_header[14];
assign tlp_digest = tlp_header[15];
assign traffic_class = tlp_header[22:20];
assign tlp_type = tlp_header[31:24];
assign byte_enable = tlp_header[39:32];
//assign tag = tlp_header[47:40]; //for MRd and MWr
assign tag = tlp_header[79:72]; //for Cpld and Cpl
assign requestor_id = tlp_header[63:48];
assign address = (tlp_type[5] == 1'b0) ? {32'b0,tlp_header[95:66]} : tlp_header[127:66]; //if 3DW Address
assign byte_count = tlp_header[43:32];
assign lower_addr = tlp_header[70:64];
assign compl_status = tlp_header[47:45];

assign RCB = pcie_params[6];
assign MPS = pcie_params[2:0];
assign MRRS = pcie_params[5:3];


assign debug_o = {cpld_recv_count[tag_r[7:5]][6:0],cpld_recv_len_arr[tag_r[7:5]][11:3]};

always@* begin
	casez(data_loc)
		2'd0: mem_data_o = tlp_data[31:0];
		2'd1: mem_data_o = tlp_data[63:32];
		2'd2: mem_data_o = tlp_data[95:64];
		default: mem_data_o = tlp_data[127:96]; //2'd3
	endcase
	
	casez(tlp_type[6:0])
		7'b1?_00000: posted=1; //Memory write
		7'b11_10???: posted=1; //Message write
		default: posted=0;
	endcase
end

always@* begin
	if( ({{1'b0,tag[4:0]}+6'd1, 5'b0} << MRRS) <= cpld_recv_len_arr[tag[7:5]][10:0])
		desired_total_len = 12'h80 << MRRS;
	else
		desired_total_len = {cpld_recv_len_arr[tag[7:5]][9:0],2'b0} & ~(12'hF80 << MRRS);
		
	cpld_start_offset = desired_total_len - byte_count[11:0];
end


assign m_axis_rx_tready = (rx_state == 8'd0 || rx_state == 8'd1 || rx_state == 8'd3 || rx_state == 8'd6 || rx_state == 8'd10) ? 1'b1 : 1'b0;
assign mem_write_o = (rx_state == 8'd2) ? !poisoned_data : 1'b0;
assign mem_addr_o = {address,2'b00} + {52'b0,data_index,2'b00};		
assign tx_req = (rx_state == 8'd4) ? !poisoned_data : 1'b0;

//assign dram_write_complete = (dram_write_ack_ff[1] ^ dram_write_ack_ff[2]) && (data_index - {7'b0,sof_loc_r[3],!sof_loc_r[2]} >= byte_count[10:2]);
//assign dram_write_complete = (cpld_recv_cnt == (32'h1 << {26'h0,send_block_num_r}) - 32'h1);
//assign dram_write_complete = (cpld_recv_cnt[tag_r[7:5]] == ({1'b0,tag_r[4:0]} + 6'd1) );


assign cpld_recv_len_arr[0] = cpld_recv0_len;
assign cpld_recv_len_arr[1] = cpld_recv1_len;
assign cpld_recv_len_arr[2] = cpld_recv2_len;
assign cpld_recv_len_arr[3] = cpld_recv3_len;
assign cpld_recv_len_arr[4] = cpld_recv4_len;
assign cpld_recv_len_arr[5] = cpld_recv5_len;
assign cpld_recv_len_arr[6] = cpld_recv6_len;
assign cpld_recv_len_arr[7] = cpld_recv7_len;

assign cpld_recv0_count = cpld_recv_count[0];


integer i;

always@(posedge pcie_clk) begin

	if(~pcie_reset_n) begin
		rx_state <= 8'd0;
		cfg_mgmt_rd_en <= 1'b0;
		init_end <= 1'b0;
		rx_state_r <= 8'd0;
		dram_write_req <= 1'b0;
		pcie_recv_tag_free <= 8'b0;

		for(i=0;i<8;i=i+1) begin
			//cpld_recv_cnt[i] <= 6'd0;
			cpld_recv_count[i] <= 32'h0;
		end
			
		tag_r <= 8'b0;
		mrd_resend_req <= 1'b0;
		mrd_fail_count <= 32'h0;
		
	end else begin
		rx_state_r <= rx_state;
		
		dram_write_ack_ff <= {dram_write_ack_ff[1:0],dram_write_ack};
		
		if(poisoned_data) begin
			//if(rx_state_r == 8'd0 || rx_state_r == 8'd1)
			//begin
				if(rx_state == 8'd5) //completion tlp
					//tlp_poisoned_edge[2] <= ~tlp_poisoned_edge[2];
					tlp_poisoned_edge[2] <= 1;
				else if(rx_state == 8'd2 || rx_state == 8'd3) //Mem write tlp
					//tlp_poisoned_edge[1] <= ~tlp_poisoned_edge[1];
					tlp_poisoned_edge[1] <= 1;
				else if(rx_state == 8'd4) //Mem reade tlp
					//tlp_poisoned_edge[0] <= ~tlp_poisoned_edge[0];
					tlp_poisoned_edge[0] <= 1;
			//end
		end
		
		/*if(dram_write_complete)
			cpld_recv_cnt[tag_r[7:5]] <= 6'd0;
		else if(rx_state_r == 8'd7 && rx_state == 8'd0)
			cpld_recv_cnt[tag_r[7:5]] <= cpld_recv_cnt[tag_r[7:5]] + 6'd1;
			
		if(dram_write_complete)
			pcie_recv_tag_free <= pcie_recv_tag_free ^ (8'b1<<tag_r[7:5]);*/
		
		casez(rx_state)
			8'd0: begin //Get TLP Header
				mrd_resend_req <= 1'b0;
				sof_present_r <= 1'b0;
				
				if(m_axis_rx_tvalid & ~sof_present)
					mrd_fail_count <= mrd_fail_count + 32'd1;
				
				if(m_axis_rx_tvalid & sof_present) begin
					casez(sof_loc[3:2])
						2'b00: tlp_header[127:0] <= m_axis_rx_tdata[127:0];
						2'b01: tlp_header[95:0] <= m_axis_rx_tdata[127:32];
						2'b10: tlp_header[63:0] <= m_axis_rx_tdata[127:64];
						default: tlp_header[31:0] <= m_axis_rx_tdata[127:96];	
					endcase
					tlp_data[127:96] <= m_axis_rx_tdata[127:96];
					sof_loc_r <= sof_loc;
					data_loc <= 2'd3;
					data_index <= 10'b0;
					eof_present_r <= eof_present;

					if(sof_loc[3:2] == 2'd0 || (sof_loc[3:2] == 2'd1 & ~m_axis_rx_tdata[29+32]) ) begin //tlp header done							
							
						if(sof_loc[3:2] == 2'd0)
							rx_state <= m_axis_rx_tdata[27:25] == 3'b101 ? 8'd5 : (m_axis_rx_tdata[30] ? (m_axis_rx_tdata[29] ? 8'd3 : 8'd2 ) : 8'd4); //completion, with data, 4DW
						else //2'd1
							rx_state <= m_axis_rx_tdata[27+32:25+32] == 3'b101 ? 8'd5 : (m_axis_rx_tdata[30+32] ? 8'd3 : 8'd4); //completion, with data
							
					end else
						rx_state <= 8'd1;
				end
			end
			8'd1: begin //Get TLP Header / Data
				if(m_axis_rx_tvalid) begin
					eof_present_r <= eof_present;
					
					if(sof_present) begin //record next tlp
						sof_present_r <= 1'b1;
						m_axis_rx_tdata_r <= m_axis_rx_tdata;
						sof_loc_r2 <= sof_loc;
					end else
						sof_present_r <= 1'b0;

					casez(sof_loc_r[3:2])
						2'b01: tlp_header[127:96] <= m_axis_rx_tdata[31:0];
						2'b10: tlp_header[127:64] <= m_axis_rx_tdata[63:0];
						default: tlp_header[127:32] <= m_axis_rx_tdata[95:0];	
					endcase						

					casez(sof_loc_r[3:2])
						2'b01: begin
							tlp_data[127:32] <= m_axis_rx_tdata[127:32];
							data_loc <= 2'd1;
						end
						2'b10: begin
							if(tlp_data[29]) begin //4DW
								tlp_data[127:64] <= m_axis_rx_tdata[127:64];
								data_loc <= 2'd2;
							end else begin
								tlp_data[127:32] <= m_axis_rx_tdata[127:32];
								data_loc <= 2'd2;
							end
						end
						default: begin
							if(tlp_data[29]) begin //4DW
								tlp_data[127:96] <= m_axis_rx_tdata[127:96];
								data_loc <= 2'd3;
							end else begin
								tlp_data[127:64] <= m_axis_rx_tdata[127:64];
								data_loc <= 2'd2;
							end
						end
					endcase
					
					if(tlp_header[27:25] == 3'b101) //Completion
						rx_state <= 8'd5;
					else if(tlp_header[30]) //Memory Write, IO Write, Config Write, Message Write
						rx_state <= 8'd2;
					else //Memory Read, IO Read, Config Read, Message Read
						rx_state <= 8'd4;
				end
			end
			8'd2: begin //Write Mem
				if(mem_ack_i) begin
					data_loc <= data_loc + 2'd1;
					data_index <= data_index + 10'd1;
					
					if(data_index+10'd1 == payload_length) begin
						if(~posted) //IO Write, Config Write
							rx_state <= 8'd4;
						else begin //Memory Write, Message Write
							if(sof_present_r)
								rx_state <= 8'd9;
							else
								rx_state <= 8'd0;
						end
					end else if(&data_loc)
						rx_state <= 8'd3;
				end
			end
			8'd3: begin //Get TLP Data from TLP Write
				if(m_axis_rx_tvalid) begin
					tlp_data[127:0] <= m_axis_rx_tdata[127:0];
					data_loc <= 2'd0;
					rx_state <= 8'd2;
					
					if(sof_present) begin //record next tlp
						sof_present_r <= 1'b1;
						m_axis_rx_tdata_r <= m_axis_rx_tdata;
						sof_loc_r2 <= sof_loc;
					end else
						sof_present_r <= 1'b0;
				end
			end
			8'd4: begin //Wait Tx Engine
				if(tx_ack | poisoned_data) begin
					if(sof_present_r)
						rx_state <= 8'd9;
					else
						rx_state <= 8'd0;
				end
			end
			
			8'd5: begin //Check Completion TLP data is loaded >= 128-bit
				data_index <= {8'b0,sof_loc_r[3],!sof_loc_r[2]};

				casez(tag[7:5])
					3'd0: dram_write_addr <= cpld_recv0_addr + ( ( {20'h0,tag[4:0],7'h0} << MRRS ) | {20'h0,cpld_start_offset[11:0]} );
					3'd1: dram_write_addr <= cpld_recv1_addr + ( ( {20'h0,tag[4:0],7'h0} << MRRS ) | {20'h0,cpld_start_offset[11:0]} );
					3'd2: dram_write_addr <= cpld_recv2_addr + ( ( {20'h0,tag[4:0],7'h0} << MRRS ) | {20'h0,cpld_start_offset[11:0]} );
					3'd3: dram_write_addr <= cpld_recv3_addr + ( ( {20'h0,tag[4:0],7'h0} << MRRS ) | {20'h0,cpld_start_offset[11:0]} );
					3'd4: dram_write_addr <= cpld_recv4_addr + ( ( {20'h0,tag[4:0],7'h0} << MRRS ) | {20'h0,cpld_start_offset[11:0]} );
					3'd5: dram_write_addr <= cpld_recv5_addr + ( ( {20'h0,tag[4:0],7'h0} << MRRS ) | {20'h0,cpld_start_offset[11:0]} );
					3'd6: dram_write_addr <= cpld_recv6_addr + ( ( {20'h0,tag[4:0],7'h0} << MRRS ) | {20'h0,cpld_start_offset[11:0]} );
					default: dram_write_addr <= cpld_recv7_addr + ( ( {20'h0,tag[4:0],7'h0} << MRRS ) | {20'h0,cpld_start_offset[11:0]} );
				endcase
				
				/*casez(tag[7:5])
					3'd0: dram_write_addr <= cpld_recv0_addr + {20'h0,tag[4:0],lower_addr-cpld_recv0_len[22:16]};
					3'd1: dram_write_addr <= cpld_recv1_addr + {20'h0,tag[4:0],lower_addr-cpld_recv1_len[22:16]};
					3'd2: dram_write_addr <= cpld_recv2_addr + {20'h0,tag[4:0],lower_addr-cpld_recv2_len[22:16]};
					3'd3: dram_write_addr <= cpld_recv3_addr + {20'h0,tag[4:0],lower_addr-cpld_recv3_len[22:16]};
					3'd4: dram_write_addr <= cpld_recv4_addr + {20'h0,tag[4:0],lower_addr-cpld_recv4_len[22:16]};
					3'd5: dram_write_addr <= cpld_recv5_addr + {20'h0,tag[4:0],lower_addr-cpld_recv5_len[22:16]};
					3'd6: dram_write_addr <= cpld_recv6_addr + {20'h0,tag[4:0],lower_addr-cpld_recv6_len[22:16]};
					default: dram_write_addr <= cpld_recv7_addr + {20'h0,tag[4:0],lower_addr-cpld_recv7_len[22:16]};
				endcase*/

				tag_r <= tag;
				
				if((~poisoned_data) & ~|compl_status) begin
					//cpld_recv_count[tag[7:5]] <= cpld_recv_count[tag[7:5]] + {22'b0,payload_length[9:0]};

					//cpl_recv_tick <= ~cpl_recv_tick;
					//cpl_data_inc <= {4'b0,payload_length[9:0],2'b0};
					
					if(byte_count[11:2] == payload_length[9:0]) begin
						cpl_recv_end_tick <= ~cpl_recv_end_tick;
						cpld_recv_count[tag[7:5]] <= cpld_recv_count[tag[7:5]] + 32'd1;
					end
				end
				/*else
					cpld_recv_count[tag[7:5]] <= cpld_recv_count[tag[7:5]] - {20'b0,cpld_start_offset[11:0]};*/
					
				/*if( (~|compl_status) && payload_length[9:0] == byte_count[11:2] )
					cpld_recv_count[tag[7:5]] <= cpld_recv_count[tag[7:5]] + 32'd1;*/
				
				casez(sof_loc_r[3:2])
					2'd0: begin
						dram_write_data[31:0] <= {96'h0,tlp_data[127:96]};
						dram_write_sel <= 4'b0001;
					end
					2'd2: begin
						dram_write_data[95:0] <= {32'b0,tlp_data[127:32]};
						dram_write_sel <= 4'b0111;
					end
					default: begin
						dram_write_data[63:0] <= {64'b0,tlp_data[127:64]};
						dram_write_sel <= 4'b0011;
					end
				endcase
				
				if(poisoned_data|(|compl_status)) begin
					if(eof_present_r)
						rx_state <= 8'd11;
					else
						rx_state <= 8'd10;
				end else if({8'b0,sof_loc_r[3],!sof_loc_r[2]} >= payload_length[9:0]) begin
					rx_state <= 8'd7;
					dram_write_req <= ~dram_write_req;
				end else
					rx_state <= 8'd6;
			end
			
			8'd6: begin //Get TLP Data from TLP Completion
				if(m_axis_rx_tvalid) begin
					rx_state <= 8'd7;
					dram_write_req <= ~dram_write_req;
					data_index <= data_index + 10'd4;
					
					casez(sof_loc_r[3:2])
						2'd0: begin
							dram_write_data[127:0] <= {m_axis_rx_tdata[95:0],tlp_data[127:96]};
							tlp_data[127:96] <= m_axis_rx_tdata[127:96];
						end
						2'd1: begin
							dram_write_data[127:0] <= m_axis_rx_tdata[127:0];
						end
						2'd2: begin
							dram_write_data[127:0] <= {m_axis_rx_tdata[31:0],tlp_data[127:32]};
							tlp_data[127:32] <= m_axis_rx_tdata[127:32];
						end
						default: begin
							dram_write_data[127:0] <= {m_axis_rx_tdata[63:0],tlp_data[127:64]};
							tlp_data[127:64] <= m_axis_rx_tdata[127:64];
						end
					endcase
					
					casez(payload_length[9:0]-data_index-10'd4)
						10'b1????_???01: dram_write_sel <= 4'b0011;
						10'b1????_???10: dram_write_sel <= 4'b0111;
						default: dram_write_sel <= 4'b1111;
					endcase
					
					if(sof_present) begin //record next tlp
						sof_present_r <= 1'b1;
						m_axis_rx_tdata_r <= m_axis_rx_tdata;
						sof_loc_r2 <= sof_loc;
					end else
						sof_present_r <= 1'b0;
				end
			end
			
			8'd7: begin //write data to dram		
				if(dram_write_ack_ff[1] ^ dram_write_ack_ff[2]) begin
					casez(payload_length[9:0]-data_index)
						10'b1????_???01: dram_write_sel <= 4'b0011;
						10'b1????_???10: dram_write_sel <= 4'b0111;
						default: dram_write_sel <= 4'b1111;
					endcase
				
					if(data_index < payload_length[9:0]) begin
						dram_write_addr <= dram_write_addr + 32'h10;
						rx_state <= 8'd6;
					end else if(data_index - {8'b0,sof_loc_r[3],!sof_loc_r[2]} < payload_length[9:0]) begin
						dram_write_req <= ~dram_write_req;
						dram_write_addr <= dram_write_addr + 32'h10;
						data_index <= data_index + 10'd4;
						casez(sof_loc_r[3:2])
							2'd0: dram_write_data[31:0] <= {tlp_data[127:96]};
							2'd2: dram_write_data[95:0] <= {tlp_data[127:32]};
							default: dram_write_data[63:0] <= {tlp_data[127:64]};
						endcase
					end else begin
						casez(tag_r[7:5])
							3'd0: dram_write_addr <= req_flag0_addr;
							3'd1: dram_write_addr <= req_flag1_addr;
							3'd2: dram_write_addr <= req_flag2_addr;
							3'd3: dram_write_addr <= req_flag3_addr;
							3'd4: dram_write_addr <= req_flag4_addr;
							3'd5: dram_write_addr <= req_flag5_addr;
							3'd6: dram_write_addr <= req_flag6_addr;
							default: dram_write_addr <= req_flag7_addr;
						endcase
										
						//if(cpld_recv_count[tag_r[7:5]][15:0] >= cpld_recv_len_arr[tag_r[7:5]][15:0]) begin
						if(cpld_recv_count[tag_r[7:5]][6:0] >= (cpld_recv_len_arr[tag_r[7:5]][11:5] >> MRRS) + (|(cpld_recv_len_arr[tag_r[7:5]][9:0] & ~(10'h3E0 << MRRS)) ? 7'd1 : 7'd0) ) begin
							rx_state <= 8'd8;
							dram_write_req <= ~dram_write_req;
							dram_write_sel <= 4'b0001;
							dram_write_data[31:0] <= 32'hFFFFFFFF;
							cpld_recv_count[tag_r[7:5]] <= 32'h0;
							pcie_recv_tag_free <= pcie_recv_tag_free ^ (8'b1<<tag_r[7:5]);
							//cpl_recv_end_tick <= ~cpl_recv_end_tick;
						end else begin
							if(sof_present_r)
								rx_state <= 8'd9;
							else
								rx_state <= 8'd0;
							//cpld_recv_cnt[tag_r[7:5]] <= cpld_recv_cnt[tag_r[7:5]] + 6'd1;
						end
					end
				end
			end
			8'd8: begin //write finish flag
				if(dram_write_ack_ff[1] ^ dram_write_ack_ff[2]) begin
					if(sof_present_r)
						rx_state <= 8'd9;
					else
						rx_state <= 8'd0;
				end
			end
			8'd9: begin //handle next tlp
				sof_present_r <= 1'b0;
				casez(sof_loc_r2[3:2])
					2'b01: tlp_header[95:0] <= m_axis_rx_tdata_r[127:32];
					2'b10: tlp_header[63:0] <= m_axis_rx_tdata_r[127:64];
					default: tlp_header[31:0] <= m_axis_rx_tdata_r[127:96];	
				endcase
				tlp_data[127:96] <= m_axis_rx_tdata_r[127:96];
				sof_loc_r <= sof_loc_r2;
				data_loc <= 2'd3;
				data_index <= 10'b0;
				if(sof_loc_r2[3:2] == 2'd1 & ~m_axis_rx_tdata_r[29+32]) begin //tlp header done							
					rx_state <= m_axis_rx_tdata_r[27+32:25+32] == 3'b101 ? 8'd5 : (m_axis_rx_tdata_r[30+32] ? 8'd3 : 8'd4); //completion, with data			
				end else
					rx_state <= 8'd1;
			end
			8'd10: begin
				if(eof_present & m_axis_rx_tvalid)
					rx_state <= 8'd11;
			end
			8'd11: begin
				rx_state <= 8'd12;
				//mrd_fail_count <= mrd_fail_count + 32'd1;
				mrd_resend_req <= 1'b1;
				mrd_resend_len <= desired_total_len >> 2;
				mrd_resend_tag <= tag_r[7:0];
				casez(tag[7:5])
					3'd0: mrd_resend_addr <= mrd_resend0_addr + ( {20'h0,tag_r[4:0],7'h0} << MRRS );
					3'd1: mrd_resend_addr <= mrd_resend1_addr + ( {20'h0,tag_r[4:0],7'h0} << MRRS );
					3'd2: mrd_resend_addr <= mrd_resend2_addr + ( {20'h0,tag_r[4:0],7'h0} << MRRS );
					3'd3: mrd_resend_addr <= mrd_resend3_addr + ( {20'h0,tag_r[4:0],7'h0} << MRRS );
					3'd4: mrd_resend_addr <= mrd_resend4_addr + ( {20'h0,tag_r[4:0],7'h0} << MRRS );
					3'd5: mrd_resend_addr <= mrd_resend5_addr + ( {20'h0,tag_r[4:0],7'h0} << MRRS );
					3'd6: mrd_resend_addr <= mrd_resend6_addr + ( {20'h0,tag_r[4:0],7'h0} << MRRS );
					default: mrd_resend_addr <= mrd_resend7_addr + ( {20'h0,tag_r[4:0],7'h0} << MRRS );
				endcase
			end
			8'd12: begin //resend mrd
				if(mrd_resend_ack) begin
					mrd_resend_req <= 1'b0;
					rx_state <= 8'd0;
				end
			end
			
			
			/*8'd16: begin
				rx_state <= 8'd17;
				cfg_mgmt_rd_en <= 1'b1;
				cfg_mgmt_dwaddr <= 10'h4;
			end
			8'd17: begin
				cfg_mgmt_rd_en <= !cfg_mgmt_rd_wr_done;
				if(cfg_mgmt_rd_wr_done) begin
					rx_state <= 8'd0;
					init_end <= 1'b1;
					bar0[31:0] <= cfg_mgmt_do;
				end
			end*/

			default: begin
				rx_state <= 8'd0;
			end
		endcase
	end

end

assign state_o = rx_state[3:0];

endmodule