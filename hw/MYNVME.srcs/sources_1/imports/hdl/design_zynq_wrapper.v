//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.1 (win64) Build 3247384 Thu Jun 10 19:36:33 MDT 2021
//Date        : Wed Mar 23 23:11:50 2022
//Host        : DESKTOP-TFNO2LM running 64-bit major release  (build 9200)
//Command     : generate_target design_zynq_wrapper.bd
//Design      : design_zynq_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_zynq_wrapper
   (Core0_nIRQ_0,
    DDR_PL_addr,
    DDR_PL_ba,
    DDR_PL_cas_n,
    DDR_PL_ck_n,
    DDR_PL_ck_p,
    DDR_PL_cke,
    DDR_PL_cs_n,
    DDR_PL_dm,
    DDR_PL_dq,
    DDR_PL_dqs_n,
    DDR_PL_dqs_p,
    DDR_PL_odt,
    DDR_PL_ras_n,
    DDR_PL_reset_n,
    DDR_PL_we_n,
    DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    GPIO_0_tri_i,
    GPIO_0_tri_o,
    M_AXI_GP_araddr,
    M_AXI_GP_arprot,
    M_AXI_GP_arready,
    M_AXI_GP_arvalid,
    M_AXI_GP_awaddr,
    M_AXI_GP_awprot,
    M_AXI_GP_awready,
    M_AXI_GP_awvalid,
    M_AXI_GP_bready,
    M_AXI_GP_bresp,
    M_AXI_GP_bvalid,
    M_AXI_GP_rdata,
    M_AXI_GP_rready,
    M_AXI_GP_rresp,
    M_AXI_GP_rvalid,
    M_AXI_GP_wdata,
    M_AXI_GP_wready,
    M_AXI_GP_wstrb,
    M_AXI_GP_wvalid,
    S_AXI_HP0_araddr,
    S_AXI_HP0_arburst,
    S_AXI_HP0_arcache,
    S_AXI_HP0_arid,
    S_AXI_HP0_arlen,
    S_AXI_HP0_arlock,
    S_AXI_HP0_arprot,
    S_AXI_HP0_arqos,
    S_AXI_HP0_arready,
    S_AXI_HP0_arsize,
    S_AXI_HP0_arvalid,
    S_AXI_HP0_awaddr,
    S_AXI_HP0_awburst,
    S_AXI_HP0_awcache,
    S_AXI_HP0_awid,
    S_AXI_HP0_awlen,
    S_AXI_HP0_awlock,
    S_AXI_HP0_awprot,
    S_AXI_HP0_awqos,
    S_AXI_HP0_awready,
    S_AXI_HP0_awsize,
    S_AXI_HP0_awvalid,
    S_AXI_HP0_bid,
    S_AXI_HP0_bready,
    S_AXI_HP0_bresp,
    S_AXI_HP0_bvalid,
    S_AXI_HP0_rdata,
    S_AXI_HP0_rid,
    S_AXI_HP0_rlast,
    S_AXI_HP0_rready,
    S_AXI_HP0_rresp,
    S_AXI_HP0_rvalid,
    S_AXI_HP0_wdata,
    S_AXI_HP0_wid,
    S_AXI_HP0_wlast,
    S_AXI_HP0_wready,
    S_AXI_HP0_wstrb,
    S_AXI_HP0_wvalid,
    clk_50M,
    clk_pl,
    pcie_clk,
    pcie_rstn,
    rstn_pl);
  input Core0_nIRQ_0;
  output [14:0]DDR_PL_addr;
  output [2:0]DDR_PL_ba;
  output DDR_PL_cas_n;
  output [0:0]DDR_PL_ck_n;
  output [0:0]DDR_PL_ck_p;
  output [0:0]DDR_PL_cke;
  output [0:0]DDR_PL_cs_n;
  output [3:0]DDR_PL_dm;
  inout [31:0]DDR_PL_dq;
  inout [3:0]DDR_PL_dqs_n;
  inout [3:0]DDR_PL_dqs_p;
  output [0:0]DDR_PL_odt;
  output DDR_PL_ras_n;
  output DDR_PL_reset_n;
  output DDR_PL_we_n;
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  input [63:0]GPIO_0_tri_i;
  output [63:0]GPIO_0_tri_o;
  output [31:0]M_AXI_GP_araddr;
  output [2:0]M_AXI_GP_arprot;
  input M_AXI_GP_arready;
  output M_AXI_GP_arvalid;
  output [31:0]M_AXI_GP_awaddr;
  output [2:0]M_AXI_GP_awprot;
  input M_AXI_GP_awready;
  output M_AXI_GP_awvalid;
  output M_AXI_GP_bready;
  input [1:0]M_AXI_GP_bresp;
  input M_AXI_GP_bvalid;
  input [31:0]M_AXI_GP_rdata;
  output M_AXI_GP_rready;
  input [1:0]M_AXI_GP_rresp;
  input M_AXI_GP_rvalid;
  output [31:0]M_AXI_GP_wdata;
  input M_AXI_GP_wready;
  output [3:0]M_AXI_GP_wstrb;
  output M_AXI_GP_wvalid;
  input [31:0]S_AXI_HP0_araddr;
  input [1:0]S_AXI_HP0_arburst;
  input [3:0]S_AXI_HP0_arcache;
  input [5:0]S_AXI_HP0_arid;
  input [3:0]S_AXI_HP0_arlen;
  input [1:0]S_AXI_HP0_arlock;
  input [2:0]S_AXI_HP0_arprot;
  input [3:0]S_AXI_HP0_arqos;
  output S_AXI_HP0_arready;
  input [2:0]S_AXI_HP0_arsize;
  input S_AXI_HP0_arvalid;
  input [31:0]S_AXI_HP0_awaddr;
  input [1:0]S_AXI_HP0_awburst;
  input [3:0]S_AXI_HP0_awcache;
  input [5:0]S_AXI_HP0_awid;
  input [3:0]S_AXI_HP0_awlen;
  input [1:0]S_AXI_HP0_awlock;
  input [2:0]S_AXI_HP0_awprot;
  input [3:0]S_AXI_HP0_awqos;
  output S_AXI_HP0_awready;
  input [2:0]S_AXI_HP0_awsize;
  input S_AXI_HP0_awvalid;
  output [5:0]S_AXI_HP0_bid;
  input S_AXI_HP0_bready;
  output [1:0]S_AXI_HP0_bresp;
  output S_AXI_HP0_bvalid;
  output [63:0]S_AXI_HP0_rdata;
  output [5:0]S_AXI_HP0_rid;
  output S_AXI_HP0_rlast;
  input S_AXI_HP0_rready;
  output [1:0]S_AXI_HP0_rresp;
  output S_AXI_HP0_rvalid;
  input [63:0]S_AXI_HP0_wdata;
  input [5:0]S_AXI_HP0_wid;
  input S_AXI_HP0_wlast;
  output S_AXI_HP0_wready;
  input [7:0]S_AXI_HP0_wstrb;
  input S_AXI_HP0_wvalid;
  input clk_50M;
  output clk_pl;
  input pcie_clk;
  input pcie_rstn;
  output [0:0]rstn_pl;

  wire Core0_nIRQ_0;
  wire [14:0]DDR_PL_addr;
  wire [2:0]DDR_PL_ba;
  wire DDR_PL_cas_n;
  wire [0:0]DDR_PL_ck_n;
  wire [0:0]DDR_PL_ck_p;
  wire [0:0]DDR_PL_cke;
  wire [0:0]DDR_PL_cs_n;
  wire [3:0]DDR_PL_dm;
  wire [31:0]DDR_PL_dq;
  wire [3:0]DDR_PL_dqs_n;
  wire [3:0]DDR_PL_dqs_p;
  wire [0:0]DDR_PL_odt;
  wire DDR_PL_ras_n;
  wire DDR_PL_reset_n;
  wire DDR_PL_we_n;
  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;

  wire [31:0]M_AXI_GP_araddr;
  wire [2:0]M_AXI_GP_arprot;
  wire M_AXI_GP_arready;
  wire M_AXI_GP_arvalid;
  wire [31:0]M_AXI_GP_awaddr;
  wire [2:0]M_AXI_GP_awprot;
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
  wire [3:0]M_AXI_GP_wstrb;
  wire M_AXI_GP_wvalid;
  wire [31:0]S_AXI_HP0_araddr;
  wire [1:0]S_AXI_HP0_arburst;
  wire [3:0]S_AXI_HP0_arcache;
  wire [5:0]S_AXI_HP0_arid;
  wire [3:0]S_AXI_HP0_arlen;
  wire [1:0]S_AXI_HP0_arlock;
  wire [2:0]S_AXI_HP0_arprot;
  wire [3:0]S_AXI_HP0_arqos;
  wire S_AXI_HP0_arready;
  wire [2:0]S_AXI_HP0_arsize;
  wire S_AXI_HP0_arvalid;
  wire [31:0]S_AXI_HP0_awaddr;
  wire [1:0]S_AXI_HP0_awburst;
  wire [3:0]S_AXI_HP0_awcache;
  wire [5:0]S_AXI_HP0_awid;
  wire [3:0]S_AXI_HP0_awlen;
  wire [1:0]S_AXI_HP0_awlock;
  wire [2:0]S_AXI_HP0_awprot;
  wire [3:0]S_AXI_HP0_awqos;
  wire S_AXI_HP0_awready;
  wire [2:0]S_AXI_HP0_awsize;
  wire S_AXI_HP0_awvalid;
  wire [5:0]S_AXI_HP0_bid;
  wire S_AXI_HP0_bready;
  wire [1:0]S_AXI_HP0_bresp;
  wire S_AXI_HP0_bvalid;
  wire [63:0]S_AXI_HP0_rdata;
  wire [5:0]S_AXI_HP0_rid;
  wire S_AXI_HP0_rlast;
  wire S_AXI_HP0_rready;
  wire [1:0]S_AXI_HP0_rresp;
  wire S_AXI_HP0_rvalid;
  wire [63:0]S_AXI_HP0_wdata;
  wire [5:0]S_AXI_HP0_wid;
  wire S_AXI_HP0_wlast;
  wire S_AXI_HP0_wready;
  wire [7:0]S_AXI_HP0_wstrb;
  wire S_AXI_HP0_wvalid;
  wire clk_50M;
  wire clk_pl;
  wire pcie_clk;
  wire pcie_rstn;
  wire [0:0]rstn_pl;

 
  design_zynq design_zynq_i
       (.Core0_nIRQ_0(Core0_nIRQ_0),
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
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .GPIO_0_tri_i(GPIO_0_tri_i),
        .GPIO_0_tri_o(GPIO_0_tri_o),
        .M_AXI_GP_araddr(M_AXI_GP_araddr),
        .M_AXI_GP_arprot(M_AXI_GP_arprot),
        .M_AXI_GP_arready(M_AXI_GP_arready),
        .M_AXI_GP_arvalid(M_AXI_GP_arvalid),
        .M_AXI_GP_awaddr(M_AXI_GP_awaddr),
        .M_AXI_GP_awprot(M_AXI_GP_awprot),
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
        .S_AXI_HP0_araddr(S_AXI_HP0_araddr),
        .S_AXI_HP0_arburst(S_AXI_HP0_arburst),
        .S_AXI_HP0_arcache(S_AXI_HP0_arcache),
        .S_AXI_HP0_arid(S_AXI_HP0_arid),
        .S_AXI_HP0_arlen(S_AXI_HP0_arlen),
        .S_AXI_HP0_arlock(S_AXI_HP0_arlock),
        .S_AXI_HP0_arprot(S_AXI_HP0_arprot),
        .S_AXI_HP0_arqos(S_AXI_HP0_arqos),
        .S_AXI_HP0_arready(S_AXI_HP0_arready),
        .S_AXI_HP0_arsize(S_AXI_HP0_arsize),
        .S_AXI_HP0_arvalid(S_AXI_HP0_arvalid),
        .S_AXI_HP0_awaddr(S_AXI_HP0_awaddr),
        .S_AXI_HP0_awburst(S_AXI_HP0_awburst),
        .S_AXI_HP0_awcache(S_AXI_HP0_awcache),
        .S_AXI_HP0_awid(S_AXI_HP0_awid),
        .S_AXI_HP0_awlen(S_AXI_HP0_awlen),
        .S_AXI_HP0_awlock(S_AXI_HP0_awlock),
        .S_AXI_HP0_awprot(S_AXI_HP0_awprot),
        .S_AXI_HP0_awqos(S_AXI_HP0_awqos),
        .S_AXI_HP0_awready(S_AXI_HP0_awready),
        .S_AXI_HP0_awsize(S_AXI_HP0_awsize),
        .S_AXI_HP0_awvalid(S_AXI_HP0_awvalid),
        .S_AXI_HP0_bid(S_AXI_HP0_bid),
        .S_AXI_HP0_bready(S_AXI_HP0_bready),
        .S_AXI_HP0_bresp(S_AXI_HP0_bresp),
        .S_AXI_HP0_bvalid(S_AXI_HP0_bvalid),
        .S_AXI_HP0_rdata(S_AXI_HP0_rdata),
        .S_AXI_HP0_rid(S_AXI_HP0_rid),
        .S_AXI_HP0_rlast(S_AXI_HP0_rlast),
        .S_AXI_HP0_rready(S_AXI_HP0_rready),
        .S_AXI_HP0_rresp(S_AXI_HP0_rresp),
        .S_AXI_HP0_rvalid(S_AXI_HP0_rvalid),
        .S_AXI_HP0_wdata(S_AXI_HP0_wdata),
        .S_AXI_HP0_wid(S_AXI_HP0_wid),
        .S_AXI_HP0_wlast(S_AXI_HP0_wlast),
        .S_AXI_HP0_wready(S_AXI_HP0_wready),
        .S_AXI_HP0_wstrb(S_AXI_HP0_wstrb),
        .S_AXI_HP0_wvalid(S_AXI_HP0_wvalid),
        .clk_50M(clk_50M),
        .clk_pl(clk_pl),
        .pcie_clk(pcie_clk),
        .pcie_rstn(pcie_rstn),
        .rstn_pl(rstn_pl));
endmodule
