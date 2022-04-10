`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/13 23:33:07
// Design Name: 
// Module Name: pcie_bridge
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pcie_bridge(

	input user_clk, //125Mhz
	input user_reset_n,
	//input user_link_up,

	output    [127:0]	s_axis_tx_tdata,
	output 				s_axis_tx_tvalid,
	input					s_axis_tx_tready,
	output    [15:0]		s_axis_tx_tkeep,
	output 				s_axis_tx_tlast,
	output    [3:0]		s_axis_tx_tuser,

	input  [127:0]	    m_axis_rx_tdata,
	input               m_axis_rx_tvalid,
	output          	m_axis_rx_tready,
	input  [15:0]       m_axis_rx_tkeep,
	input               m_axis_rx_tlast,
	input  [21:0]       m_axis_rx_tuser,
	
	input pl_clk,
	input pl_rstn,
	
	output hp_arvalid,
	output [31:0] hp_araddr,
	input hp_arready,
	
	output hp_rready,
	input hp_rvalid,
	input [1:0] hp_rresp,
	input hp_rlast,
	input [63:0] hp_rdata,
	
	output hp_awvalid,
	output [31:0] hp_awaddr,
	output [3:0] hp_awlen,
	input hp_awready,
	
	output hp_wvalid,
	output [63:0] hp_wdata,
	output [7:0] hp_wstrb,
	output hp_wlast,
	input hp_wready,
	
	output hp_bready,
	input hp_bvalid,
	input [1:0] hp_bresp,
	
	
	input [31:0]M_AXI_GP_araddr,
	output M_AXI_GP_arready,
	input M_AXI_GP_arvalid,
	input [31:0]M_AXI_GP_awaddr,
	output M_AXI_GP_awready,
	input M_AXI_GP_awvalid,
	input M_AXI_GP_bready,
	output [1:0]M_AXI_GP_bresp,
	output reg M_AXI_GP_bvalid,
	output reg [31:0]M_AXI_GP_rdata,
	input M_AXI_GP_rready,
	output [1:0]M_AXI_GP_rresp,
	output reg M_AXI_GP_rvalid,
	input [31:0]M_AXI_GP_wdata,
	output reg M_AXI_GP_wready,
	input M_AXI_GP_wvalid,
	input [3:0] M_AXI_GP_wstrb,
	
	
	input trigger,
	
	input [15:0] completer_id,
	
	input [31:0] cfg_mgmt_do,
	input cfg_mgmt_rd_wr_done,
	output [9:0] cfg_mgmt_dwaddr,
	output cfg_mgmt_rd_en,
	
	output reg pcie_irq,
	input fclk,
	input fclk_reset_n,
	
	output reg msi_req,
	output reg [7:0] msi_di,
	input msi_rdy,
	input [2:0] msi_num,
	input [7:0] msi_do,
	input msi_msienable,
	input msi_msixenable,
	input msi_msixfm,
	output reg msi_assert,
	
	input [11:0] fc_cpld,
	input [7:0] fc_cplh,
	input [11:0] fc_npd,
	input [7:0] fc_nph,
	input [11:0] fc_pd,
	input [7:0] fc_ph,
	output [2:0] fc_sel,
	
	input [5:0] tx_buf_av,
	output rx_np_ok,
	output rx_np_req,
	input [15:0] cfg_dcommand,
	input [15:0] cfg_lcommand,
	input [15:0] cfg_command,
	input [15:0] cfg_dstatus,
	input [15:0] cfg_dcommand2,
	input [15:0] cfg_lstatus,
	input tx_cfg_req,
	
	input [63:0] GPIO_o
);


wire pcie_rx_run;
wire fc_grant;
wire m_axis_rx_tready_w;
wire s_axis_tx_tvalid_w;

assign m_axis_rx_tready = m_axis_rx_tready_w & pcie_rx_run;
assign s_axis_tx_tvalid = s_axis_tx_tvalid_w & pcie_rx_run;

wire init_end;
//wire [31:0] bar0;

wire dram_write_req;
wire [31:0] dram_write_addr;
wire [3:0] dram_write_sel;
wire [127:0] dram_write_data;
reg [127:0] dram_write_data_le;
wire dram_write_ack;

wire pcie_send_req;
wire pcie_send_rw;
wire [63:0] pcie_send_addr;
wire [127:0] pcie_send_data;
reg [127:0] pcie_send_data_le;
wire [9:0] pcie_send_len;
wire [7:0] pcie_send_tag;
wire pcie_send_ack;

wire [31:0] cpld_recv0_addr;
wire [31:0] cpld_recv1_addr;
wire [31:0] cpld_recv2_addr;
wire [31:0] cpld_recv3_addr;
wire [31:0] cpld_recv4_addr;
wire [31:0] cpld_recv5_addr;
wire [31:0] cpld_recv6_addr;
wire [31:0] cpld_recv7_addr;

wire [31:0] cpld_recv0_len;
wire [31:0] cpld_recv1_len;
wire [31:0] cpld_recv2_len;
wire [31:0] cpld_recv3_len;
wire [31:0] cpld_recv4_len;
wire [31:0] cpld_recv5_len;
wire [31:0] cpld_recv6_len;
wire [31:0] cpld_recv7_len;

wire [31:0] req_flag0_addr;
wire [31:0] req_flag1_addr;
wire [31:0] req_flag2_addr;
wire [31:0] req_flag3_addr;
wire [31:0] req_flag4_addr;
wire [31:0] req_flag5_addr;
wire [31:0] req_flag6_addr;
wire [31:0] req_flag7_addr;

wire [31:0] cpld_recv0_count;

reg [15:0] pcie_read_req_tail;
wire [15:0] pcie_read_req_head;
reg [15:0] pcie_write_req_tail;
wire [15:0] pcie_write_req_head;
wire [15:0] pcie_read_req_overlap;
wire [15:0] pcie_write_req_overlap;

wire [2:0] tlp_poisoned_edge;

wire mrd_resend_req;
wire [63:0] mrd_resend_addr;
wire [9:0] mrd_resend_len;
wire [7:0] mrd_resend_tag;
wire mrd_resend_ack;

reg [11:0] r_rx_limit_fc_cpld;
reg [7:0] r_rx_limit_fc_cplh;
reg [11:0] r_rx_limit_fc_npd;
reg [7:0] r_rx_limit_fc_nph;
reg [11:0] r_rx_limit_fc_pd;
reg [7:0] r_rx_limit_fc_ph;
reg [11:0] r_tx_limit_fc_cpld;
reg [7:0] r_tx_limit_fc_cplh;
reg [11:0] r_tx_limit_fc_npd;
reg [7:0] r_tx_limit_fc_nph;
reg [11:0] r_tx_limit_fc_pd;
reg [7:0] r_tx_limit_fc_ph;

reg [11:0] r_rx_consumed_fc_cpld;
reg [7:0] r_rx_consumed_fc_cplh;
reg [11:0] r_rx_consumed_fc_npd;
reg [7:0] r_rx_consumed_fc_nph;
reg [11:0] r_rx_consumed_fc_pd;
reg [7:0] r_rx_consumed_fc_ph;
reg [11:0] r_tx_consumed_fc_cpld;
reg [7:0] r_tx_consumed_fc_cplh;
reg [11:0] r_tx_consumed_fc_npd;
reg [7:0] r_tx_consumed_fc_nph;
reg [11:0] r_tx_consumed_fc_pd;
reg [7:0] r_tx_consumed_fc_ph;

wire [7:0] tx_ph_consumed_reserved;
wire [15:0] tx_pd_consumed_reserved;
wire [7:0] tx_nph_consumed_reserved;

wire [7:0] rx_cplh_received;
wire [15:0] rx_cpld_received;
wire [7:0] rx_cplh_allocated;
wire [15:0] rx_cpld_allocated;

reg [31:0] timer_counter;
reg [31:0] mem_req_delay;
reg [31:0] mem_req_delay_dma;


wire fc_mwr_grant;
wire fc_mrd_grant;
wire fc_cpl_grant;
wire mwr_req_tick;
wire [15:0] mwr_data_inc;
wire mrd_req_tick;
wire [15:0] mrd_data_inc;
wire cpl_recv_end_tick;
wire cpl_recv_tick;
wire [15:0] cpl_data_inc;



reg [1:0] fc_sel_ff;

wire msi_permitted;
reg msi_req_r;
wire [31:0] mrd_fail_count;

  
	

  

wire [127:0] tlp_header;
wire tx_req;
wire tx_ack;

wire mem_write_o;
wire mem_read_o;
wire [63:0] mem_addr_o_wr;
wire [63:0] mem_addr_o_rd;
//wire mem_ack_i_wr;
//wire mem_ack_i_rd;
wire [31:0] mem_data_o;
reg [31:0] mem_data_i;

reg [31:0] mem_data_o_le;
reg [31:0] mem_data_i_le;

always@* begin
	mem_data_o_le[31:24] = mem_data_o[7:0];
	mem_data_o_le[23:16] = mem_data_o[15:8];
	mem_data_o_le[15:8] = mem_data_o[23:16];
	mem_data_o_le[7:0] = mem_data_o[31:24];
end

always@* begin
	mem_data_i_le[31:24] = mem_data_i[7:0];
	mem_data_i_le[23:16] = mem_data_i[15:8];
	mem_data_i_le[15:8] = mem_data_i[23:16];
	mem_data_i_le[7:0] = mem_data_i[31:24];
end

always@* begin
	dram_write_data_le[31:24] = dram_write_data[7:0];
	dram_write_data_le[23:16] = dram_write_data[15:8];
	dram_write_data_le[15:8] = dram_write_data[23:16];
	dram_write_data_le[7:0] = dram_write_data[31:24];
	
	dram_write_data_le[31+32:24+32] = dram_write_data[7+32:0+32];
	dram_write_data_le[23+32:16+32] = dram_write_data[15+32:8+32];
	dram_write_data_le[15+32:8+32] = dram_write_data[23+32:16+32];
	dram_write_data_le[7+32:0+32] = dram_write_data[31+32:24+32];
	
	dram_write_data_le[31+64:24+64] = dram_write_data[7+64:0+64];
	dram_write_data_le[23+64:16+64] = dram_write_data[15+64:8+64];
	dram_write_data_le[15+64:8+64] = dram_write_data[23+64:16+64];
	dram_write_data_le[7+64:0+64] = dram_write_data[31+64:24+64];
	
	dram_write_data_le[31+96:24+96] = dram_write_data[7+96:0+96];
	dram_write_data_le[23+96:16+96] = dram_write_data[15+96:8+96];
	dram_write_data_le[15+96:8+96] = dram_write_data[23+96:16+96];
	dram_write_data_le[7+96:0+96] = dram_write_data[31+96:24+96];
end

always@* begin
	pcie_send_data_le[31:24] = pcie_send_data[7:0];
	pcie_send_data_le[23:16] = pcie_send_data[15:8];
	pcie_send_data_le[15:8] = pcie_send_data[23:16];
	pcie_send_data_le[7:0] = pcie_send_data[31:24];
	
	pcie_send_data_le[31+32:24+32] = pcie_send_data[7+32:0+32];
	pcie_send_data_le[23+32:16+32] = pcie_send_data[15+32:8+32];
	pcie_send_data_le[15+32:8+32] = pcie_send_data[23+32:16+32];
	pcie_send_data_le[7+32:0+32] = pcie_send_data[31+32:24+32];
	
	pcie_send_data_le[31+64:24+64] = pcie_send_data[7+64:0+64];
	pcie_send_data_le[23+64:16+64] = pcie_send_data[15+64:8+64];
	pcie_send_data_le[15+64:8+64] = pcie_send_data[23+64:16+64];
	pcie_send_data_le[7+64:0+64] = pcie_send_data[31+64:24+64];
	
	pcie_send_data_le[31+96:24+96] = pcie_send_data[7+96:0+96];
	pcie_send_data_le[23+96:16+96] = pcie_send_data[15+96:8+96];
	pcie_send_data_le[15+96:8+96] = pcie_send_data[23+96:16+96];
	pcie_send_data_le[7+96:0+96] = pcie_send_data[31+96:24+96];
end

reg [31:0] INT_MASK_Reg = 32'hFFFFFFFF;
reg [31:0] CC_Reg = 32'h0; //Controller Configuration
reg [31:0] CSTS_Reg = 32'h0; //Controller Status
reg [31:0] AQA_Reg = 32'h0; //Admin Queue Attributes
reg [63:0] ASQ_Reg = 64'h0; //Admin Submission Queue Base Address
reg [63:0] ACQ_Reg = 64'h0; //Admin Completion Queue Base Address
reg [15:0] DB_S_Tail_Admin_Reg = 16'h0; //Submission Queue 0 Tail Doorbell (Admin)
reg [15:0] DB_C_Head_Admin_Reg = 16'h0; //Completion Queue 0 Head Doorbell (Admin)
reg [15:0] DB_S_Tail_IO0_Reg = 16'h0; //Submission Queue 1 Tail Doorbell (IO)
reg [15:0] DB_C_Head_IO0_Reg = 16'h0; //Completion Queue 1 Head Doorbell (IO)
reg [15:0] DB_S_Tail_IO1_Reg = 16'h0; //Submission Queue 2 Tail Doorbell (IO)
reg [15:0] DB_C_Head_IO1_Reg = 16'h0; //Completion Queue 2 Head Doorbell (IO)



reg [1:0] pcie_flag;

reg [31:0] pcie_send_from_ddr_read_addr;
reg [31:0] pcie_send_from_ddr_write_addr;


wire pcie_send_end;
wire dram_write_complete;
wire [7:0] pcie_recv_tag_free;
reg reset_pcie_recv_reg;


wire [31:0] module_state;
reg [5:0] intr_ff;
reg [5:0] cc_change;
reg [31:0] pcie_ctrl_reg;

wire [15:0] debug_o;



assign M_AXI_GP_arready = 1'b1;
assign M_AXI_GP_rresp = 2'b00;

assign M_AXI_GP_awready = !M_AXI_GP_wready;
assign M_AXI_GP_bresp = 2'b00;


reg [63:0] GPIO_o_r1, GPIO_o_r2, GPIO_o_r3;
reg [15:0] module_state_r1, module_state_r2;

always@(posedge pl_clk) begin
	GPIO_o_r1 <= GPIO_o;
	GPIO_o_r2 <= GPIO_o_r1;
	GPIO_o_r3 <= GPIO_o_r2;
end

always@(posedge user_clk) begin
	module_state_r1 <= module_state[15:0];
	module_state_r2 <= module_state_r1;
end


always@(posedge user_clk) begin

	if(~user_reset_n)
		M_AXI_GP_rvalid <= 1'b0;
	else if(M_AXI_GP_arvalid)
		M_AXI_GP_rvalid <= 1'b1;
	else if(M_AXI_GP_rvalid & M_AXI_GP_rready)
		M_AXI_GP_rvalid <= 1'b0;

	if(M_AXI_GP_arvalid & user_reset_n) begin
		casez(M_AXI_GP_araddr[12:0])
			13'h0010: M_AXI_GP_rdata[31:0] <= INT_MASK_Reg;
			13'h0014: M_AXI_GP_rdata[31:0] <= CC_Reg;
			13'h001C: M_AXI_GP_rdata[31:0] <= CSTS_Reg; //Reserved(28),Shutdown Status(2),Controller Fatal Status(1),Ready(1)
			13'h0024: M_AXI_GP_rdata[31:0] <= AQA_Reg;
			13'h0028: M_AXI_GP_rdata[31:0] <= ASQ_Reg[31:0];
			13'h002C: M_AXI_GP_rdata[31:0] <= ASQ_Reg[63:32];
			13'h0030: M_AXI_GP_rdata[31:0] <= ACQ_Reg[31:0];
			13'h0034: M_AXI_GP_rdata[31:0] <= ACQ_Reg[63:32];
			
			13'h0100: M_AXI_GP_rdata[31:0] <= module_state_r2;
			13'h0104: M_AXI_GP_rdata[31:0] <= pcie_ctrl_reg;
			13'h0114: M_AXI_GP_rdata[31:0] <= {29'h0,cc_change};
			13'h0118: M_AXI_GP_rdata[31:0] <= {29'h0,tlp_poisoned_edge[2:0]};
			
			13'h0200: M_AXI_GP_rdata[31:0] = cpld_recv0_count;
			/*13'h0204: M_AXI_GP_rdata[31:0] <= cpld_recv0_len;
			13'h0208: M_AXI_GP_rdata[31:0] <= cpld_recv0_addr;
			13'h020C: M_AXI_GP_rdata[31:0] <= req_flag0_addr;*/
			
			
			13'h0400: M_AXI_GP_rdata[31:0] <= pcie_send_from_ddr_read_addr;
			13'h0404: M_AXI_GP_rdata[31:0] <= pcie_send_from_ddr_write_addr;
			//13'h0404: M_AXI_GP_rdata[31:0] <= pcie_recv_to_ddr_addr;
			13'h0408: M_AXI_GP_rdata[31:0] <= {pcie_write_req_tail,pcie_read_req_tail};
			13'h040C: M_AXI_GP_rdata[31:0] <= {pcie_write_req_overlap,pcie_write_req_head};
			13'h0410: M_AXI_GP_rdata[31:0] <= {pcie_read_req_overlap,pcie_read_req_head};
			
			13'h0500: M_AXI_GP_rdata[31:0] <= {8'h0,r_rx_limit_fc_cplh,4'h0,r_rx_limit_fc_cpld};
			13'h0504: M_AXI_GP_rdata[31:0] <= {8'h0,r_rx_limit_fc_nph,4'h0,r_rx_limit_fc_npd};
			13'h0508: M_AXI_GP_rdata[31:0] <= {8'h0,r_rx_limit_fc_ph,4'h0,r_rx_limit_fc_pd};
			13'h050C: M_AXI_GP_rdata[31:0] <= {8'h0,r_tx_limit_fc_cplh,4'h0,r_tx_limit_fc_cpld};
			13'h0510: M_AXI_GP_rdata[31:0] <= {8'h0,r_tx_limit_fc_nph,4'h0,r_tx_limit_fc_npd};
			13'h0514: M_AXI_GP_rdata[31:0] <= {8'h0,r_tx_limit_fc_ph,4'h0,r_tx_limit_fc_pd};
			
			13'h0520: M_AXI_GP_rdata[31:0] <= {8'h0,r_rx_consumed_fc_cplh,4'h0,r_rx_consumed_fc_cpld};
			13'h0524: M_AXI_GP_rdata[31:0] <= {8'h0,r_rx_consumed_fc_nph,4'h0,r_rx_consumed_fc_npd};
			13'h0528: M_AXI_GP_rdata[31:0] <= {8'h0,r_rx_consumed_fc_ph,4'h0,r_rx_consumed_fc_pd};
			13'h052C: M_AXI_GP_rdata[31:0] <= {8'h0,r_tx_consumed_fc_cplh,4'h0,r_tx_consumed_fc_cpld};
			13'h0530: M_AXI_GP_rdata[31:0] <= {8'h0,r_tx_consumed_fc_nph,4'h0,r_tx_consumed_fc_npd};
			13'h0534: M_AXI_GP_rdata[31:0] <= {8'h0,r_tx_consumed_fc_ph,4'h0,r_tx_consumed_fc_pd};
			
			13'h0540: M_AXI_GP_rdata[31:0] <= {tx_ph_consumed_reserved,tx_nph_consumed_reserved,rx_cplh_received,rx_cplh_allocated};
			13'h0544: M_AXI_GP_rdata[31:0] <= {rx_cpld_received,rx_cpld_allocated};
			13'h0548: M_AXI_GP_rdata[31:0] <= {rx_cpld_received,rx_cpld_allocated};
			13'h054c: M_AXI_GP_rdata[31:0] <= {16'b0,tx_pd_consumed_reserved};
			
			
			13'h0600: M_AXI_GP_rdata[31:0] <= timer_counter;
			13'h0604: M_AXI_GP_rdata[31:0] <= {cfg_lcommand,cfg_dcommand};
			13'h0608: M_AXI_GP_rdata[31:0] <= mrd_fail_count;
			13'h060c: M_AXI_GP_rdata[31:0] <= {cfg_command,cfg_dstatus};
			13'h0610: M_AXI_GP_rdata[31:0] <= {cfg_dcommand2,cfg_lstatus};
			
			13'h0700: M_AXI_GP_rdata[31:0] <= mem_req_delay;
			13'h0704: M_AXI_GP_rdata[31:0] <= mem_req_delay_dma;

			13'h0800: M_AXI_GP_rdata[31:0] <= {30'h0,pcie_flag};
			13'h0804: M_AXI_GP_rdata[31:0] <= {10'b0,msi_assert,msi_req,msi_rdy,msi_msixfm,msi_msixenable,msi_msienable, msi_do,5'b0,msi_num};		
			
			13'h1000: M_AXI_GP_rdata[31:0] <= {16'h0,DB_S_Tail_Admin_Reg};
			13'h1004: M_AXI_GP_rdata[31:0] <= {16'h0,DB_C_Head_Admin_Reg};
			13'h1008: M_AXI_GP_rdata[31:0] <= {16'h0,DB_S_Tail_IO0_Reg};
			13'h100C: M_AXI_GP_rdata[31:0] <= {16'h0,DB_C_Head_IO0_Reg};
			13'h1010: M_AXI_GP_rdata[31:0] <= {16'h0,DB_S_Tail_IO1_Reg};
			13'h1014: M_AXI_GP_rdata[31:0] <= {16'h0,DB_C_Head_IO1_Reg};
			
			default: M_AXI_GP_rdata[31:0] <= 32'b0;
		endcase
	end
end


reg [12:0] M_AXI_GP_awaddr_r;

always@(posedge user_clk) begin

	if(~user_reset_n) begin
		intr_ff <= 3'b0;
	end else begin
		intr_ff <= {tlp_poisoned_edge[2:0],CC_Reg[15:14],CC_Reg[0]};
	end
	
end

always@(posedge user_clk) begin

	if(~user_reset_n) 
		M_AXI_GP_bvalid <= 1'b0;
	else if(M_AXI_GP_wvalid & M_AXI_GP_wready)
		M_AXI_GP_bvalid <= 1'b1;
	else if(M_AXI_GP_bvalid & M_AXI_GP_bready)
		M_AXI_GP_bvalid <= 1'b0;
		
	if(~user_reset_n)
		M_AXI_GP_wready <= 1'b0;
	else if(M_AXI_GP_bvalid)
		M_AXI_GP_wready <= 1'b0;
	else if(M_AXI_GP_awvalid)
		M_AXI_GP_wready <= 1'b1;

	timer_counter[31:0] <= timer_counter[31:0] + 32'd1;

	if(M_AXI_GP_awvalid & user_reset_n)
		M_AXI_GP_awaddr_r[12:0] <= {M_AXI_GP_awaddr[12:2],2'b00};

	if( user_reset_n & M_AXI_GP_wvalid && (M_AXI_GP_awaddr_r[12:0] == 13'h0808) )
		pcie_irq <= |(intr_ff ^ {tlp_poisoned_edge[2:0],CC_Reg[15:14],CC_Reg[0]});
	else
		pcie_irq <= pcie_irq | (|(intr_ff ^ {tlp_poisoned_edge[2:0],CC_Reg[15:14],CC_Reg[0]}));

		
	if( user_reset_n & M_AXI_GP_wvalid && (M_AXI_GP_awaddr_r[12:0] == 13'h0800) )
		pcie_flag <= M_AXI_GP_wdata[1:0] | {pcie_send_end, dram_write_complete};
	else
		pcie_flag <= pcie_flag | {pcie_send_end, dram_write_complete};
	
	if(~user_reset_n) begin
		msi_req_r <= 1'b0;
		msi_di <= 8'h0;
	end else if( M_AXI_GP_wvalid && (M_AXI_GP_awaddr_r[12:0] == 13'h0804) ) begin
		msi_req_r <= 1;
		msi_di <= M_AXI_GP_wdata[7:0];
	end else if(fc_mwr_grant & !INT_MASK_Reg[msi_di])
		msi_req_r <= 1'b0;
		
	if(~user_reset_n)
		reset_pcie_recv_reg <= 1'b0;
	else if(M_AXI_GP_wvalid && (M_AXI_GP_awaddr_r[12:0] == 13'h0900))
		reset_pcie_recv_reg <= ~reset_pcie_recv_reg;
end

/*
reg [31:0] axi_gp_wdata_mask;

always@* begin

end

*/

always@(posedge user_clk) begin

	if(~user_reset_n) begin
		cc_change <= 3'b0;
	end else if(M_AXI_GP_wvalid & M_AXI_GP_wready) begin
		casez(M_AXI_GP_awaddr_r[12:0])
			13'h001C: CSTS_Reg[3:0] <= M_AXI_GP_wdata[3:0];
			13'h0104: pcie_ctrl_reg <= M_AXI_GP_wdata[31:0];
			13'h0114: cc_change <= M_AXI_GP_wdata[5:0] | (intr_ff ^ {tlp_poisoned_edge[2:0],CC_Reg[15:14],CC_Reg[0]});
			13'h0400: pcie_send_from_ddr_read_addr[31:0] <= M_AXI_GP_wdata[31:0];
			13'h0404: pcie_send_from_ddr_write_addr[31:0] <= M_AXI_GP_wdata[31:0];
			13'h0408: {pcie_write_req_tail,pcie_read_req_tail} <= M_AXI_GP_wdata[31:0];
			13'h0700: mem_req_delay <= M_AXI_GP_wdata[31:0];
			13'h0704: mem_req_delay_dma <= M_AXI_GP_wdata[31:0];
			default: begin
			end
		endcase
	end else begin
		cc_change <= cc_change | (intr_ff ^ {tlp_poisoned_edge[2:0],CC_Reg[15:14],CC_Reg[0]});
	end

end

always@(posedge user_clk) begin

	if(~user_reset_n)
		msi_req <= 0;
	else if(msi_req_r) begin
		if(fc_mwr_grant & !INT_MASK_Reg[msi_di])
			msi_req <= 1;
	end else if(msi_rdy)
		msi_req <= 0;

	if(~user_reset_n) begin
		CC_Reg <= 32'h0;
		AQA_Reg <= 32'h0;
		ASQ_Reg <= 64'h0;
		ACQ_Reg <= 64'h0;
		DB_S_Tail_Admin_Reg <= 16'h0;
		DB_C_Head_Admin_Reg <= 16'h0;
		DB_S_Tail_IO0_Reg <= 16'h0;
		DB_C_Head_IO0_Reg <= 16'h0;
		DB_S_Tail_IO1_Reg <= 16'h0;
		DB_C_Head_IO1_Reg <= 16'h0;
	end else begin

		if(mem_write_o) begin
			casez(mem_addr_o_wr[12:0])
				13'h000C: INT_MASK_Reg <= INT_MASK_Reg | mem_data_o_le[31:0];
				13'h0010: INT_MASK_Reg <= INT_MASK_Reg & ~mem_data_o_le[31:0];
				13'h0014: CC_Reg <= {8'h0,mem_data_o_le[27:4],3'h0,mem_data_o_le[0]};
				13'h0024: AQA_Reg <= {4'b0,mem_data_o_le[27:16],4'b0,mem_data_o_le[11:0]};
				13'h0028: ASQ_Reg[31:0] <= {mem_data_o_le[31:12],12'h0};
				13'h002C: ASQ_Reg[63:32] <= mem_data_o_le;
				13'h0030: ACQ_Reg[31:0] <= {mem_data_o_le[31:12],12'h0};
				13'h0034: ACQ_Reg[63:32] <= mem_data_o_le;
				13'h1000: DB_S_Tail_Admin_Reg <= mem_data_o_le[15:0];
				13'h1004: DB_C_Head_Admin_Reg <= mem_data_o_le[15:0];
				13'h1008: DB_S_Tail_IO0_Reg <= mem_data_o_le[15:0];
				13'h100C: DB_C_Head_IO0_Reg <= mem_data_o_le[15:0];
				13'h1010: DB_S_Tail_IO1_Reg <= mem_data_o_le[15:0];
				13'h1014: DB_C_Head_IO1_Reg <= mem_data_o_le[15:0];
				default: begin
				end
			endcase
		end else if(intr_ff[0] & ~CC_Reg[0]) begin
			DB_S_Tail_Admin_Reg <= 16'h0;
			DB_C_Head_Admin_Reg <= 16'h0;
			DB_S_Tail_IO0_Reg <= 16'h0;
			DB_C_Head_IO0_Reg <= 16'h0;
			DB_S_Tail_IO1_Reg <= 16'h0;
			DB_C_Head_IO1_Reg <= 16'h0;
		end

	end
end

always@* begin
	casez(mem_addr_o_rd[12:0])
		//13'h00: mem_data_i = 32'h28010FFF; //Timeout(8),Reserved(5),Arbitration Mechanism Supported(2), Contiguous Queues Required(1), Maximum Queue Entries Supported(16)
		13'h00: mem_data_i = 32'h200100FF; //Timeout(8),Reserved(5),Arbitration Mechanism Supported(2), Contiguous Queues Required(1), Maximum Queue Entries Supported(16)
		//8'h04: mem_data_i = {8'h0,4'd15,4'd0,3'b0,8'h1,1'b0,4'h0}; //Reserved(8),Memory Page Size Maximum(4),Memory Page Size Minimum(4),Reserved(3),Command Sets Supported(8),Reserved(1),Doorbell Stride(4)
		13'h04: mem_data_i = 32'h00000020; //Reserved(8),Memory Page Size Maximum(4),Memory Page Size Minimum(4),Reserved(3),Command Sets Supported(8),Reserved(1),Doorbell Stride(4)
		13'h08: mem_data_i = {16'h1,8'h0,8'h0};//NVMe Version 1.0
		13'h0C: mem_data_i = INT_MASK_Reg; //INTMS
		13'h10: mem_data_i = INT_MASK_Reg; //INTMC
		13'h14: mem_data_i = CC_Reg;
		13'h1C: mem_data_i = {28'h0,CSTS_Reg}; //Reserved(28),Shutdown Status(2),Controller Fatal Status(1),Ready(1)
		13'h24: mem_data_i = AQA_Reg;
		13'h28: mem_data_i = ASQ_Reg[31:0];
		13'h2C: mem_data_i = ASQ_Reg[63:32];
		13'h30: mem_data_i = ACQ_Reg[31:0];
		13'h34: mem_data_i = ACQ_Reg[63:32];
		default: mem_data_i = 32'h0;
	endcase
end



assign fc_sel = {fc_sel_ff[1:0],!fc_sel_ff[0]};


always @ (posedge user_clk)
begin
	if(~user_reset_n) begin
		r_rx_limit_fc_cpld <= 0;
		r_rx_limit_fc_cplh <= 0;
		r_rx_limit_fc_npd <= 0;
		r_rx_limit_fc_nph <= 0;
		r_rx_limit_fc_pd <= 0;
		r_rx_limit_fc_ph <= 0;

		r_tx_limit_fc_cpld <= 0;
		r_tx_limit_fc_cplh <= 0;
		r_tx_limit_fc_npd <= 0;
		r_tx_limit_fc_nph <= 0;
		r_tx_limit_fc_pd <= 0;
		r_tx_limit_fc_ph <= 0;
		
		fc_sel_ff <= 2'b0;
	end
	else begin
		fc_sel_ff <= fc_sel_ff + 2'd1;
		
		casez(fc_sel_ff)
			2'b00: begin
				r_tx_limit_fc_cpld <= fc_cpld;
				r_tx_limit_fc_cplh <= fc_cplh;
				r_tx_limit_fc_npd <= fc_npd;
				r_tx_limit_fc_nph <= fc_nph;
				r_tx_limit_fc_pd <= fc_pd;
				r_tx_limit_fc_ph <= fc_ph;
			end
			2'b01: begin
				r_tx_consumed_fc_cpld <= fc_cpld;
				r_tx_consumed_fc_cplh <= fc_cplh;
				r_tx_consumed_fc_npd <= fc_npd;
				r_tx_consumed_fc_nph <= fc_nph;
				r_tx_consumed_fc_pd <= fc_pd;
				r_tx_consumed_fc_ph <= fc_ph;
			end
			2'b10: begin
				r_rx_limit_fc_cpld <= fc_cpld;
				r_rx_limit_fc_cplh <= fc_cplh;
				r_rx_limit_fc_npd <= fc_npd;
				r_rx_limit_fc_nph <= fc_nph;
				r_rx_limit_fc_pd <= fc_pd;
				r_rx_limit_fc_ph <= fc_ph;
			end
			default: begin
				r_rx_consumed_fc_cpld <= fc_cpld;
				r_rx_consumed_fc_cplh <= fc_cplh;
				r_rx_consumed_fc_npd <= fc_npd;
				r_rx_consumed_fc_nph <= fc_nph;
				r_rx_consumed_fc_pd <= fc_pd;
				r_rx_consumed_fc_ph <= fc_ph;
			end
		endcase

	end
end

pcie_fc fc_ctrl(
	.pcie_clk(user_clk),
	.pcie_reset_n(user_reset_n),
	
	.fc_mwr_grant(fc_mwr_grant),
	.fc_mrd_grant(fc_mrd_grant),
	.fc_cpl_grant(fc_cpl_grant),
	
	.tx_ph_limit(r_tx_limit_fc_ph),
	.tx_pd_limit(r_tx_limit_fc_pd),
	.tx_ph_consumed(r_tx_consumed_fc_ph),
	.tx_pd_consumed(r_tx_consumed_fc_pd),
	
	.tx_nph_limit(r_tx_limit_fc_nph),
	.tx_nph_consumed(r_tx_consumed_fc_nph),
	
	.MRRS(cfg_dcommand[14:12]),
	.MPS(cfg_dcommand[7:5]),
	
	.mwr_req_tick(mwr_req_tick),
	.mwr_data_inc(mwr_data_inc),
	.mrd_req_tick(mrd_req_tick),
	.mrd_data_inc(mrd_data_inc),
	.cpl_recv_end_tick(cpl_recv_end_tick),
	.cpl_recv_tick(cpl_recv_tick),
	.cpl_data_inc(cpl_data_inc),
	
	.tx_buf_av(tx_buf_av),
	.msi_req(msi_req_r),
	.tx_cfg_req(tx_cfg_req),
	
	.tx_ph_consumed_reserved(tx_ph_consumed_reserved),
	.tx_pd_consumed_reserved(tx_pd_consumed_reserved),
	.tx_nph_consumed_reserved(tx_nph_consumed_reserved),

	.rx_cplh_received(rx_cplh_received),
	.rx_cpld_received(rx_cpld_received),
	.rx_cplh_allocated(rx_cplh_allocated),
	.rx_cpld_allocated(rx_cpld_allocated)
);

dram_writer pcie_to_dram(
	.pcie_clk(user_clk),
	.pcie_reset_n(user_reset_n),
	
	.pcie_rx_valid(m_axis_rx_tvalid),
	//.pcie_rx_data({debug_o[15:0],module_state[15:0],m_axis_rx_tdata[95:0]}),
	.pcie_rx_data({m_axis_rx_tdata[127:104],module_state[15:8],m_axis_rx_tdata[95:0]}),
	
	.pcie_rx_ready(m_axis_rx_tready_w),
	.pcie_rx_run(pcie_rx_run),
	//.pcie_rx_last(m_axis_rx_tlast),
	.pcie_rx_user(m_axis_rx_tuser),
	
	//.pcie_tx_data({s_axis_tx_tdata[127:104],module_state[15:8],s_axis_tx_tdata[95:0]}),
	.pcie_tx_data({s_axis_tx_tdata[127:106],pcie_send_len[9:0],s_axis_tx_tdata[95:0]}),
	.pcie_tx_valid(s_axis_tx_tvalid_w),
	.pcie_tx_ready(s_axis_tx_tready),
	//.pcie_tx_tkeep(s_axis_tx_tkeep),
	//.pcie_tx_tlast(s_axis_tx_tlast),
	//.pcie_tx_tuser(s_axis_tx_tuser),

	.ddr_clk(pl_clk),
	.ddr_reset_n(pl_rstn),
	
	.ddr_awvalid(hp_awvalid),
	.ddr_awaddr(hp_awaddr),
	.ddr_awready(hp_awready),
	.ddr_awlen(hp_awlen),
	.ddr_wvalid(hp_wvalid),
	.ddr_wdata(hp_wdata),
	.ddr_wstrb(hp_wstrb),
	.ddr_wlast(hp_wlast),
	.ddr_wready(hp_wready),
	.ddr_bready(hp_bready),
	.ddr_bvalid(hp_bvalid),
	.ddr_bresp(hp_bresp),
	
	.trigger(trigger),
	.state_o(module_state[3:0]),
	
	.init_end(init_end),
	//.bar0(bar0),
	
	.dram_write_req(dram_write_req),
	.dram_write_addr(dram_write_addr),
	.dram_write_sel(dram_write_sel),
	.dram_write_data(dram_write_data_le),
	.dram_write_ack(dram_write_ack),
	
	.fifo_head_o(module_state[20:16]),
	.fifo_tail_o(module_state[25:21]),
	
	.pcie_record_lock(pcie_ctrl_reg[0])
);
	
dram_reader dram_to_pcie(
	.ddr_clk(pl_clk),
	.ddr_reset_n(pl_rstn),
	
	.pcie_clk(user_clk),
	.pcie_reset_n(user_reset_n),
	
	.db_admin_s_tail(DB_S_Tail_Admin_Reg),
	.db_admin_s_addr(ASQ_Reg),
	
	.pcie_req_tail_change( GPIO_o_r3[32] ^ GPIO_o_r2[32] ),
	.pcie_send_from_ddr_read_addr(pcie_send_from_ddr_read_addr),
	.pcie_send_from_ddr_write_addr(pcie_send_from_ddr_write_addr),

	.ddr_arvalid(hp_arvalid),
	.ddr_araddr(hp_araddr),
	.ddr_arready(hp_arready),

	.ddr_rready(hp_rready),
	.ddr_rvalid(hp_rvalid),
	.ddr_rdata(hp_rdata),
	.ddr_rresp(hp_rresp),
	
	.state_o(module_state[7:4]),
		
	.pcie_send_req(pcie_send_req),
	.pcie_send_rw(pcie_send_rw),
	.pcie_send_addr(pcie_send_addr),
	.pcie_send_data(pcie_send_data),
	.pcie_send_len(pcie_send_len),
	.pcie_send_tag(pcie_send_tag),
	.pcie_send_ack(pcie_send_ack),
	
	.pcie_send_end(pcie_send_end),
	.pcie_recv_tag_free(pcie_recv_tag_free),
	
	.cpld_recv0_addr(cpld_recv0_addr),
	.cpld_recv1_addr(cpld_recv1_addr),
	.cpld_recv2_addr(cpld_recv2_addr),
	.cpld_recv3_addr(cpld_recv3_addr),
	.cpld_recv4_addr(cpld_recv4_addr),
	.cpld_recv5_addr(cpld_recv5_addr),
	.cpld_recv6_addr(cpld_recv6_addr),
	.cpld_recv7_addr(cpld_recv7_addr),
	
	.cpld_recv0_len(cpld_recv0_len),
	.cpld_recv1_len(cpld_recv1_len),
	.cpld_recv2_len(cpld_recv2_len),
	.cpld_recv3_len(cpld_recv3_len),
	.cpld_recv4_len(cpld_recv4_len),
	.cpld_recv5_len(cpld_recv5_len),
	.cpld_recv6_len(cpld_recv6_len),
	.cpld_recv7_len(cpld_recv7_len),
	
	.req_flag0_addr(req_flag0_addr),
	.req_flag1_addr(req_flag1_addr),
	.req_flag2_addr(req_flag2_addr),
	.req_flag3_addr(req_flag3_addr),
	.req_flag4_addr(req_flag4_addr),
	.req_flag5_addr(req_flag5_addr),
	.req_flag6_addr(req_flag6_addr),
	.req_flag7_addr(req_flag7_addr),
	
	.pcie_read_req_tail(pcie_read_req_tail),
	.pcie_read_req_head(pcie_read_req_head),
	.pcie_write_req_tail(pcie_write_req_tail),
	.pcie_write_req_head(pcie_write_req_head),
	.pcie_read_req_overlap(pcie_read_req_overlap),
	.pcie_write_req_overlap(pcie_write_req_overlap),
	
	.pcie_params({cfg_lcommand[3],cfg_dcommand[14:12],cfg_dcommand[7:5]}),
	.mem_req_delay(mem_req_delay_dma),
	.reset_pcie_recv(reset_pcie_recv_reg)
);

tlp_rx_engine rx_engine (
	.pcie_clk(user_clk), //125Mhz
	.pcie_reset_n(user_reset_n),

	.m_axis_rx_tdata(m_axis_rx_tdata),
	.m_axis_rx_tvalid(m_axis_rx_tvalid & pcie_rx_run),
	//.m_axis_rx_tvalid(m_axis_rx_tvalid),
	.m_axis_rx_tready(m_axis_rx_tready_w),
	.m_axis_rx_tkeep(m_axis_rx_tkeep),
	//.m_axis_rx_tlast(),
	.m_axis_rx_tuser(m_axis_rx_tuser),
	
	.tlp_header(tlp_header),
	.tx_req(tx_req),
	.tx_ack(tx_ack),
	
	.mem_write_o(mem_write_o),
	.mem_ack_i(1),
	.mem_addr_o(mem_addr_o_wr),
	.mem_data_o(mem_data_o),
	
	.init_end(init_end),
	//.bar0(bar0),
	.state_o(module_state[11:8]),
	
	.cfg_mgmt_do(cfg_mgmt_do),
	.cfg_mgmt_rd_wr_done(cfg_mgmt_rd_wr_done),
	.cfg_mgmt_dwaddr(cfg_mgmt_dwaddr),
	.cfg_mgmt_rd_en(cfg_mgmt_rd_en),
	
	//.pcie_recv_to_ddr_addr(pcie_recv_to_ddr_addr),
	
	.dram_write_req(dram_write_req),
	.dram_write_addr(dram_write_addr),
	.dram_write_sel(dram_write_sel),
	.dram_write_data(dram_write_data),
	.dram_write_ack(dram_write_ack),
	
	.dram_write_complete(dram_write_complete),
	.pcie_recv_tag_free(pcie_recv_tag_free),
	
	.cpld_recv0_addr(cpld_recv0_addr),
	.cpld_recv1_addr(cpld_recv1_addr),
	.cpld_recv2_addr(cpld_recv2_addr),
	.cpld_recv3_addr(cpld_recv3_addr),
	.cpld_recv4_addr(cpld_recv4_addr),
	.cpld_recv5_addr(cpld_recv5_addr),
	.cpld_recv6_addr(cpld_recv6_addr),
	.cpld_recv7_addr(cpld_recv7_addr),
	
	.cpld_recv0_len(cpld_recv0_len),
	.cpld_recv1_len(cpld_recv1_len),
	.cpld_recv2_len(cpld_recv2_len),
	.cpld_recv3_len(cpld_recv3_len),
	.cpld_recv4_len(cpld_recv4_len),
	.cpld_recv5_len(cpld_recv5_len),
	.cpld_recv6_len(cpld_recv6_len),
	.cpld_recv7_len(cpld_recv7_len),
	
	.req_flag0_addr(req_flag0_addr),
	.req_flag1_addr(req_flag1_addr),
	.req_flag2_addr(req_flag2_addr),
	.req_flag3_addr(req_flag3_addr),
	.req_flag4_addr(req_flag4_addr),
	.req_flag5_addr(req_flag5_addr),
	.req_flag6_addr(req_flag6_addr),
	.req_flag7_addr(req_flag7_addr),
	
	.tlp_poisoned_edge(tlp_poisoned_edge),
	
	.cpld_recv0_count(cpld_recv0_count),
	
	.mrd_resend_req(mrd_resend_req),
	.mrd_resend_addr(mrd_resend_addr),
	.mrd_resend_len(mrd_resend_len),
	.mrd_resend_tag(mrd_resend_tag),
	.mrd_resend_ack(mrd_resend_ack),
	
	.pcie_params({cfg_lcommand[3],cfg_dcommand[14:12],cfg_dcommand[7:5]}),
	.mrd_fail_count(mrd_fail_count),
	
	.cpl_recv_end_tick(cpl_recv_end_tick),
	.cpl_recv_tick(cpl_recv_tick),
	.cpl_data_inc(cpl_data_inc),
	
	.debug_o(debug_o)
);

tlp_tx_engine tx_engine (
	.pcie_clk(user_clk), //125Mhz
	.pcie_reset_n(user_reset_n),

	.s_axis_tx_tdata(s_axis_tx_tdata),
	.s_axis_tx_tvalid(s_axis_tx_tvalid_w),
	.s_axis_tx_tready(s_axis_tx_tready & pcie_rx_run),
	.s_axis_tx_tkeep(s_axis_tx_tkeep),
	.s_axis_tx_tlast(s_axis_tx_tlast),
	.s_axis_tx_tuser(s_axis_tx_tuser),
	
	.mem_read_o(mem_read_o),
	.mem_addr_o(mem_addr_o_rd),
	.mem_data_i(mem_data_i_le),
	.mem_ack_i(1),
	
	.completer_id(completer_id),
	.tlp_header(tlp_header),
	.tx_req(tx_req),
	.tx_ack(tx_ack),
	
	.pcie_send_req(pcie_send_req),
	.pcie_send_rw(pcie_send_rw),
	.pcie_send_addr(pcie_send_addr),
	.pcie_send_data(pcie_send_data_le),
	.pcie_send_len(pcie_send_len),
	.pcie_send_tag(pcie_send_tag),
	.pcie_send_ack(pcie_send_ack),
	
	.state_o(module_state[15:12]),
	//.pcie_send_end(pcie_send_end),
	//.fc_grant(fc_grant),
	/*.fc_cpld_grant(r_tx_cpld_gnt & (|tx_buf_av[5:3])),
	.fc_mrd_grant(r_tx_mrd_gnt & (|tx_buf_av[5:3])),
	.fc_mwr_grant(r_tx_mwr_gnt & (|tx_buf_av[5:3])),*/
	
	.fc_cpl_grant(fc_cpl_grant),
	.fc_mrd_grant(fc_mrd_grant),
	.fc_mwr_grant(fc_mwr_grant),
	
	.mrd_resend_req(mrd_resend_req),
	.mrd_resend_addr(mrd_resend_addr),
	.mrd_resend_len(mrd_resend_len),
	.mrd_resend_tag(mrd_resend_tag),
	.mrd_resend_ack(mrd_resend_ack),
	
	.mem_req_delay(mem_req_delay),
	
	.rx_np_ok(rx_np_ok),
	.rx_np_req(rx_np_req),
	
	//.msi_permitted(msi_permitted),
	.msi_idle(1),
	
	.mwr_req_tick(mwr_req_tick),
	.mwr_data_inc(mwr_data_inc),
	.mrd_req_tick(mrd_req_tick),
	.mrd_data_inc(mrd_data_inc)
);

endmodule
