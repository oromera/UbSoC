module bin2gray (bin, gray); 

parameter SIZE = 8;

input  [SIZE-1:0] bin; 
output [SIZE-1:0] gray; 

assign gray = (bin>>1) ^ bin; 

endmodule 

			
module gray_counter (clk_i, rst_n_i, en_i, period_i, clock_o);

parameter SIZE = 8;
 
input            clk_i;
input            rst_n_i;
input            en_i;
input [SIZE-1:0] period_i;

output           clock_o;

reg   [SIZE-1:0] gray_code;
reg   [SIZE-1:0] tog;
reg              clock;
wire  [SIZE-1:0] gray_code_comp;
 
integer i,j,k;
 
bin2gray #SIZE B2G(period_i, gray_code_comp);

assign clock_o = clock;
 
always @(posedge clk_i or negedge rst_n_i) 
  if (rst_n_i==1'b0) begin
   gray_code <= 0;
   clock <= 1'b0;
  end
  else begin //sequential update
    if (en_i==1'b1) 
      if (gray_code_comp==gray_code) begin
        gray_code <= 0;
        clock  <= 1'b1;
      end
      else begin //enabled
        clock  <= 1'b0;
        tog = 0;
        for (i=0; i<=SIZE-1; i=i+1) begin  //i loop
        //
        // Toggle bit if number of bits set in [SIZE-1:i] is even
        // XNOR current bit up to MSB bit 
        //
          for (j=i; j<=SIZE-1; j=j+1) tog[i] = tog[i] ^ gray_code[j];  
          tog[i] = !tog[i];                 
        //
        // Disable tog[i] if a lower bit is toggling
        //
          for (k=0; k<=i-1; k=k+1) tog[i] = tog[i] && !tog[k];
        end //i loop
        //
        //Toggle MSB if no lower bits set (covers code wrap case)
        //
        if (tog[SIZE-2:0]==0) tog[SIZE-1] = 1; 
        //
        //Apply the toggle mask
        //
        gray_code <= gray_code ^ tog;          
      end //enabled
   end //sequential update
endmodule
