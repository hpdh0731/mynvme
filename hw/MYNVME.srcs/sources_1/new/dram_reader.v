`define PCIE_REQ_LEN 16'h8000

module dram_reader (
	input ddr_clk, //200Mhz
	input ddr_reset_n,
	
	input pcie_clk, //125Mhz
	input pcie_reset_n,
	
	//input [1:0] start_pcie_mem_tlp,
	input [31:0] pcie_send_from_ddr_read_addr,
	input [31:0] pcie_send_from_ddr_write_addr,
	input [15:0] db_admin_s_tail,
	input [63:0] db_admin_s_addr,
	
	output ddr_arvalid,
	output [31:0] ddr_araddr,
	input ddr_arready,

	output ddr_rready,
	input ddr_rvalid,
	input [63:0] ddr_rdata,
	input [1:0] ddr_rresp,
	
		
	output reg pcie_send_req,
	output reg pcie_send_rw,
	output reg [63:0] pcie_send_addr,
	output reg [127:0] pcie_send_data,
	output reg [9:0] pcie_send_len,
	output reg [7:0] pcie_send_tag,
	input pcie_send_ack,
	
	output [3:0] state_o,
	output pcie_send_end,
	input [7:0] pcie_recv_tag_free,
	
	output reg [63:0] mrd_send0_addr,
	output reg [63:0] mrd_send1_addr,
	output reg [63:0] mrd_send2_addr,
	output reg [63:0] mrd_send3_addr,
	output reg [63:0] mrd_send4_addr,
	output reg [63:0] mrd_send5_addr,
	output reg [63:0] mrd_send6_addr,
	output reg [63:0] mrd_send7_addr,
	
	output reg [31:0] cpld_recv0_addr,
	output reg [31:0] cpld_recv1_addr,
	output reg [31:0] cpld_recv2_addr,
	output reg [31:0] cpld_recv3_addr,
	output reg [31:0] cpld_recv4_addr,
	output reg [31:0] cpld_recv5_addr,
	output reg [31:0] cpld_recv6_addr,
	output reg [31:0] cpld_recv7_addr,
	
	output reg [31:0] req_flag0_addr,
	output reg [31:0] req_flag1_addr,
	output reg [31:0] req_flag2_addr,
	output reg [31:0] req_flag3_addr,
	output reg [31:0] req_flag4_addr,
	output reg [31:0] req_flag5_addr,
	output reg [31:0] req_flag6_addr,
	output reg [31:0] req_flag7_addr,
	
	output reg [31:0] cpld_recv0_len,
	output reg [31:0] cpld_recv1_len,
	output reg [31:0] cpld_recv2_len,
	output reg [31:0] cpld_recv3_len,
	output reg [31:0] cpld_recv4_len,
	output reg [31:0] cpld_recv5_len,
	output reg [31:0] cpld_recv6_len,
	output reg [31:0] cpld_recv7_len,
	
	input pcie_req_tail_change,
	input [15:0] pcie_read_req_tail,
	output reg [15:0] pcie_read_req_head,
	input [15:0] pcie_write_req_tail,
	output reg [15:0] pcie_write_req_head,
	output reg [15:0] pcie_read_req_overlap,
	output reg [15:0] pcie_write_req_overlap,
	
	input [6:0] pcie_params,
	input [31:0] mem_req_delay,
	input reset_pcie_recv
);

reg [7:0] ddr_state;
reg [31:0] dram_addr_reg;
reg [3:0] pcie_send_ack_ff;

//reg [1:0] start_pcie_mem_tlp_flag;

//reg [15:0] db_admin_s_tail_r;

reg [31:0] all_send_len;
reg [7:0] ddr_state_r;

reg [2:0] pcie_send_end_ff;
reg pcie_send_end_toggle;
reg [7:0] pcie_recv_tag_avail;
reg [7:0] pcie_recv_tag_free_ff [2:0];
reg [2:0] pcie_recv_chosen_tag;

reg [15:0] pcie_read_req_tail_r;
reg [15:0] pcie_write_req_tail_r;

reg arb_rw;
reg RCB [1:0];
reg [2:0] MPS [1:0];
reg [2:0] MRRS [1:0];

reg [15:0] mem_req_delay_cnt_r;
reg [15:0] mem_req_delay_cnt_w;
reg [2:0] reset_pcie_recv_ff;

reg resp_fail;

assign ddr_arvalid = ddr_state == 8'd1 || ddr_state == 8'd5 ? 1'b1 : 1'b0;
//assign ddr_araddr = (db_admin_s_tail_r != db_admin_s_tail) ? db_admin_s_addr+{42'h0,db_admin_s_tail_r,6'h0} : dram_addr_reg;
assign ddr_araddr = dram_addr_reg;

assign ddr_rready = ddr_state == 8'd2 || ddr_state == 8'd3 || ddr_state == 8'd6 || ddr_state == 8'd7 ? 1'b1 : 1'b0;

assign pcie_send_end = pcie_send_end_ff[2] ^ pcie_send_end_ff[1];

always@(posedge pcie_clk) begin
	if(~pcie_reset_n)
		pcie_send_end_ff <= 3'b0;
	else
		pcie_send_end_ff <= {pcie_send_end_ff[1:0],pcie_send_end_toggle};
end

always@(posedge ddr_clk) begin
	RCB[0] <= pcie_params[6];
	MPS[0] <= pcie_params[2:0];
	MRRS[0] <= pcie_params[5:3];
	RCB[1] <= RCB[0];
	MPS[1] <= MPS[0];
	MRRS[1] <= MRRS[0];
end

always@(posedge ddr_clk) begin
	if(~ddr_reset_n) begin
		ddr_state <= 8'd0;
		ddr_state_r <= 8'd0;
		//db_admin_s_tail_r <= 16'h0;
		pcie_send_end_toggle <= 1'b0;
		pcie_send_tag[7:5] <= 3'd0;
		pcie_recv_tag_avail <= {8{1'b1}};
		
		pcie_read_req_head <= 16'h0;
		pcie_write_req_head <= 16'h0;
		pcie_read_req_overlap <= 16'h0;
		pcie_write_req_overlap <= 16'h0;
		reset_pcie_recv_ff <= 3'b0;
		
	end else begin
	
		//pcie_send_end_toggle <= pcie_send_end_toggle ^ ((ddr_state_r == 8'd8) && (ddr_state == 8'd0));
		
		if(pcie_req_tail_change) begin
			pcie_read_req_tail_r <= pcie_read_req_tail;
			pcie_write_req_tail_r <= pcie_write_req_tail;
		end

		pcie_send_ack_ff <= {pcie_send_ack_ff[2:0],pcie_send_ack};
		ddr_state_r <= ddr_state;
		
		/*if(|start_pcie_mem_tlp)
            start_pcie_mem_tlp_flag <= start_pcie_mem_tlp | start_pcie_mem_tlp_flag;
		else if(pcie_send_ack_ff[1] ^ pcie_send_ack_ff[2])
            start_pcie_mem_tlp_flag <= !pcie_send_rw ? {start_pcie_mem_tlp_flag[1],1'b0} : {1'b0,start_pcie_mem_tlp_flag[0]} ;*/
		
		pcie_recv_tag_free_ff[2] <= pcie_recv_tag_free_ff[1];
		pcie_recv_tag_free_ff[1] <= pcie_recv_tag_free_ff[0];
		pcie_recv_tag_free_ff[0] <= pcie_recv_tag_free;
		
		reset_pcie_recv_ff[2:0] <= {reset_pcie_recv_ff[1:0],reset_pcie_recv};
		
		if(reset_pcie_recv_ff[2] ^ reset_pcie_recv_ff[1])
			pcie_recv_tag_avail <= {8{1'b1}};
		else if(ddr_state == 8'd1 && !pcie_send_rw)
			pcie_recv_tag_avail <= (pcie_recv_tag_avail | (pcie_recv_tag_free_ff[1]^pcie_recv_tag_free_ff[2])) & ~(8'd1<<pcie_recv_chosen_tag);
		else
			pcie_recv_tag_avail <= pcie_recv_tag_avail | (pcie_recv_tag_free_ff[1]^pcie_recv_tag_free_ff[2]);
			
			
		if(ddr_state > 8'd0 && !pcie_send_rw)
			mem_req_delay_cnt_r <= mem_req_delay[15:0];
		else if(|mem_req_delay_cnt_r)
			mem_req_delay_cnt_r <= mem_req_delay_cnt_r - 16'd1;
			
		if(ddr_state > 8'd0 && pcie_send_rw)
			mem_req_delay_cnt_w <= mem_req_delay[31:16];
		else if(|mem_req_delay_cnt_w)
			mem_req_delay_cnt_w <= mem_req_delay_cnt_w - 16'd1;
			
		casez(ddr_state)
			8'd0: begin
				//if(start_pcie_mem_tlp_flag[0] & (|pcie_recv_tag_avail) ) begin
				if(pcie_read_req_tail_r != pcie_read_req_head && (|pcie_recv_tag_avail) && (!arb_rw) && mem_req_delay_cnt_r == 0) begin
					ddr_state <= 8'd1;
					pcie_send_rw <= 1'b0;
					dram_addr_reg <= pcie_send_from_ddr_read_addr | pcie_read_req_head;
				//end else if(start_pcie_mem_tlp_flag[1]) begin
				end else if(pcie_write_req_tail_r != pcie_write_req_head && arb_rw && mem_req_delay_cnt_w == 0) begin
					ddr_state <= 8'd1;
					pcie_send_rw <= 1'b1;
					dram_addr_reg <= pcie_send_from_ddr_write_addr | pcie_write_req_head;
				end
				
				arb_rw <= ~arb_rw;
				
				//dram_addr_reg <= pcie_send_from_ddr_addr;
				
				casez(pcie_recv_tag_avail)
					8'b???????1: pcie_recv_chosen_tag <= 3'd0;
					8'b??????10: pcie_recv_chosen_tag <= 3'd1;
					8'b?????100: pcie_recv_chosen_tag <= 3'd2;
					8'b????1000: pcie_recv_chosen_tag <= 3'd3;
					8'b???10000: pcie_recv_chosen_tag <= 3'd4;
					8'b??100000: pcie_recv_chosen_tag <= 3'd5;
					8'b?1000000: pcie_recv_chosen_tag <= 3'd6;
					default: pcie_recv_chosen_tag <= 3'd7;
				endcase
			end
			8'd1: begin		
				if(ddr_arready)
					ddr_state <= 8'd2;
				
				if(!pcie_send_rw)
					casez(pcie_recv_chosen_tag)
						3'd0: req_flag0_addr <= dram_addr_reg + 32'h8;
						3'd1: req_flag1_addr <= dram_addr_reg + 32'h8;
						3'd2: req_flag2_addr <= dram_addr_reg + 32'h8;
						3'd3: req_flag3_addr <= dram_addr_reg + 32'h8;
						3'd4: req_flag4_addr <= dram_addr_reg + 32'h8;
						3'd5: req_flag5_addr <= dram_addr_reg + 32'h8;
						3'd6: req_flag6_addr <= dram_addr_reg + 32'h8;
						default: req_flag7_addr <= dram_addr_reg + 32'h8;
					endcase
			end
			8'd2: begin
				if(ddr_rvalid) begin
					pcie_send_addr <= ddr_rdata;
					//if(~ddr_rresp[1])
						ddr_state <= 8'd3;
						
					resp_fail <= ddr_rresp[1:0] != 2'b00 ? 1'b1 : 1'b0;
				end
			end
			8'd3: begin
				if(ddr_rvalid) begin
					//pcie_send_len <= ddr_rdata[31:0];
					if(pcie_send_rw) begin
						if(ddr_rdata[31:0] >= (32'h20 << MPS[1])) //page = 0x1000, pcie payload = 0x80
							pcie_send_len <= (10'h20 << MPS[1]);
						else
							pcie_send_len <= ddr_rdata[9:0] & ~(10'h3E0 << MPS[1]);
					end else begin
						if(ddr_rdata[31:0] >= (32'h20 << MRRS[1])) //page = 0x1000, pcie payload = 0x80
							pcie_send_len <= (10'h20 << MRRS[1]);
						else
							pcie_send_len <= ddr_rdata[9:0] & ~(10'h3E0 << MRRS[1]);
					end
					all_send_len <= ddr_rdata[31:0];
					
					pcie_send_tag[7:5] <= pcie_recv_chosen_tag;
					pcie_send_tag[4:0] <= 5'd0;
					//pcie_send_tag[4:0] <= (ddr_rdata[4:0] == 5'd0) ? (ddr_rdata[9:5] - 5'd1) : ddr_rdata[9:5];
					
					if(!pcie_send_rw) begin
						casez(pcie_recv_chosen_tag)
							3'd0: mrd_send0_addr <= pcie_send_addr;
							3'd1: mrd_send1_addr <= pcie_send_addr;
							3'd2: mrd_send2_addr <= pcie_send_addr;
							3'd3: mrd_send3_addr <= pcie_send_addr;
							3'd4: mrd_send4_addr <= pcie_send_addr;
							3'd5: mrd_send5_addr <= pcie_send_addr;
							3'd6: mrd_send6_addr <= pcie_send_addr;
							default: mrd_send7_addr <= pcie_send_addr;
						endcase
					
						casez(pcie_recv_chosen_tag)
							3'd0: cpld_recv0_addr <= ddr_rdata[63:32];
							3'd1: cpld_recv1_addr <= ddr_rdata[63:32];
							3'd2: cpld_recv2_addr <= ddr_rdata[63:32];
							3'd3: cpld_recv3_addr <= ddr_rdata[63:32];
							3'd4: cpld_recv4_addr <= ddr_rdata[63:32];
							3'd5: cpld_recv5_addr <= ddr_rdata[63:32];
							3'd6: cpld_recv6_addr <= ddr_rdata[63:32];
							default: cpld_recv7_addr <= ddr_rdata[63:32];
						endcase
						
						casez(pcie_recv_chosen_tag)
							3'd0: cpld_recv0_len <= {9'b0,pcie_send_addr[6:0],ddr_rdata[15:0]};
							3'd1: cpld_recv1_len <= {9'b0,pcie_send_addr[6:0],ddr_rdata[15:0]};
							3'd2: cpld_recv2_len <= {9'b0,pcie_send_addr[6:0],ddr_rdata[15:0]};
							3'd3: cpld_recv3_len <= {9'b0,pcie_send_addr[6:0],ddr_rdata[15:0]};
							3'd4: cpld_recv4_len <= {9'b0,pcie_send_addr[6:0],ddr_rdata[15:0]};
							3'd5: cpld_recv5_len <= {9'b0,pcie_send_addr[6:0],ddr_rdata[15:0]};
							3'd6: cpld_recv6_len <= {9'b0,pcie_send_addr[6:0],ddr_rdata[15:0]};
							default: cpld_recv7_len <= {9'b0,pcie_send_addr[6:0],ddr_rdata[15:0]};
						endcase
					end
					
					if((ddr_rresp[1:0] != 2'b00) || resp_fail)
						ddr_state <= 8'd1;
					else
					begin
						ddr_state <= 8'd4;
						//pcie_send_req <=  start_pcie_mem_tlp_flag[0] ? ~pcie_send_req : pcie_send_req;
						pcie_send_req <= ~pcie_send_rw ? ~pcie_send_req : pcie_send_req;
						dram_addr_reg <= ddr_rdata[63:32];
					end
				end
			end
			8'd4: begin
				//dram_addr_reg <= dram_addr_reg + 32'h10;

				if(pcie_send_rw)
					ddr_state <= 8'd5;
				else if(pcie_send_ack_ff[2] ^ pcie_send_ack_ff[3]) begin
					if(all_send_len > (32'h20 << MRRS[1]) ) begin
						pcie_send_req <= ~pcie_send_req;
						pcie_send_len <= (all_send_len >= (32'h40 << MRRS[1])) ? (10'h20 << MRRS[1]) : all_send_len[9:0] & ~(10'h3E0 << MRRS[1]);
						all_send_len <= all_send_len - (32'h20 << MRRS[1]);
						pcie_send_addr <= pcie_send_addr + (64'h80 << MRRS[1]);
						pcie_send_tag[4:0] <= pcie_send_tag[4:0] + 5'd1;
					end else begin
						ddr_state <= 8'd0;
						if(pcie_read_req_head + 16'h10 < `PCIE_REQ_LEN)
							pcie_read_req_head <= pcie_read_req_head + 16'h10;
						else begin
							pcie_read_req_head <= 16'h0;
							pcie_read_req_overlap <= pcie_read_req_overlap + 16'h1;
						end
					end
					
					/*if(db_admin_s_tail_r != db_admin_s_tail)
						db_admin_s_tail_r <= db_admin_s_tail_r + 16'h1;*/
				end
			end
			8'd5: begin
				if(ddr_arready)
					ddr_state <= 8'd6;
			end
			8'd6: begin
				if(ddr_rvalid) begin
					pcie_send_data[63:0] <= ddr_rdata[63:0];
					//if(~ddr_rresp[1])
						ddr_state <= 8'd7;
						
					resp_fail <= ddr_rresp[1:0] != 2'b00 ? 1'b1 : 1'b0;
				end
			end
			8'd7: begin
				if(ddr_rvalid) begin
					pcie_send_data[127:64] <= ddr_rdata[63:0];
					if((ddr_rresp[1:0] != 2'b00) || resp_fail) 
						ddr_state <= 8'd5;
					else
					begin
						ddr_state <= 8'd8;
						pcie_send_req <= ~pcie_send_req;
					end
				end
			end
			8'd8: begin
				if(pcie_send_ack_ff[2] ^ pcie_send_ack_ff[3]) begin
					dram_addr_reg <= dram_addr_reg + 32'h10;
					if(pcie_send_len > 10'd4) begin
						ddr_state <= 8'd5;
						pcie_send_len <= pcie_send_len - 10'd4;
					end else if(all_send_len > (32'h20 << MPS[1]) ) begin
						ddr_state <= 8'd5;
						pcie_send_len <= (all_send_len >= (32'h40 << MPS[1])) ? (10'h20 << MPS[1]) : all_send_len[9:0] & ~(10'h3E0 << MPS[1]);
						all_send_len <= all_send_len - (32'h20 << MPS[1]);
						pcie_send_addr <= pcie_send_addr + (64'h80 << MPS[1]);
					end else begin
						ddr_state <= 8'd0;
						if(pcie_write_req_head + 16'h10 < `PCIE_REQ_LEN)
							pcie_write_req_head <= pcie_write_req_head + 16'h10;
						else begin
							pcie_write_req_head <= 16'h0;
							pcie_write_req_overlap <= pcie_write_req_overlap + 16'h1;
						end
					end
				end
			end
			default: begin
				ddr_state <= 8'd0;
			end
		endcase
	end
end

assign state_o = ddr_state[3:0];

endmodule