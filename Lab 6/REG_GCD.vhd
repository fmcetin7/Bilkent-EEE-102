----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2023 19:15:16
-- Design Name: 
-- Module Name: REG_GCD - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity REG_GCD is
port(
    LOAD_REG: in std_logic;
    REG_IN: in std_logic_vector(7 downto 0);
    CLK_IN:in std_logic;
    CLR: in std_logic;
    REG_OUT:out std_logic_vector(7 downto 0));
end REG_GCD;

architecture REG_GCD of REG_GCD is

begin

process(CLK_IN)
begin
    if rising_edge(CLK_IN) then
        if CLR = '1' then
            REG_OUT<=(others=>'0');
        else
           if LOAD_REG='1' then
                REG_OUT <= REG_IN;
           end if;
        end if;
    end if;
end process;

end REG_GCD;
