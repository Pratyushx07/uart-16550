module uart_tx_top(
  input  clk,
  input  rst,
  input  baud_pulse,
  input  pen,
  input  thre,
  input  stb,
  input  sticky_parity,
  input  eps,
  input  set_break,
  input  [7:0] din,
  input  [1:0] wls,
  output reg pop,
  output reg sreg_empty,
  output reg tx
);

  typedef enum logic [1:0] {IDLE, START, SEND, PARITY} state_t;
  state_t state;

  reg [7:0] shft_reg;
  reg tx_data;
  reg d_parity;
  reg [2:0] bitcnt;
  reg [4:0] count;
  reg parity_out;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state       <= IDLE;
      count       <= 5'd15;
      bitcnt      <= 3'd0;
      shft_reg    <= 8'd0;
      pop         <= 1'b0;
      sreg_empty  <= 1'b0;
      tx_data     <= 1'b1;
    end else if (baud_pulse) begin
      case (state)
        IDLE: begin
          if (!thre) begin
            if (count != 0)
              count <= count - 1;
            else begin
              count    <= 5'd15;
              state    <= START;
              bitcnt   <= {1'b1, wls};
              pop      <= 1'b1;
              shft_reg <= din;
              tx_data  <= 1'b0;
            end
          end
        end

        START: begin
          if (count != 0)
            count <= count - 1;
          else begin
            count <= 5'd15;
            state <= SEND;
            case (wls)
              2'b00: d_parity <= ^shft_reg[4:0];
              2'b01: d_parity <= ^shft_reg[5:0];
              2'b10: d_parity <= ^shft_reg[6:0];
              2'b11: d_parity <= ^shft_reg[7:0];
            endcase
            tx_data  <= shft_reg[0];
            shft_reg <= shft_reg >> 1;
            pop      <= 1'b0;
          end
        end

        SEND: begin
          case ({sticky_parity, eps})
            2'b00: parity_out <= ~d_parity;
            2'b01: parity_out <= d_parity;
            2'b10: parity_out <= 1'b1;
            2'b11: parity_out <= 1'b0;
          endcase

          if (bitcnt != 0) begin
            if (count != 0)
              count <= count - 1;
            else begin
              count   <= 5'd15;
              bitcnt  <= bitcnt - 1;
              tx_data <= shft_reg[0];
              shft_reg <= shft_reg >> 1;
            end
          end else begin
            if (count != 0)
              count <= count - 1;
            else begin
              sreg_empty <= 1'b1;
              if (pen) begin
                state   <= PARITY;
                count   <= 5'd15;
                tx_data <= parity_out;
              end else begin
                tx_data <= 1'b1;
                count   <= (stb == 0) ? 5'd15 :
                           (wls == 2'b00) ? 5'd23 : 5'd31;
                state <= IDLE;
              end
            end
          end
        end

        PARITY: begin
          if (count != 0)
            count <= count - 1;
          else begin
            tx_data <= 1'b1;
            count   <= (stb == 0) ? 5'd15 :
                       (wls == 2'b00) ? 5'd17 : 5'd31;
            state <= IDLE;
          end
        end
      endcase
    end
  end

  always @(posedge clk or posedge rst)
    if (rst)
      tx <= 1'b1;
    else
      tx <= tx_data & ~set_break;

endmodule
