module LA_BTN_FLTR #(
    parameter CNTR_WIDTH = 3
) (
   input CLK,
   input RST,
   input CE,
   input BTN_IN,
   output BTN_OUT,
   output reg BTN_CEO
   );

    reg BTN_D, BTN_S1;
    reg [CNTR_WIDTH-1:0] FLTR_CNT;
    reg BTN_S2;
    
    always@(posedge CLK, posedge RST)
    if(RST) begin
        BTN_D <= 1'b0;
        BTN_S1 <= 1'b0;
    end
    else begin
        BTN_D <= BTN_IN;
        BTN_S1 <= BTN_D;
    end

    always@(posedge CLK, posedge RST)
        if(RST)FLTR_CNT <= {CNTR_WIDTH{1'b0}};
        else if(~(BTN_S1 ^ BTN_S2)) FLTR_CNT <= {CNTR_WIDTH{1'b0}};
        else if(CE) FLTR_CNT <= FLTR_CNT + 1'b1;
    
    always @(posedge CLK, posedge RST) begin
        if(RST)BTN_CEO <= 1'b0;
        else if(CE & (&FLTR_CNT)) BTN_S2 <= BTN_S1;
    end

    always @(posedge CLK, posedge RST) begin
        if(RST) BTN_CEO <= 1'b0;
        else BTN_CEO <= CE & (&FLTR_CNT) & BTN_S1;
    end

    assign BTN_OUT = BTN_CEO;

endmodule