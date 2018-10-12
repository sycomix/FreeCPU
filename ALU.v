module ALU(
	input wire [7:0] a,
	input wire [7:0] b,
	input wire [7:0] op,
	output wire [7:0] z,
	output wire [7:0] o_flags
);

/*
FLAGS:

8'bHGFEDCBA

A: Overflow
B: Underflow
C: CMP_GT
D: CMP_EQ
E: DIV_BY_0
F: UNKNWN
G: N/A
H: N/A

*/

reg [15:0] i_z;
reg [7:0] i_flg;

wire [8:0] add_out;

assign z = i_z[7:0];
assign o_flags = i_flg;

FastAdder8 fa8(.cin(), .a(a), .b(b), .out(add_out[7:0]), .cout(add_out[8]));

always @* begin
	case(op & 8'b00011111) // 5-bit instructions: 3 flag bits
		// ADD
		0: begin
			i_z <= add_out;
			i_flg <= add_out[8] ? 8'b1 : 8'b0; // Set overflow flag if necessary
		end
		
		// SUB
		1: begin
			i_z <= a-b;
			i_flg <= i_z[15] << 1;
		end
		
		// MUL
		2: begin
			i_z <= a*b;
			i_flg <= i_z[15:8] != 8'b0 ? 8'b1 : 8'b0;
		end
		
		// DIV
		3: begin
			if(b != 8'b0) begin
				i_z <= a/b;
				i_flg <= 8'b0;
			end else begin
				i_z <= 16'b0;
				i_flg <= 8'b10000;
			end
		end
		
		// CMP
		4: begin
			/*
			Flag bits:
			
			000 -> No output
			001 -> a > b
			010 -> a < b
			011 -> No output
			100 -> a == b
			101 -> a >= b
			110 -> a <= b
			111 -> No output
			
			*/
			i_z <= (op[7:5] == 3'b000) || (op[7:5] == 3'b011) || (op[7:5] == 3'b111) ? 16'b0 : (op[5] && a > b) || (op[6] && a < b ) || (op[7] && a == b) ? 16'b1 : 16'b0;
			i_flg <=
					(a > b ? 8'b100 : 8'b0) | // a > b
					(a == b ? 8'b1000 : 8'b0); // a == b
		end
		
		// AND
		5: begin
			i_z <= a & b;
			i_flg <= 8'b0;
		end
		
		// OR
		6: begin
			i_z <= a | b;
			i_flg <= 8'b0;
		end
		
		// XOR
		7: begin
			i_z <= a ^ b;
			i_flg <= 8'b0;
		end
		
		// NOT
		8: begin
			i_z <= ~a;
			i_flg <= 8'b0;
		end
		
		// NAND
		9: begin
			i_z <= ~(a & b);
			i_flg <= 8'b0;
		end
		
		// NOR
		10: begin
			i_z <= ~(a | b);
			i_flg <= 8'b0;
		end
		
		// XNOR
		11: begin
			i_z <= ~(a ^ b);
			i_flg <= 8'b0;
		end
		
		// CL_MUL
		12: begin
			i_z <=
				(a[7] ? b << 7 : 16'b0) ^
				(a[6] ? b << 6 : 16'b0) ^
				(a[5] ? b << 5 : 16'b0) ^
				(a[4] ? b << 4 : 16'b0) ^
				(a[3] ? b << 3 : 16'b0) ^
				(a[2] ? b << 2 : 16'b0) ^
				(a[1] ? b << 1 : 16'b0) ^
				(a[0] ? b 		: 16'b0);
			
			i_flg <=
				(a[7] && (b[1] || b[2] || b[3] || b[4] || b[5] || b[6] || b[7])) ||
				(a[6] && (b[2] || b[3] || b[4] || b[5] || b[6] || b[7])) ||
				(a[5] && (b[3] || b[4] || b[5] || b[6] || b[7])) ||
				(a[4] && (b[4] || b[5] || b[6] || b[7])) ||
				(a[3] && (b[5] || b[6] || b[7])) ||
				(a[2] && (b[6] || b[7])) ||
				(a[1] && b[7])
				? 8'b1 : 8'b0;
		end
		default: begin
			i_z <= 16'b0;
			i_flg <= 8'b100000; // Unknown opcode
		end
	endcase
end

endmodule
