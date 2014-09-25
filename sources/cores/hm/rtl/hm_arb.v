/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009, 2010, 2011 Sebastien Bourdeauducq
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright (C) 2014 Benoît Morgan
 *
 */

module hm_arb5(
	input trn_clk,
	input trn_rst,
	
	input [4:0] req,
	output [2:0] gnt
);

reg [2:0] state;
reg [2:0] next_state;

assign gnt = state;

always @(posedge trn_clk) begin
	if(trn_rst)
		state <= 3'd0;
	else
		state <= next_state;
end

task init;
begin
  state <= 0;
  next_state <= 0;
end
endtask

initial begin
  init;
end

always @(*) begin
	next_state = state;
	case(state)
		3'd0: begin
			if(~req[0]) begin
				     if(req[1]) next_state = 3'd1;
				else if(req[2]) next_state = 3'd2;
				else if(req[3]) next_state = 3'd3;
				else if(req[4]) next_state = 3'd4;
			end
		end
		3'd1: begin
			if(~req[1]) begin
				     if(req[2]) next_state = 3'd2;
				else if(req[3]) next_state = 3'd3;
				else if(req[4]) next_state = 3'd4;
				else if(req[0]) next_state = 3'd0;
			end
		end
		3'd2: begin
			if(~req[2]) begin
				     if(req[3]) next_state = 3'd3;
				else if(req[4]) next_state = 3'd4;
				else if(req[0]) next_state = 3'd0;
				else if(req[1]) next_state = 3'd1;
			end
		end
		3'd3: begin
			if(~req[3]) begin
				     if(req[4]) next_state = 3'd4;
				else if(req[0]) next_state = 3'd0;
				else if(req[1]) next_state = 3'd1;
				else if(req[2]) next_state = 3'd2;
			end
		end
		3'd4: begin
			if(~req[4]) begin
				     if(req[0]) next_state = 3'd0;
				else if(req[1]) next_state = 3'd1;
				else if(req[2]) next_state = 3'd2;
				else if(req[3]) next_state = 3'd3;
			end
		end
	endcase
end

endmodule
