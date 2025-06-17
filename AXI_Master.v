`timescale 1ns / 1ps

module AXI_Master(
    input clk,
    input rst,
    input newd,
    input [7:0] data_in,
    input tready,
    output tvalid,
    output [7:0] tdata,
    output tlast
    );
    
    parameter IDLE=0,TX=1;   // FSM states
    reg ps,ns;
    reg [2:0] count;  // to check the length of the data
    
    //Sequential state-update logic (FSM State Register)
    always@(posedge clk) begin
        if(rst)
            ps<=IDLE;    // if rst is asserted return back to IDLE state
        else
            ps<=ns;      // update present state (ps) to next state (ns)
    end
    
    //Sequential logic for counting transmitted data bits
    always@(posedge clk) begin
        if(ps==IDLE)
            count<=0;  // start of a new transfer
         else if(ps==TX && count!=3 && tready)  // taking length of the stream is 3
            count<=count+1;  // indicating one data bit sent
         else
            count<=count;  // no new data bit sent or not ready
    end
    
    //Next state logic for FSM
    //If 'newd' is asserted (new data ready), move to TX (transmit) state Otherwise, stay in IDLE
    //If 'tready' is high (slave ready to accept data):
    //    If count is not yet 4, stay in TX (continue transmitting)
    //    If count reaches 4, go back to IDLE (transfer complete)
    //    If 'tready' is low, remain in TX (wait until ready)
    always@(*) begin
        case(ps)
            IDLE: ns=newd?TX:IDLE; 
            TX:   ns=tready?((count!=3)?TX:IDLE):TX;
            default: ns=IDLE;
        endcase
    end
    
    //Output logic
    // 'tdata' is assigned only when 'tvalid' is high; otherwise, output is undefined or held
    assign tdata=tvalid?(data_in):0;
    //'tlast' is asserted when the last bit of a 4-bit transfer is reached ie count=4 and in TX state
    assign tlast=((count==3) && (ps==TX));
    // 'tvalid' is high only when in TX state,indicating valid data is being transmitted
    assign tvalid=(ps==TX);
    
endmodule
