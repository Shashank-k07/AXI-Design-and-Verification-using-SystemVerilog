module axi_top;
bit aclk;
bit aresetn;
initial begin 
	aclk  = 0;
	forever #5 aclk = ~aclk;
end
initial begin 
	aresetn = 0;
	repeat(2) @(posedge aclk);
	aresetn = 1;
end

axi_interface pvif(aclk, aresetn);

axi_env e;
initial begin
	e = new();
	common::vif  = pvif;//maintain this method before calling run method else cause illegal  interface dereference
	common::overlapping = 0;
	common::out_of_order = 0;
	//common::testname = "single_write_test";
	//common::testname = "multiple_write_test";
	common::testname = "single_write_read_test";
	//common::testname = "multiple_write_read_test";
	//common::testname = "increment_transaction_test";
	//common::tesetname = "narrow_transfer_test";
	//common::testname = "aligned_narrow_transfer";
	//common::testname ="unaligned_narrow_transfer";
	//common::testname = "out_of_order_transaction_test";
	//common::testname = "overlapping_transaction_test";
	//common::testname = "overlapping_out_of_order_test";
	//common::testname = "outoforder_narrow_transfer_align";
	//common::testname = "outoforder_narrow_transfer_unalign";
	//common::testname = "overlapping_narrow_transfer_align";
	//common::testname = "overlapping_narrow_transfer_unalign";
	//common::testname = "outoforder_overlapping_narrow_align";
	//common::testname = "outoforder_overlapping_narrow_unalign";
	//common::testname = "write_parallel_read";
	//common::testname = "fixed_type_transaction";
	//common::testname = "wrap_transaction_test";
	//common::testname = "Wrap_transaction_error_response";

	$display("Operation inn top module is %0s",common::testname);
	e.run();
end
initial begin
	#2000;
	$finish;
end
endmodule
quit