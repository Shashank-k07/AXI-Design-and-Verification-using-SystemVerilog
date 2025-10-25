class axi_env;
	axi_gen gen;
	axi_bfm bfm;
	axi_slave_bfm sbfm;
	axi_monitor mon;
	axi_scoreboard sco;
	task run();
		fork
			gen = new();
			bfm = new();
			sbfm = new();
			mon = new();
			sco = new();
			gen.run();
			bfm.run();
			sbfm.run();
			mon.run();
			sco.run();
		join
	endtask
endclass
