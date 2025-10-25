class axi_monitor;
    //First we will include virtual interface 
    virtual axi_interface avif;
    //Create a packet
    axi_tx tx;
    task run();
        avif = common::vif;
        //At every clock cycle if there is any valid data, address and evry other signal inside interface then we need store those data to the packet tx handle  and then send it to the SoC and monitor block
        forever begin
            @(posedge avif.aclk);
            tx = new();
            //1.Store all valid write_address_channel signals to tx
            if(avif.awvalid==1'b1 && avif.awready==1'b1)begin//While checking address signals are valid or not , also check is slave is ready to recieve or not
                tx.awaddr = avif.awaddr;
                tx.awsize = avif.awsize;
                tx.awlen = avif.awlen;
                tx.awburst = avif.awburst;
                tx.awprot = avif.awprot;
                tx.awcache = avif.awcache;
                tx.awid = avif.awid;
                tx.awlock = avif.awlock;
                tx.awvalid = avif.awvalid;
                tx.awready = avif.awready;
                common::mon2soc.put(tx);
            end//End of conditional statement of awvalid and awready

            //2.Store all valid write_data_channel signals to tx
            if(avif.wvalid==1'b1 && avif.wready==1'b1)begin 
                tx.wdata.push_back(avif.wdata);
                tx.wstrb = avif.wstrb;
                tx.wid = avif.wid;
                tx.wlast = avif.wlast;
                tx.wvalid = avif.awvalid;
                tx.wready = avif.awready;
                common::mon2soc.put(tx);
            end//End of conditional  statement of wvalid and wready

            //3.Store all valid write_response_channel signals to tx
            if(avif.bvalid==1'b1 && avif.bready==1'b1)begin
                tx.bvalid = avif.bvalid;
                tx.bready = avif.bready;
                tx.bid = avif.bid;
                tx.bresp = avif.bresp;
                common::mon2soc.put(tx);
            end//End of conditoinal statement of bready and bvalid

            //4.Store all valid read_address_channel signals to tx
            if(avif.arvalid==1'b1 && avif.arready==1'b1)begin
                tx.araddr = avif.araddr;
                tx.arsize = avif.arsize;
                tx.arlen = avif.arlen;
                tx.arburst = avif.arburst;
                tx.arprot = avif.arprot;
                tx.arcache = avif.arcache;
                tx.arid = avif.arid;
                tx.arlock = avif.arlock;
                tx.arvalid = avif.arvalid;
                tx.arready = avif.arready;
                common::mon2soc.put(tx);
            end//End of conditional statement of arvalid  and arready

            //5.Store all valid read_data_channel signals to tx
            if(avif.rvalid==1'b1 && avif.rready==1'b1)begin
                tx.rdata = avif.rdata;
                tx.rid = avif.rid;
                tx.rresp = avif.rresp;
                tx.rlast = avif.rlast;
                tx.rvalid = avif.rvalid;
                tx.rready = avif.rready;
                common::mon2soc.put(tx);
            end//End of conditional statement of rvalid and rready
        
        end//End of forever loop
    endtask
endclass