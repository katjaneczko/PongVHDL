----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:     
-- Design Name: 
-- Module Name:    
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity vga_driver is
    Port ( 	
				CLK : in  STD_LOGIC;
				RST : in  STD_LOGIC;
				BTN_W : in STD_LOGIC;
				BTN_N : in STD_LOGIC;
				BTN_S : in STD_LOGIC;
				BTN_E : in STD_LOGIC;
				HSYNC : out  STD_LOGIC;
				VSYNC : out  STD_LOGIC;
				RGB : out  STD_LOGIC_VECTOR (2 downto 0)
		   );
end vga_driver;

architecture Behavioral of vga_driver is

	signal clk25 : std_logic;

	constant HD : integer := 639;  --  639   Horizontal Display (640)
	constant HFP : integer := 16;         --   right border (front porch)
	constant HSP : integer := 96;       --   96  retrace
	constant HBP : integer := 48;        --   48   Left boarder (back porch)
	
	constant VD : integer := 479;   --  479   Vertical Display (480)
	constant VFP : integer := 10;       	 --   front porch
	constant VSP : integer := 2;				 --    retrace
	constant VBP : integer := 29;       --   back porch
	
	signal video_on : std_logic := '0';
	signal paddle_on, ball_on : std_logic;
	signal paddle_rgb: std_logic_vector( 2 downto 0):= "110";
	signal ball_rgb: std_logic_vector( 2 downto 0):= "111";
	
	--constant MAX_X : integer := 640;
	--constant MAX_Y : integer := 480;
	signal hPos : integer := 0;
	signal vPos : integer := 0;
	
	--paddle position
	signal paddle_on_left_x_position : integer := 5;
	signal paddle_on_left_y_position : integer := 220;

	signal paddle_on_right_x_position : integer := 635;
	signal paddle_on_right_y_position : integer := 220;
	
	signal paddle_on_height : integer := 30;
	signal paddle_on_width : integer := 4;
	
	--paddle move
	signal paddle_on_left_y_up : integer := 0;
	signal paddle_on_left_y_down : integer := 0;
	signal paddle_on_right_y_up : integer := 0;
	signal paddle_on_right_y_down : integer := 0;	
	
	
	constant ball_size : integer := 8;
	signal BALL_X_speed : integer := 2;
	signal BALL_Y_speed : integer := 2;
	
	signal BALL_X_position : integer := 300;
	signal BALL_Y_position : integer := 220;
	
	constant paddle_speed : integer := 8; 

	signal modulo_counter: std_logic_vector(9 downto 0) := (others => '0');
	signal licznik : unsigned(32 downto 0) := (others => '0');
	
	signal reset : std_logic := '0';

begin

	clk_div: process(CLK)
	begin
		if ( rising_edge(CLK) )then
			clk25 <= not clk25;
		end if;
	end process;
	

BALL_RGB_DISPLAY: process ( clk25 )
begin
      
      if
		(BALL_X_position <= hPos + ball_size) 
		and (BALL_X_position + ball_size >= hPos)
		and (BALL_Y_position <= vPos + ball_size)
		and (BALL_Y_position + ball_size >= vPos)then   
              
              ball_on <= '1';
      else
              
              ball_on <= '0'; 
      end if;
                  
end process;
	

PADDLE_RGB_DISPLAY: process (paddle_on_right_y_position, paddle_on_right_x_position, paddle_on_left_y_position, paddle_on_left_x_position, vPos, hPos, paddle_on_height, paddle_on_width)
begin
		--left paddle
      if ( (paddle_on_left_x_position <= hPos + paddle_on_width) and   
         (paddle_on_left_x_position + paddle_on_width >= hPos) and
			(paddle_on_left_y_position <= vPos + paddle_on_height) and  
         (paddle_on_left_y_position + paddle_on_height >= vPos) ) 
			
			or
		--right paddle
			( (paddle_on_right_x_position <= hPos + paddle_on_width) and   
         (paddle_on_right_x_position + paddle_on_width >= hPos) and
			(paddle_on_right_y_position <= vPos + paddle_on_height) and  
         (paddle_on_right_y_position + paddle_on_height >= vPos) )
			
			then    
              paddle_on <= '1';
			else
              paddle_on <= '0'; 
			end if;
		
                  
end process;

		
Horizontal_position_counter:process(clk25, RST)
begin
	if(RST = '1')then
		hpos <= 0;
	elsif(rising_edge(clk25))then
		if (hPos = (HD + HFP + HSP + HBP)) then
			hPos <= 0;
		else
			hPos <= hPos + 1;
		end if;
	end if;
end process;

Vertical_position_counter:process(clk25, RST, hPos)
begin
	if(RST = '1')then
		vPos <= 0;
	elsif(rising_edge(clk25))then
		if(hPos = (HD + HFP + HSP + HBP))then
			if (vPos = (VD + VFP + VSP + VBP)) then
				vPos <= 0;
			else
				vPos <= vPos + 1;
			end if;
		end if;
			
	end if;
end process;

Horizontal_Synchronisation:process(clk25, RST, hPos)
begin
	if(RST = '1')then
		HSYNC <= '0';
	elsif(rising_edge(clk25))then
		if((hPos <= (HD + HFP)) OR (hPos > HD + HFP + HSP))then
			HSYNC <= '1';
		else
			HSYNC <= '0';
		end if;
		

	end if;
end process;

Vertical_Synchronisation:process(clk25, RST, vPos)
begin
	if(RST = '1')then
		VSYNC <= '0';
	elsif(rising_edge(clk25))then
		if((vPos <= (VD + VFP)) OR (vPos > VD + VFP + VSP))then
			VSYNC <= '1';
		else
			VSYNC <= '0';
		end if;
			
	end if;
end process;

videoOn:process(clk25, RST, hPos, vPos)
begin
	
	if(RST = '1')then
		video_on <= '0';
	elsif(rising_edge(clk25))then
		if(hPos <= HD and vPos <= VD)then
			video_on <= '1';
		else
			video_on <= '0';
		end if;
	end if;
end process;

	
paddle_move : process( BTN_N, BTN_E, BTN_W, BTN_S )
begin
		if rising_edge(BTN_E) then
			paddle_on_left_y_up <= paddle_on_left_y_up + paddle_speed;
		end if;
		
		if rising_edge(BTN_N) then
			paddle_on_left_y_down <= paddle_on_left_y_down + paddle_speed;
		end if;

		if rising_edge(BTN_W) then
			paddle_on_right_y_up <= paddle_on_right_y_up + paddle_speed;
		end if;
		
		if rising_edge(BTN_S) then
			paddle_on_right_y_down <= paddle_on_right_y_down + paddle_speed;
		end if;

end process paddle_move;

paddle_on_left_y_position <= 220 + paddle_on_left_y_up - paddle_on_left_y_down;
paddle_on_right_y_position <= 220 + paddle_on_right_y_up - paddle_on_right_y_down;


movement : process(clk25)
begin
if rising_edge(clk25) then
		licznik <= licznik + 1;
	
		if licznik = 1100000 then
			BALL_X_position <= BALL_X_position + BALL_X_speed;
			BALL_Y_position <= BALL_Y_position + BALL_Y_speed;
			
			--bottom hit
			if BALL_Y_position > VD then --VD=479
			BALL_Y_speed <= -BALL_Y_speed;		
			BALL_Y_position <= BALL_Y_position - abs (2*BALL_Y_speed);			
			end if;
			
			--top hit
			if BALL_Y_position < 0 then
			BALL_Y_speed <= -BALL_Y_speed;
			BALL_Y_position <= BALL_Y_position + abs (2*BALL_Y_speed);			
			end if;		

			--left paddle hit
			if
			( BALL_X_position < paddle_on_left_x_position + paddle_on_width) then
				
				BALL_X_speed <= -BALL_X_speed;		
				BALL_X_position <= BALL_X_position + abs (2*BALL_X_speed);
			
				if(  BALL_Y_position >= (paddle_on_left_y_position-ball_size) )
				and (  BALL_Y_position <= paddle_on_left_y_position + paddle_on_height)
				then
					reset <= '0';
				else
					reset <= '1';
				end if;
				
			end if;
			
			--right paddle hit
			if
			( (BALL_X_position+ball_size ) > paddle_on_right_x_position ) then
				
				BALL_X_speed <= -BALL_X_speed;			
				BALL_X_position <= BALL_X_position - abs (2*BALL_X_speed);
				
				if(  BALL_Y_position >= (paddle_on_right_y_position-ball_size) )
				and (  BALL_Y_position <= paddle_on_right_y_position + paddle_on_height)
				then
					reset <= '0';
				else
					reset <= '1';
				end if;	
			
			end if;	


		
			
			licznik <= (others => '0');
		end if;
		
end if;
end process movement;


process (video_on, paddle_on, ball_on, paddle_rgb, ball_rgb)
begin
	if	video_on = '0' then
		RGB <= "000";
	else
		if ball_on = '1' then
		
			if reset = '0' then
				RGB <= ball_rgb;
			elsif( reset = '1') then
				RGB <= "100";
			end if;
		
		elsif paddle_on = '1' then
		RGB <= paddle_rgb;
		
		else
		RGB <= "000";
		end if;
		
	end if;
end process;

end Behavioral;

