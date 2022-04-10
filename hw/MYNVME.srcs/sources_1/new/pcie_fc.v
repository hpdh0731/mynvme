module pcie_fc(
	input pcie_clk,
	input pcie_reset_n,
	
	output fc_mwr_grant,
	output fc_mrd_grant,
	output fc_cpl_grant,
	
	input [7:0] tx_ph_limit,
	input [11:0] tx_pd_limit,
	input [7:0] tx_ph_consumed,
	input [11:0] tx_pd_consumed,
	
	input [7:0] tx_nph_limit,
	input [7:0] tx_nph_consumed,
	
	input [2:0] MRRS,
	input [2:0] MPS,
	
	//in the end of the fsm
	input mwr_req_tick,
	input [15:0] mwr_data_inc,
	input mrd_req_tick,
	input [15:0] mrd_data_inc,
	input cpl_recv_end_tick,
	input cpl_recv_tick,
	input [15:0] cpl_data_inc,
	
	input [5:0] tx_buf_av,
	input msi_req,
	input tx_cfg_req,
	
	output reg [7:0] tx_ph_consumed_reserved,
	output reg [15:0] tx_pd_consumed_reserved,
	output reg [7:0] tx_nph_consumed_reserved,

	output reg [7:0] rx_cplh_received,
	output reg [15:0] rx_cpld_received,
	output reg [7:0] rx_cplh_allocated,
	output reg [15:0] rx_cpld_allocated
);

reg [7:0] tx_ph_consumed_ff;
reg [11:0] tx_pd_consumed_ff;
reg [7:0] tx_nph_consumed_ff;




reg mwr_req_tick_ff;
reg mrd_req_tick_ff;
reg cpl_recv_tick_ff;
reg cpl_recv_end_tick_ff;
reg msi_req_ff;
reg tx_cfg_req_ff;


reg r_mwr_grant;
reg r_mrd_grant;
reg r_cpl_grant;

//assign fc_mwr_grant = r_mwr_grant & |tx_buf_av[5:4];
//assign fc_mrd_grant = r_mrd_grant & r_cpl_grant & |tx_buf_av[5:4];
//assign fc_cpl_grant = |tx_buf_av[5:4];

assign fc_mwr_grant = r_mwr_grant & (&tx_buf_av[4:0]);
assign fc_mrd_grant = r_mrd_grant & r_cpl_grant & (&tx_buf_av[4:0]);
assign fc_cpl_grant = |tx_buf_av[5:2];

always@(posedge pcie_clk) begin

	mrd_req_tick_ff <= mrd_req_tick;
	mwr_req_tick_ff <= mwr_req_tick;
	cpl_recv_tick_ff <= cpl_recv_tick;
	cpl_recv_end_tick_ff <= cpl_recv_end_tick;
	msi_req_ff <= msi_req;
	tx_cfg_req_ff <= tx_cfg_req;
	
	tx_ph_consumed_ff <= tx_ph_consumed;
	tx_pd_consumed_ff <= tx_pd_consumed;
	tx_nph_consumed_ff <= tx_nph_consumed;
	
	r_mwr_grant <= (tx_ph_limit - tx_ph_consumed_reserved - 8'h1 < 8'h80) && ({tx_pd_limit,4'b0} - tx_pd_consumed_reserved - (16'h80 << MPS) < 16'h8000);
	//r_mwr_grant <= (tx_ph_limit - tx_ph_consumed - 8'h8 <= 8'h80) && (tx_pd_limit - tx_pd_consumed - 12'h40 <= 12'h800);
	//r_mrd_grant <= (tx_nph_limit - tx_nph_consumed_reserved - 8'h1 <= 8'h80);
	r_mrd_grant <= (tx_nph_limit - tx_nph_consumed - 8'h1C <= 8'h80);
	//r_cpl_grant <= (rx_cplh_allocated - rx_cplh_received - 8'd1 - (8'd2 << MRRS) <= 8'h80) && (rx_cpld_allocated - rx_cpld_received - (16'h80 << MRRS) <= 16'h8000);
end

always@(posedge pcie_clk) begin
	if(~pcie_reset_n) begin
		rx_cplh_received <= 8'd0;
		rx_cpld_received <= 16'd0;
		rx_cplh_allocated <= 8'd36 - 8'd1 - (8'd2 << MRRS);
		rx_cpld_allocated <= (16'd616 - (16'h8 << MRRS)) << 4;
		
		tx_ph_consumed_reserved <= 8'd0;
		tx_pd_consumed_reserved <= 16'h0;
		tx_nph_consumed_reserved <= 8'd0;
		
		r_cpl_grant <= 1'b1;
	end else begin

		if(tx_ph_consumed_ff != tx_ph_consumed)
			tx_ph_consumed_reserved <= tx_ph_consumed;
		else if(mwr_req_tick_ff ^ mwr_req_tick) begin
			if(msi_req & ~msi_req_ff)
				tx_ph_consumed_reserved <= tx_ph_consumed_reserved + 8'd2;
			else
				tx_ph_consumed_reserved <= tx_ph_consumed_reserved + 8'd1;
		end else if(msi_req & ~msi_req_ff)
				tx_ph_consumed_reserved <= tx_ph_consumed_reserved + 8'd1;
		/*else if(tx_cfg_req & ~tx_cfg_req_ff)
			tx_ph_consumed_reserved <= tx_ph_consumed_reserved + 8'd1;*/
			
		if(tx_pd_consumed_ff != tx_pd_consumed)
			tx_pd_consumed_reserved <= {tx_pd_consumed,4'hf};
		else if(mwr_req_tick_ff ^ mwr_req_tick) begin
			if(msi_req & ~msi_req_ff)
				tx_pd_consumed_reserved <= tx_pd_consumed_reserved + mwr_data_inc + 8'd16;
			else
				tx_pd_consumed_reserved <= tx_pd_consumed_reserved + mwr_data_inc;
		end else if(msi_req & ~msi_req_ff)
			tx_pd_consumed_reserved <= tx_pd_consumed_reserved + 8'd16;
		/*else if(tx_cfg_req & ~tx_cfg_req_ff)
			tx_pd_consumed_reserved <= tx_pd_consumed_reserved + 8'd32;*/
			
			
		/*if(tx_nph_consumed_ff != tx_nph_consumed)
			tx_nph_consumed_reserved <= tx_nph_consumed;
		else if(mrd_req_tick_ff ^ mrd_req_tick)
			tx_nph_consumed_reserved <= tx_nph_consumed_reserved + 8'd1;
			
			
		if(cpl_recv_tick_ff ^ cpl_recv_tick) begin
			rx_cpld_allocated <= rx_cpld_allocated + cpl_data_inc;
		end
		
		if(cpl_recv_end_tick_ff ^ cpl_recv_end_tick) begin
			rx_cplh_allocated <= rx_cplh_allocated + 8'd1 + (8'd2 << MRRS);
		end
		
		if(mrd_req_tick_ff ^ mrd_req_tick) begin
			rx_cplh_received <= rx_cplh_received + 8'd1 + (8'd2 << MRRS);
			rx_cpld_received <= rx_cpld_received + mrd_data_inc;
		end*/
		
		if(mrd_req_tick_ff ^ mrd_req_tick)
			r_cpl_grant <= 1'b0;
		else if(cpl_recv_end_tick_ff ^ cpl_recv_end_tick)
			r_cpl_grant <= 1'b1;
			
			
	end
end


endmodule