----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2023 19:30:57
-- Design Name: 
-- Module Name: GCD_BEHAV - Behavioral
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

entity GCD_BEHAV is
Port (
CLK_IN:in std_logic;
CLR: in std_logic;
SLCT_X: in std_logic;
SLCT_Y: in std_logic;
X_LOAD: in std_logic;
Y_LOAD: in std_logic;
G_LOAD: in std_logic;
XIN: in std_logic_vector(7 downto 0);
YIN: in std_logic_vector(7 downto 0);
GCD: out std_logic_vector(7 downto 0);
EQUAL: out std_logic;
LITTLE: out std_logic);
end GCD_BEHAV;



architecture Behavioral of GCD_BEHAV is
component MUX_GCD
port(
NUM1: in std_logic_vector(7 downto 0);
NUM2:in std_logic_vector(7 downto 0);
SEL: in std_logic;
OUTNUM:out std_logic_vector(7 downto 0));
end component;
component REG_GCD
port(
LOAD_REG: in std_logic;
REG_IN: in std_logic_vector(7 downto 0);
CLK_IN:in std_logic;
CLR: in std_logic;
REG_OUT:out std_logic_vector(7 downto 0));
end component;

signal X,OUTNUM,F_X,F_Y,X_MINUS_Y,Y_MINUS_X: std_logic_vector(7 downto 0);
begin
X_MINUS_Y<=X-OUTNUM;
Y_MINUS_X<=OUTNUM-X;
EQ: process(X,OUTNUM)
begin
if X=OUTNUM then
EQUAL<= '1';
else
EQUAL<='0';
end if;
end process;
LT: process(X,OUTNUM)

begin
if X<OUTNUM then
LITTLE<='1';
else
LITTLE<='0';
end if;
end process;
MUX1: MUX_GCD
port map(NUM1=>X_MINUS_Y, NUM2=>XIN,SEL=>SLCT_X, OUTNUM=>F_X);
MUX2: MUX_GCD
port map(NUM1=>Y_MINUS_X, NUM2=>YIN, SEL=>SLCT_Y, OUTNUM=>F_Y);
REG1: REG_GCD
port map(LOAD_REG=>X_LOAD, REG_IN=>F_X, CLK_IN=>CLK_IN, CLR=>CLR,
REG_OUT=>X);

REG2: REG_GCD
port map(LOAD_REG=>Y_LOAD, REG_IN=>F_Y, CLK_IN=>CLK_IN, CLR=>CLR,
REG_OUT=>OUTNUM);
REG3: REG_GCD
port map(LOAD_REG=>G_LOAD, REG_IN=>X, CLK_IN=>CLK_IN, CLR=>CLR,
REG_OUT=>GCD);
end Behavioral;
