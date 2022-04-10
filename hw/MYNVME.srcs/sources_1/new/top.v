`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/14 17:21:19
// Design Name: 
// Module Name: top
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


module top(
	inout [14:0]DDR_addr,
	inout [2:0]DDR_ba,
	inout DDR_cas_n,
	inout DDR_ck_n,
	inout DDR_ck_p,
	inout DDR_cke,
	inout DDR_cs_n,
	inout [3:0]DDR_dm,
	inout [31:0]DDR_dq,
	inout [3:0]DDR_dqs_n,
	inout [3:0]DDR_dqs_p,
	inout DDR_odt,
	inout DDR_ras_n,
	inout DDR_reset_n,
	inout DDR_we_n,
	
    output [14:0]DDR_PL_addr,
    output [2:0]DDR_PL_ba,
    output DDR_PL_cas_n,
    output [0:0]DDR_PL_ck_n,
    output [0:0]DDR_PL_ck_p,
    output [0:0]DDR_PL_cke,
    output [0:0]DDR_PL_cs_n,
    output [3:0]DDR_PL_dm,
    inout [31:0]DDR_PL_dq,
    inout [3:0]DDR_PL_dqs_n,
    inout [3:0]DDR_PL_dqs_p,
    output [0:0]DDR_PL_odt,
    output DDR_PL_ras_n,
    output DDR_PL_reset_n,
    output DDR_PL_we_n,
	
	input sys_clk_p, 
	input sys_clk_n,
	input sys_rst_n,
	
	output [3:0] pci_exp_txp,
	output [3:0] pci_exp_txn,
	input [3:0] pci_exp_rxp,
	input [3:0] pci_exp_rxn,
	
	input CLK_50M,
	input PS_CLK,
	input PS_SRSTB,
	input PS_PORB,
	input DDR_VRP,
	input DDR_VRN,
	
	input PL_KEY1,
	input PL_KEY2,
	
	output PL_LED1,
	output PL_LED2,
	output PL_LED3,
	output PL_LED4,
	output PL_LED5,
	output PL_LED6,
	
	inout [53:0] MIO
);
	
	wire sys_rst_n_c;
	wire sys_clk;
	
	wire clk_pl;
	wire rstn_pl;

	IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));
	IBUFDS_GTE2 refclk_ibuf (.O(sys_clk), .ODIV2(), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));
	
	
	
	wire user_clk;
	wire user_reset;
	wire user_lnk_up;

	wire s_axis_tx_tready;
	wire [3:0] s_axis_tx_tuser;
	wire [127:0] s_axis_tx_tdata;
	wire [15:0] s_axis_tx_tkeep;
	wire s_axis_tx_tlast;
	wire s_axis_tx_tvalid;
	wire [5:0] tx_buf_av;

	wire [127:0] m_axis_rx_tdata;
	wire [15:0] m_axis_rx_tkeep;
	wire m_axis_rx_tlast;
	wire m_axis_rx_tvalid;
	wire m_axis_rx_tready;
	wire [21:0] m_axis_rx_tuser;
	
	
	wire [31:0] S_AXI_HP0_awaddr;
	wire [3:0] S_AXI_HP0_awlen;
	wire S_AXI_HP0_awready;
	wire S_AXI_HP0_awvalid;
	
	wire S_AXI_HP0_bready;
	wire [1:0] S_AXI_HP0_bresp;
	wire S_AXI_HP0_bvalid;
	
	wire S_AXI_HP0_wlast;
	wire S_AXI_HP0_wready;
	wire [7:0] S_AXI_HP0_wstrb;
	wire S_AXI_HP0_wvalid;
	wire [63:0] S_AXI_HP0_wdata;
	
	wire [31:0] S_AXI_HP0_araddr;
	wire S_AXI_HP0_arready;
	wire S_AXI_HP0_arvalid;
	
	wire [63:0] S_AXI_HP0_rdata;
	wire S_AXI_HP0_rready;
	wire [1:0] S_AXI_HP0_rresp;
	wire S_AXI_HP0_rvalid;
	wire S_AXI_HP0_rlast;
	
	wire [31:0]M_AXI_GP_araddr;
	wire M_AXI_GP_arready;
	wire M_AXI_GP_arvalid;
	wire [31:0]M_AXI_GP_awaddr;
	wire M_AXI_GP_awready;
	wire M_AXI_GP_awvalid;
	wire M_AXI_GP_bready;
	wire [1:0]M_AXI_GP_bresp;
	wire M_AXI_GP_bvalid;
	wire [31:0]M_AXI_GP_rdata;
	wire M_AXI_GP_rready;
	wire [1:0]M_AXI_GP_rresp;
	wire M_AXI_GP_rvalid;
	wire [31:0]M_AXI_GP_wdata;
	wire M_AXI_GP_wready;
	wire M_AXI_GP_wvalid;
	wire [3:0] M_AXI_GP_wstrb;


	wire [15:0] completer_id;
	
	/*wire [31:0] cfg_mgmt_do;
	wire cfg_mgmt_rd_wr_done;
	wire [9:0] cfg_mgmt_dwaddr;
	wire cfg_mgmt_rd_en;*/
	
	wire pcie_irq;
	wire fclk;
	wire fclk_reset_n;
	
	
	wire cfg_interrupt;
	wire cfg_interrupt_rdy;
	wire [7:0] cfg_interrupt_di;
	wire [2:0] cfg_interrupt_mmenable;
	wire [7:0] cfg_interrupt_do;
	wire cfg_interrupt_msixfm;
	wire cfg_interrupt_msienable;
	wire cfg_interrupt_msixenable;
	wire cfg_interrupt_assert;
	
	
	wire	[11:0]								fc_cpld;
	wire	[7:0]								fc_cplh;
	wire	[11:0]								fc_npd;
	wire	[7:0]								fc_nph;
	wire	[11:0]								fc_pd;
	wire	[7:0]								fc_ph;
	wire	[2:0]								fc_sel;
	
	wire rx_np_ok;
	wire rx_np_req;
	wire [15:0] cfg_dcommand;
	wire [15:0] cfg_lcommand;
	wire [15:0] cfg_command;
	wire [15:0] cfg_dstatus;
	wire [15:0] cfg_dcommand2;
	wire [15:0] cfg_lstatus;
	wire tx_cfg_req;

	

    wire [31:0]M_AXI_SYS_araddr;
    wire [1:0]M_AXI_SYS_arburst;
    wire [3:0]M_AXI_SYS_arcache;
    wire [11:0]M_AXI_SYS_arid;
    wire [3:0]M_AXI_SYS_arlen;
    wire [1:0]M_AXI_SYS_arlock;
    wire [2:0]M_AXI_SYS_arprot;
    wire [3:0]M_AXI_SYS_arqos;
    wire M_AXI_SYS_arready;
    wire [2:0]M_AXI_SYS_arsize;
    wire M_AXI_SYS_arvalid;
    wire [31:0]M_AXI_SYS_awaddr;
    wire [1:0]M_AXI_SYS_awburst;
    wire [3:0]M_AXI_SYS_awcache;
    wire [11:0]M_AXI_SYS_awid;
    wire [3:0]M_AXI_SYS_awlen;
    wire [1:0]M_AXI_SYS_awlock;
    wire [2:0]M_AXI_SYS_awprot;
    wire [3:0]M_AXI_SYS_awqos;
    wire M_AXI_SYS_awready;
    wire [2:0]M_AXI_SYS_awsize;
    wire M_AXI_SYS_awvalid;
    wire [11:0]M_AXI_SYS_bid;
    wire M_AXI_SYS_bready;
    wire [1:0]M_AXI_SYS_bresp;
    wire M_AXI_SYS_bvalid;
    wire [31:0]M_AXI_SYS_rdata;
    wire [11:0]M_AXI_SYS_rid;
    wire M_AXI_SYS_rlast;
    wire M_AXI_SYS_rready;
    wire [1:0]M_AXI_SYS_rresp;
    wire M_AXI_SYS_rvalid;
    wire [31:0]M_AXI_SYS_wdata;
    wire M_AXI_SYS_wlast;
    wire M_AXI_SYS_wready;
    wire [3:0]M_AXI_SYS_wstrb;
    wire M_AXI_SYS_wvalid;
    
    wire [63:0] GPIO_o;
	
	
	/*reg user_reset_r;
	
	always@(posedge user_clk)
		if(user_reset) begin
			user_reset_r <= 1'b0;
		end else begin
			user_reset_r <= user_lnk_up;
		end*/

		
	pcie_7x_0 pcie_7x_0_i
	(
		.sys_clk                                   ( sys_clk ),
		.sys_rst_n                                 ( sys_rst_n_c ),
		
		.pci_exp_txn                               ( pci_exp_txn ),
		.pci_exp_txp                               ( pci_exp_txp ),
		.pci_exp_rxn                               ( pci_exp_rxn ),
		.pci_exp_rxp                               ( pci_exp_rxp ),

		.user_clk_out                              ( user_clk ),
		.user_reset_out                            ( user_reset ),
		.user_lnk_up                               ( user_lnk_up ),
		.user_app_rdy                              ( ),

		.s_axis_tx_tready                          ( s_axis_tx_tready ),
		.s_axis_tx_tdata                           ( s_axis_tx_tdata ),
		.s_axis_tx_tkeep                           ( s_axis_tx_tkeep ),
		.s_axis_tx_tuser                           ( s_axis_tx_tuser ),
		.s_axis_tx_tlast                           ( s_axis_tx_tlast ),
		.s_axis_tx_tvalid                          ( s_axis_tx_tvalid ),
		.tx_buf_av(tx_buf_av),

		.m_axis_rx_tdata                           ( m_axis_rx_tdata ),
		.m_axis_rx_tkeep                           ( m_axis_rx_tkeep ),
		.m_axis_rx_tlast                           ( m_axis_rx_tlast ),
		.m_axis_rx_tvalid                          ( m_axis_rx_tvalid ),
		.m_axis_rx_tready                          ( m_axis_rx_tready ),
		.m_axis_rx_tuser                           ( m_axis_rx_tuser ),

		//------------------------------------------------//
		// EP Only                                        //
		//------------------------------------------------//
		.cfg_interrupt                             ( cfg_interrupt ),
		.cfg_interrupt_rdy                         ( cfg_interrupt_rdy ),
		.cfg_interrupt_assert                      ( 1'b0 ),
		.cfg_interrupt_di                          ( cfg_interrupt_di ),
		.cfg_interrupt_do                          ( cfg_interrupt_do ),
		.cfg_interrupt_mmenable                    ( cfg_interrupt_mmenable ),
		.cfg_interrupt_msienable                   ( cfg_interrupt_msienable ),
		.cfg_interrupt_msixenable                  ( cfg_interrupt_msixenable ),
		.cfg_interrupt_msixfm                      ( cfg_interrupt_msixfm ),
		.cfg_interrupt_stat                        ( 1'b0 ),
		.cfg_pciecap_interrupt_msgnum              ( 5'd8 ),
		
		.cfg_bus_number(completer_id[15:8]),
		.cfg_device_number(completer_id[7:3]),
		.cfg_function_number(completer_id[2:0]),
		
		/*.cfg_mgmt_do(cfg_mgmt_do),
		.cfg_mgmt_rd_wr_done(cfg_mgmt_rd_wr_done),
		.cfg_mgmt_wr_rw1c_as_rw(1'b0),
		.cfg_mgmt_di(32'h0),
		.cfg_mgmt_byte_en(4'hF),
		.cfg_mgmt_dwaddr(cfg_mgmt_dwaddr),
		.cfg_mgmt_wr_en(1'b0),
		.cfg_mgmt_rd_en(cfg_mgmt_rd_en),
		.cfg_mgmt_wr_readonly(1'b1),*/
		
		.fc_cpld									(fc_cpld),
		.fc_cplh									(fc_cplh),
		.fc_npd										(fc_npd),
		.fc_nph										(fc_nph),
		.fc_pd										(fc_pd),
		.fc_ph										(fc_ph),
		.fc_sel										(fc_sel),
		
		.cfg_trn_pending(1'b0),
		.cfg_pm_halt_aspm_l0s(1'b0),
		.cfg_pm_halt_aspm_l1(1'b0),
		.cfg_pm_force_state_en(1'b0),
		.cfg_pm_force_state(2'b0),
		.cfg_dsn(64'b0),
		.cfg_ds_device_number(5'b0),
		.cfg_ds_function_number(3'b0),
		.cfg_ds_bus_number(8'b0),
		.cfg_pm_send_pme_to(1'b0),
		.cfg_pm_wake(1'b0),
		.rx_np_ok(rx_np_ok),
		.rx_np_req(rx_np_req),
		.tx_cfg_gnt(1'b1),
		.cfg_turnoff_ok(1'b0),
		
		.cfg_dcommand(cfg_dcommand),
		.cfg_lcommand(cfg_lcommand),
		.cfg_command(cfg_command),
		.cfg_dstatus(cfg_dstatus),
		.cfg_dcommand2(cfg_dcommand2),
		.cfg_lstatus(cfg_lstatus),
		.tx_cfg_req(tx_cfg_req)
	);
	
	design_zynq_wrapper zynq7035
	(
		.DDR_addr(DDR_addr),
		.DDR_ba(DDR_ba),
		.DDR_cas_n(DDR_cas_n),
		.DDR_ck_n(DDR_ck_n),
		.DDR_ck_p(DDR_ck_p),
		.DDR_cke(DDR_cke),
		.DDR_cs_n(DDR_cs_n),
		.DDR_dm(DDR_dm),
		.DDR_dq(DDR_dq),
		.DDR_dqs_n(DDR_dqs_n),
		.DDR_dqs_p(DDR_dqs_p),
		.DDR_odt(DDR_odt),
		.DDR_ras_n(DDR_ras_n),
		.DDR_reset_n(DDR_reset_n),
		.DDR_we_n(DDR_we_n),
		
		.DDR_PL_addr(DDR_PL_addr),
		.DDR_PL_ba(DDR_PL_ba),
		.DDR_PL_cas_n(DDR_PL_cas_n),
		.DDR_PL_ck_n(DDR_PL_ck_n),
		.DDR_PL_ck_p(DDR_PL_ck_p),
		.DDR_PL_cke(DDR_PL_cke),
		.DDR_PL_cs_n(DDR_PL_cs_n),
		.DDR_PL_dm(DDR_PL_dm),
		.DDR_PL_dq(DDR_PL_dq),
		.DDR_PL_dqs_n(DDR_PL_dqs_n),
		.DDR_PL_dqs_p(DDR_PL_dqs_p),
		.DDR_PL_odt(DDR_PL_odt),
		.DDR_PL_ras_n(DDR_PL_ras_n),
		.DDR_PL_reset_n(DDR_PL_reset_n),
		.DDR_PL_we_n(DDR_PL_we_n),
		
		.FIXED_IO_ddr_vrn(DDR_VRN),
		.FIXED_IO_ddr_vrp(DDR_VRP),
		.FIXED_IO_mio(MIO),
		.FIXED_IO_ps_clk(PS_CLK),
		.FIXED_IO_ps_porb(PS_PORB),
		.FIXED_IO_ps_srstb(PS_SRSTB),
		
		.S_AXI_HP0_araddr(S_AXI_HP0_araddr),
		.S_AXI_HP0_arburst(2'b01),
		.S_AXI_HP0_arcache(4'd0),
		.S_AXI_HP0_arid(6'd5),
		.S_AXI_HP0_arlen(4'd1),
		.S_AXI_HP0_arlock(2'b00),
		.S_AXI_HP0_arprot(3'b000),
		.S_AXI_HP0_arqos(4'd0),
		.S_AXI_HP0_arready(S_AXI_HP0_arready),
		.S_AXI_HP0_arsize(3'd3),
		.S_AXI_HP0_arvalid(S_AXI_HP0_arvalid),
		.S_AXI_HP0_awaddr(S_AXI_HP0_awaddr),
		.S_AXI_HP0_awburst(2'b01),
		.S_AXI_HP0_awcache(4'd0),
		.S_AXI_HP0_awid(6'd5),
		.S_AXI_HP0_awlen(S_AXI_HP0_awlen),
		.S_AXI_HP0_awlock(2'b00),
		.S_AXI_HP0_awprot(3'b000),
		.S_AXI_HP0_awqos(4'd0),
		.S_AXI_HP0_awready(S_AXI_HP0_awready),
		.S_AXI_HP0_awsize(3'd3),
		.S_AXI_HP0_awvalid(S_AXI_HP0_awvalid),
		.S_AXI_HP0_bid(),
		.S_AXI_HP0_bready(S_AXI_HP0_bready),
		.S_AXI_HP0_bresp(S_AXI_HP0_bresp),
		.S_AXI_HP0_bvalid(S_AXI_HP0_bvalid),
		.S_AXI_HP0_rdata(S_AXI_HP0_rdata),
		.S_AXI_HP0_rid(),
		.S_AXI_HP0_rlast(S_AXI_HP0_rlast),
		.S_AXI_HP0_rready(S_AXI_HP0_rready),
		.S_AXI_HP0_rresp(S_AXI_HP0_rresp),
		.S_AXI_HP0_rvalid(S_AXI_HP0_rvalid),
		.S_AXI_HP0_wdata(S_AXI_HP0_wdata),
		.S_AXI_HP0_wid(6'd5),
		.S_AXI_HP0_wlast(S_AXI_HP0_wlast),
		.S_AXI_HP0_wready(S_AXI_HP0_wready),
		.S_AXI_HP0_wstrb(S_AXI_HP0_wstrb),
		.S_AXI_HP0_wvalid(S_AXI_HP0_wvalid),
	
		.Core0_nIRQ_0(pcie_irq),

        .M_AXI_GP_araddr(M_AXI_GP_araddr),
        .M_AXI_GP_arprot(),
        .M_AXI_GP_arready(M_AXI_GP_arready),
        .M_AXI_GP_arvalid(M_AXI_GP_arvalid),
        .M_AXI_GP_awaddr(M_AXI_GP_awaddr),
        .M_AXI_GP_awprot(),
        .M_AXI_GP_awready(M_AXI_GP_awready),
        .M_AXI_GP_awvalid(M_AXI_GP_awvalid),
        .M_AXI_GP_bready(M_AXI_GP_bready),
        .M_AXI_GP_bresp(M_AXI_GP_bresp),
        .M_AXI_GP_bvalid(M_AXI_GP_bvalid),
        .M_AXI_GP_rdata(M_AXI_GP_rdata),
        .M_AXI_GP_rready(M_AXI_GP_rready),
        .M_AXI_GP_rresp(M_AXI_GP_rresp),
        .M_AXI_GP_rvalid(M_AXI_GP_rvalid),
        .M_AXI_GP_wdata(M_AXI_GP_wdata),
        .M_AXI_GP_wready(M_AXI_GP_wready),
        .M_AXI_GP_wstrb(M_AXI_GP_wstrb),
        .M_AXI_GP_wvalid(M_AXI_GP_wvalid),
        
        .clk_50M(CLK_50M),
        .clk_pl(clk_pl),
        .rstn_pl(rstn_pl),
		
		.pcie_clk(user_clk),
		.pcie_rstn(user_lnk_up & ~user_reset),
		.GPIO_0_tri_i({63'b0,user_lnk_up & ~user_reset}),
		.GPIO_0_tri_o(GPIO_o)
	);
	
	pcie_bridge pcie_bridge(

		.user_clk(user_clk),
		.user_reset_n(user_lnk_up & ~user_reset),
		//.user_link_up(user_lnk_up & ~user_reset),

		.s_axis_tx_tdata(s_axis_tx_tdata),
		.s_axis_tx_tvalid(s_axis_tx_tvalid),
		.s_axis_tx_tready(s_axis_tx_tready),
		.s_axis_tx_tkeep(s_axis_tx_tkeep),
		.s_axis_tx_tlast(s_axis_tx_tlast),
		.s_axis_tx_tuser(s_axis_tx_tuser),

		.m_axis_rx_tdata(m_axis_rx_tdata),
		.m_axis_rx_tvalid(m_axis_rx_tvalid),
		.m_axis_rx_tready(m_axis_rx_tready),
		.m_axis_rx_tkeep(m_axis_rx_tkeep),
		.m_axis_rx_tlast(m_axis_rx_tlast),
		.m_axis_rx_tuser(m_axis_rx_tuser),
	
		.pl_clk(clk_pl),
		.pl_rstn(rstn_pl),
	
		.hp_arvalid(S_AXI_HP0_arvalid),
		.hp_araddr(S_AXI_HP0_araddr),
		.hp_arready(S_AXI_HP0_arready),
		
		.hp_rready(S_AXI_HP0_rready),
		.hp_rvalid(S_AXI_HP0_rvalid),
		.hp_rresp(S_AXI_HP0_rresp),
		.hp_rlast(S_AXI_HP0_rlast),
		.hp_rdata(S_AXI_HP0_rdata),
	
		.hp_awvalid(S_AXI_HP0_awvalid),
		.hp_awaddr(S_AXI_HP0_awaddr),
		.hp_awlen(S_AXI_HP0_awlen),
		.hp_awready(S_AXI_HP0_awready),
		
		.hp_wvalid(S_AXI_HP0_wvalid),
		.hp_wdata(S_AXI_HP0_wdata),
		.hp_wstrb(S_AXI_HP0_wstrb),
		.hp_wlast(S_AXI_HP0_wlast),
		.hp_wready(S_AXI_HP0_wready),
		
		.hp_bready(S_AXI_HP0_bready),
		.hp_bvalid(S_AXI_HP0_bvalid),
		.hp_bresp(S_AXI_HP0_bresp),
		
		.M_AXI_GP_araddr(M_AXI_GP_araddr),
        .M_AXI_GP_arready(M_AXI_GP_arready),
        .M_AXI_GP_arvalid(M_AXI_GP_arvalid),
        .M_AXI_GP_awaddr(M_AXI_GP_awaddr),
        .M_AXI_GP_awready(M_AXI_GP_awready),
        .M_AXI_GP_awvalid(M_AXI_GP_awvalid),
        .M_AXI_GP_bready(M_AXI_GP_bready),
        .M_AXI_GP_bresp(M_AXI_GP_bresp),
        .M_AXI_GP_bvalid(M_AXI_GP_bvalid),
        .M_AXI_GP_rdata(M_AXI_GP_rdata),
        .M_AXI_GP_rready(M_AXI_GP_rready),
        .M_AXI_GP_rresp(M_AXI_GP_rresp),
        .M_AXI_GP_rvalid(M_AXI_GP_rvalid),
        .M_AXI_GP_wdata(M_AXI_GP_wdata),
        .M_AXI_GP_wready(M_AXI_GP_wready),
        .M_AXI_GP_wvalid(M_AXI_GP_wvalid),
		.M_AXI_GP_wstrb(M_AXI_GP_wstrb),
		
		.trigger(1'b0),
		
		.completer_id(completer_id),
		
		.cfg_mgmt_do(cfg_mgmt_do),
		.cfg_mgmt_rd_wr_done(cfg_mgmt_rd_wr_done),
		.cfg_mgmt_dwaddr(cfg_mgmt_dwaddr),
		.cfg_mgmt_rd_en(cfg_mgmt_rd_en),
		
		.pcie_irq(pcie_irq),
		.fclk(fclk),
		.fclk_reset_n(fclk_reset_n),
		
		.msi_req(cfg_interrupt),
		.msi_rdy(cfg_interrupt_rdy),
		.msi_di(cfg_interrupt_di),
		.msi_num(cfg_interrupt_mmenable),
		.msi_do(cfg_interrupt_do),
		.msi_msienable(cfg_interrupt_msienable),
		.msi_msixenable(cfg_interrupt_msixenable),
		.msi_msixfm(cfg_interrupt_msixfm),
		.msi_assert(cfg_interrupt_assert),
		
		.fc_cpld									(fc_cpld),
		.fc_cplh									(fc_cplh),
		.fc_npd										(fc_npd),
		.fc_nph										(fc_nph),
		.fc_pd										(fc_pd),
		.fc_ph										(fc_ph),
		.fc_sel										(fc_sel),
		
		.tx_buf_av(tx_buf_av),
		.rx_np_ok(rx_np_ok),
		.rx_np_req(rx_np_req),
		.cfg_dcommand(cfg_dcommand),
		.cfg_lcommand(cfg_lcommand),
		.cfg_command(cfg_command),
		.cfg_dstatus(cfg_dstatus),
		.cfg_dcommand2(cfg_dcommand2),
		.cfg_lstatus(cfg_lstatus),
		.tx_cfg_req(tx_cfg_req),
		
		.GPIO_o(GPIO_o)

	);
		
	
endmodule
