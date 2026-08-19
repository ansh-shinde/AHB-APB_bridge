module data(
    input           hclk,
    input           hreset,
    input   [1:0]   htrans,
    input   [2:0]   hsize,
    input           hwrite,
    input           hselb,
    input           en_psel,
    input           pw_addr_data,
    input           pr_addr,
    input   [31:0]  haddr,
    input   [31:0]  prdata,
    input   [31:0]  hwdata,
    output  reg     hwrite_reg,
    output  reg        psel0,psel1,psel2,psel3,valid,
    output  reg        valid_size,valid_addr,
    output  reg[31:0]  paddr,pwdata,hrdata
);

    localparam HTRANS_IDLE   = 2'b00;    
    localparam HTRANS_BUSY   = 2'b01;    
    localparam HTRANS_NONSEQ = 2'b10;    
    localparam HTRANS_SEQ    = 2'b11;

    localparam HSIZE_BYTE = 3'b000;
    localparam HSIZE_HALF = 3'b001;
    localparam HSIZE_WORD = 3'b010;


    reg [31:0] addr_reg1,
               addr_reg2,
               data_reg1;
   


//=========================================================================
// pipeline handling block
//=========================================================================

   always@(posedge hclk or posedge hreset)begin
       if (hreset) begin
           addr_reg1 <= 32'b0;
           addr_reg2 <= 32'b0;
           data_reg1 <= 32'b0;
           hwrite_reg <= 1'b0;
       end
       else if(hselb)begin
           addr_reg1 <= haddr;
           addr_reg2 <= addr_reg1;
           hwrite_reg <= hwrite;
           data_reg1 <= hwdata;
           hrdata    <= prdata;
           if (pw_addr_data) begin
               paddr  <= addr_reg2;
               pwdata <= data_reg1;
           end
           if (pr_addr) begin
               paddr  <= addr_reg2;
           end
       end
   end


//============================================================================
// alignment check and address check block
//============================================================================

    always@(*)begin
        if ((addr_reg1>=32'h00 )&&(addr_reg1<=32'h7C)) begin
            valid_addr=1'b1;
        end
        else begin
            valid_addr=1'b0;
        end
        if (hsize > 2) begin
            valid_size=0;
        end
        else begin
            case (hsize)
                HSIZE_HALF: begin
                    if (addr_reg1[0]==0) begin
                        valid_size=1;
                    end
                    else begin
                        valid_size=0;
                    end
                end
                HSIZE_WORD: begin
                    if (addr_reg1[1:0]==2'b0) begin
                        valid_size=1;
                    end
                    else begin
                        valid_size=0;
                    end
                end
                HSIZE_BYTE: valid_size=1;
                default: begin
                    valid_size=0;
                end
            endcase
        end
    end

//==============================================================================
// valid generate block
// =============================================================================

    always@(*)begin
        if ((valid_addr)&&(valid_size)&&(htrans!=HTRANS_BUSY)&&(htrans!=HTRANS_IDLE)) begin
            valid=1;
        end
        else begin
            valid=0;
        end
    end

//================================================================================
// addr decode block
// ===============================================================================

    always@(*)begin
        if (en_psel) begin
            psel0 = 0;
            psel1 = 0;
            psel2 = 0;
            psel3 = 0;
           case (addr_reg2[6:5])
               0: psel0=1;
               1: psel1=1;
               2: psel2=1;
               3: psel3=1;
               default: begin
                   psel0=0;
                   psel1=0;
                   psel2=0;
                   psel3=0;
               end
           endcase
           end
        else begin
            psel0=0;
            psel1=0;
            psel2=0;
            psel3=0;
        end
    end

endmodule
