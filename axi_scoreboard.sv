class axi_scoreboard;
    //Create a packet to recieve the that from the monitor
    axi_tx tx;
    axi_tx wr_tx[int];

    bit[7:0] expected_data[int];
    int wdata;
    int rd_data[int];

    int count;
    
    task run();
        forever begin
            common::mon2soc.get(tx);

            //1.Write address channel
            if(tx.awvalid==1'b1 && tx.awready==1'b1)begin
                wr_tx[tx.awid] = new();
                wr_tx[tx.awid].awaddr = tx.awaddr;
                wr_tx[tx.awid].awburst = tx.awburst;
                wr_tx[tx.awid].awsize = tx.awsize;
            end//End pof conditional statement of awvalid and awready

            //2.Write data channel
            if(tx.wvalid==1'b1 && tx.wready==1'b1)begin
                //Create the expected data with respect data to WSTRB
                count = 0;
                wdata = tx.wdata.pop_back();
                for(int j = 0; j<($size(tx.wdata)/8); j++) begin //if wdata size is 32 bits then for loop will work 4 times and if wdata size is 128 bits the loop will work 16 times and so 
					if(tx.wstrb[j]==1)begin//Checks every bit  of wstrb 
						expected_data[wr_tx[tx.wid].awaddr+count] = wdata[j*8 +:  8];
                        count = count+1;
					end//wstrb condition
				end		
                $display("Expected data = %0p, Address = %0h", expected_data, wr_tx[tx.wid].awaddr);
    			wr_tx[tx.wid].awaddr = wr_tx[tx.wid].awaddr - (wr_tx[tx.wid].awaddr)%2**wr_tx[tx.wid].awsize; //aligned address conversion
				wr_tx[tx.wid].awaddr = wr_tx[tx.wid].awaddr + 2**wr_tx[tx.wid].awsize;
            end//End of conditional statement of wvalid and wready

            //3.Write response channel
            if(tx.bvalid==1'b1 && tx.bready==1'b1)begin
            end//End of conditional statement of bavlid and bready

            //4.Read address channel
            if(tx.arvalid==1'b1 && tx.arready==1'b1)begin
            end//End of condtional statement of arvalid and arready
        end//End of forever loop
    endtask
endclass