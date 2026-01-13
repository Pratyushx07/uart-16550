module uart_top(
  input  clk,
  input  rst,
  input  wr,
  input  rd,
  input  rx,
  input  [2:0] addr,
  input  [7:0] din,
  output tx,
  output [7:0] dout
);

  csr_t csr;

  wire baud_pulse;
  wire tx_fifo_push, tx_fifo_pop;
  wire rx_fifo_push, rx_fifo_pop;

  wire [7:0] tx_fifo_out;
  wire [7:0] rx_fifo_out;

  wire tx_rst, rx_rst;
  wire [3:0] rx_fifo_threshold;

  wire r_pe, r_fe, r_bi;

  /* Register block */
  regs_uart regs_inst (
    .clk (clk),
    .rst (rst),
    .wr_i (wr),
    .rd_i (rd),
    .rx_fifo_empty_i (),
    .rx_oe (),
    .rx_pe (r_pe),
    .rx_fe (r_fe),
    .rx_bi (r_bi),
    .addr_i (addr),
    .din_i (din),
    .rx_fifo_in (rx_fifo_out),
    .tx_push_o (tx_fifo_push),
    .rx_pop_o (rx_fifo_pop),
    .baud_out (baud_pulse),
    .tx_rst (tx_rst),
    .rx_rst (rx_rst),
    .rx_fifo_threshold (rx_fifo_threshold),
    .dout_o (dout),
    .csr_o (csr)
  );

  /* TX FIFO */
  fifo_top tx_fifo (
    .clk (clk),
    .rst (rst | tx_rst),
    .en  (csr.fcr.ena),
    .push_in (tx_fifo_push),
    .pop_in  (tx_fifo_pop),
    .din (din),
    .threshold (4'd0),
    .dout (tx_fifo_out),
    .empty (),
    .full (),
    .overrun (),
    .underrun (),
    .thre_trigger ()
  );

  /* UART TX */
  uart_tx_top tx_inst (
    .clk (clk),
    .rst (rst),
    .baud_pulse (baud_pulse),
    .pen (csr.lcr.pen),
    .thre (1'b0),
    .stb (csr.lcr.stb),
    .sticky_parity (csr.lcr.stick_parity),
    .eps (csr.lcr.eps),
    .set_break (csr.lcr.set_break),
    .din (tx_fifo_out),
    .wls (csr.lcr.wls),
    .pop (tx_fifo_pop),
    .sreg_empty (),
    .tx (tx)
  );

  /* UART RX */
  uart_rx_top rx_inst (
    .clk (clk),
    .rst (rst),
    .baud_pulse (baud_pulse),
    .rx (rx),
    .sticky_parity (csr.lcr.stick_parity),
    .eps (csr.lcr.eps),
    .pen (csr.lcr.pen),
    .wls (csr.lcr.wls),
    .push (rx_fifo_push),
    .pe (r_pe),
    .fe (r_fe),
    .bi (r_bi),
    .dout (rx_fifo_out)
  );

  /* RX FIFO */
  fifo_top rx_fifo (
    .clk (clk),
    .rst (rst | rx_rst),
    .en  (csr.fcr.ena),
    .push_in (rx_fifo_push),
    .pop_in  (rx_fifo_pop),
    .din (rx_fifo_out),
    .threshold (rx_fifo_threshold),
    .dout (),
    .empty (),
    .full (),
    .overrun (),
    .underrun (),
    .thre_trigger ()
  );

endmodule
