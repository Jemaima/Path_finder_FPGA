 module define_next_pos(
	input clk,
	input reset, //сброс
	input isDirDefined,  // evaluate only if dir defined
	input [1:0] direction,  //dir 
	// 00 - down, 01 - left, 10 - up, 11 - right
	input longStep,
	input [4:0] pathWidth, // 31 max
	input video_data_valid,  // if новый пиксель
	input video_data_in,     // binary image
	output [4:0] Coordinate  // coordinate in local area
	);
	
	reg [4:0] locWidth = 5'd0;
	reg [4:0] cnt = 5'd0;
	reg [5:0] tmpCoord = 6'd0;
	
	always @(posedge clk)
	begin
		
		if (!isDirDefined) //time to find new coordinate
		begin
			cnt = 5'd0;
			tmpCoord = 6'd0;
		end
		
		else if (cnt == {pathWidth[3:0],1'b1}) // all line scanned
			tmpCoord = 6'd0;
		
		else if (video_data_valid) //sum
		begin
			cnt = cnt+1'b1;
			locWidth = locWidth+video_data_in;
			tmpCoord = tmpCoord+1'b1;
		end
	end
	assign Coordinate = 

	
	end