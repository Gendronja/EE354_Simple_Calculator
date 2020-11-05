// --------------------------------
// Simple Calculator
// Jason Yik, Haoda Wang, Jason Gendron
// EE 354
// --------------------------------

module simple_calculator_top (   
        MemOE, MemWR, RamCS, QuadSpiFlashCS, // Disable the three memory chips
        ClkPort,                             // the 100 MHz incoming clock signal
		// VGA signals:
		Hsync, Vsync,
		vgaRed, vgaGreen, vgaBlue,
        // Control signals
        BtnL, BtnU, BtnD, BtnR,            // the Left, Up, Down, and the Right buttons         BtnL, BtnR,
        BtnC,                              // the center button (this is our reset in most of our designs)
        Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8, Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0, // 16 switches
        Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0, // 8 LEDs
        An3, An2, An1, An0,                // 4 anodes
        An7, An6, An5, An4,                // another 4 anodes (we need to turn these unused SSDs off)
        Ca, Cb, Cc, Cd, Ce, Cf, Cg,        // 7 cathodes
        Dp,                                // Dot Point Cathode on SSDs
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
    wire        Reset = 0;
    wire        board_clk;
    wire [2:0]  ssdscan_clk;
    wire [15:0] Input;
    wire        BtnU_pulse, BtnD_pulse, BtnL_pulse, BtnR_pulse, BtnC_pulse;
    wire        Flag;
    wire [15:0] A, B;
    wire [16:0] C;
    wire        QI, QGet_A, QGet_B, QGet_Op, QAdd, QSub, QMul, QDiv, QErr, QDone;
	wire [11:0] rgb;

    // to produce divided clock
    reg  [26:0]  DIV_CLK;
    // SSD (Seven Segment Display)
    reg  [3:0]  SSD;
    wire [3:0]  SSD7, SSD6, SSD5, SSD4, SSD3, SSD2, SSD1, SSD0;
    reg  [7:0]  SSD_CATHODES;


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
    assign Reset = 0;
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
    ee354_debouncer #(.N_dc(28)) ee354_debouncer_center
        (.CLK(board_clk), .RESET(Reset), .PB(BtnC), .DPB( ),
        .SCEN(BtnC_pulse), .MCEN( ), .CCEN( ));
		
	display_controller dc(.clk(ClkPort), .Hsync(Hsync), .Vsync(Vsync), .bright(bright), .hCount(hc), .vCount(vc));
	calculator_output sc(.clk(ClkPort), .bright(bright), .hCount(hc), .vCount(vc), .rgb(rgb), .A(A), .B(B), .C(C));	

    simple_calculator ee354_simple_calculator
        (.In(Input), .Clk(board_clk), .Reset(Reset), .Done(Done), .SCEN(BtnC_pulse), .ButU(BtnU_pulse), .ButD(BtnD_pulse),
        .ButL(ButL_pulse), .ButR(BtnR_pulse), .A(A), .B(B), .C(C), .Flag(Flag), .QI(QI), .QGet_A(QGet_A),
        .QGet_B(QGet_B), .QGet_Op(QGet_Op), .QAdd(QAdd), .QSub(QSub), .QMul(QMul), .QDiv(QDiv),
        .QErr(QErr), .QDone(QDone));

    //------------
    // OUTPUT: LEDS
    assign {Ld12, Ld11, d10, Ld9, Ld8, Ld7, Ld6, Ld5, Ld4} = {QDone, QErr, QDiv, QMul, QSub, QAdd, QGet_Op, QGet_B, QGet_A}; 
    assign {Ld3, Ld2, Ld1, Ld0} = {BtnU, BtnD, BtnL, BtnR};

    //------------
    // SSD (Seven Segment Display)
    // reg [3:0]    SSD;
    // wire [3:0]   SSD3, SSD2, SSD1, SSD0;
    
    //SSDs display Xin, Yin, Quotient, and Reminder  
    assign SSD7 = A[15:12];
    assign SSD6 = A[11:8];
    assign SSD5 = A[7:4];
    assign SSD4 = A[3:0];
    assign SSD3 = B[15:12];
    assign SSD2 = B[11:8];
    assign SSD1 = B[7:4];
    assign SSD0 = B[3:0];


    // need a scan clk for the seven segment display 
    
    // 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
    // 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
    // 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
    
    // 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
    
    //                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
    //  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
    //
    //               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
    //  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
    //
    //         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
    //  DIV_CLK[19]       |___________|           |___________|
    //

    assign ssdscan_clk = DIV_CLK[19:17];
    assign An0  = !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 000
    assign An1  = !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) && (ssdscan_clk[0]));  // when ssdscan_clk = 001
    assign An2  = !(~(ssdscan_clk[2]) && (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 010
    assign An3  = !(~(ssdscan_clk[2]) && (ssdscan_clk[1]) && (ssdscan_clk[0]));  // when ssdscan_clk = 011
    assign An4  = !((ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 100
    assign An5  = !((ssdscan_clk[2]) && ~(ssdscan_clk[1]) && (ssdscan_clk[0]));  // when ssdscan_clk = 101
    assign An6  = !((ssdscan_clk[2]) && (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 110
    assign An7  = !((ssdscan_clk[2]) && (ssdscan_clk[1]) && (ssdscan_clk[0]));  // when ssdscan_clk = 111
    // Turn off another 4 anodes
    
    
    always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3, SSD4, SSD5, SSD6, SSD7)
    begin : SSD_SCAN_OUT
        case (ssdscan_clk) 
                  3'b000: SSD = SSD0;
                  3'b001: SSD = SSD1;
                  3'b010: SSD = SSD2;
                  3'b011: SSD = SSD3;
                  3'b100: SSD = SSD4;
                  3'b101: SSD = SSD5;
                  3'b110: SSD = SSD6;
                  3'b111: SSD = SSD7;
                  
        endcase 
    end

    // Following is Hex-to-SSD conversion
    always @ (SSD) 
    begin : HEX_TO_SSD
        case (SSD) // in this solution file the dot points are made to glow by making Dp = 0
            //                                                                abcdefg,Dp
            4'b0000: SSD_CATHODES = 8'b00000011; // 0
            4'b0001: SSD_CATHODES = 8'b10011111; // 1
            4'b0010: SSD_CATHODES = 8'b00100101; // 2
            4'b0011: SSD_CATHODES = 8'b00001101; // 3
            4'b0100: SSD_CATHODES = 8'b10011001; // 4
            4'b0101: SSD_CATHODES = 8'b01001001; // 5
            4'b0110: SSD_CATHODES = 8'b01000001; // 6
            4'b0111: SSD_CATHODES = 8'b00011111; // 7
            4'b1000: SSD_CATHODES = 8'b00000001; // 8
            4'b1001: SSD_CATHODES = 8'b00001001; // 9
            4'b1010: SSD_CATHODES = 8'b00010001; // A
            4'b1011: SSD_CATHODES = 8'b11000001; // B
            4'b1100: SSD_CATHODES = 8'b01100011; // C
            4'b1101: SSD_CATHODES = 8'b10000101; // D
            4'b1110: SSD_CATHODES = 8'b01100001; // E
            4'b1111: SSD_CATHODES = 8'b01110001; // F    
            default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
        endcase
    end 
    
    // reg [7:0]  SSD_CATHODES;
    assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

endmodule
