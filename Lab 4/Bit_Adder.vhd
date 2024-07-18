----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.10.2023 18:59:32
-- Design Name: 
-- Module Name: Bit_Adder - Behavioral
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

entity Bit_Adder is
    Port ( carry_0 : in STD_LOGIC;
           bit_1 : in STD_LOGIC;
           bit_2 : in STD_LOGIC;
           sum : out STD_LOGIC;
           carry_1 : out STD_LOGIC);
end Bit_Adder;

architecture Behavioral of Bit_Adder is

begin
sum <= bit_1 xor bit_2 xor carry_0;
carry_1 <= ((bit_1 xor bit_2) and carry_0) or (bit_1 and bit_2);

end Behavioral;
