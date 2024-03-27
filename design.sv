module Pro1(dff dif);

always@(posedge dif.clk)
	begin
	if(dif.rst)
		dif.dout<='0;
	else
		dif.dout<=dif.din;
	end

endmodule

interface dff;

logic clk;
logic rst;
logic din;
logic dout;




endinterface


