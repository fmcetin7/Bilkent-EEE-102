----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.10.2023 19:05:53
-- Design Name: 
-- Module Name: Four_Bit_Adder - Behavioral
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

library Bit_adder;
use Bit_adder.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Four_Bit_Adder is
    Port ( carry_0 : in STD_LOGIC;
           num_1 : in STD_LOGIC_VECTOR (3 downto 0);
           num_2 : in STD_LOGIC_VECTOR (3 downto 0);
           result : out STD_LOGIC_VECTOR (3 downto 0);
           overflow : out STD_LOGIC;
           carry_4 : inout STD_LOGIC);
end Four_Bit_Adder;

architecture Behavioral of Four_Bit_Adder is

signal carry : STD_LOGIC_VECTOR (3 downto 1);

component Bit_Adder 
port(carry_0,bit_1,bit_2 : in STD_LOGIC;
sum, carry_1 : out STD_LOGIC); 
end component;

begin

S0: Bit_Adder port map(carry_0 => carry_0, bit_1 => num_1(0),
    bit_2 => num_2(0),sum => result(0),carry_1 => carry(1));
S1: Bit_Adder port map(carry_0 => carry(1), bit_1 => num_1(1),
    bit_2 => num_2(1),sum => result(1),carry_1 => carry(2));
S2: Bit_Adder port map(carry_0 => carry(2), bit_1 => num_1(2),
    bit_2 => num_2(2),sum => result(2),carry_1 => carry(3));
S3: Bit_Adder port map(carry_0 => carry(3), bit_1 => num_1(3),
    bit_2 => num_2(3),sum => result(3),carry_1 => carry_4);

overflow <= carry_4 xor carry(3);

end Behavioral;
