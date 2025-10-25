class common;
	static mailbox gen2bfm = new();
	static virtual axi_interface vif;
	static string testname;
	static bit overlapping ;
	static bit out_of_order;
	static mailbox mon2soc = new();
endclass
