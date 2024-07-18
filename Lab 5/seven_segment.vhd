----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.10.2023 16:31:50
-- Design Name: 
-- Module Name: seven_segment - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity seven_segment is
    Port ( anode: out std_logic_vector(3 downto 0);
        a_g : out std_logic_vector(6 downto 0);
        inn : in std_logic_vector(15 downto 0);
        clk: in std_logic;
        reset: in std_logic );
        
end seven_segment;

architecture Behavioral of seven_segment is

signal clock_divided : std_logic_vector(19 downto 0) := "00000000000000000000" ;
signal act : std_logic_vector(1 downto 0);
signal leds : std_logic_vector(3 downto 0);


begin    
    process(clk)
    begin
        if reset = '1' then
            clock_divided <= "00000000000000000000"; 
        else
            if (rising_edge(clk)) then
                clock_divided <= clock_divided + 1;       
                    if clock_divided = x"5F5E0FF" then
                        clock_divided <= "00000000000000000000";
                    end if;
            end if;
        end if;        
    act <= clock_divided(16 downto 15);    
    end process;
    
        
    process(act)
    begin
    case act is
        when "00" => anode <= "0111"; 
            leds <= inn (15 downto 12);
        when "01" => anode <= "1011";
            leds <= inn (11 downto 8);
        when "10" => anode <= "1101"; 
            leds <= inn(7 downto 4);
        when "11" => anode <= "1110"; 
            leds <= inn(3 downto 0);
        when others => anode <= "1111";
    end case;
    end process;
    
    
    process(leds)
    begin
    case leds is
        when "0000" => a_g <= "0000001"; --0
        when "0001" => a_g <= "1001111"; --1
        when "0010" => a_g <= "0010010"; --2
        when "0011" => a_g <= "0000110"; --3
        when "0100" => a_g <= "1001100"; --4
        when "0101" => a_g <= "0100100"; --5
        when "0110" => a_g <= "0100000"; --6
        when "0111" => a_g <= "0001111"; --7
        when "1000" => a_g <= "0000000"; --8
        when "1001" => a_g <= "0000100"; --9
        when "1010" => a_g <= "0001000"; --A
        when "1011" => a_g <= "1100000"; --B
        when "1100" => a_g <= "0110001"; --C
        when "1101" => a_g <= "1000010"; --D
        when "1110" => a_g <= "0110000"; --E
        when "1111" => a_g <= "0111000"; --F
        when others => a_g <= "1111111"; --Empty
    end case;
    end process;
    
end Behavioral;
