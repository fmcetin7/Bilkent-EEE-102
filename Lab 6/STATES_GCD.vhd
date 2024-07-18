----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.11.2023 19:18:26
-- Design Name: 
-- Module Name: STATES_GCD - Behavioral
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

entity STATES_GCD is
Port (
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
end STATES_GCD;

architecture STATES_GCD of STATES_GCD is

type state_type is(START, INPUT, F_TEST,S_TEST,F_UPD,S_UPD,DONE);

signal PRE_STATE, NEX_STATE: state_type;

begin
SREG: process(CLK_IN, CLR)

begin
    if CLR = '1' then
        PRE_STATE<=START;
    elsif RISING_EDGE(CLK_IN)then
        PRE_STATE<=NEX_STATE;
    end if;
end process;



C1: process(PRE_STATE,GO,EQUAL,LITTLE)
begin

case PRE_STATE   is

when START=>
    if GO='1' then
    NEX_STATE<=INPUT;
    else
    NEX_STATE<=START;
    end if;

when INPUT=>
    NEX_STATE<=F_TEST;

when F_TEST=>
    if EQUAL = '1' then
    NEX_STATE<=DONE;
    else
    NEX_STATE<=S_TEST;
    end if;

when S_TEST=>
    if LITTLE='1' then
    NEX_STATE<= F_UPD;
    else
    NEX_STATE<=S_UPD;
    end if;

when F_UPD=>
    NEX_STATE<=F_TEST;

when S_UPD=>
    NEX_STATE<=F_TEST;

when DONE=>
    NEX_STATE<=DONE;

When others =>
    NULL;

end case;
end process;


C2: process(PRE_STATE)
begin
X_LOAD<='0';Y_LOAD<='0';G_LOAD<='0';SLCT_X<='0';SLCT_Y<='0';

case PRE_STATE is

when INPUT=>
X_LOAD<='1';Y_LOAD<='1';
SLCT_X<='1';SLCT_Y<='1';

when F_UPD=>
Y_LOAD<='1';

when S_UPD=>
X_LOAD<='1';

when DONE=>
G_LOAD<='1';

when others =>
NULL;
end case;
end process;
end STATES_GCD;
