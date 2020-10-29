// --------------------------------
// Simple Calculator
// Jason Yik, Haoda Wang, Jason Gendron
// EE 354
// --------------------------------

module simple_calculator(In, Clk, Reset, Done, SCEN, ButU, ButD, ButL, ButR, C, Flag, QI, QGet_A, QGet_B, QGet_Op, QAdd, QSub, QMul, QDiv, QErr, QDone);

input [15:0] In;
input Clk, Reset;
output Done;
input SCEN; //used as confirm
input ButU, ButD, ButL, ButR;
output [15:0] C;
output Flag; //set to 1 if overflow
output QI, QGet_A, QGet_B, QGet_Op, QAdd, QSub, QMul, QDiv, QErr, QDone;


reg [15:0] C; //remainder is dropped for division (could use this)
reg [15:0] A, B;
reg [9:0] state;

assign {QI, QGet_A, QGet_B, QGet_Op, QAdd, QSub, QMul, QDiv, QErr, QDone} = state;

localparam
INITIAL = 10'b0000000001;
GET_A   = 10'b0000000010;
GET_B   = 10'b0000000100;
GET_OP  = 10'b0000001000;
ADD     = 10'b0000010000;
SUB     = 10'b0000100000;
MUL     = 10'b0001000000;
DIV     = 10'b0010000000;
ERR     = 10'b0100000000;
DONE    = 10'b1000000000;

always @ (posedge Clk, posedge Reset) 
begin: CU_and_DU
	if(Reset)
		begin
		state <= INITIAL;
		A = 16'bXXXX_XXXX_XXXX_XXXX;
		B = 16'bXXXX_XXXX_XXXX_XXXX;
		C = 16'bXXXX_XXXX_XXXX_XXXX;
		end
	else
		begin
		(* full_case, parallel_case *)
		case(state)
			INITIAL: //press confirm to begin
				begin
				//state transitions
				if(SCEN) state <= GET_A;

				//data path
				Flag <= 0;

				end
			GET_A:
				begin
				//state transitions
				if(SCEN) state <= GET_B;

				//data path
				A <= In;

				end
			GET_B:
				begin
				//state transitions
				if(SCEN) state <= GET_OP;

				//data path
				B <= In;

				end
			GET_OP:
				begin
				//state transitions

				//data path

				end
			ADD:
				begin
				//state transitions

				//data path

				end
			SUB:
				begin
				//state transitions

				//data path

				end
			MUL:
				begin
				//state transitions

				//data path

				end
			DIV:
				begin
				//state transitions

				//data path

				end
			ERR:
				begin
				//state transitions

				//data path

				end
			DONE:
				begin
				//state transitions

				//data path

				end
		end

end