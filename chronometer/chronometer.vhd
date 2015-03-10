-- Projekt 1
-- £ukasz Przenios³o, EiT3
-- 26.12.2012

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity chronometer is
	port ( 
			 -- OUT's
			 leds : out STD_LOGIC_VECTOR (6 downto 0);
			 anodes : out STD_LOGIC_VECTOR (3 downto 0);
			 colon : out STD_LOGIC;
			 
			 debug_led : out STD_LOGIC_VECTOR (0 to 5);
			 
			 -- IN's
			 pb1 : in STD_LOGIC;
			 pb2 : in STD_LOGIC;
			 CLK : in STD_LOGIC
		  );
end chronometer;

architecture Behavioral of chronometer is
 
-- types:
type led_array is array (9 downto 0) of STD_LOGIC_VECTOR (6 downto 0);

-- signals:
signal base_prescaler : STD_LOGIC_VECTOR (24 downto 0); -- base frequency prescaler
signal display_prescaler : STD_LOGIC_VECTOR (24 downto 0); -- display frequency prescaler
signal display_nr : STD_LOGIC_VECTOR (1 downto 0); -- used to chose active display
signal colon_prescaler : STD_LOGIC_VECTOR (15 downto 0); -- colon prescaling
signal key_lock, key_lock2 : BIT; -- debounce help signal.

-- flag signals:
signal counter_full : BIT := '1'; -- 1 means full;
signal digit_clear : BIT; -- 1 means clear.
signal counter_for_dot : BIT; -- 1 means full.
signal colon_indicator : STD_LOGIC; -- 0 means its on.
signal lcd_stop : BIT; -- 1 means lcd stop.
signal db_pb1, db_pb2 : BIT;

signal digit0, digit1, digit2, digit3 : integer range 0 to 9;
signal final_digit0, final_digit1, final_digit2, final_digit3 : integer range 0 to 9;
signal current_state : integer range 0 to 5 := 0;
												
constant my_led_array : led_array := ("0010000", -- 9
												  "0000000", -- 8
												  "1111000", -- 7
												  "0000010", -- 6
												  "0010010", -- 5
												  "0011001", -- 4
												  "0110000", -- 3
												  "0100100", -- 2
												  "1111001", -- 1
												  "1000000"); --0

-- DEBOUNCE
type State_Type is (S0, S1);
-- 1												  
signal State : State_Type := S0;
signal DPB, SPB : STD_LOGIC;
signal DReg : STD_LOGIC_VECTOR (7 downto 0);

-- 2
signal State2 : State_Type := S0;
signal DPB2, SPB2 : STD_LOGIC;
signal DReg2 : STD_LOGIC_VECTOR (7 downto 0);

-- ###########################################################################################

begin

	-- fills the lcd with digits.
	counting : process (CLK, digit_clear)
		begin
		
			if digit_clear = '1' then
				counter_for_dot <= '0';
				digit0 <= 0;
				digit1 <= 0;
				digit2 <= 0;
				digit3 <= 0;
			
			elsif rising_edge(CLK) and counter_full = '0' then	
				base_prescaler <= base_prescaler + 1;
				
				if (base_prescaler = 500000) then
					base_prescaler <= (others => '0');
						
					digit3 <= digit3 +1;
					if digit3 = 9 then
						digit3 <= 0;
						digit2 <= digit2 +1;
							
						if digit2 = 9 then
							digit2 <= 0;
							digit1 <= digit1 +1;
							
							if digit1 = 9 then
								digit1 <= 0;
								digit0 <= digit0 +1;
								
								if digit0 = 9 then
									counter_for_dot <= '1';
									digit0 <= 9;
									digit1 <= 9;
									digit2 <= 9;
									digit3 <= 9;
									
								end if;
							end if;
						end if;
					end if;				
				end if;
			end if;
			
		
		end process counting;
		
-- ###########################################################################################
	
	-- switches the lcd panels, controls the dot, freezes/ defreezes the lcd.
	display_switch : process (CLK)
		begin
				
			if rising_edge(CLK) then 
			
				if counter_for_dot = '0' then
					colon_indicator <= '0';
				end if;
				
				if lcd_stop = '0' or (counter_for_dot = '1' and current_state = 3) then
					final_digit0 <= digit0;
					final_digit1 <= digit1;
					final_digit2 <= digit2;
					final_digit3 <= digit3;
				end if;
			
				display_prescaler <= display_prescaler + 1;
				
				if (display_prescaler = 100000) then
					display_prescaler <= (others => '0');
						
					if counter_for_dot = '1' then
						colon_prescaler <= colon_prescaler + 1;
						
						if colon_prescaler = 500 then
							colon_prescaler <= (others => '0');
							colon_indicator <= not colon_indicator;
								
						end if;	
					end if;
					
					case display_nr is
						when "00" =>
										leds <= my_led_array(final_digit0);
										anodes <= "0111";
										colon <= '1';
						when "01" =>
										leds <= my_led_array(final_digit1);
										anodes <= "1011";
										colon <= colon_indicator;
						when "10" =>
										leds <= my_led_array(final_digit2);
										anodes <= "1101";
										colon <= '1';
						when "11" => 
										leds <= my_led_array(final_digit3);
										anodes <= "1110";
										colon <= '1';
						when others => null;
					end case;
			
					display_nr <= display_nr + 1; -- self pb2 after display_nr = 3.
			
				end if;
			end if;
			
		end process display_switch;
			
-- ###########################################################################################
	
	-- debounce elimination for pb1.
	debouncing1 : process (CLK, pb1)
		variable SDC : integer;
		constant Delay : integer := 50000;
		begin
		
			if CLK'Event and CLK = '1' then
			-- Double latch input signal
				DPB <= SPB;
				SPB <= pb1;

				case State is
					when S0 =>
						DReg <= DReg(6 downto 0) & DPB;

						SDC := Delay;

						State <= S1;
					when S1 =>
						SDC := SDC - 1;

						if SDC = 0 then
							State <= S0;
						end if;
					when others =>
						State <= S0;
				end case;

				if DReg = X"FF" then
					db_pb1 <= '1';
				elsif DReg = X"00" then
					db_pb1 <= '0';
				end if;
			end if;
	end process debouncing1;
	
-- ###########################################################################################
	
	-- debounce elimination for pb2.
	debouncing2 : process (CLK, pb2)
		variable SDC : integer;
		constant Delay : integer := 50000;
		begin
		
			if CLK'Event and CLK = '1' then
			-- Double latch input signal
				DPB2 <= SPB2;
				SPB2 <= pb2;

				case State2 is
					when S0 =>
						DReg2 <= DReg2(6 downto 0) & DPB2;

						SDC := Delay;

						State2 <= S1;
					when S1 =>
						SDC := SDC - 1;

						if SDC = 0 then
							State2 <= S0;
						end if;
					when others =>
						State2 <= S0;
				end case;

				if DReg2 = X"FF" then
					db_pb2 <= '1';
				elsif DReg2 = X"00" then
					db_pb2 <= '0';
				end if;
			end if;
	end process debouncing2;
	
-- ###########################################################################################
	
	-- buttons actions.
	buttons : process (CLK)
		begin		
					
			if CLK'Event and CLK = '1' then
					
				-- pb1
				case current_state is
				
-- >>>>>>>>>>>>>>>>         0       <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
					when 0 =>
						if key_lock = '0' and db_pb1 = '1' then
							key_lock <= '1';
							current_state <= 1;
							
						elsif key_lock = '1' and db_pb1 = '0' then
							key_lock <= '0';
						
						else
							current_state <= 0;
						end if;
						
-- >>>>>>>>>>>>>>>>         1       <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
					when 1 =>
						if key_lock = '0' and db_pb1 = '1' then
							key_lock <= '1';
							current_state <= 2;
							
						elsif key_lock = '1' and db_pb1 = '0' then
							key_lock <= '0';
							
						elsif key_lock2 = '0' and db_pb2 = '1' then
							key_lock2 <= '1';
							if counter_for_dot = '0' then
								current_state <= 3;
							else
								current_state <= 0;
							end if;
							
						elsif key_lock2 = '1' and db_pb2 = '0' then
							key_lock2 <= '0';
						
						else
							current_state <= 1;
						end if;
						
-- >>>>>>>>>>>>>>>>         2       <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
					when 2 =>
						if key_lock = '0' and db_pb1 = '1' then
							key_lock <= '1';
							current_state <= 1;
							
						elsif key_lock = '1' and db_pb1 = '0' then
							key_lock <= '0';
							
						elsif key_lock2 = '0' and db_pb2 = '1' then
							key_lock2 <= '1';
							current_state <= 0;
							
						elsif key_lock2 = '1' and db_pb2 = '0' then
							key_lock2 <= '0';
							
						else
							current_state <= 2;
						end if;
						
-- >>>>>>>>>>>>>>>>         3       <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
					when 3 =>
						if key_lock = '0' and db_pb1 = '1' then
							key_lock <= '1';
							current_state <= 4;
							
						elsif key_lock = '1' and db_pb1 = '0' then
							key_lock <= '0';
							
						elsif key_lock2 = '0' and db_pb2 = '1' then
							key_lock2 <= '1';
							if counter_for_dot = '0' then
								current_state <= 1;
							else
								current_state <= 0;
							end if;
							
						elsif key_lock2 = '1' and db_pb2 = '0' then
							key_lock2 <= '0';
							
						else
							current_state <= 3;
						end if;
							
-- >>>>>>>>>>>>>>>>         4       <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
					when 4 =>
						if key_lock2 = '0' and db_pb2 = '1' then
							key_lock2 <= '1';
							current_state <= 5;
							
						elsif key_lock2 = '1' and db_pb2 = '0' then
							key_lock2 <= '0';
							
						else
							current_state <= 4;
						end if;
						
-- >>>>>>>>>>>>>>>>         5       <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
					when 5 =>
						if key_lock2 = '0' and db_pb2 = '1' then
							key_lock2 <= '1';
							current_state <= 0;
							
						elsif key_lock2 = '1' and db_pb2 = '0' then
							key_lock2 <= '0';
							
						else
							current_state <= 5;
						end if;
						
					when others =>
						null;
				
				end case;
				
			end if;
			
	end process buttons;
	
-- ###########################################################################################
	
	-- state machine, controlls the time and space. Spits out leds according to state its in.
	states : process (current_state, counter_for_dot)
		begin
		
			if counter_for_dot = '1' then
				counter_full <= '1';
			end if;
			
			case current_state is
				when 0 =>
					digit_clear <= '1';
					counter_full <= '1';
					lcd_stop <= '0';
					debug_led <= "100000";
				
				when 1 =>
					digit_clear <= '0';
					counter_full <= '0';
					lcd_stop <= '0';
					debug_led <= "010000";
					
				when 2 =>
					counter_full <= '1';
					lcd_stop <= '0';
					debug_led <= "001000";
					
				when 3 =>
					counter_full <= '0';
					lcd_stop <= '1';
					debug_led <= "000100";
				
				when 4 =>
					counter_full <= '1';
					lcd_stop <= '1';
					debug_led <= "000010";
					
				when 5 => 
					counter_full <= '1';
					lcd_stop <= '0';
					debug_led <= "000001";
					
			end case;
		
	end process states;

end Behavioral;

