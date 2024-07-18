----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2023 19:33:05
-- Design Name: 
-- Module Name: MOD_GCD - Behavioral
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

entity MOD_GCD is
Port (
GO:in std_logic;
XIN:in std_logic_vector(7 downto 0);
YIN: in std_logic_vector(7 downto 0);
CLK_IN: in std_logic;
CLR: in std_logic;
GCD_OUT: out std_logic_vector(7 downto 0));
end MOD_GCD;

architecture Behavioral of MOD_GCD is
component GCD_BEHAV
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
end component;

component STATES_GCD
Port(
CLK_IN: in std_logic;
CLR: in std_logic;
GO:in std_logic;
EQUAL: in std_logic;
LITTLE: in std_logic;
SLCT_X: out std_logic;
SLCT_Y: out std_logic;
X_LOAD: out std_logic;
Y_LOAD: out std_logic;
G_LOAD: out std_logic);
end component;
signal EQUAL, LITTLE, SLCT_X,SLCT_Y: std_logic;
signal X_LOAD,Y_LOAD,G_LOAD: std_logic;
begin

SIG1:GCD_BEHAV port

map(CLK_IN=>CLK_IN,CLR=>CLR,SLCT_X=>SLCT_X,SLCT_Y=>SLCT_Y,X_LOAD=>X_LOAD
,Y_LOAD=>Y_LOAD,
G_LOAD=>G_LOAD,XIN=>XIN,YIN=>YIN,GCD=>GCD_OUT,EQUAL=>EQUAL,LITTLE=>LITTLE);

SIG2: STATES_GCD 

port map(CLK_IN=>CLK_IN,CLR=>CLR,GO=>GO,EQUAL=>EQUAL,LITTLE=>LITTLE,
SLCT_X=>SLCT_X,SLCT_Y=>SLCT_Y,X_LOAD=>X_LOAD,Y_LOAD=>Y_LOAD,G_LOAD=>G_LOAD);
end Behavioral;