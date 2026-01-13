module regs_uart(
  input  clk,
  input  rst,
  input  wr_i,
  input  rd_i,
  input  rx_fifo_empty_i,
  input  rx_oe,
  input  rx_pe,
  input  rx_fe,
  input  rx_bi,
  input  [2:0] addr_i,
  input  [7:0] din_i,
  input  [7:0] rx_fifo_in,

  output tx_push_o,
  output rx_pop_o,
  output baud_out,
  output tx_rst,
  output rx_rst,
  output [3:0] rx_fifo_threshold,
  output reg [7:0] dout_o,
  output csr_t csr_o
);

  csr_t csr;
  div_t dl;

  /* TX / RX FIFO access */
  assign tx_push_o = wr_i & (addr_i == 3'b000) & ~csr.lcr.dlab;
  assign rx_pop_o  = rd_i & (addr_i == 3'b000) & ~csr.lcr.dlab;

  reg [7:0] rx_data;
  always @(posedge clk)
    if (rx_pop_o)
      rx_data <= rx_fifo_in;

  /* Baud divisor registers */
  always @(posedge clk)
    if (wr_i && csr.lcr.dlab && addr_i == 3'b000)
      dl.dlsb <= din_i;

  always @(posedge clk)
    if (wr_i && csr.lcr.dlab && addr_i == 3'b001)
      dl.dmsb <= din_i;

  reg [15:0] baud_cnt;
  reg baud_pulse;

  always @(posedge clk or posedge rst) begin
    if (rst)
      baud_cnt <= 16'd0;
    else if (baud_cnt == 0)
      baud_cnt <= dl;
    else
      baud_cnt <= baud_cnt - 1;
  end

  always @(posedge clk)
    baud_pulse <= |dl & (baud_cnt == 0);

  assign baud_out = baud_pulse;

  /* FIFO Control Register */
  always @(posedge clk or posedge rst) begin
    if (rst)
      csr.fcr <= '0;
    else if (wr_i && addr_i == 3'b010) begin
      csr.fcr.rx_trigger <= din_i[7:6];
      csr.fcr.dma_mode   <= din_i[3];
      csr.fcr.tx_rst     <= din_i[2];
      csr.fcr.rx_rst     <= din_i[1];
      csr.fcr.ena        <= din_i[0];
    end else begin
      csr.fcr.tx_rst <= 1'b0;
      csr.fcr.rx_rst <= 1'b0;
    end
  end

  assign tx_rst = csr.fcr.tx_rst;
  assign rx_rst = csr.fcr.rx_rst;

  always @(*) begin
    if (!csr.fcr.ena)
      rx_fifo_threshold = 4'd0;
    else
      case (csr.fcr.rx_trigger)
        2'b00: rx_fifo_threshold = 4'd1;
        2'b01: rx_fifo_threshold = 4'd4;
        2'b10: rx_fifo_threshold = 4'd8;
        2'b11: rx_fifo_threshold = 4'd14;
      endcase
  end

  /* Line Control Register */
  always @(posedge clk or posedge rst) begin
    if (rst)
      csr.lcr <= '0;
    else if (wr_i && addr_i == 3'b011)
      csr.lcr <= din_i;
  end

  /* Line Status Register */
  always @(posedge clk or posedge rst) begin
    if (rst)
      csr.lsr <= 8'h60;
    else begin
      csr.lsr.dr <= ~rx_fifo_empty_i;
      csr.lsr.oe <= rx_oe;
      csr.lsr.pe <= rx_pe;
      csr.lsr.fe <= rx_fe;
      csr.lsr.bi <= rx_bi;
    end
  end

  /* Scratch Register */
  always @(posedge clk or posedge rst) begin
    if (rst)
      csr.scr <= 8'd0;
    else if (wr_i && addr_i == 3'b111)
      csr.scr <= din_i;
  end

  /* Read MUX */
  always @(posedge clk) begin
    case (addr_i)
      3'b000: dout_o <= csr.lcr.dlab ? dl.dlsb : rx_data;
      3'b001: dout_o <= csr.lcr.dlab ? dl.dmsb : 8'd0;
      3'b011: dout_o <= csr.lcr;
      3'b101: dout_o <= csr.lsr;
      3'b111: dout_o <= csr.scr;
      default: dout_o <= 8'd0;
    endcase
  end

  assign csr_o = csr;

endmodule
