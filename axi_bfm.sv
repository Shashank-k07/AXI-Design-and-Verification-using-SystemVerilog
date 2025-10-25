class axi_bfm;
	axi_tx tx;
	virtual axi_interface mvif;
	write_read wr_rd;
	axi_tx wr_tx[int];
	int wdata_size_bytes;
	int active_bytes;
	int offset_address;
	int aligned_address;
	int wstrb_bit;
	int c;


	task run();
		mvif = common::vif;
		forever begin
			tx = new();
			common::gen2bfm.get(tx);
			if(tx.wr_rd==write_then_read)begin
				//1. Write address channel
				write_address_channel();

				//2. Write data channel
				write_data_channel();

				//3. Write response channel
				write_response_channel();

				//4. Read address channel
				read_address_channel();

				//5. Read data channel
				read_data_channel();

			end//Write then read

			//Write and read parallel
			if(tx.wr_rd==write_parallel_read)fork
				begin
					//1. Write address channel
					write_address_channel();

					//2. Write data channel
					write_data_channel();

					//3. Write response channel
					write_response_channel();

       				end
				begin
					//1.Read address channel
					read_address_channel();

					//2.Read data channel
					read_data_channel();

		       		end
			join//Write parallel 

			//Write onnly
			if(tx.wr_rd==write_only)begin
				if(common::overlapping==1 || common::out_of_order==1)begin
					if(tx.awvalid==1 && tx.wvalid==1'b0)
						write_address_channel();
					if(tx.wvalid==1'b1)begin
						write_data_channel();

						write_response_channel();
					end
				end
				else begin//There is out of order or overlapping then normal write transaction happens
					//1. Write address channel
					write_address_channel();

					//2. Write data channel
					write_data_channel();
					
					//3. Write response channel
					write_response_channel();
				end 
			end//write only

			//Read only 
			if(tx.wr_rd==read_only)begin
				//1.Read address channel
				read_address_channel();
				//2.Read data channel
				read_data_channel();
			end//Read only
			common::vif = mvif;
			@(posedge mvif.aclk);
		end
	endtask

	//Create five separate task each for different channel
	
	//1. Write address channel task
	task write_address_channel();
		//Put all address and control signals to interface
		mvif.awaddr <= tx.awaddr;
		mvif.awlen <= tx.awlen;
		mvif.awsize <= tx.awsize;
		mvif.awburst <= tx.awburst;
		mvif.awid <= tx.awid;
		mvif.awlock <= tx.awlock;
		mvif.awcache <= tx.awcache;
		mvif.awprot <= tx.awprot;
		mvif.awvalid <= 1'b1;
		wait(common::vif.awready==1'b1);
		//Store all the address and control signal into one associative array
		wr_tx[tx.awid] = new();
		wr_tx[tx.awid].awaddr = tx.awaddr;
		wr_tx[tx.awid].awid = tx.awid;
		wr_tx[tx.awid].awsize = tx.awsize;
		wr_tx[tx.awid].awburst = tx.awburst;
		wr_tx[tx.awid].awlock = tx.awlock;
		wr_tx[tx.awid].awlen = tx.awlen;
		wr_tx[tx.awid].awprot = tx.awprot;
		wr_tx[tx.awid].awcache = tx.awcache;
		wr_tx[tx.awid].awvalid = 1'b1;
		$display(" Master BFM awaddr:%0h, awid:%0h, awlen:%0h, awburst:%0h, awsize:%0h, awvalid:%0h at %0t",wr_tx[tx.awid].awaddr, wr_tx[tx.awid].awid, wr_tx[tx.awid].awlen, wr_tx[tx.awid].awburst, wr_tx[tx.awid].awsize, wr_tx[tx.awid].awvalid, $time);
		@(posedge mvif.aclk);
		mvif.awvalid = 1'b0;
	endtask//Task of Write_address

	//2. Write data channel
	task write_data_channel();
		@(posedge mvif.aclk);
		mvif.bready <= 1'b1;
		wr_tx[tx.wid].wid = tx.wid;
		mvif.wid <= tx.wid;		
		$display("Master BFM wid:%0h at %0t", wr_tx[tx.wid].wid, $time);
		for(int i = 0; i<=wr_tx[tx.wid].awlen; i++)begin
			fork
				//Statement 01
				if(common::overlapping==1'b1)begin
					if(tx.awvalid==1'b1)
						write_address_channel();
				end
				//Statement 02
				begin
				mvif.wdata = tx.wdata.pop_back();//Get the data also deletes the data from the array
				mvif.wvalid <= 1;
				wdata_size_bytes = ($size(mvif.wdata)/8);
				//2.Number of active address in each transfer
				active_bytes = 2**wr_tx[tx.wid].awsize;
				//3.Start address is aligned or unaligend and if unaligned what is remainder(offset address)
				offset_address = wr_tx[tx.wid].awaddr%wdata_size_bytes;//This mainly related to narrow transfer
				//4.Convert aligned address to unaligned address
				aligned_address = wr_tx[tx.wid].awaddr - (wr_tx[tx.wid].awaddr%active_bytes);
				c = wr_tx[tx.wid].awaddr - aligned_address;
				$display(" %0h transfer awaddr: %0h wdata is %0h with size in bytes is %0h and Number of active bytes is %0h with offset address is %0h  at %0t", i,wr_tx[tx.wid].awaddr, mvif.wdata,wdata_size_bytes, active_bytes, offset_address, $time);
				tx.wstrb = 0;
				//1. Aligned address
				if((wr_tx[tx.wid].awaddr%2**wr_tx[tx.wid].awsize)==0)begin 
					for(int j = 0; j<active_bytes; j = j+1)begin 
						wstrb_bit = (offset_address+j)%(wdata_size_bytes);
						tx.wstrb[wstrb_bit]=1'b1;
					end
				end//address is aligned 
				//2.Unaligned address
				else begin
					if(wr_tx[tx.wid].awsize==1)
						c = 0;
					else 
						c = 1;
					for(int j=offset_address;j<(offset_address+c+wr_tx[tx.wid].awsize);j++)begin 
						tx.wstrb[j] = 1'b1;
					end
				end//Address is unaligned 
				$display("IN master BFM Wstrb of %0h transfer is %0h", i, tx.wstrb);
				mvif.wstrb = tx.wstrb;
				//Convert unaligned address to aligned address
				wr_tx[tx.wid].awaddr = wr_tx[tx.wid].awaddr - (wr_tx[tx.wid].awaddr%2**wr_tx[tx.wid].awsize);
				//Next transfer address
				wr_tx[tx.wid].awaddr = wr_tx[tx.wid].awaddr+ 2**wr_tx[tx.wid].awsize;
				$display("In master BFM Awaddr for %0h transfer is %0h", i+1, wr_tx[tx.wid].awaddr);
				if(i==wr_tx[tx.wid].awlen)begin
					mvif.wlast <= 1'b1;
				end
				else 
					mvif.wlast <= 1'b0;

				wait(mvif.wready);
				//Master needs to wait until ready comes slave
				@(posedge mvif.aclk);//After this make wlast low
				end
			join
		end//No. of transfers
		
		mvif.wvalid <= 1'b0;
		endtask//Task of write_data_channel
	

	//3. Write response channel
	task write_response_channel();
	//	mvif.bready = 1'b1;
		wait(mvif.bvalid==1'b1);
		@(posedge mvif.aclk);
		mvif.bready = 0;
	endtask//Task of write_response_channel

	//4. Read address channel
	task read_address_channel();
		mvif.araddr = tx.araddr;
		mvif.arlen = tx.arlen;
		mvif.arsize = tx.arsize;
		mvif.arburst = tx.arburst;
		mvif.arid = tx.arid;
		mvif.arlock = tx.arlock;
		mvif.arcache = tx.arcache;
		mvif.arprot = tx.arprot;
		mvif.arvalid = 1;
		$display("Master BFM araddr:%0h, arlen:%0h, arsize:%0h, arburst:%0h, arid:%0h, arvalid:%0h at %0t", mvif.araddr, mvif.arlen, mvif.arsize, mvif.arburst, mvif.arid, mvif.arvalid, $time); 
		wait(mvif.arready==1);
		@(posedge mvif.aclk);
		mvif.arvalid = 0;
	endtask//Task of read_address_channel

	//5. Read data channel
	task read_data_channel();
		mvif.rready <= 1;
		wait(mvif.rvalid==1'b1);
		@(posedge mvif.aclk);
		mvif.rready <= 1'b0;
	endtask//Task of read_data_channel
endclass
