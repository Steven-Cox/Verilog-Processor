module processor(clk, switchIn, bus, digit0, digit1, digit2, digit3, hexButton, clk27, w, countSteps);
input clk, hexButton, clk27, w;
input [15:0]switchIn;
output [15:0]bus;
output [6:0]digit0, digit1, digit2, digit3;
output [1:0]countSteps;
wire [15:0]register0, register1, register2, register3, register4, register5, register6, register7, registerA, registerG, operationTemp;
wire [10:0]enableRegister, regXXXen, regYYYen, registerToBus;
wire [8:0]instruct;	

instructionRegister instructReg(.clk(debouncedClk), .switchIn(bus), .instruct(instruct), .countSteps(countSteps), .instructInput(instructInput));

count stepCounter(.clk(debouncedClk), .clearCount(clearCount), .countSteps(countSteps));

storageRegisters storageReg (.clk(debouncedClk), .bus(bus), .register0(register0), .register1(register1), .register2(register2), .register3(register3), .register4(register4),
							 .register5(register5), .register6(register6), .register7(register7), .registerA(registerA), .registerG(registerG), .operationTemp(operationTemp), .enableRegister(enableRegister));
							 
mux bigMux (.bus(bus), .register0(register0), .register1(register1), .register2(register2), .register3(register3), .register4(register4), .register5(register5),
			.register6(register6), .register7(register7), .registerG(registerG), .switchIn(switchIn), .registerToBus(registerToBus), .operationTemp(operationTemp));
			
controlCircuit ctrlCircuit (.instruct(instruct), .regXXXen(regXXXen), .regYYYen(regYYYen), .switchIn(switchIn), .enableRegister(enableRegister), .clearCount(clearCount), .countSteps(countSteps),
							.registerToBus(registerToBus), .instructInput(instructInput), .w(w));
							
decoderegister3to8 decode (.instruct(instruct), .regXXXen(regXXXen), .regYYYen(regYYYen));

segseven segSevDisp (.hexButton(hexButton), .switchIn(switchIn), .register0(register0), .register1(register1), .register2(register2), .register3(register3), .register4(register4),
					 .register5(register5), .register6(register6), .register7(register7), .registerA(registerA), .digit0(digit0), .digit1(digit1), .digit2(digit2), .digit3(digit3),
					.bus(bus));
					
ALU addsubUnit(.instruct(instruct), .registerA(registerA), .bus(bus), .operationTemp(operationTemp));

clockdebounce dbclock(.clk(clk), .debouncedClk(debouncedClk), .clk27(clk27));

endmodule

module instructionRegister(clk, switchIn, instruct, countSteps, instructInput);
input clk, instructInput;
input [15:0]switchIn;
input [1:0]countSteps;
output reg [8:0]instruct;

always@(posedge clk)
begin
	if(instructInput == 1)
	begin
		casex(switchIn)
			16'b000_0000_xxx_xxx_xxx: instruct <= {3'b000, switchIn[8:3]}; //load data into rx								000_0000_XXX_UUU_UUU
			16'b000_0001_xxx_xxx_xxx: instruct <= {3'b001, switchIn[8:3]}; //move ry into rx								000_0001_XXX_YYY_UUU
			16'b100_0010_xxx_xxx_xxx: instruct <= {3'b010, switchIn[8:3]}; //add rx to ry, store in rx						100_0010_XXX_YYY_UUU
			16'b100_0011_xxx_xxx_xxx: instruct <= {3'b011, switchIn[8:3]}; //subtract ry from rx, store in rx				100_0011_XXX_YYY_UUU
			16'b100_0100_xxx_xxx_xxx: instruct <= {3'b100, switchIn[8:3]}; //or bit pattern of rx and ry, store in rx		100_0100_XXX_YYY_UUU
			16'b100_0101_xxx_xxx_xxx: instruct <= {3'b101, switchIn[8:3]}; //and bit pattern of rx and ry, store in rx		100_0101_XXX_YYY_UUU
			16'b100_0110_xxx_xxx_xxx: instruct <= {3'b110, switchIn[8:3]}; //1's comp of ry, store in rx					100_0110_XXX_YYY_UUU
			16'b100_0111_xxx_xxx_xxx: instruct <= {3'b111, switchIn[8:3]}; //2's comp of ry, store in rx					100_0111_XXX_YYY_UUU
		endcase
	end
end
endmodule

module count(clk, clearCount, countSteps);
input clk, clearCount;
output reg [1:0]countSteps;

always@(posedge clk)
begin
	if(clearCount == 1)
		countSteps <= 2'b00;
	else
	begin
		countSteps <= countSteps + 2'b01;
	end
end
endmodule


module storageRegisters(clk, bus, register0, register1, register2, register3, register4, register5, register6, register7, registerA, registerG, operationTemp, enableRegister);
input clk;
input [15:0]bus, operationTemp;
input [10:0]enableRegister;
output reg [15:0]register0, register1, register2, register3, register4, register5, register6, register7, registerA, registerG;

always@(posedge clk)
begin
	case(enableRegister)
		11'b000_0000_0010: registerG <= operationTemp;
		11'b000_0000_0100: registerA <= bus;
		11'b000_0000_1000: register0 <= bus;
		11'b000_0001_0000: register1 <= bus;
		11'b000_0010_0000: register2 <= bus;
		11'b000_0100_0000: register3 <= bus;
		11'b000_1000_0000: register4 <= bus;
		11'b001_0000_0000: register5 <= bus;
		11'b010_0000_0000: register6 <= bus;
		11'b100_0000_0000: register7 <= bus;
	endcase
end
endmodule

module mux(bus, register0, register1, register2, register3, register4, register5, register6, register7, registerG, switchIn, registerToBus, operationTemp);
input [15:0]register0, register1, register2, register3, register4, register5, register6, register7, registerG, switchIn, operationTemp;
input [10:0]registerToBus;
output reg [15:0]bus;

always@(register0, register1, register2, register3, register4, register5, register6, register7, registerG, switchIn)
	begin
		case(registerToBus)
			11'b000_0000_0001: bus <= switchIn;
			11'b000_0000_0010: bus <= registerG;
			11'b000_0000_0100: bus <= operationTemp;
			11'b000_0000_1000: bus <= register0;
			11'b000_0001_0000: bus <= register1;
			11'b000_0010_0000: bus <= register2;
			11'b000_0100_0000: bus <= register3;
			11'b000_1000_0000: bus <= register4;
			11'b001_0000_0000: bus <= register5;
			11'b010_0000_0000: bus <= register6;
			11'b100_0000_0000: bus <= register7;
		endcase
	end
endmodule

module controlCircuit(instruct, regXXXen, regYYYen, switchIn, enableRegister, clearCount, countSteps, registerToBus, instructInput, w);
input w;
input [1:0]countSteps;
input [8:0]instruct;
input [10:0]regXXXen, regYYYen;
input [15:0]switchIn;
output reg [10:0]enableRegister;
output reg [10:0]registerToBus;
output reg clearCount;
output reg instructInput;

always@(countSteps, enableRegister, switchIn, w, regXXXen, regYYYen, instruct)
begin
if(w==1)
begin
	if(countSteps == 2'b00) //step 0
	begin
		enableRegister <= 11'b000_0000_0000;
		registerToBus <= 11'b000_0000_0001;
		clearCount <= 0;
		instructInput <= 1;
	end               
	
	if(countSteps == 2'b01) //step 1
	begin
		instructInput <=0;
		casex(instruct[8:6])
			3'b000: //load rx from data in
			begin
				registerToBus <= 11'b000_0000_0001;
				enableRegister <= regXXXen;
				clearCount <=1;
			end
			
			3'b001: //move ry to rx
			begin
				registerToBus <= regYYYen;
				enableRegister <= regXXXen;
				clearCount <=1;
			end
						
			3'b010: //add rx to ry
			begin
				registerToBus <= regXXXen;
				enableRegister <= 11'b000_0000_0100; 
			end
						
			3'b011: //sub ry from rx
			begin
				registerToBus <= regXXXen;
				enableRegister <= 11'b000_0000_0100; 
			end
						
			3'b100: //logical or
			begin
				registerToBus <= regXXXen;
				enableRegister <= 11'b000_0000_0100; 
			end
						
			3'b101: //logical and
			begin
				registerToBus <= regXXXen;
				enableRegister <= 11'b000_0000_0100; 
			end
						
			3'b110: // 1's comp
			begin
				registerToBus <= regYYYen;
				enableRegister <= 11'b000_0000_0100; 
			end
						
			3'b111: // 2's comp
			begin
				registerToBus <= regYYYen;
				enableRegister <= 11'b000_0000_0100; 
			end

		endcase
	end 						
			

if(countSteps == 2'b10) //step 2
begin
	instructInput <=0;
	casex(instruct[8:6])
		3'b010: //load rx from data in
		begin
			registerToBus <= regYYYen;
			enableRegister <= 11'b000_0000_0010;
		end
					
		3'b011: //move ry to rx
		begin
			registerToBus <= regYYYen;
			enableRegister <= 11'b000_0000_0010;
		end

		3'b100: //add rx to ry
		begin
			registerToBus <= regYYYen;
			enableRegister <= 11'b000_0000_0010; 
		end
					
		3'b101: //sub ry from rx
		begin
			registerToBus <= regYYYen;
			enableRegister <= 11'b000_0000_0010; 
		end
					
		3'b110:  // 1's comp
		begin
			registerToBus <= 11'b000_0000_0100;
			enableRegister <= regXXXen; 
			clearCount <= 1;
		end
					
		3'b111: // 2's comp
		begin
			registerToBus <= 11'b000_0000_0100;
			enableRegister <= regXXXen; 
			clearCount <= 1;
		end
	endcase
end
                                                                    

if(countSteps == 2'b11) //step 3
begin
	instructInput <=0;
	casex(instruct[8:6])
		3'b010: //add rx to ry
		begin
			registerToBus <= 11'b000_0000_0010;
			enableRegister <= regXXXen; 
			clearCount <=1;
		end
					
		3'b011: //sub ry from rx
		begin
			registerToBus <= 11'b000_0000_0010;
			enableRegister <= regXXXen; 
			clearCount <=1;
		end

		3'b100: //logical or
		begin
			registerToBus <= 11'b000_0000_0010;
			enableRegister <= regXXXen; 
			clearCount <=1;
		end
					
		3'b101: //logical and
		begin
			registerToBus <= 11'b000_0000_0010;
			enableRegister <= regXXXen; 
			clearCount <=1;
		end
	endcase
end                                             
end

else
begin
	enableRegister <= 11'b000_0000_0000;
	registerToBus <= 11'b000_0000_0000;
	clearCount <= 1;
	instructInput <= 0;
end
end				
endmodule


module decoderegister3to8(instruct, regXXXen, regYYYen);
input [8:0]instruct;
output reg [10:0]regXXXen, regYYYen;

always@(instruct)
begin
	case(instruct[5:3])
		3'b000: regXXXen <= 11'b000_0000_1000; //register0
		3'b001: regXXXen <= 11'b000_0001_0000; //register1
		3'b010: regXXXen <= 11'b000_0010_0000; //register2
		3'b011: regXXXen <= 11'b000_0100_0000; //register3
		3'b100: regXXXen <= 11'b000_1000_0000; //register4
		3'b101: regXXXen <= 11'b001_0000_0000; //register5
		3'b110: regXXXen <= 11'b010_0000_0000; //register6
		3'b111: regXXXen <= 11'b100_0000_0000; //register7
	endcase
	case(instruct[2:0])
		3'b000: regYYYen <= 11'b000_0000_1000; //register0
		3'b001: regYYYen <= 11'b000_0001_0000; //register1
		3'b010: regYYYen <= 11'b000_0010_0000; //register2
		3'b011: regYYYen <= 11'b000_0100_0000; //register3
		3'b100: regYYYen <= 11'b000_1000_0000; //register4
		3'b101: regYYYen <= 11'b001_0000_0000; //register5
		3'b110: regYYYen <= 11'b010_0000_0000; //register6
		3'b111: regYYYen <= 11'b100_0000_0000; //register7
	endcase
end
endmodule


module segseven(hexButton, switchIn, register0, register1, register2, register3, register4, register5, register6, register7, registerA, digit0, digit1, digit2, digit3, bus);
input hexButton;
input [15:0]register0, register1, register2, register3, register4, register5, register6, register7, registerA, bus, switchIn;
output reg [6:0]digit0, digit1, digit2, digit3;
reg [15:0]valueOut;

always@(hexButton)
begin
	if(hexButton == 0)
	case(switchIn[2:0])
		3'b000: valueOut <= register0;
		3'b001: valueOut <= register1;
		3'b010: valueOut <= register2;
		3'b011: valueOut <= register3;
		3'b100: valueOut <= register4;
		3'b101: valueOut <= register5;
		3'b110: valueOut <= register6;
		3'b111: valueOut <= register7;
	endcase
	else if(hexButton == 1)
		valueOut <= bus;

	case(valueOut[3:0])
		4'b0000: digit0 <= 7'b000_0001;
		4'b0001: digit0 <= 7'b100_1111;
		4'b0010: digit0 <= 7'b001_0010;
		4'b0011: digit0 <= 7'b000_0110;
		4'b0100: digit0 <= 7'b100_1100;
		4'b0101: digit0 <= 7'b010_0100;
		4'b0110: digit0 <= 7'b010_0000;
		4'b0111: digit0 <= 7'b000_1111;
		4'b1000: digit0 <= 7'b000_0000;
		4'b1001: digit0 <= 7'b000_0100;
		4'b1010: digit0 <= 7'b000_1000;
		4'b1011: digit0 <= 7'b110_0000;
		4'b1100: digit0 <= 7'b111_0010;
		4'b1101: digit0 <= 7'b100_0010;
		4'b1110: digit0 <= 7'b011_0000;
		4'b1111: digit0 <= 7'b011_1000;
	endcase
	case(valueOut[7:4])
		4'b0000: digit1 <= 7'b000_0001;
		4'b0001: digit1 <= 7'b100_1111;
		4'b0010: digit1 <= 7'b001_0010;
		4'b0011: digit1 <= 7'b000_0110;
		4'b0100: digit1 <= 7'b100_1100;
		4'b0101: digit1 <= 7'b010_0100;
		4'b0110: digit1 <= 7'b010_0000;
		4'b0111: digit1 <= 7'b000_1111;
		4'b1000: digit1 <= 7'b000_0000;
		4'b1001: digit1 <= 7'b000_0100;
		4'b1010: digit1 <= 7'b000_1000;
		4'b1011: digit1 <= 7'b110_0000;
		4'b1100: digit1 <= 7'b111_0010;
		4'b1101: digit1 <= 7'b100_0010;
		4'b1110: digit1 <= 7'b011_0000;
		4'b1111: digit1 <= 7'b011_1000;
	endcase
	case(valueOut[11:8])
		4'b0000: digit2 <= 7'b000_0001;
		4'b0001: digit2 <= 7'b100_1111;
		4'b0010: digit2 <= 7'b001_0010;
		4'b0011: digit2 <= 7'b000_0110;
		4'b0100: digit2 <= 7'b100_1100;
		4'b0101: digit2 <= 7'b010_0100;
		4'b0110: digit2 <= 7'b010_0000;
		4'b0111: digit2 <= 7'b000_1111;
		4'b1000: digit2 <= 7'b000_0000;
		4'b1001: digit2 <= 7'b000_0100;
		4'b1010: digit2 <= 7'b000_1000;
		4'b1011: digit2 <= 7'b110_0000;
		4'b1100: digit2 <= 7'b111_0010;
		4'b1101: digit2 <= 7'b100_0010;
		4'b1110: digit2 <= 7'b011_0000;
		4'b1111: digit2 <= 7'b011_1000;
	endcase
	case(valueOut[15:12])
		4'b0000: digit3 <= 7'b000_0001;
		4'b0001: digit3 <= 7'b100_1111;
		4'b0010: digit3 <= 7'b001_0010;
		4'b0011: digit3 <= 7'b000_0110;
		4'b0100: digit3 <= 7'b100_1100;
		4'b0101: digit3 <= 7'b010_0100;
		4'b0110: digit3 <= 7'b010_0000;
		4'b0111: digit3 <= 7'b000_1111;
		4'b1000: digit3 <= 7'b000_0000;
		4'b1001: digit3 <= 7'b000_0100;
		4'b1010: digit3 <= 7'b000_1000;
		4'b1011: digit3 <= 7'b110_0000;
		4'b1100: digit3 <= 7'b111_0010;
		4'b1101: digit3 <= 7'b100_0010;
		4'b1110: digit3 <= 7'b011_0000;
		4'b1111: digit3 <= 7'b011_1000;
	endcase
end
endmodule


module ALU(instruct, registerA, bus, operationTemp);
input [15:0]registerA, bus;
input [8:0]instruct;
output reg [15:0]operationTemp;

always@(registerA, bus, instruct)
begin
	if(instruct[8:6] == 3'b010) // Add 
		operationTemp <= registerA + bus;

	else if (instruct[8:6] == 3'b011) // Sub
		operationTemp <= registerA - bus;
		
	else if(instruct[8:6] == 3'b100) // logical or
		operationTemp <= (registerA | bus);

	else if (instruct[8:6] == 3'b101) // logical and
		operationTemp <= (registerA & bus);
		
	else if(instruct[8:6] == 3'b110) // 1's comp
		operationTemp <= ~registerA;

	else if (instruct[8:6] == 3'b111) // 2's comp
		operationTemp <= ~registerA + 1;
end
endmodule


module clockdebounce(clk, debouncedClk, clk27);
input clk, clk27;
output reg debouncedClk;
reg [15:0] clockCount;

always@(posedge clk27)
if(clk==0)
begin
	if(clockCount != 16'b1111_1111_1111_1111)
		begin
			clockCount<= clockCount+1;
			debouncedClk <=0;
		end
				
	else if(clockCount ==16'b1111_1111_1111_1111)
		begin	
			debouncedClk <=1;
		end
end
else if(clk==1)
begin
	debouncedClk <=0;
	clockCount <= 16'b0000_0000_0000_0000;
end
	
endmodule

