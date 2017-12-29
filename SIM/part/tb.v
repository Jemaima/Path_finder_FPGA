`timescale 1ns / 1ps

module tb;

	// Inputs
	reg clk_108_mhz;
	reg [1:0] mode;
	reg video_frame_valid;
	reg video_line_valid;
	reg video_data_valid;
	reg [7:0] video_data_in;
	reg [19:0] video_address;

	// Outputs
	wire video_data_ready;
	wire [7:0] video_data_out;
	parameter nShots = 10;

	// Instantiate the Unit Under Test (UUT)
	student_block uut (
		.clk(clk_108_mhz),
		.mode(mode),
		.video_frame_valid(video_frame_valid), 
		.video_line_valid(video_line_valid), 
		.video_data_valid(video_data_valid), 
		.video_data_in(video_data_in), 
		.video_address(video_address), 
		.video_data_ready(video_data_ready), 
		.video_data_out(video_data_out)
	);

	integer i, j, r, c, f;
	integer outfile; 
	
	reg [7:0] frame [702*576-1:0];

	initial begin
		clk_108_mhz = 1'b0;
		forever #5 clk_108_mhz = ~clk_108_mhz; 
	end

	initial begin
		mode = 2'b01;
	end
	
	initial begin
		video_frame_valid = 0;
		#996;
		repeat (nShots*2) begin
			video_frame_valid = 1;
			#25920000 video_frame_valid = 0;
			#1000000;
		end
		#10000 $stop;
	end

	initial begin
		video_line_valid = 0;
		#996;
		repeat (nShots*2) begin       // ??? string 93*2
			repeat (288) begin
				#15000;
				video_line_valid = 1;
				#56160 video_line_valid = 0;
				#18840;
			end
			#1000000;
		end
	end

	initial begin
		video_data_valid = 0;
		#996;
		repeat (nShots*2) begin       // ??? string 93*2
			repeat (288) begin
				#15000;
				repeat (702) begin
					#20;
					video_data_valid = 1;
					#10 video_data_valid = 0;
					#50;
				end
				#18840;
			end
			#1000000;
		end
	end

	initial begin
		$readmemh("TestData.dat", frame); 
		video_data_in = 8'd0;
		#996;
		
		repeat (nShots) begin 
		i = 0;
			repeat (2) begin       // ???
				
				repeat (288) begin
					#15000;
					repeat (702) begin
						#20;
						video_data_in = frame[i];
						#60;
						i = i + 1;
					end
					#18840;
				end
				#1000000;
			end
		end
	end

	initial begin
		video_address = 20'd0;
		#996;
		repeat (nShots) begin
			f = 0;
			repeat (2) begin
				r = 0;
				repeat (288) begin
					#15000;
					c = 0;
					repeat (702) begin
						#20;
						video_address = {r[8:0],f[0],c[9:0]};
						#60;
						c = c + 1;
					end
					#18840;
					r = r + 1;
				end
				#1000000;
				f = 1;
			end
		end
	end
 
	initial begin
		outfile = $fopen("ProcData.dat", "w");
		j = 0;
		#996;
		while (j < 702*576*nShots) begin   // 702*576*2????
			@(posedge clk_108_mhz);
			if (video_data_ready)
			begin
				$fwrite(outfile, "%d\n", video_data_out);
				j = j + 1;
			end
			#8;
		end
		$fclose(outfile);
	end
 
endmodule

