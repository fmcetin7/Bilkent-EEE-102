----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2023 19:13:14
-- Design Name: 
-- Module Name: MUX_GCD - Behavioral
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
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MUX_GCD is
port(
    NUM1: in std_logic_vector(7 downto 0);
    NUM2:in std_logic_vector(7 downto 0);
    SEL: in std_logic;
    OUTNUM:out std_logic_vector(7 downto 0));
end MUX_GCD;

architecture MUX_GCD of MUX_GCD is

begin

with SEL select OUTNUM<=
    NUM1 when '0',
    NUM2 when others;
end MUX_GCD;
