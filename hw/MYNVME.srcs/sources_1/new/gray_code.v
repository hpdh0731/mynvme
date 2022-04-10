

module binary_to_gray#
(
    parameter len = 5
)
(
	input [len-1:0] binary,
	output reg [len-1:0] gray
);

integer i;
always@* begin
	for(i=0;i<len-1;i=i+1) begin
		gray[i] = binary[i] ^ binary[i+1];
	end
	gray[len-1] = binary[len-1];
end

endmodule


module gray_to_binary#
(
    parameter len = 5
)
(
	input [len-1:0] gray,
	output reg [len-1:0] binary
);

integer i, j;
always@* begin
	for(i=0;i<len;i=i+1) begin
		for(j=0;j<=i;j=j+1) begin
			binary[i] = binary[i] ^ gray[j];
		end
	end
end

endmodule