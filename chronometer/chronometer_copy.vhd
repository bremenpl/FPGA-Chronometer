-- Projekt 1
-- £ukasz Przenios³o, EiT3

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
			 
			 debug_led : out STD_LOGIC_VECTOR (5 downto 0) := "100000"; 
			 
			 -- IN's
			 pb1 : in STD_LOGIC;
			 pb2 : in STD_LOGIC;
			 CLK : in STD_LOGIC
		  );
end chronometer;

architecture Behavioral of chronometer is

-- types:
type led_array is array (9 downto 0) of STD_LOGIC_VECTOR (6 downto 0);
type mState is (s0, s1, s2, s3);

-- signals:
signal base_prescaler : STD_LOGIC_VECTOR (24 downto 0); -- base frequency prescaler
signal display_prescaler : STD_LOGIC_VECTOR (24 downto 0); -- display frequency prescaler
signal display_nr : STD_LOGIC_VECTOR (1 downto 0); -- used to chose active display
signal colon_prescaler : STD_LOGIC_VECTOR (15 downto 0); -- colon prescaling
signal s, z : mState;
signal in_state2_pressed : BIT;

-- flag signals:
signal counter_full, counter_for_dot : BIT; -- 1 means full.
signal colon_indicator : STD_LOGIC; -- 0 means its on.
signal fixed_pb1, fixed_pb2 : BIT; -- buttons after debounce.

signal digit0, digit1, digit2, digit3 : integer range 0 to 9;

-- states from 0 to 5:
signal state : integer range 0 to 5;
												
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

begin

	counting : process (fixed_pb1, fixed_pb2, CLK, state)
		begin
			
			if fixed_pb1 = '1' then
			
				case state is
					when 0 =>
								state <= 1;
					when 1 =>
								state <= 2;
					when 2 =>
								state <= 1;
					when 3 =>
								state <= 4;
					when 4 =>
								null;
					when others => -- (5)
								null;
				end case;
			
			elsif fixed_pb2 = '1' then 
				case state is
					when 0 =>
								null;
					when 1 =>
								state <= 3;
					when 2 =>
								state <= 0;
					when 3 =>
								state <= 1;
					when 4 =>
								state <= 5;
					when others => -- (5)
								state <= 0;
				end case;
			
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
									counter_for_dot <= '1'; -- stop counting.
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
			
			-- state machine:
			case state is
				when 0 => debug_led <= "000001";
							digit0 <= 0;
							digit1 <= 0;
							digit2 <= 0;
							digit3 <= 0;
							counter_full <= '1';
							counter_for_dot <= '0';
							
				when 1 => debug_led <= "000010";
							counter_full <= '0';
							
				when 2 => debug_led <= "000100";
							--counter_full <= not counter_full;
							counter_full <= '1';
							
				when 3 => debug_led <= "001000";
							
				when 4 => debug_led <= "010000";
							
				when 5 => debug_led <= "100000";
				
				when others => debug_led <= "111111";
							
			end case;
		
		end process counting;
		
	-- #######################################################
		
	display_switch : process (fixed_pb2, CLK)
		begin
		
			if fixed_pb2 = '1' and state = 0 then
				display_nr <= (others => '0');
				anodes <= "1111"; -- when pb2 pushed no leds on.
				colon_indicator <= '0';
				
			elsif rising_edge(CLK) then 
				display_prescaler <= display_prescaler + 1;
				
				if (display_prescaler = 100000) then
						display_prescaler <= (others => '0');
						
						if counter_for_dot = '1' then
						colon_prescaler <= colon_prescaler + 1;
						end if;
						
						if colon_prescaler = 500 then
							colon_prescaler <= (others => '0');
							if (colon_indicator = '0') then colon_indicator <= '1';
							elsif (colon_indicator = '1') then colon_indicator <= '0';
							end if;
						end if;
					
					case display_nr is
						when "00" =>
										leds <= my_led_array(digit0);
										anodes <= "0111";
										colon <= '1';
						when "01" =>
										leds <= my_led_array(digit1);
										anodes <= "1011";
										colon <= colon_indicator;
						when "10" =>
										leds <= my_led_array(digit2);
										anodes <= "1101";
										colon <= '1';
						when "11" => 
										leds <= my_led_array(digit3);
										anodes <= "1110";
										colon <= '1';
						when others => null;
					end case;
			
					display_nr <= display_nr + 1; -- self pb2 after display_nr = 3.
			
				end if;
			end if;
			
		end process display_switch;
		
				
	-- #######################################################

	debounce_pb1 : process(CLK) is
		begin
	
			if rising_edge (CLK) then
		
			case s is
					when s0 => if pb1 = '0' then s <= s0;
					else s<=s1;
			end if;
			
					when s1 => if pb1 = '0' then s <= s0;
					else s<=s2;
			end if;
			
					when s2 => if pb1 = '0' then s <= s3;
					else s<=s2;
					
			end if;
					when s3 => if pb1 = '0' then s <= s0;
					else s<=s2;
			end if;
					
			end case;
		end if;
	
	end process debounce_pb1;
	
	outs1: process(s)
		begin
			case s is
				when s0 => fixed_pb1 <= '0';
				when s1 => fixed_pb1 <= '0';
				when s2 => fixed_pb1 <= '1';
				when s3 => fixed_pb1 <= '1';
		end case;
	end process outs1;
	
	-- #######################################################
	
	debounce_pb2 : process(CLK) is
		begin
	
			if rising_edge (CLK) then
		
			case z is
					when s0 => if pb2 = '0' then z <= s0;
					else z <=s1;
			end if;
			
					when s1 => if pb2 = '0' then z <= s0;
					else z <=s2;
			end if;
			
					when s2 => if pb2 = '0' then z <= s3;
					else z <=s2;
					
			end if;
					when s3 => if pb2 = '0' then z <= s0;
					else z <=s2;
			end if;
					
			end case;
		end if;
	
	end process debounce_pb2;
	
	outs2: process(z)
		begin
			case z is
				when s0 => fixed_pb2 <= '0';
				when s1 => fixed_pb2 <= '0';
				when s2 => fixed_pb2 <= '1';
				when s3 => fixed_pb2 <= '1';
		end case;
	end process outs2;

end Behavioral;

