/*
File     : divider_top.v 
Author   : Gandhi Puvvada
Revision  : 1.1, 2.0 (Nexys-3), 3.0 (Nexys-4)
Date : Feb 15, 2008, 10/14/08, 2/12/2012, 10/3/2020
*/

/*
A verlog top module for the 4-bit division by repetitive subtraction.
An example verilog design for the ee201L students.

 The program does the following:
 
 We set the 4-bit dividend (Xin) and the 4-bit divisor (Yin) 
 on Sw7-Sw4 and Sw3-Sw0 respectively. 
 The BtnL (Btn Left) is our Start button and BtnR (Btn Right) is our Ack button.
 The Ld3, Ld2, Ld1, Ld0 glow when BtnL, BtnU, BtnR, BtnD  are pressed respectively.
 The Ld4 glows when the Done signal is activated by the divider.
 Ld7, Ld6, Ld5 represent Initial (QI), Compute (QC) and Done (QD) states.
 The BtnC (the center button) on the Nexys 3 or Nexys 4 boards acts as the Reset button in this design.
 The right 4 digits (SSDs) from left to right display, the dividend, the divisor,
 the quotient, and the remainder.
 
 We did not add debouncing circuitry, nor single stepping circuitry
 in this rather simple-minded design. 
 Since we have a separate START button (BtnL) and a separate ACK button (BtnR), 
 the bouncing of these buttons does not affect the operation of the divider.

*/
/*
 Make sure to use the ee354_top.xdc file containing pin info.
                                                                                      
*/
module simple_calculator_top      (   
        MemOE, MemWR, RamCS, QuadSpiFlashCS, // Disable the three memory chips

        ClkPort,                           // the 100 MHz incoming clock signal
        
		// VGA signals:
		Hsync, Vsync,
		vgaRed, vgaGreen, vgaBlue,
		
        BtnL, BtnU, BtnD, BtnR,            // the Left, Up, Down, and the Right buttons         BtnL, BtnR,
        BtnC,                              // the center button (this is our reset in most of our designs)
        Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8, Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0, // 16 switches
        Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0, // 8 LEDs
        An3, An2, An1, An0,                // 4 anodes
        An7, An6, An5, An4,                // another 4 anodes (we need to turn these unused SSDs off)
        Ca, Cb, Cc, Cd, Ce, Cf, Cg,        // 7 cathodes
        Dp,                                // Dot Point Cathode on SSDs
		MemOE, MemWR, RamCS, QuadSpiFlashCS
      );
     
                                
    /*  INPUTS */
    // Clock & Reset I/O
    input       ClkPort;    
    // Project Specific Inputs
    input       BtnL, BtnU, BtnD, BtnR, BtnC;   
    input       Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8, Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0;
    
    
    /*  OUTPUTS */
    // Control signals on Memory chips  (to disable them)
    output  MemOE, MemWR, RamCS, QuadSpiFlashCS;
	// VGA signals
	output Hsync, Vsync;
	output [3:0] vgaRed, vgaGreen, vgaBlue;
	wire[9:0] hc, vc;
	
    // Project Specific Outputs
    // LEDs
    output  Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7;
    // SSD Outputs
    output  Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;
    output  An0, An1, An2, An3; 
    output  An4, An5, An6, An7; // extra four unused SSDs need to be turned off
    
    /*  LOCAL SIGNALS */
    wire        Reset;
    wire        board_clk;
    wire [2:0]  ssdscan_clk;
    wire [15:0] Input;
    wire        BtnU_pulse, BtnD_pulse, BtnL_pulse, BtnR_pulse;
    reg         Flag;
    reg  [15:0] C;
    reg         QI, QGet_A, QGet_B, QGet_Op, QAdd, QSub, QMul, QDiv, QErr, QDone;
	wire [11:0] rgb;

// to produce divided clock
    reg [26:0]  DIV_CLK;
// SSD (Seven Segment Display)
    reg [3:0]   SSD;
    wire [3:0]  SSD7, SSD6, SSD5, SSD4, SSD3, SSD2, SSD1, SSD0;
    reg [7:0]   SSD_CATHODES;


//------------
// CLOCK DIVISION

    // The clock division circuitary works like this:
    //
    // ClkPort ---> [BUFGP2] ---> board_clk
    // board_clk ---> [clock dividing counter] ---> DIV_CLK
    // DIV_CLK ---> [constant assignment] ---> sys_clk;
    
    // Instantiation of BUFGP is an old practice. The implementation tools provide an appropriate Global Buffer automatically.
    // BUFGP BUFGP1 (board_clk, ClkPort);   
    assign board_clk = ClkPort;

    // As the ClkPort signal travels throughout our design,
    // it is necessary to provide global routing to this signal. 
    // The BUFGPs buffer these input ports and connect them to the global 
    // routing resources in the FPGA.

    // BUFGP BUFGP2 (Reset, BtnC); In the case of Spartan 3E (on Nexys-2 board), we were using BUFGP to provide global routing for the reset signal. But Spartan 6 (on Nexys-3) does not allow this.
    assign Reset = BtnC;
//------------
    // Our clock is too fast (100MHz) for SSD scanning
    // create a series of slower "divided" clocks
    // each successive bit is 1/2 frequency
    always @(posedge board_clk, posedge Reset)    
    begin                           
        if (Reset)
        DIV_CLK <= 0;
        else
        DIV_CLK <= DIV_CLK + 1'b1;
    end

    assign Input = {Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8, Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0};
    assign Reset = BtnC;
	// Assign VGA values from rgb
	assign vgaRed = rgb[11 : 8];
	assign vgaGreen = rgb[7  : 4];
	assign vgaBlue = rgb[3  : 0];
	
	// disable mamory ports
	assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;

    ee354_debouncer #(.N_dc(28)) ee354_debouncer_up
        (.CLK(board_clk), .RESET(Reset), .PB(BtnU), .DPB( ),
        .SCEN(BtnU_pulse), .MCEN( ), .CCEN( ));
    ee354_debouncer #(.N_dc(28)) ee354_debouncer_down
        (.CLK(board_clk), .RESET(Reset), .PB(BtnD), .DPB( ),
        .SCEN(BtnD_pulse), .MCEN( ), .CCEN( ));
    ee354_debouncer #(.N_dc(28)) ee354_debouncer_left
        (.CLK(board_clk), .RESET(Reset), .PB(BtnL), .DPB( ),
        .SCEN(BtnL_pulse), .MCEN( ), .CCEN( ));
    ee354_debouncer #(.N_dc(28)) ee354_debouncer_right
        (.CLK(board_clk), .RESET(Reset), .PB(BtnR), .DPB( ),
        .SCEN(BtnR_pulse), .MCEN( ), .CCEN( ));
		
	display_controller dc(.clk(ClkPort), .Hsync(Hsync), .Vsync(Vsync), .bright(bright), .hCount(hc), .vCount(vc), .A(A), .B(B), .C(C));
	calculator_output sc(.clk(ClkPort), .bright(bright), .rst(BtnC), .hCount(hc), .vCount(vc), .rgb(rgb), .A(A), .B(B), .C(C));	

    simple_calculator #(.N_dc(28)) ee354_simple_calculator
        (.In(Input), .Clk(board_clk), .Reset(Reset), .Done(Done), .SCEN(), .ButU(BtnU_pulse), .ButD(BtnD_pulse),
        .ButL(ButL_pulse), .ButR(BtnR_pulse), .C(C), .Flag(Flag), .QI(QI), .QGet_A(QGet_A),
        .QGet_B(QGet_B), .QGet_Op(QGet_Op), .QAdd(QAdd), .QSub(QSub), .QMul(QMul), .QDiv(QDiv),
        .QErr(QErr), .QDone(QDone));
endmodule
