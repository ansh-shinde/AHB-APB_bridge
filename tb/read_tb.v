module test_rd;

reg clk;

reg hselb, hwrite, hreset;
reg [1:0]htrans;
reg [2:0]hsize;
reg [2:0]hburst;
reg [31:0]hwdata,haddr;
wire hready,hresp;
wire [31:0]hrdata;

reg rx,cts;

wire tx, intrr_tx, intrr_rx,rts;

wire psel0, psel2, psel3, psel4, penable_top, pwrite_top, pready_top,pslverr_top;
wire [31:0]pwdata_top,paddr_top,prdata_top, pwdata_rop;

//======================
// DUT
//======================

top dut1(
    .hclk    (clk),
    .hreset (hreset),
    .hwrite  (hwrite),
    .hselb   (hselb),
    .pready  (pready_top),
    .pslverr (pslverr_top),
    .hwdata  (hwdata),
    .prdata  (prdata_top),
    .htrans  (htrans),
    .hsize   (hsize),
    .hburst  (hburst),
    .haddr   (haddr),
    .hready  (hready),
    .hresp   (hresp),
    .psel0   (psel0),
    .psel1   (psel1),
    .psel2   (psel2),
    .psel3   (psel3),
    .penable (penable_top),
    .pwrite  (pwrite_top),
    .pwdata  (pwdata_top),
    .paddr   (paddr_top),
    .hrdata  (hrdata)
);


apb_uart dut2(
    .preset(hreset),
    .pclk(clk),
    .penable(penable_top),
    .pwrite(pwrite_top),
    .psel(psel0),
    .paddr(paddr_top),
    .pwdata(pwdata_top),
    .pready(pready_top),
    .pslverr(pslverr_top),
    .prdata(prdata_top),
    .rx(rx),
    .intrr_tx(intrr_tx),
    .intrr_rx(intrr_rx),
    .cts(cts),
    .rts(rts),
    .tx(tx)
);

//======================
// CLOCK
//======================

initial begin
    clk = 1'b0;
end

always #5 clk = ~clk;

//============================================================
// INITIAL VALUES
//============================================================

initial begin
    hreset = 1'b1;
    hwrite  = 1'b0;
    hselb   = 1'b0;
    hwdata  = 32'b0;
    htrans  = 2'b00;       // IDLE
    hsize   = 3'b000;
    hburst  = 3'b000;
    haddr   = 32'b0;
    rx=1;
end

initial begin
    $dumpfile("bridge_interface_rd.vcd");
    $dumpvars(0, test_rd);

    $dumpvars(0,dut2.regfile[0]);
    $dumpvars(0,dut2.regfile[1]);
    $dumpvars(0,dut2.regfile[2]);
    $dumpvars(0,dut2.regfile[3]);
    $dumpvars(0,dut2.regfile[4]);
    $dumpvars(0,dut2.regfile[5]);
    $dumpvars(0,dut2.regfile[6]);
    $dumpvars(0,dut2.regfile[7]);

    $dumpvars(0,dut2.receiver.dat.fifo.dat.str.regfile[0]);
    $dumpvars(0,dut2.receiver.dat.fifo.dat.str.regfile[1]);
    $dumpvars(0,dut2.receiver.dat.fifo.dat.str.regfile[2]);
    $dumpvars(0,dut2.receiver.dat.fifo.dat.str.regfile[3]);
    $dumpvars(0,dut2.receiver.dat.fifo.dat.str.regfile[4]);
    $dumpvars(0,dut2.receiver.dat.fifo.dat.str.regfile[5]);
    $dumpvars(0,dut2.receiver.dat.fifo.dat.str.regfile[6]);
    $dumpvars(0,dut2.receiver.dat.fifo.dat.str.regfile[7]);
    #400000 $finish;
end

//------------------------------------------------------------------------------
// Rx Bit Task
//------------------------------------------------------------------------------

task send_bit;
input bit_val;
begin
    rx = bit_val;
    #4210;
end
endtask

//------------------------------------------------------------------------------
// UART Frame Task
//------------------------------------------------------------------------------

task send_uart_frame;
input [7:0] data;
input parity;
input stop;
integer i;
begin
    if(rts) begin
        send_bit(0);

        for(i=0;i<8;i=i+1)
            send_bit(data[i]);

        send_bit(parity);
        send_bit(stop);
        #4210;
    end
end
endtask

initial begin

    #20;
    hreset = 1'b0;
    hselb = 1; 

    @(posedge clk)begin
        htrans=2'b10;
        hsize=3'b010;
        hburst=3'b000;
        haddr=32'h8C; // invalid addr
        hwrite=1;
    end

    @(posedge clk)begin
        hwdata=32'h01010101;
    end

    repeat(2)@(posedge clk)begin
        htrans=2'b00;
    end

// load config data
    @(posedge clk)begin
        htrans=2'b10;
        hsize=3'b010;
        hburst=3'b000;  
        haddr=32'h00;
        hwrite=1;
    end
    @(posedge clk)begin
        hwdata=32'h01010101;
    end
    repeat(2)@(posedge clk)begin
        htrans=2'b00;
    end

// load baud rate
    @(posedge clk)begin
        htrans=2'b10;
        hsize=3'b010;
        hburst=3'b000;
        haddr=32'h08;
        hwrite=1;
    end
    @(posedge clk)begin
        hwdata=32'h1B2;
    end
    repeat(2)@(posedge clk)begin
        htrans=2'b00;
    end

    @(posedge clk);
// UART RX TESTS
    send_uart_frame(8'h11,1,1);
    send_uart_frame(8'hA5,1,1);
    send_uart_frame(8'h55,0,1); // parity error
    send_uart_frame(8'h33,1,0); // framing error
    send_uart_frame(8'h77,1,1);
    send_uart_frame(8'h88,1,1);
    send_uart_frame(8'h99,1,1);

    wait(intrr_rx==1)begin
         @(posedge clk)begin
             htrans=2'b10;
             hsize=3'b010;
             hburst=3'b000;
             haddr=32'h10; 
             hwrite=0;
         end

         wait(hready==1);

         repeat(2)@(posedge clk)begin
             htrans=2'b00;
         end    

         @(posedge clk)begin
             htrans=2'b10;
             hsize=3'b010;
             hburst=3'b000;
             haddr=32'h10; 
             hwrite=0;
         end

         wait(hready==1);

         repeat(2)@(posedge clk)begin
             htrans=2'b00;
         end

         @(posedge clk)begin
             htrans=2'b10;
             hsize=3'b010;
             hburst=3'b000;
             haddr=32'h10;
             hwrite=0;
         end

         wait(hready==1);

         repeat(2)@(posedge clk)begin
             htrans=2'b00;
         end

         @(posedge clk)begin
             htrans=2'b10;
             hsize=3'b010;
             hburst=3'b000;
             haddr=32'h10;
             hwrite=0;
         end


         repeat(2)@(posedge clk)begin
             htrans=2'b00;
         end    
     end

end
endmodule 

