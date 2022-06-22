module vgaHdmi(
  // **input**
  input clock, clock50, reset,
  input switchSobel,
  input button0,

  // **output**
  output reg hsync, vsync,
  output reg dataEnable,
  output reg vgaClock,
  output [23:0] RGBchannel
);

reg [9:0]pixelH, pixelV; // estado interno de pixeles del modulo
reg [23:0]RGBchannel_reg;
reg [1:0] resContador;
reg [23:0]RGBchannel_reg_sobel;


initial begin
  hsync      = 1;
  vsync      = 1;
  pixelH     = 0;
  pixelV     = 0;
  dataEnable = 0;
  vgaClock   = 0;
  resContador= 0;
  
end

// Manejo de Pixeles y Sincronizacion

always @(posedge clock or posedge reset) begin
  if(reset) begin
    hsync  <= 1;
    vsync  <= 1;
    pixelH <= 0;
    pixelV <= 0;
  end
  else begin
    // Display Horizontal
    if(pixelH==0 && pixelV!=524) begin
      pixelH<=pixelH+1'b1;
      pixelV<=pixelV+1'b1;
    end
    else if(pixelH==0 && pixelV==524) begin
      pixelH <= pixelH + 1'b1;
      pixelV <= 0; // pixel 525
    end
    else if(pixelH<=640) pixelH <= pixelH + 1'b1;
    // Front Porch
    else if(pixelH<=656) pixelH <= pixelH + 1'b1;
    // Sync Pulse
    else if(pixelH<=752) begin
      pixelH <= pixelH + 1'b1;
      hsync  <= 0;
    end
    // Back Porch
    else if(pixelH<799) begin
      pixelH <= pixelH+1'b1;
      hsync  <= 1;
    end
    else pixelH<=0; // pixel 800

    // Manejo Senal Vertical
    // Sync Pulse
    if(pixelV == 491 || pixelV == 492)
      vsync <= 0;
    else
      vsync <= 1;
  end
end

// dataEnable signal
always @(posedge clock or posedge reset) begin
  if(reset) dataEnable<= 0;

  else begin
    if(pixelH >= 0 && pixelH <640 && pixelV >= 0 && pixelV < 480)
      dataEnable <= 1;
    else
      dataEnable <= 0;
  end
end

// VGA pixeClock signal
// Los clocks no deben manejar salidas directas, se debe usar un truco
initial vgaClock = 0;

always @(posedge clock50 or posedge reset) begin
  if(reset) vgaClock <= 0;
  else      vgaClock <= ~vgaClock;
end

// **************************************************************
// Screen colors using de10nano switches for test


//screen === 640x480
always @(posedge clock50 or negedge button0) begin
  if (!button0) begin
    resContador <= resContador+1'b1;
  end else begin
    if(resContador == 0)begin
      if(pixelH <320 && pixelV<240) begin
        RGBchannel_reg <= 24'b111111110000000000000000;
      end else if (pixelH >=320 && pixelV<240) begin
        RGBchannel_reg <= 24'b000000001111111100000000;
      end else if (pixelH <320 && pixelV>=240) begin
        RGBchannel_reg <= 24'b000000000000000011111111;
      end else begin
        RGBchannel_reg <= 24'b111111110000000011111111;
      end
    end else begin
      if (pixelH <200 && pixelV<240) begin
        RGBchannel_reg <=24'b111111111111111100000000;
      end else if (pixelH <420 && pixelV<240) begin
        RGBchannel_reg <=24'b000000001111111111111111;
      end else if(pixelH >=420 && pixelV<240) begin
        RGBchannel_reg <=24'b111111111111111111111111;
      end else if (pixelH <200 && pixelV>=240) begin
        RGBchannel_reg <=24'b000000001111111100000000;
      end else if (pixelH <400 && pixelV>=240) begin
        RGBchannel_reg <=24'b000000000000000000000000;
      end else begin
        RGBchannel_reg <=24'b111111110000000011111111;
      end



    end
  end

end




// INVOQUING SOBEL 
lane lane(
  .clk(clock50), 
  .reset_n(!reset),
  .enable_in(3'b111),
  
  .vs_in(vsync),
  .hs_in(hsync),
  .de_in(dataEnable),
  .r_in(RGBchannel_reg[23:16]),
  .g_in(RGBchannel_reg[15:8]),
  .b_in(RGBchannel_reg[7:0]),

  // .vs_out    : out std_logic;                      -- corresponding to video-in
  // .hs_out    : out std_logic;
  // .de_out    : out std_logic;
  .r_out(RGBchannel_reg_sobel[23:16]),
  .g_out(RGBchannel_reg_sobel[15:8]),
  .b_out(RGBchannel_reg_sobel[7:0]),
  
  // .clk_o     : out std_logic;                      -- output clock (do not modify)
  // .led       : out std_logic_vector(2 downto 0)
);



assign RGBchannel = (switchSobel)? RGBchannel_reg_sobel : RGBchannel_reg;










endmodule












