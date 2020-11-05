`timescale 1ns / 1ps

module calculator_output(
	input clk,             // Sys clk, display_controller.v handles vga sync
	input bright,
	input [9:0] hCount, vCount,
	input rst,
	input [15:0] A, B, C,
	input flag,            // Error or overflow state flag
	output reg [11:0] rgb
   );
    
    wire Ablock, Bblock, Cblock;
    
	reg block_fill;
	reg digit;
	wire [9:0] arrayPos;
	reg [9:0] CorrPos;
	wire [3:0] row, col;
	
	parameter BLK   = 12'b0000_0000_0000;			// Black text
	reg [11:0] background; // White normally or light red if in error state
	
	// Start positions for A, B, and C fields on VGA
	parameter AVert = 10'd100;
	parameter BVert = 10'd150;
	parameter CVert = 10'd200;
	
	// Horizontal start position for each block of text
	parameter hStartPos = 10'd200;
	parameter hEndPos = 10'd360;
	
	
	
	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = BLK;
		else if (block_fill == 1)
			rgb = BLK; 
		else	
			rgb = background;
	end
	
	
	always@(*) 
	begin: Number_Selection_From_Array
		// Select array position based on horizontal position on VGA monitor
		// Each digit location is 10x10 pixels (8x8 for digit, and 1 pixel on each side for spacing)
		
		CorrPos = 15 - arrayPos; 
		
		if ((vCount >= AVert) && (vCount <= BVert))
			digit = A[CorrPos];
			
		else if ((vCount >= BVert) && (vCount <= CVert))
			digit = B[CorrPos];
			
		else if ((vCount >= CVert) && (vCount <= CVert + 10))
			digit = C[CorrPos];
		
		else
			digit = 1'bx;
	
	end
	
	
	always@(*)
	begin
	   if (Ablock || Bblock || Cblock)
	   begin
		// if in pixel 4 or 5 of a text block row, and digit is "1", fill block
		   if (digit == 1)
		   begin
			   case (col)
			
			    10'd0:
			    	block_fill <= 0;
			
			    10'd1:
				    block_fill <= 0;
			
			    10'd2:
				    block_fill <= 0;
				
			    10'd3:
				    block_fill <= 0;
				
			    10'd4:
			        if((row != 0) && (row != 9))
				        block_fill <= 1;
			
			    10'd5:
			        if((row != 0) && (row != 9))
				        block_fill <= 1;
			
			    10'd6:
				    block_fill <= 0;
			
 			    10'd7:
				    block_fill <= 0;
				
			    10'd8:
     				block_fill <= 0;
			
			    10'd9:
				    block_fill <= 0;
			    endcase
			end	
		
		
			// Logic for writing a 0
		    else if (digit == 0)
		    begin
			    case (col)
			
			    10'd0:
				    block_fill <= 0;
			
			    10'd1:
					if ((row == 3) || (row == 4) || (row == 5) || (row == 6))
						block_fill <= 1;
					else
						block_fill <= 0;
			
			    10'd2:
					if ((row == 3) || (row == 4) || (row == 5) || (row == 6))
						block_fill <= 1;
					else
						block_fill <= 0;
				
			    10'd3:
					if ((row == 1) || (row == 2) || (row == 7) || (row == 8))
						block_fill <= 1;
						
					else
						block_fill <= 0;
				
			    10'd4:
					if ((row == 1) || (row == 2) || (row == 7) || (row == 8))
						block_fill <= 1;
						
					else
						block_fill <= 0;
			
			    10'd5:
					if ((row == 1) || (row % 10 == 2) || (row == 7) || (row == 8))
						block_fill <= 1;
						
					else
						block_fill <= 0;
			
			    10'd6:
					if ((row == 1) || (row == 2) || (row == 7) || (row == 8))
						block_fill <= 1;
						
					else
						block_fill <= 0;
			
			    10'd7:
					if ((row == 3) || (row == 4) || (row == 5) || (row == 6))
						block_fill <= 1;
					else
						block_fill <= 0;
				
			    10'd8:
					if ((row == 3) || (row == 4) || (row == 5) || (row == 6))
						block_fill <= 1;
					else
						block_fill <= 0;
			
			    10'd9:
				    block_fill <= 0;
			    endcase
			end
		end
		else
		    block_fill <= 0;
	end
	
	
	// Check if hCount and vCount within the A, B, or C blocks
	assign Ablock = ((hCount >= hStartPos) && (hCount <= hEndPos)) && ((vCount >= AVert) && (vCount <= (AVert + 10)));
	assign Bblock = ((hCount >= hStartPos) && (hCount <= hEndPos)) && ((vCount >= BVert) && (vCount <= (BVert + 10)));
	assign Cblock = ((hCount >= hStartPos) && (hCount <= hEndPos)) && ((vCount >= CVert) && (vCount <= (CVert + 10)));
	// Pick array value based on hCount and vCount, only usable in specific A, B, C blocks. Assign 0 if outside of blocks
	assign arrayPos = ((vCount >= AVert) && (vCount <= CVert + 10) && (hCount >= hStartPos) && (hCount <= hEndPos)) ? 
					  ((((hCount % 100) - (hCount % 10)))/10 + (10*(hCount >= 300))) : 0;
					  
	assign col = (hCount % 10);
	assign row = (vCount % 10);
	
		always@(*) 
		begin
			if(flag == 1)
				background <= 12'b1111_0000_0000; // Light red on error code
			else 
				background <= 12'b1111_1111_1111;	// White normally			
		end
	
	
	
	 /*
	 Ascii Representations of 1 and 0:
	 
	 * = fill
	 - = empty
	 
	 0: 
		----------
		---****---
	    ---****---
		-**----**-
		-**----**-
		-**----**-
		-**----**-
		---****---
		---****---
		----------
	 1:
		----------
		----**----
		----**----
		----**----
		----**----
		----**----
		----**----
		----**----
		----**----
		----------
	 
	 */


endmodule
