class axi_slave_bfm;
	virtual axi_interface svif;///virtual interface
	axi_tx tx;	
	axi_tx wr_tx[int];//associative array
	axi_tx rd_tx[int]; //read data and read address channel
	int data_size;
	int data_in_bytes;
	int temp_id;
	int prev_wdata;
	bit[3:0] prev_wstrb;
	reg[7:0]  mem [10000:0];
	int count;
	int wr_ptr = 0;
	int rd_ptr = 0;
	int wr_k, rd_k;
	int wr_wrap_boundary, rd_wrap_boundary;
	int wr_upper_boundary, rd_upper_boundary;
	int  offset_address;
	int aligned_address, k;
	
	task run();
		svif = common::vif;
		forever begin//Every clock cycle check all request ROM master
			@(posedge svif.aclk);//If in posedge of aclk aresetn is 0 then all the signals move to default values
			if(svif.aresetn==1'b0)begin
				svif.awready = 1'bx;
				svif.wready = 1'bx;
				svif.bid = 4'bxxxx;
				svif.bvalid = 1'bx;
				svif.bresp = 2'bxx;
				svif.arready = 1'bx;
				svif.arid = 4'bxxxx;
				svif.rresp = 2'bxx;
				svif.rvalid = 1'bx;
				svif.rdata = 32'hxxxxxxxx;
				svif.rlast = 1'bx;
				for(int i =0;i<10000;i++)begin
					mem[i]=0;
				end
			end
			else begin
				//If master is not sending valid address and control data Write address channel
				if(svif.awvalid==1'b0)
					svif.awready = 1'b0;
				//If master is not sending valid write data and strb value Write data channel
				if(svif.wvalid==1'b0)
					svif.wready = 1'b0;
				//If master is not ready to recive response Write response channel
				if(svif.bready==1'b0)
					svif.bvalid = 1'b0;
				//If master is not sending valid read address Read address channel
				if(svif.arvalid==1'b0)
					svif.arready = 1'b0;
				//Master is not ready recieve read data Read data/response channel
				if(svif.rready==1'b0)
					svif.rvalid = 1'b0;
				//Master sending valid address and controlsignal data Write address channel
				if(svif.awvalid==1)begin
					@(posedge svif.aclk);
					svif.awready = 1'b1;//Slave is ready to recive address and control signal
					wr_tx[svif.awid] = new();
					wr_tx[svif.awid].awaddr = svif.awaddr;
					wr_tx[svif.awid].awlen = svif.awlen;
					wr_tx[svif.awid].awsize = svif.awsize;
					wr_tx[svif.awid].awburst = svif.awburst;
					wr_tx[svif.awid].awprot = svif.awprot;
					wr_tx[svif.awid].awcache = svif.awcache;
					wr_tx[svif.awid].awlock = svif.awlock;
					wr_tx[svif.awid].awid = svif.awid; 
				//	prev_awaddr = wr_tx[svif.wid].awaddr;
					$display("In slave BFM awaddr:%0h, awlen:%0h, awsize:%0h, awburst:%0h, awid:%0h at %0t", wr_tx[svif.awid].awaddr, wr_tx[svif.awid].awlen, wr_tx[svif.awid].awsize, wr_tx[svif.awid].awburst, wr_tx[svif.awid].awid, $time);
				end//End of write address channel

				//Write data channel
				if(svif.wvalid==1)begin
					//Master sending valid wdata
					@(posedge svif.aclk);
				    svif.wready = 1;//Slave sending bit 1 indicating it is ready to recieve data
				    wr_tx[svif.wid].wid = svif.wid;
				    data_in_bytes = ($size(svif.wdata)/8);//wdata size in bytes

					//Fixed type transaction
				    if(wr_tx[svif.wid].awburst==2'b00)begin//Here we need to implement behaviour of FIFO memory
					   	for(int i = 0; i<=svif.awlen; i++)begin
							$display("Fixed type transaction: %0h transfer with wid %0h and wdata:%0h , wr_ptr is %0h",i,wr_tx[svif.wid].wid,svif.wdata,wr_ptr);	
						    wait(prev_wdata!=svif.wdata|| prev_wstrb!=svif.wstrb);
						    count = 0;
						    for(int j = 0; j<data_in_bytes; j++) begin //if wdata size is 32 bits then for loop will work 4 times and if wdata size is 128 bits the loop will work 16 times and so 
								mem[wr_ptr+count] = svif.wdata[j*8 +:  8];
								$display("mem[%0h] = %0h",wr_ptr+count, mem[wr_ptr+count]);
								count = count + 1;
							end
							prev_wdata = svif.wdata;
							prev_wstrb = svif.wstrb;
							wr_ptr = wr_ptr + ($size(svif.wdata)/8);							
							@(posedge svif.aclk);
						end //awlen for loop
				    end//End of fixed type transaction

					//Increment type transaction
				    if(wr_tx[svif.wid].awburst==1)begin
		  		      	for(int i = 0; i<=svif.awlen; i++)begin
					       	wait(prev_wdata!=svif.wdata|| prev_wstrb!=svif.wstrb);
							$display("Increment transaction: %0h transfer start_address:%0h with wid:%0h, wdata:%0h, wstrb:%0h",i,wr_tx[svif.wid].awaddr,wr_tx[svif.wid].wid,svif.wdata,svif.wstrb);
					       	count = 0;
							
					       	for(int j = 0; j<data_in_bytes; j++) begin //if wdata size is 32 bits then for loop will work 4 times and if wdata size is 128 bits the loop will work 16 times and so 
								if(svif.wstrb[j]==1)begin//Checks every bit  of wstrb 
									mem[wr_tx[svif.wid].awaddr+count] = svif.wdata[j*8 +:  8];
									$display("mem[%0h] = %0h",wr_tx[svif.wid].awaddr+count, mem[wr_tx[svif.wid].awaddr+count]);
									count = count+1;	
								end//wstrb condition
							end
							prev_wdata = svif.wdata;
							prev_wstrb = svif.wstrb;
							wr_tx[svif.wid].awaddr = wr_tx[svif.wid].awaddr - (wr_tx[svif.wid].awaddr)%2**wr_tx[svif.wid].awsize; //aligned address conversion
							wr_tx[svif.wid].awaddr = wr_tx[svif.wid].awaddr + 2**wr_tx[svif.wid].awsize;
							@(posedge svif.aclk);
							if(svif.bready==1)begin
								if(svif.wlast==1)begin
									svif.bvalid = 1;
									svif.bid = svif.wid;
									svif.bresp = 2'b00;
								end//end of wlast condtion
							end//end of write response channel
						end //awlen for loop
			      	end//Increment type transaction

					//Wrap type transaction
			       	if(wr_tx[svif.wid].awburst==2'b10)begin//WRAP type transaction
				     	//STEP 1: Check for aligned address 
				       	if(wr_tx[svif.wid].awaddr%2**wr_tx[svif.wid].awsize==0)begin
				       		//STEP 2: Check for transfer is  2,4,8,16
							$display("In wrap transaction the given address is aligned address");
							if(wr_tx[svif.wid].awlen==1||wr_tx[svif.wid].awlen==3||wr_tx[svif.wid].awlen==7||wr_tx[svif.wid].awlen==15)begin
				       			//STEP 3:wrap_boundary
								wr_k = (wr_tx[svif.wid].awaddr/((wr_tx[svif.wid].awlen+1)*(2**wr_tx[svif.wid].awsize)));
								wr_wrap_boundary = wr_k*((wr_tx[svif.wid].awlen+1)*(2**wr_tx[svif.wid].awsize));
				       			//STEP 4:upper_boundary
								wr_upper_boundary = wr_wrap_boundary+((wr_tx[svif.wid].awlen+1)*(2**wr_tx[svif.wid].awsize));
				       			for(int i = 0; i<=svif.awlen; i++)begin
					       			wait(prev_wdata!=svif.wdata|| prev_wstrb!=svif.wstrb);
					       			$display("Wrap transaction: %0h transfer start_address:%0h with wid:%0h, wdata:%0h, wstrb:%0h",i,wr_tx[svif.wid].awaddr,wr_tx[svif.wid].wid,svif.wdata,svif.wstrb);
									count = 0;
					      			for(int j=0; j<data_in_bytes; j++) begin //if wdata size is 32 bits then for loop will work 4 times and if wdata size is 128 bits the loop will work 16 times and so 
										if(svif.wstrb[j]==1)begin//Checks every bit  of wstrb 
											mem[wr_tx[svif.wid].awaddr+count] = svif.wdata[j*8 +:  8]; 
											$display("mem[%0h] = %0h",wr_tx[svif.wid].awaddr+count, mem[wr_tx[svif.wid].awaddr+count]);
											count = count+1;
										end//wstrb condition				
									end
									$display("WRAP Transaction %0h transfer start address is %0h and wdata is %0h", i, wr_tx[svif.wid].awaddr, svif.wdata); 
									prev_wdata = svif.wdata;
									prev_wstrb = svif.wstrb;
									wr_tx[svif.wid].awaddr = wr_tx[svif.wid].awaddr - (wr_tx[svif.wid].awaddr)%2**wr_tx[svif.wid].awsize;
									wr_tx[svif.wid].awaddr = wr_tx[svif.wid].awaddr + 2**wr_tx[svif.wid].awsize;
									//Whenever next transfer address is equals to upper_boundar_address then address moves to wrap_boundary_address
									if(wr_tx[svif.wid].awaddr==wr_upper_boundary)
										wr_tx[svif.wid].awaddr = wr_wrap_boundary;
									@(posedge svif.aclk);
									if(svif.bready==1)begin
										if(svif.wlast==1)begin
											svif.bvalid = 1;
											svif.bid = svif.wid;
											svif.bresp = 2'b00;
										end//end of wlast condtion
									end//end of write response channel
								end //End of awlen loop
							end//End of awlen conditional statement
							else begin 
								$display("In wrap transaction awlen is no 2, 4, 8, 16 %0t", $time);
								$display("In wrap transaction bready;%0h, wlast:%0h",svif.bready, svif.wlast);
								if(svif.bready==1)begin
									if(svif.wlast==1)begin
										svif.bvalid = 1;
										svif.bid = svif.wid;
										svif.bresp = 2'b10;
									end//end of wlast condtion
								end//end of write response channel
							end
						end//End of aligned address conditional statement
						else begin
							$display("Address is unaligned in wrap transaction with bready %0h and wlast %0h", svif.bready, svif.wlast);
							if(svif.bready==1)begin
								if(svif.wlast==1)begin
									svif.bvalid = 1;
									svif.bid = svif.wid;
									svif.bresp = 2'b10;
								end//end of wlast condtion
							end
						end
				    end//WRAP type transaction 
				end//wvalid condtional statement

 				//Read address channel
				if(svif.arvalid==1)begin
					// wait(svif.awvalid!=0);
					svif.arready = 1'b1;//slave is ready to recive address and control signal
					//read address channel
					rd_tx[svif.arid] = new();
					rd_tx[svif.arid].araddr = svif.araddr;
					rd_tx[svif.arid].arlen = svif.arlen;
					rd_tx[svif.arid].arsize = svif.arsize;
					rd_tx[svif.arid].arburst = svif.arburst;
					rd_tx[svif.arid].arprot = svif.arprot;
					rd_tx[svif.arid].arcache = svif.arcache;
					rd_tx[svif.arid].arlock = svif.arlock;
					rd_tx[svif.arid].arid = svif.arid;
				end//End of read address channel

				//Read data channel
				if(svif.rready==1'b1)begin
					svif.rvalid <= 1;
					svif.rid = svif.arid;
					rd_tx[svif.rid].rid = svif.rid;

					//Fixed type transaction
					if(rd_tx[svif.rid].arburst==2'b00)begin
						//Number of transfer slave has to send to master is decided by arlen
						for(int i = 0;i<=rd_tx[svif.rid].arlen;i++)begin
							//How many bytes of data has to be send
							count = 0;
							//Slave needs to send data from memory
							for(int j = 0;j<($size(svif.rdata)/8);j++)begin
								svif.rdata[j*8 +: 8] = mem[rd_ptr+count];
								count = count+1;
							end
							rd_ptr = rd_ptr + ($size(svif.rdata)/8);;
							svif.rresp = 2'b00;
							if(i==svif.arlen)//Checking for last transfer 
								svif.rlast = 1;
							@(posedge svif.aclk);
							svif.rlast = 0;
						end//End of transfer
					end//End of Fixed type transaction

					
					//Increment type transaction
					if(rd_tx[svif.rid].arburst==1)begin
						//Number of transfer slave has to send to master is decided by arlen
						for(int i =0;i<=rd_tx[svif.rid].arlen;i++)begin
							rd_tx[svif.rid].araddr = rd_tx[svif.rid].araddr - (rd_tx[svif.rid].araddr%2**rd_tx[svif.rid].arsize);
							offset_address  = rd_tx[svif.rid].araddr%($size(svif.rdata)/8);
							count = 0;
							svif.rdata = 0;
							//Slave needs to send data from memory
							if((rd_tx[svif.rid].araddr%($size(svif.rdata)/8))==0)begin
								for(int j = 0;j<2**rd_tx[svif.rid].arsize;j++)begin
									svif.rdata[j*8 +: 8] = mem[rd_tx[svif.rid].araddr+count];
									count = count+1;
								end
							end

							if((rd_tx[svif.rid].araddr%($size(svif.rdata)/8)!=0))begin
								if(rd_tx[svif.rid].arsize==1)
									k = 0;
								if(rd_tx[svif.rid].arsize!=0||i!=0)
									k = 1;
								for(int j = offset_address;j<(rd_tx[svif.rid].arsize+offset_address+k);j++)begin
									svif.rdata[j*8 +: 8] = mem[rd_tx[svif.rid].araddr+count];
									count = count+1;
								end
							end
							rd_tx[svif.rid].araddr = rd_tx[svif.rid].araddr +2**rd_tx[svif.rid].arsize;
							svif.rresp = 2'b00;
							if(i==svif.arlen)//Checking for last transfer 
								svif.rlast = 1;
							@(posedge svif.aclk);
							svif.rlast = 0;
						end//End of transfer
					end//End of Increment type transaction


					if(rd_tx[svif.rid].arburst==2'b10)begin//WRAP Type transaction
						//STEP 1: Check for aligned address 
					    if(rd_tx[svif.rid].araddr%2**rd_tx[svif.rid].arsize==0)begin
					    	//STEP 2: Check for transfer is  2,4,8,16
							if(rd_tx[svif.rid].arlen==1||rd_tx[svif.rid].arlen==3||rd_tx[svif.rid].arlen==7||rd_tx[svif.rid].arlen==15)begin
					       			//STEP 3:wrap_boundary
								rd_k = (rd_tx[svif.rid].araddr/((rd_tx[svif.rid].arlen+1)*(2**rd_tx[svif.rid].arsize)));
								rd_wrap_boundary = rd_k*((rd_tx[svif.rid].arlen+1)*(2**rd_tx[svif.rid].arsize));
					       			//STEP 4:upper_boundary
								rd_upper_boundary = rd_wrap_boundary+((rd_tx[svif.rid].arlen+1)*(2**rd_tx[svif.rid].arsize));

								//Number of transfer slave has to send to master is decided by arlen
								for(int i =0;i<=rd_tx[svif.rid].arlen;i++)begin
									//How many bytes of data has to be send
									count = 0;
									svif.rdata = 0;
									//Slave needs to send data from memory
									offset_address = rd_tx[svif.rid].araddr%($size(svif.rdata)/8);
									if((rd_tx[svif.rid].araddr%($size(svif.rdata)/8))==0)begin
										for(int j = 0;j<2**rd_tx[svif.rid].arsize;j++)begin
											svif.rdata[j*8 +: 8] = mem[rd_tx[svif.rid].araddr+count];
											count = count+1;
										end
									end
									if((rd_tx[svif.rid].araddr%($size(svif.rdata)/8)!=0))begin
										if(rd_tx[svif.rid].arsize==1)
											k = 0;
										if(rd_tx[svif.rid].arsize!=0||i!=0)
											k = 1;
										for(int j = offset_address;j<(rd_tx[svif.rid].arsize+offset_address+k);j++)begin
											svif.rdata[j*8 +: 8] = mem[rd_tx[svif.rid].araddr+count];
											count = count+1;
										end
									end
									$display("%0h transfer rdata  is %0h",i,svif.rdata);
									rd_tx[svif.rid].araddr = rd_tx[svif.rid].araddr +2**rd_tx[svif.rid].arsize;
									svif.rresp = 2'b00;
									if(i==svif.arlen)//Checking for last transfer 
										svif.rlast = 1;
									if(rd_tx[svif.rid].araddr==rd_upper_boundary)
										rd_tx[svif.rid].araddr = rd_wrap_boundary;
									@(posedge svif.aclk);
									svif.rlast = 0;
								end//End of transfer
							end//End of awlen conditional statement
							else begin 
								svif.rresp = 2'b10;
							end
						end//End of aligned address conditional statement
						else begin
							svif.rresp = 2'b10;
						end
					end//End of Wrap type transaction
					svif.rvalid = 1'b0;
				end//End of read data channel
			end//else condition of areser=tn
		end //forever looop
		common::vif = svif;			
	endtask
endclass
