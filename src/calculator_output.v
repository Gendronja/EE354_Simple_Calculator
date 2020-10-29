`timescale 1ns / 1ps

module calculator_output(
	input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input bright,
	input rst,
	input up, input down, input left, input right,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [11:0] background
   );
	wire block_fill;
	wire arrayPos;
	
	reg digit;
	
	//these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions
	
	parameter BLK   = 12'b0000_0000_0000;			// Black
	parameter background = 12'b1111_1111_1111;		// White
	
	
	// Start positions for A, B, and ANS fields on VGA
	parameter AHoriz = 10'd250;
	parameter AVert = 10'd100;
	parameter BHoriz = 10'd250;
	parameter BVert = 10'd200;
	parameter CHoriz = 10'd250;
	parameter CVert = 10'd300;
	
	// Horizontal start positions for each digit
	parameter hPos1 = 10'd250;
	parameter hPos2 = 10'd260;
	parameter hPos3 = 10'd270;
	parameter hPos4 = 10'd280;
	parameter hPos5 = 10'd290;
	parameter hPos6 = 10'd300;
	parameter hPos7 = 10'd310;
	parameter hPos8 = 10'd320;
	parameter hPos9 = 10'd330;
	parameter hPos10 = 10'd340;
	parameter hPos11 = 10'd350;
	parameter hPos12 = 10'd360;
	parameter hPos13 = 10'd370;
	parameter hPos14 = 10'd380;
	parameter hPos15 = 10'd390;
	parameter hPos16 = 10'd400;
	
	
	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = 12'b0000_0000_0000;
		else if (Ablock_fill||Bblock_fill||ANSblock_fill) 
			rgb = BLK; 
		else	
			rgb=background;
	end
	
	
	always@(*) begin
		// Select array position based on horizontal position on VGA monitor
		// Each digit location is 10x10 pixels (8x8 for digit, and 1 pixel on each side for spacing)
		if((hCount>=hPos1) && (hCount<=hPos2))
			arrayPos = 0;
		else if((hCount>=hPos2) && (hCount<=hPos3))
			arrayPos = 1;	
		else if((hCount>=hPos3) && (hCount<=hPos4))
			arrayPos = 2;	
		else if((hCount>=hPos4) && (hCount<=hPos5))
			arrayPos = 3;
		else if((hCount>=hPos5) && (hCount<=hPos6))
			arrayPos = 4;
		else if((hCount>=hPos6) && (hCount<=hPos7))
			arrayPos = 5;
		else if((hCount>=hPos7) && (hCount<=hPos8))
			arrayPos = 6;
		else if((hCount>=hPos8) && (hCount<=hPos9))
			arrayPos = 7;
		else if((hCount>=hPos9) && (hCount<=hPos10))
			arrayPos = 8;
		else if((hCount>=hPos10) && (hCount<=hPos11))
			arrayPos = 9;
		else if((hCount>=hPos11) && (hCount<=hPos12))
			arrayPos = 10;
		else if((hCount>=hPos12) && (hCount<=hPos13))
			arrayPos = 11;
		else if((hCount>=hPos13) && (hCount<=hPos14))
			arrayPos = 12;
		else if((hCount>=hPos14) && (hCount<=hPos15))
			arrayPos = 13;
		else if((hCount>=hPos15) && (hCount<=hPos16))
			arrayPos = 14;	
		else if((hCount>=hPos16) && (hCount<=hPos16 + 10))
			arrayPos = 15;
		else
			arrayPos = 0;
	
		if ((vCount >= AVert) && (vCount <= BVert))
			digit <= A[arrayPos];
			
		else if ((vCount >= BVert) && (vCount <= ANSVert))
			digit <= B[arrayPos];
			
		else if ((vCount >= ANSVert) && (vCount <= ANSVert + 100))
			digit <= C[arrayPos];
	
		//the +-5 for the positions give the dimension of the block (i.e. it will be 10x10 pixels)
	//assign block_fill=vCount>=(ypos-5) && vCount<=(ypos+5) && hCount>=(xpos-5) && hCount<=(xpos+5);
	
	// Number output OFL
	assign Ablock_fill = (hCount >= AHoriz) && (hCount <= (AHoriz + 100)) && (vCount >= (AVert + 5)) && (vCount <= AVert - 5);
	assign Bblock_fill = (hCount >= BHoriz) && (hCount <= (BHoriz + 100)) && (vCount >= (BVert + 5)) && (vCount <= BVert - 5);
	assign ANSblock_fill = (hCount >= CHoriz) && (hCount <= (CHoriz+100)) && (vCount >= (CVert+5)) && (vCount <= CVert - 5);
	
	/*
	always@(posedge clk, posedge rst) 
	begin
		if(rst)
		begin 
			//rough values for center of screen
			xpos<=450;
			ypos<=250;
		end
		else if (clk) begin
		
		 Note that the top left of the screen does NOT correlate to vCount=0 and hCount=0. The display_controller.v file has the 
			synchronizing pulses for both the horizontal sync and the vertical sync begin at vcount=0 and hcount=0. Recall that after 
			the length of the pulse, there is also a short period called the back porch before the display area begins. So effectively, 
			the top left corner corresponds to (hcount,vcount)~(144,35). Which means with a 640x480 resolution, the bottom right corner 
			corresponds to ~(783,515).  
		
			if(right) begin
				xpos<=xpos+2; //change the amount you increment to make the speed faster 
				if(xpos==800) //these are rough values to attempt looping around, you can fine-tune them to make it more accurate- refer to the block comment above
					xpos<=150;
			end
			else if(left) begin
				xpos<=xpos-2;
				if(xpos==150)
					xpos<=800;
			end
			else if(up) begin
				ypos<=ypos-2;
				if(ypos==34)
					ypos<=514;
			end
			else if(down) begin
				ypos<=ypos+2;
				if(ypos==514)
					ypos<=34;
			end
		end
	end
	*/
	
	//the background color reflects the most recent button press
/*
	always@(posedge clk, posedge rst) begin
		if(rst)
			background <= 12'b1111_1111_1111;
		else 
			if(right)
				background <= 12'b1111_1111_0000;		// Purple?
			else if(left)
				background <= 12'b0000_1111_1111;		// Teal?
			else if(down)
				background <= 12'b0000_1111_0000;		// Blue
			else if(up)
				background <= 12'b0000_0000_1111;		// Green
	end
*/
	
	
endmodule
