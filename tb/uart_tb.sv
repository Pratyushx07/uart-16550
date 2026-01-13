module uart_tb;

  reg clk;
  reg rst;
  reg wr;
  reg rd;
  reg rx;
  reg [2:0] addr;
  reg [7:0] din;

  wire tx;
  wire [7:0] dout;

  uart_top dut (
    .clk  (clk),
    .rst  (rst),
    .wr   (wr),
    .rd   (rd),
    .rx   (rx),
    .addr (addr),
    .din  (din),
    .tx   (tx),
    .dout (dout)
  );

  initial begin
    clk  = 0;
    rst  = 0;
    wr   = 0;
    rd   = 0;
    addr = 0;
    din  = 0;
    rx   = 1;
  end

  always #5 clk = ~clk;

  initial begin
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

    @(negedge clk);
    wr   = 1;
    addr = 3'h3;
    din  = 8'b1000_0000;   // DLAB = 1

    @(negedge clk);
    addr = 3'h0;
    din  = 8'b0000_1000;   // Divisor LSB

    @(negedge clk);
    addr = 3'h1;
    din  = 8'b0000_0001;   // Divisor MSB

    @(negedge clk);
    addr = 3'h3;
    din  = 8'b0000_1100;   // 5-bit, parity enable, odd parity

    @(negedge clk);
    addr = 3'h0;
    din  = 8'b1111_0000;   // TX data

    @(negedge clk);
    wr = 0;

    @(posedge dut.tx_inst.sreg_empty);
    repeat (48) @(posedge dut.regs_inst.baud_out);

    $stop;
  end

endmodule
