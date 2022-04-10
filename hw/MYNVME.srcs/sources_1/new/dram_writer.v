`define FIFO_LEN 32
`define FIFO_ADDR_LEN 5
`define DDR_BUF_LEN_REG 32'h2000_0000
`define DDR_BUF_START 32'h2000_0010
`define DDR_BUF_END 32'h2fff_fff0

module dram_writer (
	input pcie_clk, //125Mhz
	input pcie_reset_n,
	
	input pcie_rx_valid,
	input [127:0] pcie_rx_data,
	output pcie_rx_run,
	input pcie_rx_ready,
	input [21:0] pcie_rx_user,
	
	input pcie_tx_valid,
	input pcie_tx_ready,
	input [127:0] pcie_tx_data,
	
	input ddr_clk, //200Mhz
	input ddr_reset_n,
	
	output ddr_awvalid,
	output [31:0] ddr_awaddr,
	output [3:0] ddr_awlen,
	input ddr_awready,
	output ddr_wvalid,
	output [63:0] ddr_wdata,
	output [7:0] ddr_wstrb,
	output ddr_wlast,
	input ddr_wready,
	output ddr_bready,
	input ddr_bvalid,
	input [1:0] ddr_bresp,
	
	input trigger,
	//output [5:0] state,
	output [3:0] state_o,
	
	input init_end,
	input [31:0] bar0,

	
	input dram_write_req,
	input [31:0] dram_write_addr,
	input [3:0] dram_write_sel,
	input [127:0] dram_write_data,
	output reg dram_write_ack,
	
	
	output [`FIFO_ADDR_LEN-1:0]  fifo_head_o,
	output [`FIFO_ADDR_LEN-1:0]  fifo_tail_o,
	
	input pcie_record_lock
);

reg [7:0] ddr_state;
reg [31:0] ddr_addr_now;



reg [127:0] FIFO [`FIFO_LEN-1:0];

reg [`FIFO_ADDR_LEN-1:0] fifo_head, fifo_tail;
wire [`FIFO_ADDR_LEN-1:0] fifo_tail_gray, fifo_tail_gray_next, fifo_tail_gray_next2, fifo_head_gray;
reg [`FIFO_ADDR_LEN-1:0] fifo_head_gray_r [1:0], fifo_tail_gray_r [1:0];

assign fifo_head_o = fifo_head;
assign fifo_tail_o = fifo_tail;

binary_to_gray b2g_0(
	.binary(fifo_head),
	.gray(fifo_head_gray)
);

binary_to_gray b2g_1(
	.binary(fifo_tail),
	.gray(fifo_tail_gray)
);

binary_to_gray b2g_2(
	.binary(fifo_tail + `FIFO_ADDR_LEN 'd1),
	.gray(fifo_tail_gray_next)
);

binary_to_gray b2g_3(
	.binary(fifo_tail + `FIFO_ADDR_LEN 'd2),
	.gray(fifo_tail_gray_next2)
);

reg [2:0] dram_write_req_ff;
reg dram_write_req_flag;
reg dram_write_switch;
//wire dram_write_switch;
//assign dram_write_switch = 1;

assign pcie_rx_run = (fifo_tail_gray_next == fifo_head_gray_r[1] || fifo_tail_gray_next2 == fifo_head_gray_r[1]) ? pcie_record_lock : 1'b1;
//assign pcie_rx_run = 1'b1;



always@(posedge pcie_clk) begin
	if(~pcie_reset_n) begin
		fifo_tail <= {`FIFO_ADDR_LEN{1'b0}};

	end else begin
		fifo_head_gray_r[1] <= fifo_head_gray_r[0];
		fifo_head_gray_r[0] <= fifo_head_gray;
	
		if( pcie_rx_run & ~pcie_record_lock ) begin
		
			if(pcie_rx_ready & pcie_rx_valid & pcie_tx_ready & pcie_tx_valid) begin
				FIFO[fifo_tail] <= pcie_tx_data;
				FIFO[fifo_tail + `FIFO_ADDR_LEN 'd1] <= pcie_rx_data;
				fifo_tail <= fifo_tail + `FIFO_ADDR_LEN 'd2;
			end else if(pcie_rx_ready & pcie_rx_valid) begin
				FIFO[fifo_tail] <= pcie_rx_data;
				fifo_tail <= fifo_tail + `FIFO_ADDR_LEN 'd1;
			end else if(pcie_tx_ready & pcie_tx_valid) begin
				FIFO[fifo_tail] <= pcie_tx_data;
				fifo_tail <= fifo_tail + `FIFO_ADDR_LEN 'd1;
			end
			
		end
	end
end




assign ddr_awvalid = ddr_state == 8'd1 || ddr_state == 8'd5 ? 1'b1 : 1'b0;
assign ddr_awaddr = dram_write_switch ? dram_write_addr : (ddr_state == 8'd5 ? `DDR_BUF_LEN_REG : ddr_addr_now);
assign ddr_awlen = ddr_state == 8'd5 ? 4'd0 : 4'd1;
assign ddr_wvalid = ddr_state == 8'd2 || ddr_state == 8'd3 || ddr_state == 8'd6 ? 1'b1 : 1'b0;
assign ddr_wdata = dram_write_switch ? (ddr_state == 8'd3 ? dram_write_data[127:64] : dram_write_data[63:0]) : ( ddr_state == 8'd6 ? {bar0,ddr_addr_now} : (ddr_state == 8'd3 ? FIFO[fifo_head][127:64] : FIFO[fifo_head][63:0]) );
//assign ddr_wdata = ddr_state == 8'd3 ? dram_write_data[127:64] : dram_write_data[63:0];
assign ddr_wstrb = dram_write_switch ? ( ddr_state == 8'd2 ? {(dram_write_sel[1] ? 4'hF : 4'h0),(dram_write_sel[0] ? 4'hF : 4'h0)} : {(dram_write_sel[3] ? 4'hF : 4'h0),(dram_write_sel[2] ? 4'hF : 4'h0)} ) : 8'hff;
assign ddr_bready = ddr_state == 8'd4 || ddr_state == 8'd7 ? 1'b1 : 1'b0;
assign ddr_wlast = ddr_state == 8'd2 ? 1'b0 : 1'b1;



always@(posedge ddr_clk) begin
	if(~ddr_reset_n) begin
		ddr_state <= 8'd0;
		ddr_addr_now <= `DDR_BUF_START;	
		
		fifo_head <= {`FIFO_ADDR_LEN{1'b0}};
		
		dram_write_req_ff <= 3'b000;
		dram_write_ack <= 1'b0;
		
	end else begin
		fifo_tail_gray_r[1] <= fifo_tail_gray_r[0];
		fifo_tail_gray_r[0] <= fifo_tail_gray;
		
		
		dram_write_req_ff <= {dram_write_req_ff[1:0],dram_write_req};
		if(dram_write_req_ff[1] ^ dram_write_req_ff[2])
			dram_write_req_flag <= 1'b1;
		else if(ddr_state == 8'd4 && ddr_bvalid && (ddr_bresp[1:0] == 2'b00) && dram_write_switch)
			dram_write_req_flag <= 1'b0;
		
		casez(ddr_state)
			8'd0: begin
				if(fifo_head_gray != fifo_tail_gray_r[1]) begin
				//if(0) begin
					ddr_state <= 8'd1;
					dram_write_switch <= 1'b0;
				end else if(dram_write_req_flag) begin
					ddr_state <= 8'd1;
					dram_write_switch <= 1'b1;
				end
			end
			8'd1: begin
				if(ddr_awready) begin
					ddr_state <= 8'd2;
				end
			end
			8'd2: begin
				if(ddr_wready) begin
					ddr_state <= 8'd3;
				end
			end
			8'd3: begin
				if(ddr_wready) begin
					ddr_state <= 8'd4;
				end
			end
			8'd4: begin
				if(ddr_bvalid) begin

					if(ddr_bresp[1:0] != 2'b00)
						ddr_state <= 8'd1;
					else if(dram_write_switch) begin
						ddr_state <= 8'd0;
						dram_write_ack <= ~dram_write_ack;
					end else
						ddr_state <= 8'd8;
						
					if((!dram_write_switch) & (ddr_bresp[1:0] == 2'b00)) begin
						fifo_head <= fifo_head + `FIFO_ADDR_LEN 'b1;
						if(ddr_addr_now < `DDR_BUF_END)
							ddr_addr_now <= ddr_addr_now + 32'h10;
						else
							ddr_addr_now <= `DDR_BUF_START;
					end
				end
			end
			8'd8: begin
				if(fifo_head_gray != fifo_tail_gray_r[1])
					ddr_state <= 8'd1;
				else
					ddr_state <= 8'd5;
			end
			8'd5: begin
				if(ddr_awready)
					ddr_state <= 8'd6;
			end
			8'd6: begin
				if(ddr_wready)
					ddr_state <= 8'd7;
			end
			8'd7: begin
				if(ddr_bvalid) begin
					ddr_state <= 8'd0;
					//ddr_addr_now <= ddr_addr_now + 32'h1;
				end
			end
			default: begin
				ddr_state <= 8'd0;
			end
		endcase
	end
end

//assign state[2:0] = ddr_state[2:0];
//assign state[5:3] = {~pcie_reset_n,pcie_rx_run,~ddr_reset_n};

assign state_o = ddr_state[3:0];

endmodule