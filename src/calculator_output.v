`timescale 1ns / 1ps

module calculator_output(
	input clk,             // Sys clk, display_controller.v handles vga sync
	input bright,
	input rst,
	input [9:0] hCount, vCount,
	input [15:0] A, B, C,
	output reg [11:0] rgb
   );
    
    wire Ablock, Bblock, Cblock;
    
	reg block_fill;
	reg digit;
	wire [9:0] arrayPos;
	
	//these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions
	
	parameter BLK   = 12'b0000_0000_0000;			// Black
	parameter background = 12'b1111_1111_1111;		// White
	
	
	// Start positions for A, B, and C fields on VGA
	parameter AVert = 10'd100;
	parameter BVert = 10'd150;
	parameter CVert = 10'd200;
	parameter DVert = 10'd210;
	
	// Horizontal start position for each block of text
	parameter hStartPos = 10'd200;
	parameter hEndPos = 10'd360;
	
	
	
	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = 12'b0000_0000_0000;
		else if (block_fill == 1)
			rgb = BLK; 
		else	
			rgb = background;
	end
	
	
	always@(*) 
	begin: Number_Selection_From_Array
		// Select array position based on horizontal position on VGA monitor
		// Each digit location is 10x10 pixels (8x8 for digit, and 1 pixel on each side for spacing)
		
/*		// Nasty way to calculate the array position for digit.
		if ((vCount >= AVert) && (vCount <= DVert) && (hCount >= hStartPos) && (hCount <= hEndPos))
			arrayPos = ((((hCount % 100) - (hCount % 10)))/10 + (10*(hCount >= 300)));
		
		else
			arrayPos = 0;
			
*/	
		if ((vCount >= AVert) && (vCount <= BVert))
			digit = A[arrayPos];
			
		else if ((vCount >= BVert) && (vCount <= CVert))
			digit = B[arrayPos];
			
		else if ((vCount >= CVert) && (vCount <= DVert))
			digit = C[arrayPos];
		
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
			   case (hCount % 10)
			
			    10'd0:
			    	block_fill <= 0;
			
			    10'd1:
				    block_fill <= 0;
			
			    10'd2:
				    block_fill <= 0;
				
			    10'd3:
				    block_fill <= 0;
				
			    10'd4:
				    block_fill <= 1;
			
			    10'd5:
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
			    case (hCount % 10)
			
			    10'd0:
				    block_fill <= 0;
			
			    10'd1:
					if ((vCount % 10 == 3) || (vCount % 10 == 4) || (vCount % 10 == 5) || (vCount % 10 == 6))
						block_fill <= 1;
					else
						block_fill <= 0;
			
			    10'd2:
					if ((vCount % 10 == 3) || (vCount % 10 == 4) || (vCount % 10 == 5) || (vCount % 10 == 6))
						block_fill <= 1;
					else
						block_fill <= 0;
				
			    10'd3:
					if ((vCount % 10 == 3) || (vCount % 10 == 4) || (vCount % 10 == 5) || (vCount % 10 == 6))
						block_fill <= 1;
						
					else
						block_fill <= 0;
				
			    10'd4:
					if ((vCount % 10 == 3) || (vCount % 10 == 4) || (vCount % 10 == 5) || (vCount % 10 == 6))
						block_fill <= 1;
						
					else
						block_fill <= 0;
			
			    10'd5:
					if ((vCount % 10 == 3) || (vCount % 10 == 4) || (vCount % 10 == 5) || (vCount % 10 == 6))
						block_fill <= 1;
						
					else
						block_fill <= 0;
			
			    10'd6:
					if ((vCount % 10 == 3) || (vCount % 10 == 4) || (vCount % 10 == 5) || (vCount % 10 == 6))
						block_fill <= 1;
						
					else
						block_fill <= 0;
			
			    10'd7:
					if ((vCount % 10 == 3) || (vCount % 10 == 4) || (vCount % 10 == 5) || (vCount % 10 == 6))
						block_fill <= 1;
					else
						block_fill <= 0;
				
			    10'd8:
					if ((vCount % 10 == 3) || (vCount % 10 == 4) || (vCount % 10 == 5) || (vCount % 10 == 6))
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
	assign arrayPos = ((vCount >= AVert) && (vCount <= DVert) && (hCount >= hStartPos) && (hCount <= hEndPos)) ? 
					  ((((hCount % 100) - (hCount % 10)))/10 + (10*(hCount >= 300))) : 0;
	//assign col = (hCount % 10);
	//assign row = (vCount % 10);
	//assign textBlock = ((vCount >= AVert) && (vCount <= BVert) && (hCount >= 250) && (hCount <= 400));
	//assign block_fill = ((digit == 1)&&(  ) ? ((vCount % 10) ) : ( )
	
	
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
