class transcation;

rand bit din;
bit dout;


function transcation copy();

copy = new();
copy.din = this.din;
copy.dout = this.dout;

endfunction

function void display(input string tag);
$display("[%0s] : DIN  = %0b  and DOUT  = %0b",tag,din,dout);
endfunction

endclass


class generator;

transcation tr;

mailbox #(transcation) mbx;
mailbox #(transcation) mbxref;
event scorenxt;
event done;
int count;


function new (mailbox #(transcation) mbx,mailbox #(transcation) mbxref);
this.mbx = mbx;
this.mbxref = mbxref;
tr = new();
endfunction

task run();

	repeat(count) 
	begin
	//assert(tr.randomize); else $error("Randomization is failed");
	tr.randomize;
	mbx.put(tr.copy);
	mbxref.put(tr.copy);
	tr.display("GEN");
	@(scorenxt);
	end
->done;	

endtask


endclass

class Driver;

transcation tr;

mailbox #(transcation) mbx;
virtual dff vif;

function new(mailbox #(transcation) mbx);
this.mbx = mbx;

endfunction


task reset();
vif.rst <=1'b1;
repeat(5) @(posedge vif.clk);

vif.rst <=1'b0;
@(posedge vif.clk);
$display("DRIVER RESET IS DONE");
endtask

task run();
forever begin
mbx.get(tr);
vif.din <=tr.din;
@(posedge vif.clk);
tr.display("DRIVER");
vif.din <=1'b0;
@(posedge vif.clk);
end
endtask

endclass


class monitor;

transcation tr;
mailbox #(transcation) mbx;
virtual dff vif;

function new(mailbox #(transcation) mbx);
this.mbx = mbx;

endfunction

task run();

tr = new();
forever begin
repeat(2) @(posedge vif.clk);
tr.dout = vif.dout;
mbx.put(tr);
tr.display("MONITOR ");

end


endtask


endclass

class scoreboard;

transcation tr;
transcation tref;
mailbox #(transcation) mbx;
mailbox #(transcation) mbxref;
event scorenxt;




function new (mailbox #(transcation) mbx,mailbox #(transcation) mbxref);
this.mbx = mbx;
this.mbxref = mbxref;
endfunction


task run();
forever begin
mbx.get(tr);
mbxref.get(tref);
tr.display("scoreboard");
tref.display("REFERENCE");

if((tr.dout == 1'bx && tr.din ==1'b0)||tr.dout == tref.dout||tref.dout == 1'bx && tref.din ==1'b0)
	$display("DATA MATCHED");
else
	$display("DATA MIS-MATCHED");

$display("*******************************");
->scorenxt;
end
endtask


endclass


class environment;

generator gen;
Driver drv;
monitor mon;
scoreboard sco;


event nxt;

mailbox #(transcation) gdmbx;
mailbox #(transcation) msmbx;
mailbox #(transcation) mbxref;

virtual dff vif;

function new(virtual dff vif);

gdmbx = new();
mbxref = new();

gen = new(gdmbx,mbxref);
drv = new(gdmbx);


msmbx = new();

mon = new(msmbx);

sco = new(msmbx,mbxref);

this.vif = vif;
drv.vif = this.vif;
mon.vif = this.vif;

gen.scorenxt = nxt;
sco.scorenxt = nxt;




endfunction


task pre_test();
drv.reset();

endtask

task test();
fork
gen.run();
drv.run();
mon.run();
sco.run();

join_any
endtask
task post_test();
wait(gen.done.triggered);
$finish();

endtask


task run();

pre_test();
test();
post_test();

endtask

endclass

module tb;

dff vif();

Pro1 dut(vif);

initial begin

vif.clk =0;

end
always #10 vif.clk = ~vif.clk;
environment env;

initial begin


env  =new(vif);
env.gen.count = 30;
env.run();


end



endmodule