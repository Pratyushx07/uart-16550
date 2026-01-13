module uart_rx_top(
  input  clk,
  input  rst,
  input  baud_pulse,
  input  rx,
  input  sticky_parity,
  input  eps,
  input  pen,
  input  [1:0] wls,
  output reg push,
  output reg pe,
  output reg fe,
  output reg bi,
  output reg [7:0] dout
);

  typedef enum logic [2:0] {IDLE, START, READ, PARITY, STOP} state_t;
  state_t state;

  reg rx_d;
  wire fall_edge;

  reg [2:0] bitcnt;
  reg [4:0] count;
  reg pe_reg;

  always @(posedge clk)
    rx_d <= rx;

  assign fall_edge = rx_d & ~rx;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state  <= IDLE;
      push   <= 1'b0;
      pe     <= 1'b0;
      fe     <= 1'b0;
      bi     <= 1'b0;
      bitcnt <= 3'd0;
      count  <= 5'd0;
    end else begin
      push <= 1'b0;

      if (baud_pulse) begin
        case (state)

          IDLE: begin
            if (fall_edge) begin
              state <= START;
              count <= 5'd15;
            end
          end

          START: begin
            count <= count - 1;
            if (count == 5'd7) begin
              if (rx)
                state <= IDLE;
            end else if (count == 0) begin
              state  <= READ;
              count  <= 5'd15;
              bitcnt <= {1'b1, wls};
            end
          end

          READ: begin
            count <= count - 1;
            if (count == 5'd7) begin
              case (wls)
                2'b00: dout <= {3'b000, rx, dout[4:1]};
                2'b01: dout <= {2'b00,  rx, dout[5:1]};
                2'b10: dout <= {1'b0,   rx, dout[6:1]};
                2'b11: dout <= {         rx, dout[7:1]};
              endcase
            end else if (count == 0) begin
              if (bitcnt == 0) begin
                case ({sticky_parity, eps})
                  2'b00: pe_reg <= ~^{rx, dout};
                  2'b01: pe_reg <=  ^{rx, dout};
                  2'b10: pe_reg <= ~rx;
                  2'b11: pe_reg <=  rx;
                endcase

                if (pen) begin
                  state <= PARITY;
                  count <= 5'd15;
                end else begin
                  state <= STOP;
                  count <= 5'd15;
                end
              end else begin
                bitcnt <= bitcnt - 1;
                count  <= 5'd15;
              end
            end
          end

          PARITY: begin
            count <= count - 1;
            if (count == 5'd7)
              pe <= pe_reg;
            else if (count == 0) begin
              state <= STOP;
              count <= 5'd15;
            end
          end

          STOP: begin
            count <= count - 1;
            if (cou
