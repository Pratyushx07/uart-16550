module fifo_top(
  input  clk,
  input  rst,
  input  en,
  input  push_in,
  input  pop_in,
  input  [7:0] din,
  input  [3:0] threshold,
  output [7:0] dout,
  output empty,
  output full,
  output overrun,
  output underrun,
  output thre_trigger
);

  reg [7:0] mem [0:15];
  reg [3:0] waddr;

  reg empty_t, full_t;
  reg overrun_t, underrun_t;
  reg thre_t;

  wire push = push_in & ~full_t;
  wire pop  = pop_in  & ~empty_t;

  assign dout = mem[0];

  always @(posedge clk or posedge rst) begin
    if (rst)
      waddr <= 4'd0;
    else begin
      case ({push, pop})
        2'b10: if (!full_t)  waddr <= waddr + 1;
        2'b01: if (!empty_t) waddr <= waddr - 1;
      endcase
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst)
      empty_t <= 1'b1;
    else begin
      case ({push, pop})
        2'b10: empty_t <= 1'b0;
        2'b01: empty_t <= (waddr == 1);
      endcase
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst)
      full_t <= 1'b0;
    else begin
      case ({push, pop})
        2'b10: full_t <= (waddr == 4'd15);
        2'b01: full_t <= 1'b0;
      endcase
    end
  end

  always @(posedge clk) begin
    case ({push, pop})
      2'b01: begin
        for (int i = 0; i < 15; i++)
          mem[i] <= mem[i+1];
        mem[15] <= 8'd0;
      end
      2'b10: mem[waddr] <= din;
      2'b11: begin
        for (int i = 0; i < 15; i++)
          mem[i] <= mem[i+1];
        mem[15] <= 8'd0;
        mem[waddr-1] <= din;
      end
    endcase
  end

  always @(posedge clk or posedge rst)
    if (rst)
      underrun_t <= 1'b0;
    else
      underrun_t <= pop_in & empty_t;

  always @(posedge clk or posedge rst)
    if (rst)
      overrun_t <= 1'b0;
    else
      overrun_t <= push_in & full_t;

  always @(posedge clk or posedge rst)
    if (rst)
      thre_t <= 1'b0;
    else
      thre_t <= (waddr >= threshold);

  assign empty        = empty_t;
  assign full         = full_t;
  assign overrun      = overrun_t;
  assign underrun     = underrun_t;
  assign thre_trigger = thre_t;

endmodule
