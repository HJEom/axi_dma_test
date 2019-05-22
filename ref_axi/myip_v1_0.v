
`timescale 1 ns / 1 ps

    	module myip_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_START_COUNT	= 32
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid,

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready
	);
	
	// state
	localparam integer
	IDLE = 0,
	
	RECEIVE = 1,
	SEND = 1;
	
	// don't use byte access for output tdata
	assign m00_axis_tstrb = 4'b1111;
	
	wire clk, rstn;
	assign clk = s00_axis_aclk;
	assign rstn = s00_axis_aresetn;
	
	// fifo regiter
	reg [320-1:0] fifo_reg;
	
	///////////////////////////////////////////////////////////////////////////////////////////
	/////////////////   receive the data from DMA to myIP         /////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
	
	// receive FSM
	reg rcv_cs;
	always@(posedge clk) begin
	   if(!rstn) begin
	       rcv_cs <= IDLE;
	   end
	   else begin
	       case(rcv_cs)
	           IDLE : begin
	                       if(s00_axis_tvalid) begin
	                           rcv_cs <= RECEIVE;
	                       end
	           end
	           RECEIVE : begin
	                       if(s00_axis_tlast) begin
	                           rcv_cs <= IDLE;
	                       end
	           end
	       endcase
	   end
	end
	
	// tready signal
	assign s00_axis_tready = (rcv_cs == RECEIVE) ? 1'b1 : 1'b0;
	
	// store the input data in fifo_reg
	always@(posedge clk) begin
	   if(!rstn) begin
	       fifo_reg <= 320'd0;
	   end
	   else begin
	       case(rcv_cs)
	           RECEIVE : begin
	                       if(s00_axis_tvalid && s00_axis_tready) begin
	                           fifo_reg <= {fifo_reg[319-32:0], s00_axis_tdata};
	                       end
	           end
	       endcase
	   end
	end
	
	///////////////////////////////////////////////////////////////////////////////////////////
    /////////////////   internal operating                        /////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////
    
    // operating count
    reg [3:0] oprt_cnt;
    always@(posedge clk) begin
        if(!rstn) begin
            oprt_cnt <= 4'd0;
        end
        else begin
            if(s00_axis_tlast) oprt_cnt <= 4'd1;
            else if(oprt_cnt != 4'd0) begin
                if(oprt_cnt == 4'd11) oprt_cnt <= 4'd0;
                else oprt_cnt <= oprt_cnt + 1'b1;
            end
        end
    end
    
    // internal operating
    reg [319:0] int_reg;
    always@(posedge clk) begin
        if(!rstn) begin
            int_reg <= 320'd0;
        end
        else begin
            case(oprt_cnt)
                4'd2  : int_reg[319:288] <= fifo_reg[319:288]*2;
                4'd3  : int_reg[287:256] <= fifo_reg[287:256]*2;
                4'd4  : int_reg[255:224] <= fifo_reg[255:224]*2;
                4'd5  : int_reg[223:192] <= fifo_reg[223:192]*2;
                4'd6  : int_reg[191:160] <= fifo_reg[191:160]*2;
                4'd7  : int_reg[159:128] <= fifo_reg[159:128]*2;
                4'd8  : int_reg[127:96]  <= fifo_reg[127:96]*2;
                4'd9  : int_reg[95:64]   <= fifo_reg[95:64]*2;
                4'd10 : int_reg[63:32]   <= fifo_reg[63:32]*2;
                4'd11 : int_reg[31:0]    <= fifo_reg[31:0]*2;
            endcase
        end
    end
    
	////////////////////////////////   ///////////////////////////////////////////////////////////
    /////////////////   send the data from myIP to DMA            /////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////
	
	// send FSM
	reg snd_cs;
	always@(posedge clk) begin
	   if(!rstn) begin
	       snd_cs <= IDLE;
	   end
	   else begin
	       case(snd_cs)
	           IDLE : begin
	                       if(oprt_cnt == 4'd11) begin
	                           snd_cs <= SEND;
	                       end
	           end
	           SEND : begin
	                       if(m00_axis_tlast) begin
	                           snd_cs <= IDLE;
	                       end
	           end
	       endcase
	   end
	end
	
    // send count
    reg [3:0] snd_cnt;
    always@(posedge clk) begin
        if(!rstn) begin
            snd_cnt <= 4'd0;
        end
        else begin
            case(snd_cs)
                IDLE : begin
                            snd_cnt <= 4'd1;
                end
                SEND : begin
                            if(m00_axis_tvalid && m00_axis_tready) begin
                                snd_cnt <= snd_cnt + 1'b1;
                            end
                end
            endcase
        end
    end
	    
    // send
    reg [31:0] m_tdata;
    always@(*) begin
        case(snd_cnt)
                4'd2  : m_tdata = int_reg[319:288];
                4'd3  : m_tdata = int_reg[287:256];
                4'd4  : m_tdata = int_reg[255:224];
                4'd5  : m_tdata = int_reg[223:192];
                4'd6  : m_tdata = int_reg[191:160];
                4'd7  : m_tdata = int_reg[159:128];
                4'd8  : m_tdata = int_reg[127:96];
                4'd9  : m_tdata = int_reg[95:64];
                4'd10 : m_tdata = int_reg[63:32];
                4'd11 : m_tdata = int_reg[31:0];
        endcase
    end
    
    // send valid
    assign m00_axis_tvalid = (snd_cs == SEND) ? 1'b1 : 1'b0;
    
    // send last
    assign m00_axis_tlast = (snd_cnt == 4'd11) ? 1'b1 : 1'b0;
    	
	// send data
	assign m00_axis_tdata = m_tdata;
	
	endmodule
