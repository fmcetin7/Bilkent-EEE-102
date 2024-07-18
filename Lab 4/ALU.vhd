----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.10.2023 18:38:04
-- Design Name: 
-- Module Name: ALU - Behavioral
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

library Four_Bit_adder;
use Four_Bit_adder.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( num1 : in STD_LOGIC_VECTOR (3 downto 0);
           num2 : in STD_LOGIC_VECTOR (3 downto 0);
           sel : in STD_LOGIC_VECTOR (2 downto 0);
           result : out STD_LOGIC_VECTOR (3 downto 0);
           overflow : out STD_LOGIC);
end ALU;

architecture Behavioral of ALU is

component Four_Bit_Adder 
port(num_1, num_2: in STD_LOGIC_VECTOR (3 downto 0); 
carry_0 : in STD_LOGIC;
result : out STD_LOGIC_VECTOR (3 downto 0);
overflow : out STD_LOGIC ; 
carry_4 : inout STD_LOGIC);
end component;

signal result1, result2, result3, result4 : STD_LOGIC_VECTOR (3 downto 0);
signal overflow1, overflow2, overflow3, overflow4 : STD_LOGIC;
signal null1, null2,null3,null4 : STD_LOGIC;

begin
Q0 : Four_Bit_Adder port map(num_1 => num1, num_2 => num2, carry_0 => '0', 
    result => result1,carry_4 => overflow1, overflow=> null1 );
Q1: Four_Bit_Adder port map(num_1 => num1, num_2 => not(num2), carry_0 => '1', 
    result => result2,carry_4 => null2 ,overflow=> overflow2);
Q2 : Four_Bit_Adder port map(num_1 => num1, num_2 => "0001", carry_0 => '0', 
    result => result3,carry_4 => null3, overflow =>overflow3);
Q3 : Four_Bit_Adder port map(num_1 => num1, num_2 => "1110", carry_0 => '1', 
    result => result4,carry_4 => null4, overflow => overflow4);

allu:process(num1, num2, sel)is
begin
    case sel is
    when "000" => --Adder--
    result <= result1;
    overflow <= overflow1;
    
    when "001" => --subtractor--
    result <= result2;
    overflow <= overflow2;
    
    when "010" => --and-gate--
    result <= num1 and num2;
    overflow <= '0';
    
    when "011" => --Logical Shift--
    result(3 downto 0) <= num1(2 downto 0) & '0';
    overflow <= num1(3);

    when "100" => -- Four Bit Rotation--
    result(3) <= num1(0);
    result(2) <= num1(1);
    result(1) <= num1(2);
    result(0) <= num1(3);
    overflow <= '0';
    
    when "101" => --inverse--
    result <= not(num1);
    overflow <= '0';
    
    when "110" => --Add 1--
    result <= result3;
    overflow <= overflow3;
    
    when others => --subtract 1--
    result <= result4;
    overflow <= overflow4;
    
    end case;
end process;  
end Behavioral;
