// --------------------------------
// Simple Calculator
// Jason Yik, Haoda Wang, Jason Gendron
// EE 354
// --------------------------------

module simple_calculator(In, Clk, Reset, Done, SCEN, ButU, ButD, ButL, ButR, A, B, C, Flag, QI, QGet_A, QGet_B, QGet_Op, QAdd, QSub, QMul, QDiv, QErr, QDone);

input [15:0] In;
input Clk, Reset;
output Done;
input SCEN; //used as confirm
input ButU, ButD, ButL, ButR;
output [15:0] A, B;
output [16:0] C;
output Flag; //set to 1 if overflow in addition / multiplication / subtraction
output QI, QGet_A, QGet_B, QGet_Op, QAdd, QSub, QMul, QDiv, QErr, QDone;


reg [16:0] C; //remainder is dropped for division (could use this), C is one bit wider to check for overflow
reg [15:0] A, B;
reg [9:0] state;

reg [15:0] temp; //to use for multiply / divide
reg Flag;

assign {QI, QGet_A, QGet_B, QGet_Op, QAdd, QSub, QMul, QDiv, QErr, QDone} = state;

localparam
INITIAL = 10'b0000000001,
GET_A   = 10'b0000000010,
GET_B   = 10'b0000000100,
GET_OP  = 10'b0000001000,
ADD     = 10'b0000010000,
SUB     = 10'b0000100000,
MUL     = 10'b0001000000,
DIV     = 10'b0010000000,
ERR     = 10'b0100000000,
DONE    = 10'b1000000000;

always @ (posedge Clk, posedge Reset) 
begin: CU_and_DU
	if(Reset)
		begin
		state <= INITIAL;
		A = 16'bXXXX_XXXX_XXXX_XXXX;
		B = 16'bXXXX_XXXX_XXXX_XXXX;
		C = 17'bX_XXXX_XXXX_XXXX_XXXX;
		temp = 16'bXXXX_XXXX_XXXX_XXXX;
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
				if(ButU) state <= MUL;
				if(ButD && B != 0) state <= DIV;
				if(ButD && B == 0) state <= ERR;
				if(ButR) state <= ADD;
				if(ButL) state <= SUB;

				//data path
				C <= 0;
				temp <= A; //for use in multiplication or division only

				end
			ADD:
				begin
				//state transitions
				state <= DONE; //set overflow in done state

				//data path
				C <= A + B;

				end
			SUB:
				begin
				//state transitions
				state <= DONE;

				//data path
				C <= A - B;
				if(A < B) Flag <= 1; //overflow

				end
			MUL: //TODO: repetitive addition, need more registers / variables
				begin
				//state transitions
				if(temp == 16'b0000_0000_0000_0001) state <= DONE;

				//data path
				C <= C + B;
				temp <= temp - 1;

				if(C[16] == 1) Flag <= 1; //overflow

				end
			DIV:
				begin
				//state transitions
				if(temp <= B) state <= DONE;

				//data path
				temp <= temp - B;
				if(temp > B) C <= C + 1;
				if(temp < B) Flag <= 1; //overflow not possible, so this means not divisible

				end
			ERR:
				begin
				//state transitions
				if(SCEN) state <= INITIAL;

				end
			DONE:
				begin
				//state transitions
				if(SCEN) state <= INITIAL;

				//data path
				if(C[16] == 1) Flag <= 1; //for addition case

				end
			endcase
		end

end

endmodule