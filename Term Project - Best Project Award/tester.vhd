----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.11.2023 20:33:57
-- Design Name: Guitar Heroes
-- Module Name: tester - Behavioral
-- Project Name: Guitar Heroes
-- Target Devices: BASYS3 FPGA Board & a VGA monitor
-- Description: Guitar Hero Game
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;



entity tester is
    Port ( clk : in STD_LOGIC; --100Mhz internal BASYS3 clock
           reset : in STD_LOGIC; --reset button
           start: in std_logic; --start switch
           difficulty: in std_logic; --difficulty selection switch
           select_song: in std_logic; --song selection switch
           note_buttons: in std_logic_vector (7 downto 0); --guitar buttons
           hsync : out STD_LOGIC; --horizontal sync output for vga driver
           vsync : out STD_LOGIC; --vertical sync output for vga driver
           audio_output: out std_logic; --the audial output
           anodes: out std_logic_vector(3 downto 0); --anodes of seven segment
           cathodes: out std_logic_vector(6 downto 0); -- cathodes of seven segment
           rgb : out STD_LOGIC_VECTOR (11 downto 0)); --the 12-bit RedGreenBlue colour code 
           --very useful visualization of 12-bit rgb coding at https://studio.code.org/projects/applab/qiyLvNCBDuOYbaBB8oe0isTwNDYTOeGA5cpWlhHNTzM
end tester;



architecture Behavioral of tester is

--25 MHz clock
signal clk25: std_logic := '0';
--50MHz clock
signal clk50: std_logic := '0';

--the horizontal constants for the 640*480 vga screen
constant hd: integer:= 639; --horizontal display
constant hfp: integer:= 16; --horizontal front porch
constant hsp: integer:= 96; --horizontal sync pulse
constant hbp: integer:= 48; --horizontal back porch
signal hpos: integer:= 0; --horizontal position

--the vertical constants for the 640*480 vga screen
constant vd: integer:= 479; --vertical display
constant vfp: integer:= 10; --vertical front porch
constant vsp: integer:= 2; --vertical sync pulse
constant vbp: integer:= 33; --vertical back porch
signal vpos: integer:= 0; --vertical position


--every single note height and widths in pixels
constant note_height: integer := 20;
constant note_width: integer := 50;

--horizontal and vertical difference between two notes in pixels
constant notes_height_diff: integer := 20;
constant notes_width_diff: integer := 10;

--different colours in 12-bit rgb representation for the notes
constant colour_green: std_logic_vector(11 downto 0):= "000011110000";
constant colour_red: std_logic_vector(11 downto 0):= "111100000000";
constant colour_yellow: std_logic_vector(11 downto 0):= "111111110000";
constant colour_blue: std_logic_vector(11 downto 0):= "000000001111";
constant colour_orange: std_logic_vector(11 downto 0):= "111110000000";
constant colour_violet: std_logic_vector(11 downto 0):= "110000001111";
constant colour_white: std_logic_vector(11 downto 0):= "111111111111";
constant colour_pink: std_logic_vector(11 downto 0):= "111100001100";
--different colours in 12-bit rgb representation for background screen (NOT THE NOTES)
constant colour_gray: std_logic_vector(11 downto 0):= "000100010001";
constant colour_black: std_logic_vector(11 downto 0):= "000000000000";

--the speed of the notes that are sliding down the screen
signal vertical_speed: integer;

--horizontal pixel information of each note according to the colour
constant note_green_horizontal: integer:= 85;
constant note_red_horizontal: integer:= 145;
constant note_yellow_horizontal: integer:= 205;
constant note_blue_horizontal: integer:= 265;
constant note_orange_horizontal: integer:= 325;
constant note_violet_horizontal: integer:= 385;
constant note_white_horizontal: integer:= 445;
constant note_pink_horizontal: integer:= 505;

-- the vertical pixel information of the strum area where the buttons must be hit exactly when the notes are there
constant strum_upper_limit: integer:= 390;
constant strum_lower_limit: integer:= 430;
constant strum_limit_height: integer:= 10;

-- the array that contains the vertical pixel information of each note
type note_vertical_properties_array is array (0 to 79) of integer; --each element of the array contains the vertical pixel info of every note
signal note_vertical_properties: note_vertical_properties_array;
--the arrays that contain the horizontal pixel information and the colour of each note
type note_horizontal_colours_string_array is array (0 to 79) of string(1 to 1);--each element of the array is one of "grybovwp" (note colours' initials)
signal note_horizontal_colours_string: note_horizontal_colours_string_array;
type note_horizontal_properties_array is array (0 to 79) of integer;--each element of the array contains the horizontal pixel info of every note
signal note_horizontal_properties: note_horizontal_properties_array;
type note_horizontal_colours_array is array (0 to 79) of std_logic_vector(11 downto 0);-- each element of the array is a 12-bit rgb representation of the note colour
signal note_horizontal_colours: note_horizontal_colours_array;


--the following 11 bitmaps are displayed in the main menu / scroll all the way down and check the binary arrays at the very end of the behavioral part!
--shoutout to https://www.dcode.fr/binary-image which is the perfect site for jpg to binary array conversion
signal gamenamevisible: boolean;
type bitmap1 is array (0 to 47) of std_logic_vector(0 to 639);
signal gamename: bitmap1;

signal photovisible: boolean;
type bitmap2 is array (0 to 260) of std_logic_vector(0 to 299);
signal photo: bitmap2;

signal songvisible: boolean;
type bitmap3 is array (0 to 18) of std_logic_vector(0 to 339);
signal song: bitmap3;

signal thunderstruckvisible: boolean;
type bitmap4 is array (0 to 18) of std_logic_vector(0 to 339);
signal thunderstruck: bitmap4;

signal smokevisible: boolean;
type bitmap5 is array (0 to 18) of std_logic_vector(0 to 339);
signal smoke: bitmap5;


signal difficultyvisible: boolean;
type bitmap6 is array (0 to 18) of std_logic_vector(0 to 339);
signal difficulty_2: bitmap6;

signal easyvisible: boolean;
type bitmap7 is array (0 to 18) of std_logic_vector(0 to 339);
signal easy: bitmap7;

signal hardvisible: boolean;
type bitmap8 is array (0 to 18) of std_logic_vector(0 to 339);
signal hard: bitmap8;

signal startswitchvisible: boolean;
type bitmap9 is array (0 to 18) of std_logic_vector(0 to 339);
signal startswitch: bitmap9;

signal fatihmehmetvisible: boolean;
type bitmap10 is array (0 to 13) of std_logic_vector(0 to 299);
signal fatihmehmet: bitmap10;

signal lightningvisible: boolean;
type bitmap11 is array (0 to 144) of std_logic_vector(0 to 84);
signal lightning: bitmap11;

--the array that makes sure you only get 1 point from each note 
--p.s. without this array you would get 1 point in each clock cycle -which means if you pressed the correct button for 1 sec, you would get 25 million points :)
type NoteScoredArray is array (0 to 79) of boolean;
signal note_scored : NoteScoredArray:= (others=>False); --set the initial value to False for all 80 elements of the array

--the score output which will be displayed on the seven segment display and its' three decimals
signal score: integer:= 0;
signal score0: integer;--least significant figure of the score signal
signal score1: integer;
signal score2: integer;
signal score3: integer; --most significant figure of the score signal

-- the necessary signals for creating a 3000Hz clock for seven segment display
signal ss_counter: std_logic_vector(19 downto 0):= "00000000000000000000";
signal clk3000: std_logic_vector(1 downto 0);--3000Hz clock
signal ss_leds: integer;

--the frequencies of the 8 different notes 
--p.s. if you divide each value to 25MHz, you find the corresponding freqeuency value
--Ex: 25million/23889 = 1046.50 Hz for freq8
signal freq8 : integer := 23889; --pink
signal freq7 : integer := 25316; --white
signal freq6 : integer := 26409; --violet
signal freq5 : integer := 31887; --orange
signal freq4 : integer := 35790; --blue
signal freq3 : integer := 37936; --yellow
signal freq2 : integer := 42589; --red
signal freq1 : integer := 47801; --green
signal freqbuzz : integer := 150000; --buzzer
signal freqnull : integer := 100000000; -- no sound

--the necessary signals for the sound output
signal freq_counter: integer := 0;
signal frequency: integer:= 0;
signal audio_signal: std_logic:= '0';



begin

--this is the process where we give an output of a square wave signal with the selected frequency
audio_output <= audio_signal;
audio: process(clk25)
begin
    if rising_edge(clk25) then
        if freq_counter >= frequency then
            audio_signal <= not audio_signal;
            freq_counter <= 0;
        else
            freq_counter <= freq_counter + 1;
        end if;
    end if;
end process;


--obtain a nearly 3kHz clock which will be used in the seven segment display from the internal 100MHz BASYS3 clock
clkdivider2: process(clk)
begin
    if (rising_edge(clk)) then
        ss_counter <= ss_counter + 1;                                       
    end if;      
clk3000 <= ss_counter(16 downto 15); 
end process;


--calculate the buzzing output and the score value, p.s. be very careful to not increase the score more than once at the same note :)
score_count: process(clk25)
begin
    if rising_edge(clk25) then
        if start = '1' then
            for i in 0 to 79 loop
--this part needs a very clear explanation; first we basically set the limits and increased the score if the 
--correct button has been hit at the right time. In order to not increase the score multiple times at the 
--same note, we use the note_scored array and initialized it at false for every element.
--Then when a note is hit that element's note_scored property is locked to true until the restart of the game!
--Note that the buzzer signal is not dependent on the note_scored array
                if ((note_vertical_properties(i) + (note_height/2)) > strum_upper_limit) and ((note_vertical_properties(i) - (note_height/2)) < strum_lower_limit) then
                    case note_horizontal_colours_string(i) is
                        when "g" =>
                            if note_buttons(6)= '1' or note_buttons(5)= '1' or note_buttons(4)= '1' or note_buttons(3)= '1' or note_buttons(2)= '1' or note_buttons(1)= '1' or note_buttons(0)= '1' then
                                frequency <= freqbuzz;
                            elsif note_buttons(7) = '1' then
                                frequency <= freq1;
                            else
                                frequency <= freqnull;
                            end if;
                            if not note_scored(i) then
                                if note_buttons(7) = '1' then
                                    score <= score + 1;
                                    note_scored(i) <= True;
                                end if;
                            end if;
                        when "r" => 
                            if note_buttons(7)= '1' or note_buttons(5)= '1' or note_buttons(4)= '1' or note_buttons(3)= '1' or note_buttons(2)= '1' or note_buttons(1)= '1' or note_buttons(0)= '1' then
                                frequency <= freqbuzz;
                            elsif note_buttons(6) = '1' then
                                frequency <= freq2;
                            else
                                frequency <= freqnull;
                            end if;
                            if not note_scored(i) then
                                if note_buttons(6) = '1' then
                                    score <= score + 1;
                                    note_scored(i) <= True;                                 
                                end if;
                            end if;
                        when "y" =>
                            if note_buttons(7)= '1' or note_buttons(6)= '1' or note_buttons(4)= '1' or note_buttons(3)= '1' or note_buttons(2)= '1' or note_buttons(1)= '1' or note_buttons(0)= '1' then
                                frequency <= freqbuzz;
                            elsif note_buttons(5) = '1' then      
                                frequency <= freq3; 
                            else
                                frequency <= freqnull;
                            end if;
                            if not note_scored(i) then
                                if note_buttons(5) = '1' then
                                    score <= score + 1;
                                    note_scored(i) <= True;
                                end if;
                            end if;
                        when "b" =>
                            if note_buttons(7)= '1' or note_buttons(6)= '1' or note_buttons(5)= '1' or note_buttons(3)= '1' or note_buttons(2)= '1' or note_buttons(1)= '1' or note_buttons(0)= '1' then
                                frequency <= freqbuzz;
                            elsif note_buttons(4) = '1' then
                                frequency <= freq4;
                            else
                                frequency <= freqnull;
                            end if;
                            if not note_scored(i) then
                                if note_buttons(4) = '1' then
                                    score <= score + 1;
                                    note_scored(i) <= True;
                                end if;
                            end if;
                        when "o" =>
                            if note_buttons(7)= '1' or note_buttons(6)= '1' or note_buttons(5)= '1' or note_buttons(4)= '1' or note_buttons(2)= '1' or note_buttons(1)= '1' or note_buttons(0)= '1' then
                                frequency <= freqbuzz;
                            elsif note_buttons(3) = '1' then
                                frequency <= freq5;
                            else
                                frequency <= freqnull;
                            end if;
                            if not note_scored(i) then
                                if note_buttons(3) = '1' then
                                    score <= score + 1;
                                    note_scored(i) <= True;                                    
                                end if;
                            end if;
                        when "v" =>
                            if note_buttons(7)= '1' or note_buttons(6)= '1' or note_buttons(5)= '1' or note_buttons(4)= '1' or note_buttons(3)= '1' or note_buttons(1)= '1' or note_buttons(0)= '1' then
                                frequency <= freqbuzz;
                            elsif note_buttons(2) = '1' then
                                frequency <= freq6;
                            else
                                frequency <= freqnull;
                            end if;
                            if not note_scored(i) then
                                if note_buttons(2) = '1' then
                                    score <= score + 1;
                                    note_scored(i) <= True;                                 
                                end if;
                            end if;
                        when "w" =>
                            if note_buttons(7)= '1' or note_buttons(6)= '1' or note_buttons(5)= '1' or note_buttons(4)= '1' or note_buttons(3)= '1' or note_buttons(2)= '1' or note_buttons(0)= '1' then
                                frequency <= freqbuzz;
                            elsif note_buttons(1) = '1' then
                                frequency <= freq7;
                            else
                                frequency <= freqnull;
                            end if;
                            if not note_scored(i) then
                                if note_buttons(1) = '1' then
                                    score <= score + 1;
                                    note_scored(i) <= True;            
                                end if;
                            end if;
                        when others => --when "p" =>
                            if note_buttons(7)= '1' or note_buttons(6)= '1' or note_buttons(5)= '1' or note_buttons(4)= '1' or note_buttons(3)= '1' or note_buttons(2)= '1' or note_buttons(1)= '1' then
                                frequency <= freqbuzz;
                            elsif note_buttons(0) = '1' then
                                    frequency <= freq8;
                            else
                                frequency <= freqnull;
                            end if;
                            if not note_scored(i) then
                                if note_buttons(0) = '1' then
                                    score <= score + 1;
                                    note_scored(i) <= True;
                                end if;
                            end if;
                    end case;            
                end if;
            end loop;
--set the score&buzzer values to zero when game is stopped or not initialized
        else
            score <= 0;
            frequency <= freqnull;
            for i in 0 to 79 loop
                note_scored(i) <= False;
            end loop;
        end if;
    end if;
end process;

--display the score signal at the seven segment display for BASYS3
seven_segment: process(clk3000)
begin
--seperate each decimal of the score function
--remark that since #notes per song is 80, the score function can be max 80.
score0 <= score mod 10;
score1 <= (score mod 100/ 10);
score2 <= (score / 100);
score3<= (score/1000);

--match the anodes and each decimal of the score function
    case clk3000 is --3000Hz clock for seven segment display
        when "00" => 
            anodes <= "1111";
            ss_leds <= score3;
        when "01" => 
            anodes <= "1011";
            ss_leds <= score2; 
        when "10" => 
            anodes <= "1101";
            ss_leds <= score1;   
        when others => --when "11" 
            anodes <= "1110";
            ss_leds <= score0; 
    end case;

--determine the 7-bit vector cathode signals for each integer
    case ss_leds is
        when 1 => cathodes <= "1001111";
        when 2 => cathodes <= "0010010";
        when 3 => cathodes <= "0000110";
        when 4 => cathodes <= "1001100";
        when 5 => cathodes <= "0100100";
        when 6 => cathodes <= "0100000";
        when 7 => cathodes <= "0001111";
        when 8 => cathodes <= "0000000";
        when 9 => cathodes <= "0000100";
        when others => cathodes <= "0000001"; --when 0 =>
    end case;
    
end process;


--obtain a 25MHz clock from the internal 100MHz clock of BASYS3
clkdivider1: process(clk)
begin
    if rising_edge(clk) then
        clk50 <= not clk50;
    end if;

    if rising_edge(clk50) then
        clk25 <= not clk25;
    end if;
end process;


--create a horizontal position counter for the vga output
--very useful info on vga drivers at https://www.youtube.com/watch?v=eJMYVLPX0no&t=228s
horizontal_position_counter: process(clk25, reset)
begin
    if reset = '1' then
        hpos <= 0;
    elsif rising_edge (clk25) then
        if (hpos = hd + hfp + hbp + hsp) then
            hpos <= 0;
        else
            hpos <= hpos + 1;
        end if;
    end if;
end process;

--create a vertical position counter which updates the vertical pos every time the horizontal pos is resetted for the vga output
--very useful info on vga drivers at https://www.youtube.com/watch?v=eJMYVLPX0no&t=228s
vertical_position_counter: process(clk25, reset)
begin
    if reset = '1' then
        vpos <= 0;
    elsif rising_edge (clk25) then
        if (hpos = hd + hfp + hbp + hsp) then
            if (vpos = vd + vfp + vbp + vsp) then
                vpos <= 0;
            else
                vpos <= vpos + 1;
            end if;
        end if;
    end if;
end process;

--the horizontal sync output for basys3 
--very useful info on vga drivers at https://www.youtube.com/watch?v=eJMYVLPX0no&t=228s
horizontal_synchronization: process(clk25, reset, hpos)
begin
    if reset = '1' then
        hsync <= '0';
    elsif rising_edge(clk25) then
        if (hpos <= (hd + hfp)) or (hpos > (hd + hfp + hsp)) then
            hsync <= '1';
        else
            hsync <= '0';
        end if;
    end if;
end process;

--the vertical sync output for basys3 
--very useful info on vga drivers at https://www.youtube.com/watch?v=eJMYVLPX0no&t=228s
vertical_synchronization: process(clk25, reset, vpos)
begin
    if reset = '1' then
        vsync <= '0';
    elsif rising_edge(clk25) then
        if (vpos <= (vd + vfp)) or (vpos > (vd + vfp + vsp)) then
            vsync <= '1';
        else
            vsync <= '0';
        end if;
    end if;
end process;

--the initialization of the vertical pixel infos of the notes and the sliding mechanism logic of the game
vertical_pos: process(clk25, vpos, hpos)
begin
    if rising_edge(clk25) then
--increase the vertical pixel value of each note according to the vertical speed
        if start = '1' then
            if vpos = 0 and hpos=0 then
                for i in 0 to 79 loop
                    if note_vertical_properties(i) < vd then
                        note_vertical_properties(i) <= note_vertical_properties(i) + vertical_speed;
--set the vertical value info to a value which is greater than max screen vertical pixel (480 in our case)
                    else
                        note_vertical_properties(i) <= 1923; --the founding year of the Turkish Republic <3
                    end if;
                end loop;
            end if;
--initialization of vertical pixels of the notes, each of them starts at a negative value!
        else
            for i in 0 to 79 loop
                note_vertical_properties(i) <=  -1 * (i+1) * (note_height + notes_height_diff);
            end loop;
        end if;
    end if;
end process;

--set the horizontal pixel value and the 12-bit rgb colour representation of each note according to the initials array
--i am lazy and since the notes are manually inputted, i just coded the initials
horizontal_pos_and_colour: process(clk25)
begin
        for i in 0 to 79 loop
            if note_horizontal_colours_string(i) = "g" then
                note_horizontal_properties(i) <= note_green_horizontal;
                note_horizontal_colours(i)<= colour_green;
            elsif note_horizontal_colours_string(i) = "r" then
                note_horizontal_properties(i) <= note_red_horizontal;
                note_horizontal_colours(i)<= colour_red;
            elsif note_horizontal_colours_string(i) = "y" then
                note_horizontal_properties(i) <= note_yellow_horizontal;
                note_horizontal_colours(i)<= colour_yellow;
            elsif note_horizontal_colours_string(i) = "b" then
                note_horizontal_properties(i) <= note_blue_horizontal;
                note_horizontal_colours(i)<= colour_blue;
            elsif note_horizontal_colours_string(i) = "o" then
                note_horizontal_properties(i) <= note_orange_horizontal;
                note_horizontal_colours(i)<= colour_orange;
            elsif note_horizontal_colours_string(i) = "v" then
                note_horizontal_properties(i) <= note_violet_horizontal;
                note_horizontal_colours(i)<= colour_violet;
            elsif note_horizontal_colours_string(i) = "w" then
                note_horizontal_properties(i) <= note_white_horizontal;
                note_horizontal_colours(i)<= colour_white;
            else    --elsif note_horizontal_colours_string(i) = "p" then
                note_horizontal_properties(i) <= note_pink_horizontal;
                note_horizontal_colours(i)<= colour_pink;
            end if;
        end loop;      
end process;

--change the initials array (Therefore the horizontal position and colour arrays) according to the song selection by the user
--remark that the notes are coded in a form such you would play on a real guitar if you actually played the real song
--easier to write the colour initials manually rather than the integer hpos and 12-bit vector rgb values :)
with select_song select note_horizontal_colours_string <=
           ("g","b","g","b","g","b","g","b","g","b","r","o","r","o","r","o","r","o","r","o",--first 20 notes of "thunderstruck"
            "g","b","g","b","g","b","g","b","r","o","r","o","r","o","r","o", --next 16 notes
            "p","v","o","v","o","y","o","r","y","g","r","g","r","g","r","g", --next 16 notes
            "p","v","o","v","o","y","o","r","y","g","r","g","r","g","r","g", --next 16 notes
            "p","p","w","w","v","v","o","b","y","r","g","g") when '0', --last 12 notes  
            
            ("g","y","o","o","g","y","v","o","g","y","o","o","y","g",--first 14 notes of "smoke on the water"
             "r","b","v","v","r","b","w","v","r","b","v","v","b","r", --next 14 notes
             "y","o","w","w","y","o","p","w","y","o","w","w","o","y", --next 14 notes
             "r","b","v","v","r","b","w","v","r","b","v","v","b","r", --next 14 notes
             "g","y","o","o","g","y","v","o","g","y","o","o","y","g", --next 14 notes
             "p","w","v","o","b","y","r","g","r","g") when others; --last 10 notes
             


--change the note speeds according to the difficulty input by the user
with difficulty select vertical_speed <=
    1 when '0',
    2 when others;

--this is the huge&complex process where we finally get to draw things on the VGA display
draw: process(clk25, reset, vpos, hpos)
begin
    if start = '1' then
--It is always nice to have a reset if the synchronization goes wrong at some point :)
        if reset = '1' then
            rgb <= colour_black;
        elsif rising_edge(clk25) then
            rgb <= colour_black;
            if (((vpos > (strum_upper_limit - strum_limit_height)) and (vpos <= strum_upper_limit)) or 
            ((vpos > strum_lower_limit) and (vpos <= (strum_lower_limit + strum_limit_height)))) 
            then
--paint the strum area to the note colour when the player has hit a correct note
                if frequency = freq1 and ((hpos > note_green_horizontal) and (hpos < note_green_horizontal + note_width)) then
                    rgb<= colour_green;
                elsif  frequency = freq2 and ((hpos > note_red_horizontal) and (hpos < note_red_horizontal + note_width)) then
                    rgb<= colour_red;
                elsif frequency = freq3 and ((hpos > note_yellow_horizontal) and (hpos < note_yellow_horizontal + note_width)) then
                    rgb<= colour_yellow;
                elsif frequency = freq4 and ((hpos > note_blue_horizontal) and (hpos < note_blue_horizontal + note_width))  then
                    rgb<= colour_blue;
                elsif frequency = freq5 and ((hpos > note_orange_horizontal) and (hpos < note_orange_horizontal + note_width))  then
                    rgb<= colour_orange;
                elsif frequency = freq6 and ((hpos > note_violet_horizontal) and (hpos < note_violet_horizontal + note_width))  then
                    rgb<= colour_violet;
                elsif frequency = freq7 and ((hpos > note_white_horizontal) and (hpos < note_white_horizontal + note_width))  then
                    rgb<= colour_black;
                elsif frequency = freq8 and ((hpos > note_pink_horizontal) and (hpos < note_pink_horizontal + note_width))  then
                    rgb<= colour_pink;    
--paint the background of the gameplay screen 
                elsif (((hpos > note_green_horizontal) and (hpos < note_green_horizontal + note_width)) or
                ((hpos > note_red_horizontal) and (hpos < note_red_horizontal + note_width)) or
                ((hpos > note_yellow_horizontal) and (hpos < note_yellow_horizontal + note_width)) or
                ((hpos > note_blue_horizontal) and (hpos < note_blue_horizontal + note_width)) or
                ((hpos > note_orange_horizontal) and (hpos < note_orange_horizontal + note_width)) or
                ((hpos > note_violet_horizontal) and (hpos < note_violet_horizontal + note_width)) or
                ((hpos > note_white_horizontal) and (hpos < note_white_horizontal + note_width)) or
                ((hpos > note_pink_horizontal) and (hpos < note_pink_horizontal + note_width)))
                then
                    rgb <= colour_white;
                end if;
            end if;
            if lightningvisible = True then
                rgb<= colour_red;
            end if;
--paint the necessary positions of the screen where notes are currently in with the necessary note colours
            for i in 0 to 79 loop
                if note_vertical_properties(i) > (-1 * note_height) and note_vertical_properties(i) <= vd then
                    if ((vpos > note_vertical_properties(i)) and (vpos <= note_vertical_properties(i) + note_height)) and
                    ((hpos > note_horizontal_properties(i)) and (hpos <= note_horizontal_properties(i) + note_width)) 
                    then
                        rgb <= note_horizontal_colours(i);
                    end if;
                end if;
            end loop;
        end if;
    else
 --this is the code for the main menu
        rgb <= colour_black;
        if (gamenamevisible = True) or (photovisible = True) or (songvisible = True) or 
        (difficultyvisible = True) or (startswitchvisible = True) 
        then
            rgb<=colour_white;
        elsif (fatihmehmetvisible = True) or (hardvisible = True) then
            rgb<=colour_red;
        elsif (thunderstruckvisible = True)or (smokevisible = True)then
            rgb<=colour_blue;
        elsif (easyvisible = True) then
            rgb<=colour_green;
        end if;
    end if;
end process;

--the rest of the code is the design signals&bitmaps that belong to the main menu
--the guitar picture is designed by an AI and the writings are designed in canva app with writing style 'Pixelion'
--shoutout to https://www.dcode.fr/binary-image is the site I used for jpg to binary array conversion

gamename <=("0000000000000000000000000000000000000000001111100111110011111001111100000000000000111111001111100000000000000011111100111110000000011111011111100111110111111000000011111100111110111111001111101111110011111000000000000001111110011111011111100111110000000000000011111100111110111111001111101111110000000000000000000000000000000000000011111101111100000000000000001111110111110000000011111001111110111110011111101111100000000111110011111101111100111111011111000000000000000000000011111001111110111110011111100000000000000111110011111101111100111111011111000000000000000111111011111001111110111110000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000011111110111111111111101111110000000000000111111111111100000000000000011111111111110000000111111011111111111110111111000000011111101111110111111111111101111111111111000000000000001111110111111011111111111110000000000000011111101111110111111111111101111110000000000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110111111111111101111110000000111111111111101111111111111011111100000000000000000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111111111110111111000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000011111100111111111111101111100000000000000111111011111100000000000000011111111111110000000111111011111111111110111111000000011111101111110111111111111101111111111111000000000000001111110111111011111111111110000000000000011111101111110111111011111101111110000000000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110111111111111101111110000000111111111111101111111111111011111100000000000000000000011111111111110111111011111100000000000000111111111111101111111111111011111100000000000000111111011111011111110111111000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000011111111111111111111101111110000000000000111111011111100000000000000011111111111110000000111111011111111111110111111000000011111101111110111111111111101111111111111000000000000001111110111111011111111111110000000000000011111101111110111111011111101111110000000000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110111111111111101111110000000111111111111101111111111111011111100000000000000000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111011111110111111000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000011111100111111111111101111110000000000000111111011111100000000000000011111111111110000000111111011111111111110111111000000011111101111110111111011111101111111111111000000000000001111110111111011111111111110000000000000011111101111110111111111111101111110000000000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110111111111111101111110000000111111111111101111111111111011111100000000000000000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111111111110111111000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000001111100111110011111001111100000000000000011111001111100000000000000011111100111110000000011110011111100111110111111000000001111100111100111111001111101111110011111000000000000000111110011110011111000111110000000000000001111100111100111111001111101111110000000000000000000000000000000000000011111101111100000000000000001111100111110000000011111001111110111110011111000111100000000111110011111101111100111110011111000000000000000000000011111001111110111110011111000000000000000111110011111101111100111111011111000000000000000111111011111001111110111110000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111111111110000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111101111111000000000000000111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111101111111000000111111111111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111111111111000000000000000111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111101111111000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111111111111000000000000000111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111101111111000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111111111111000000000000000111111011111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111111111110000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111101111111000000000000000111110011111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111001111100000000000000001111100111110000000111111001111100000000000000011111100111110000000000000011111100111110000000000000000000000000000111111001111100000000000000000000001111101111110000000000000000111110111111000000011111100111110000000000000001111110011111000000000000000000000000000000011111101111100000000000000001111110111110000000011111001111110000000000000000000000000000111110011111100000000000000011111001111100000000111111011111000000000000000011111101111100000000111110011111100000000000000000000000000001111100111111000000000000000111110011111000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011110000111100000000000000000000000000000000000011110001111000000000000000001111000111100000000000000001111000111100000000000000000000000000000011110001111000000000000000000000001111000111100000000000000000111100011110000000001111000111100000000000000001111100011110000000000000000000000000000000001111000111100000000000000001111100011110000000001111000111000000000000000000000000000000111110001110000000000000000001111001111100000000011110001111000000000000000011111000111100000000011110001111000000000000000000000000000001111100011110000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111101111100000000000000000000000000000000000111111001111100000000000000011111100111110000000000000011111100111110000000000000000000000000000111111001111100000000000000000000001111101111110000000000000000111110111111000000011111100111110000000000000001111110011111000000000000000000000000000000011111101111100000000000000001111110111110000000011111001111110000000000000000000000000000111110011111100000000000000011111001111110000000111111011111000000000000000011111101111100000000111110011111100000000000000000000000000001111100111111000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000000000000000000000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111111111111000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000000000000000000000000111111011111100000000000000011111111111110000000000000011111101111110000000000000000000000000000111111011111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111111111111000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000000000000000000000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111111111111000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000000000000000000000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111111111111000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111001111100000000000000000000000000000000000111111001111100000000000000011111100111110000000000000011111100111110000000000000000000000000000111111001111100000000000000000000001111101111110000000000000000111110111111000000001111100111110000000000000001111110011111000000000000000000000000000000011111101111100000000000000001111110111110000000011111001111110000000000000000000000000000111110011111100000000000000011111001111100000000111111011111000000000000000011111101111100000000111110011111100000000000000000000000000001111100111111000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111101111100000000111111101111111111110000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110111111011111111111110111111000000011111101111110111111111111101111110000000000000000000000000000000000000011111101111111111111011111101111110111111000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111100000000000000011111101111110000000111111111111101111111111111000000000000001111111111111011111111111110111111011111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000111111101111111111111000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110111111011111111111110111111000000011111101111110111111011111101111110000000000000000000000000000000000000011111101111111111111011111101111110111111000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111100000000000000011111101111110000000111111111111101111111111111000000000000001111111111111011111111111110111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000111111101111101111111000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110111111011111111111110111111000000011111101111110111111011111101111110000000000000000000000000000000000000011111101111111111111011111101111110111111000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111100000000000000011111101111110000000111111111111101111111111111000000000000001111111111111011111011111110111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000111111101111101111111000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110111111011111111111110111111000000011111101111110111111111111101111110000000000000000000000000000000000000011111101111111111111011111101111110111111000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111100000000000000011111101111110000000111111111111101111111111111000000000000001111111111111011111111111110111111011111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000111111101111111111110000000111111111111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110111111011111111111110111111000000011111101111110111111111111101111110000000000000000000000000000000000000011111101111111111111011111111111110111111000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111100000000000000011111101111110000000111111111111101111111111111000000000000001111101111111011111111111110111110011111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111001111100000000011111001111100111110000000011111001111100000000000000011111100111110000000000000011111100111110000000000000000000000000000111111001111000000000000000000000001111001111110011111011111000111100111110000000011111100111100111111001111001111110000000000000000000000000000000000000011111101111100111111011111001111100011110000000011111001111110011110011111000000000000000111110011111100111100111110011111000000000000000011111011111000000000000000011111101111100000000111110011111101111100111110000000000000001111100111111011111001111100111110011111000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111001111100000000000000001111100111110000000011111001111100000000000000011111100111110000000000000011111100111110000000000000000000000000000111111001111000000000000000000000001111000111110000000000000000111110111110000000001111100111100000000000000001111110000000000000000000000000000000000000001111101111100000000000000001111100011110000000011111001111110000000000000000000000000000111110011111100000000000000001111000000000000000011111011111000000000000000011111000111100000000111110011111100000000000000000000000000000000000000000000000000000000111110011111000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111101111100000000000000001111101111110000000111111001111100000000000000011111100111110000000000000011111100111110000000000000000000000000000111111001111100000000000000000000001111101111110000000000000000111110111111000000011111100111110000000000000001111110011111000000000000000000000000000000011111101111100000000000000001111110111110000000011111001111110000000000000000000000000000111110011111100000000000000011111001111110000000111111011111000000000000000011111101111100000000111110011111100000000000000000000000000000000000000000000000000000000111110011111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111111111110000000111111111111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000000000000000000000000000000000111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111101111111000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000000000000000000000000000000000111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111111111110000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000000000000000000000000000000000111111011111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111111111111000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000000000000000000000000000000000111111011111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111001111100000000000000001111100111110000000111111001111100000000000000011111100111110000000000000011111100111110000000000000000000000000000111111001111100000000000000000000001111101111110000000000000000111110111111000000011111100111110000000000000001111110011111000000000000000000000000000000011111101111100000000000000001111110111110000000011111001111110000000000000000000000000000111110011111100000000000000011111001111110000000111111011111000000000000000011111101111100000000111110011111100000000000000000000000000000000000000000000000000000000111110011111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111111111111000000111111011111100000000000000011111111111110000000000000011111101111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111111111110000000111111111111100000000000000000000000000001111111111111000000000000000111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111111111110000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111111111111000000000000000111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111111111111000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111111111111000000000000000111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111101111111000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111111111111000000000000000111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111111111100000000000000001111101111110000000111111011111100000000000000011111111111110000000000000011111111111110000000000000000000000000000111111111111100000000000000000000011111111111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110000000000000000000000000000111111111111100000000000000011111101111110000000111111011111100000000000000011111101111110000000111111111111100000000000000000000000000001111111111111000000000000000111111111111100000000000000000000000000000000000000000",
            "0000000000000000000000000000000000011111000111100000000000000001111100011110000000011111001111000000000000000001111100111110000000000000001111100111100000000000000000000000000000011111001111000000000000000000000001111000111110000000000000000111100111110000000001111100111100000000000000001111100011111000000000000000000000000000000001111101111100000000000000001111100011110000000011111000111110000000000000000000000000000111110001111100000000000000001111001111100000000011110011111000000000000000011111000111100000000111110001111000000000000000000000000000001111100111110000000000000000111110011111000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000001111100000000000000001111100000000000000000000001111100000000000000011111100000000000000000000001111100111110000000000000000000000000000111111001111000000000000000000000001111000111110000000000000000111110111110000000001111100111100000000000000001111100011110000000000000000000000000000000001111101111100000000000000001111100011110000000011111001111110000000000000000000000000000111110011111100000000000000011111001111100000000000000011111000000000000000011111000000000000000111110011111100000000000000000000000000000000000111111000000000000000111110000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000001111100111110011111001111100000000000000000000001111101111110011111011111100000000000000011111011111100111110111111000000000000000000000111111001111100000000000000000000001111101111110000000000000000111110111111000000011111100111110000000000000001111110011111000000000000000000000000000000011111101111100000000000000001111110111110000000011111001111110111110011111101111100000000111110011111100000000000000011111001111110000000000000011111001111110111110011111100000000000000111110011111101111100111111011111000000000000000111111011111001111110111110000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000011111100111111111111101111110000000000000000000011111101111111111111011111100000000000000111111011111111111110111111000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110111111111111101111110000000111111111111100000000000000011111101111110000000000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111111111110111111000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000011111100111111111111101111110000000000000000000011111101111111111111011111100000000000000111111011111111111110111111000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110111111111111101111110000000111111111111100000000000000011111101111110000000000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111111111110111111000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000011111100111111111111101111110000000000000000000011111101111111111111011111100000000000000111111011111111111110111111000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111111111111000000011111111111110111111111111101111110000000111111111111100000000000000011111101111110000000000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111111111110111111000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000011111100111111111111101111110000000000000000000011111101111111111111011111100000000000000111111011111111111110111111000000000000000000000111111111111100000000000000000000011111101111110000000000000001111110111111000000011111101111110000000000000001111111111111000000000000000000000000000000011111101111110000000000000001111110111111000000011111111111110111111111111101111110000000111111111111100000000000000011111101111110000000000000011111111111110111111111111100000000000000111111111111101111111111111011111100000000000000111111011111111111110111110000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000001111100111110111111001111100000000000000000000001111101111110011111011111100000000000000011111011111100111110111111000000000000000000000111111001111100000000000000000000001111101111110000000000000000111110111111000000011111100111110000000000000001111110011111000000000000000000000000000000011111101111100000000000000001111110111110000000011111001111110111110011111101111100000000111110011111100000000000000011111001111110000000000000011111001111110111110011111100000000000000111110011111101111100111111011111000000000000000111111011111001111110111110000000000000000000000000000000000000000000000000");
            
                                    
gamenamevisible <= (vpos > 35) and (vpos<85) and (gamename(vpos-36)(hpos) = '1');


photo <=(   "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100000000000000001111110000000000000000000000000000000000001111110000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100000000000000011111110000000000000000000000000000000000001111111000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000000000000011111110000000000000000000000000000000000001111111000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000000000000011111110000000000000000000000000000000000001111111000000000000000000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111000000000000000011111110000000000000000000000000000000000000000111000000000000000000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111000000000000000011100000000000000000000000000000000000000000111111000000000000000000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111000000000000000011100000000000000000011111111000000000000001111111100000000000000000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000000000111100000000000000000111111111000000000000000111111100000000000000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000000000000111000000000000000011111111111111100000000000111111100000000000000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010001111111000000000000111000000000000000011111111111111100000000000111011100000000000000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111000000000000111000000000000011111111111111111111100000000000011100000000000000111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111110000000000000000111111100000000111111111111111111111100000000000011100000000000000000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111110000000000000000111111100000000111111111111111111111100000000000011110000000000000000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111110000000000000000111111101111100111111111111111111111100111110011111110000000000000000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011110000000000000001111111001111100011111111111111111111100111110011111110000000000000000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011110000000000000001111000001111100011111111111111111111100111110011111110000000000000001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111100000000000001110000001111111111111111111111111111111111110011111110000000000000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111100000000000001110000001111111111111111111111111111111111110000001110000000000000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111100000000000001110000001111110111000111111111100011100111110000001111111000000000001111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111100000000000000001111110001111110111000111111111100011100111110000001111111000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111100000000000000001111111000000000111000111111111100011100000000000000111111000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100000000000000011111110000000000111111111111111111111100000000000111111000000000000000001111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100000000000000011111110001111110111111111111111111111100111110001111111000000000000000000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111100000000000011111110001111110111111111111111111111100111110001111111000000000000001111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111100000000000011111000001111111111111111111111111111111111110001111111000000000000001111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111100000000000011111000001111111111111111111111111111111111110001111111111100000000001111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111000000000000011110000001111111111111111111111111111111111110000000111111100000000000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111000000000000001100000001111100011000111111111100011100111110000000111111100000000000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111110111000111111111100011100111110000000011100000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111000111111111100011100000000000000011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111100000000000000011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111100001111110111111111111111111111100111110000011111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000001111110111111111111111111111100111110000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000001111111111111111111111111111111111110000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111000001111111111111111111111111111111111110000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100100000000000111111000001111111111111111111111111111111111110000011111000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000000000000000000001111100011111111111111111111100111110000000000000000000000010111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100100000000000000000001111100011111111111111111111100111110000000000000000000000010111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111110000000000000000000000011110111111111101111100000000000000000000000110110111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111110000000000000000000000011110111111111101111100000000000000000000000110110111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111110000000000000000000000001110111111111101110000000000000000000000000110110111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111110000000000000000000000001110111111111101110000000000000000000000000111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111110000000000000000000000001110111011001101110000000000000000000000000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110000000000000000000000001110111011001101110000000000000000000000000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110000000000000000000000001110111011001101110000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110111011001101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110111011001101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000001110111011001101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011011000000000000000000000000000000001110111011001101110000000000000000000000000000000001101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011011011011000000000000000000000000001110111011001101110000000000000000000000000001101101101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011011111011100000000000000000000000001110111011001101110000000000000000000000000011101101101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111011100000000000000000000000001110111011001101110000000000000000000000000011101101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011011011100000000000000000000000001110111011001101110000000000000000000000000011101101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011011100000000000000000000000001110111011011101110000000000000000000000000001101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011011100000000000000000000000001110010001001001110000000000000000000000000001101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000000000000000000000001110000000000001110000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110000000000001110000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000001111111111011101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000001111111011011101110000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000000000000000000000000000000001111111011011101110000000000000000000000000000000000010011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100100000000000000000000000000001111111011011101110000000000000000000000000000000011011011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111110000000000000000000000000001110111011001101110000000000000000000000000000011011011011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111110000000000000000000000000001110000000000001110000000000000000000000000000111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101111110000000000000000000000000001110000000000001110000000000000000000000000000111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111110000000000000000000000000001110011011001101110000000000000000000000000000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110000000000000000000000000001111111011011101110000000000000000000000000000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111011011101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111011011101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000001111111011011101110000000000000000000000000000000000000101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011011000000000000000000000000000000000001111111011011101110000000000000000000000000000000000101111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111001100000000000000000000000000001110111011001101110000000000000000000000000000001101101111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111100000000000000000000000000001110000000000001110000000000000000000000000000001101101111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111100000000000000000000000000001110000000000001110000000000000000000000000000001101101110100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111100000000000000000000000000001110111011001101110000000000000000000000000000001101101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111100000000000000000000000000001110111011011101110000000000000000000000000000001101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001001100000000000000000000000000001110111011011101110000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000001110111011011101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110111011011101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000000000000000000000000000000000000001110111011011101110000000000000000000000000000000000000010011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110010000000000000000000000000000000000001110111011011101110000000000000000000000000000000000010011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110110010010000000000000000000000000000001110111011011101110000000000000000000000000000000110111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110111111000000000000000000000000000001110111011011101110000000000000000000000000000000111111111011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110111111000000000000000000000000000001110111011011101110000000000000000000000000000000111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110111111000000000000000000000000000001110111011001101110000000000000000000000000000000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110111111000000000000000000000000000001110000000000001110000000000000000000000000000000111010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111000000000000000000000000000001110000000000001110000000000000000000000000000000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111000000000000000000000000000001110010011001001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110111011011101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110111011001101110000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000001110111011001101110000000000000000000000000000000000000000101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000001110010011001001110000000000000000000000000000000000000101111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111001000000000000000000000000000000000001110000000000001110000000000000000000000000000000001101111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111101100000000000000000000000000000001110010000000001110000000000000000000000000000000001101111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111100000000000000000000000000000001110111011011101110000000000000000000000000000000001101111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111100000000000000000000000000000001110111011011101110000000000000000000000000000000001101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111100000000000000000000000000000001110111011011101110000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001001100000000000000000000000000000001110111011011101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000001110000000000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000001110000000000001110000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111010000000000000000000000000000000000000000001110011011001101110000000000000000000000000000000000000010011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110010000000000000000000000000000000000000001110111011011101110000000000000000000000000000000000111111011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111011000000000000000000000000000000001110111011011101110000000000000000000000000000000000111111011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111011000000000000000000000000000000001110111011011101110000000000000000000000000000000000111111011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010111111011000000000000000000000000000000001110010011001001110000000000000000000000000000000000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010011011000000000000000000000000000000001110000000000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000001110000000000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000001111111011011101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000001111111011011101110000000000000000000000000000000000000000000001101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000001110111011001101110000000000000000000000000000000000001001001101101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101101100000000000000000000000000000000000000001110000000000001110000000000000000000000000000000000011111111101101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101101101101100000000000000000000000000000000001110000000000001110000000000000000000000000000000000011111111101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101111101110000000000000000000000000000000001110111011001101110000000000000000000000000000000000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101101110000000000000000000000000000000001111111011001101110000000000000000000000000000000000011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111110000000000000000000000000000000001110111011001101110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110000000000000000000000000000000001110000000000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000001110000000000000000000000000000000000000000000010011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000100000000000000000000000000000000000000000000001110010011001101110000000000000000011000000000000000000000010111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000011100000000000000000000000000001100000000000000000000000000000000000000000000001111111011011101110000000000000000011000000000000000001110111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000011100000000000000000000000000000111110100000000000000000000000000000000000000001110111011011101110000000000000000011000000000000000000110111111010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000011100000000000000000000000000111111111110110000000000000000000001111100000000001110111011011101110000000000000000011111000000000000000110111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000001111111000000000000000000000000111111111111110100000000000000000001111100000000001110010011001101110000000000000000011111000000000000000110010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000001111111000000000000000000000000000000111111111100000000000000000001111100000000001110000000000001110000000000000000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000001111111111000000000000000000000000000000000110110000000000000000001111111111000000001110000000000001110000000000000000011111000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000001111111111000000000000000000000000000000000000110000000000000000001111111111000000001110111011001101110000000000000000011111000000000000000000000001011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000001111111111000000000000000000000011100000000000000000000000000000001111111111000000001110111011001101110000000000000000011111000000000000000111011011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111000000000000000000000001111000000000000000000000000001111111111111110000001110111011001101110000000000000000011111000000000000000111011011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111000000000000000000000001111111101000000000000000000001111111111111110000001110000000000001110000000000000000011111000000000000000111011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111000000000000000000000001111111101101100000000000000001111111111111111110001110000000000001110000000000000000011000000000000000000011000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111000000000000000000000000011111101101100000000000000001111111111111111111001110111011011101110000000000000000011000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111000000000000000000000000001001101101100000000000000001111111111111111111001111111011011101110000000000000011100000000111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111000000000000000000000000000000001101100000000000000001111111111111111110001111111011011101110110000000000011100000000011111111111011001111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000000001111111111111111111111110010011001001110000000000000011100000011111111111111111001101111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111000000000000000000000010000000000000000000000000000000000001111111111111111110000000000001110000000000001100000000011111111111111111001101100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111000000000000000000000111110000000000000000000000000000000001111111111111111110000000000001110000000000001100000001111111111111111111001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111000000000000000000000111111111010000000000000000000000000001111111111111111110111011001101111100000000110000000011111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111000000000000000000000000011111111000000000000000000001110000001111111111001111111011001101111100000001110000000011111111111111111100000000001111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111110000000000000000011111111111111011000000000000000001111000001111111111001110010011001101111110000001110000001111111111111111111100000000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111110000000000000000011111111111111011000000000000000001111000001111111110001110000000000001110011111111000000001111111111111111111111001111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111111110000000000001111111110111111011000000000000001111111110000001111000001110000000000001110011111111000000111111111111111111111111101111111000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111111110000000000011110000000000000011000000000000001111111110000001111000001110111011001101110011111111000000111111111111111111111111101100000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111111110000000011111110000000000000000000000000000001111111110000001111000001110111011001101110000011100000000111111111111111111111111000000000111100000000000000000000000000000111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111111111111111111111111110110110000000000000000000001111111111110001000000001110000000000001110000011100000011111111111111111111111100000000000111100000000000000000000000000000111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111111111111111111111111110110110010000000000000000001111111111110001000000001110000000000001110000011100000011111111111111111111111100000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111111111111111111111100000000000111011000000100000001111111111110001000000001110010001001001110000011100000011111111111000011111111111101111111111111100000000000000000000000111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111111111111111111111100000000000111111000000100000001111111111110001000000001110011011001101110000011100000011111111111000001111111111101111111111111100111000000000000000000111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111111111111111111111111100110000000000000000000001111111111111110001000001111110111011001101110000011100000111111111111000001111111111100110000000011100111000000000000000000111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111111111111111111111111110111110000000000000000001111111111111110001000001111111111111111111111111111100000111111110000000000011111110000000000000001100111000000000000000011111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111111111111111111111111100111111111111110000000001111111111111110001001111111111111111111111111111111110011111111110000000000011111110000000000000011100001110000000000011111111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111111111111111111110000000000111111111110000001111111111111111110000001111111111111111111111111111111110011111111110000111100011111111111111111011111100000110000000001111111111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111111111111111111110000000000011111111110000001111111111111111110000001111111111111111111111111111111110011111111110000111100011111111111111111011111100000111000000011111111111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111011000000001111111111111111111111111110000001111000000000000000000000011111100011111111110000111100011111111110010010011011100111111111111111111111111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111011000000001111111111111111111111111110000001111000000000000000000000001111100011111111110000111100011111110000000000000000100011111111111111111111111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111111111111111111111110011011111101111111111111111111111111111110000001111000000000000000000000001111100011111111110000000000011111110000000000000001100011111111111111111111111100000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111111111111111111110000000000011111111111111111111111111111111110000001111000000000000000000000001111100011111111111111000001111111111100011111111101100011100000000000001111111100000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111111111111111111110000000000000000001111111111111111111111111110000001111000000000000000000000001111100000111111111111000001111111111100011011011101100011100000000000001111111100000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111111111111111111110010111111000000001111111111111111111111110000000001111111110111111111111111111111100000011111111111000011111111111100111011011101100011100001111110001111110000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111111111111111111110111111111000000001111111111111111111111110000000001111111111111111111111111111111100000011111111111111111111111111100111011011101100011100011111110001111110000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111111111111110111110111111111111001111111111111111111111111110000000001111111111111111111111111111111100000011111111111111111111100011100010000000000100000000011111110001111110000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111111111111100011100110111111111001111111111111111111111111110000000001111111111111111111111111111111100000011111111111111111111100011100010000000000000000000011111110001111110000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000011111111111111111111100011100110111011111001111111111111111111111111110000000000000000100000000000000011111111110000011111111111111111111100011100000000000000000000000011111110001111110000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000001111111111111111111100000000000010011111001111111111111111111111111100011000000000000000000000000000000000001110000000111111111111111111100000000000000000000000000000001111110001111000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000001111111111111111111100000000000000000000001111011111111111111111111100011000000000000000000000000000000000001110000000111111111111111111100000000000000000000000000000001111110001111000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000011111111111111111100000000000000000010001111000111111111111111111000011000000000000000000000000000000000000111110000111111111111111111100000000000000000000000000000001111110001110000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000001111111111111111100000000000000000000000110001111111111111111110000011000000000000000000000000000000000000011110000011111111111111111110000000000000000000000000000001111110001100000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000001111111111111111000000000000000000000000000001111111111111111110000011000000000000000000000000000000000000011110000011111111111111111110000000000000000000000000111001111110001100000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000100001111111111111111000000000000000000000000000001111111111111111110001111000000000000000000000000000000000000001111100011111111111111111110000000000000000000000000111001111110001100000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000001111111111111111000000000000000000000000000001111111111111111000001111000000000000000000000000000000000000001111100000011111111111111110000000000000000000000000111001111110000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000001111111111111111000000000000000000000000000001111111111111110001111111000000000000000000000000000000000000001111111000011111111111111110000000000000000000000000110001111110000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000001111111111111111000110000000000000000000000001111111111111110001111111000000000000000000000000000000000000001111111100011111111111111110001100000000000000000000000001111110000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000011111111111111000110000000000000000000000001111111111111000001111100000000000000000000000000000000000000000011111100000111111111111110001100000000000100110011111111111110000000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000011111111111111000110000000000000000000000001111111111110000001111100000000000000000000000000000000000000000001111100000111111111111110001100010001101101110011111111111111100000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000011111111111111000000000000000000000000000011111111111110000001111100000000000000000000000000000000000000000001111100000111111111111110000000011011101101110011111111111111100000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000001111111111111111111111000110001000000001100011111111111110001111111100000000000000000000000000000000000000000001111111000111111111111111111100011011101111110001111111111111100000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000001111111111111111111111000111011100000011110011111111111110001111111100000000000000000000000000000000000000000000011111000111111111111111111100011011101111110001111111111111100000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000001111111111111111111111000111011101100011110011111111111000001111111100000000000000000000000000000000000000000000011111000111111111111111111100011011101110110001111111111111100000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000101111111111111111111111111000111111111110001000011111111111000001111110000000000001111100010011001100111100000000000000111000111111111111111111100011011111110110001111111111111100000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000101111111111111111111111111001110011101110011111111111111111000001111110000000000001111100010011001100111100000000000000111000111111111111111111100011011101110110001111111111111100000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111111111111111111001110011001110011111111111111111000111111110000000000001111100010011001100111100000000000000111000111111111111111111100011011111111110001111111111111111000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000111111111111111111111111111001110011001110011111111111111111000111111000000000001111111111111111111111111111100000000000100000111111111111111111110011111101110110001111111111111111000110000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111111111111111111001110011001110011111111111111111110001110000000000001111111111111111111111111111100000000000000000111111111111111111110011101111110111001111111111111111000110000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000111111111111111111111111111111001110011001110011111111111111111110001110000000000001111111111111111111111111111100011100000000001111111111111111111110011101101111111001111111111111111100000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111111111111111111001100011001110011111111111111111110001110000000000001111110111011011111110001111100011100000000011111111111111111111110011101111110111001111111111111111111001100000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111111111111111110001100011001100011111111111111111110001110000000000001111000000000000000000000001100011100000001111111111111111111111110011101111111111001111111111111111111001100000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000011111111111111111111111111111111110001100111001100011111111111111111110000000000000000001111000000000000000000000011100000000000001111111111111111111111110011111111110111001111111111111111111000111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000011111111111111111111111111111111110001100111001100011111111111111111110000000000000000001111000000000000000000000011100000000000001111111111111111111111110011101110111111001111111111111111111110011000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000011111111111111111111111111111111110001100111001100111111111111111111110000000000000000001111000000000000000000000011100000000000111111111111111111111111110011101111111111000111111111100001111110011100000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000011111111111111111111111111111111111110011100111001100111111111111111111110000000000000000001111111111111111111111111111100000000011111111111111111111111111110011101110110111000111111111100001111110001111000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000011111101111111111111111111111111111110011100110001100111111111111111111111110000000000000001111111111111111111111111111100000000111111111111111111111111111110011111110111011000110001111100001111111100111100000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000011111111111111111111111111111111111110011100110001100111111111111111111111111000000000000001111111111111111111111111111100000000111111111111111111111111111110011101110110001000110001111100001111111100111000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000011011111111111111111111111111111111111110011100110011100111111111111111111111111000000000000000001111111111111111111111000000000011111111111111111111111111111110001101100100001000110001111100001111111100000110000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000011111111111111111111111111111111100011100011100110011100111111111111111111111111111000000000000000000000000000000000000000000000011111111111111111111111111001110001000100000000000000001111111111111111111000110000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000001011111111111111111111111111111111100011100001000110011100111111111111111111111111111000000000000000000000000000000000000000000001111111111111111111111111110001110000000000000000000000001111111111111111111000110000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000001111111111111111111111111111111111100011000001000110011000111111111111111111111111111010000000001111111111111111111111111111000001111111111111111111111111111001110000000000000000000000001111111111111111111000111110000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000001111111111111111111111111111111111100000000000000110011000111001111111111111111111111110000000001111111111111111111111111110000001111111111111111111111111111000000000000000000000000000001111111111111111111000111110000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000001111111011111111111111111111111111100000000000000000001000111001111111111111111111111110000000001110001110111011001101110000000001111111111111111111111111111000000000000000000000000000001111111111111111111000111110000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000001111111111111111111111111111111111111100000000000000000000000111001111111111111111111111110000001111110001110111011001101110000000111111111111111111111111111111000000000000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000001111111111111111001111111111111111111000000000000000000000000000001111111111111111111111110000001111110001110111011001101110000000111111111111111111111111111111000000000000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000001111111111111111001111111111111111111000000000000000000000000000001111111111111111111111111110001111111111111111111111111111000000111111111111111111111111111111000000000000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000001111111111111111111111111111111111111000000000000000000000000000001111111111111111111111111110001111111111111111111111111111000111111111111111111111111111111111000000000000000000000000000001111111111111111111111111111111000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000001111111111011101111111111111111111111000000000000000000000000000001111111111111000001111111110001111111111111111111111111111000111111111111111111111111111111111000000000000000000000000000001111111111111111111111111111111100000000000000000000000000000000000000000000",
            "000000000000000000000000000000000001111111011111111111111111111111111111000000000000000000000000000001111111111111000000111111110001111110000000000000000000000000111111111111111111111111111111111000000000000000000000000000001111111111111111111111111111111100000000000000000000000000000000000000000000",
            "000000000000000000000000000000000111111111111111111111111111111111111111000000000000000000000000000001111111111111000000001111110001111110000000000000000000000000111111111111111111111111111111111100111000000000000000000011111111111111111111111111111111111100000000000000000000000000000000000000000000",
            "000000000000000000000000000000000111111111111111111111111111111111111111000000000000000000000000000001111111111111000000001111110001111110000000000000000000000000111111111111111111111111111111111100111000000000001001100011111111111111111111111111111111111100000000000000000000000000000000000000000000",
            "000000000000000000000000000000000111111111111111111111111111111111111111000000011000000000000000000001111111111111000000001111110000011110000000000000000000000000111111111111111111111111111111111100111000100010011101110011111111111111111111111100111111111100000000000000000000000000000000000000000000",
            "000000000000000000000000000000000111111111111111111111111111111111111111111100011001100000000001110011111111111111000000001111111110001110000000000000000000000011111111111111111111111111111111111100000000110111011101110011111111111111111111111000111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000000111111111111111111111111111111111111111111100011111100110000001110011111111111111000000111111111110001111111111111111111111100011111111111111111111111111111111111111111101110111011101110011111111111111111111111000111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000001111111111111110001111111111111111111111111100011011100110010000110011111111111111000001111111111110001111111111111111111111100011111111111111111111111111111111111111111101110111011101110001111111111111111111100000001111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111111111111111111111111111111111100011011100110011001111111111111111111111111111111111110001111111111111111111111100011111111111111111111111111111111111111111101110111011101110001111111111111111111100000000111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111111111111111111111111111111111100111011100110011001111111111111111111111111111111111110001111111111111111111111100011111111111111111111111111111111111111111101110111111111110000000111111111111111100000000111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111111111111111111111111111111111100111011101110011001111111110000000111111111111111111110001111111111111111111111100011111111111111111111111111111111111111111111111111111110000000000111111001111111100000000111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111111111111111111111111111111111100111111101110111001111111110000000001111111111111111110001111111111111111111111100011111111111111111111111111111111111111111111111110000000000000000111111001111111100000000111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111111111111111111111111111110000000111111111111111001111111110000000001111111111111111110001111111111111111111111100011111111111111111111111111111111111111100000000000000000000000000111000000001111111000111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111111111111111111111111111110000000000011111111111001111111110000000001111111111111111110001111111111111111111111100011111111111111111111111111111111111100000000000000000000000000000111000000001111111000111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111110011110111111111111111111111000000000000000000110001111111110000000001111111111111111110001111111111111111111111100011111111111111111111111111111111111100000000000000000000000000011111000000001111111100111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111111111111111111111111111111000000000000000000000000011111110000000001111111111111111110001111111111111111111111100011111111111111111111111111111111111100000000000000000000000000011111000000001111111111111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111000111111111111111111111111110000000000000000000000000001110000001111111111111111111110001111111111111111111111100011111111111111111111111111111111111100000000011111111111111111111111000000001111111111111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111011100011111111111111111111111110000000000000000000000000001111111111111111111111111111110001111111111111111111111100011111111111111111111111111111111111100000000111111111111111111111111000000001111111111111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111100011111111111111111111111110000000000000000000000000001111111111111111111111111111110001111111111111111111111100011111111111111111111111111111111111100000000111111111111111111111111111001111111111111111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111100000111111111111111111111111111111111111111100000000001111111111111111111111111111110001111111111111111111111100011111111111111111111111111111111111111111111111111111111111111111111111001111111111111111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111011000000000000011111111111111111111111111111100000000011111111111111111111111111111110001111111111111111111111100011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111111000001111111111111111111111111111111111111110001111111111111111100000001111111111110001111111111111111111111100000111111111111111111111111111111111111111111111111111111111111111111111111111111100111111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111111000001111111111111111111111111111111111111111111111111111111111000000001111111111110001111111111111111111111100000111111111111111111111111111111111111111111111111111111111111111111111111111111100011111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000011111111111111100001001011111111111111111111111111111111111111111111111111111111000000001111111111110001111111111111111111111100000111111111111111111111111111111111111111111111111111111111111111111111111111111100011111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000000111111111111110000000111111111111111111111111111111111111111111111111111111111000000001111111111110001111111111111111111111100000111111111111111111111111111111111111111111111111111111111111111111111111111100000000111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000000111111111111111100000111111111111111111111111111111111111111111111111111111111000000001111111111110001111111111111111111111100000111111111111111111111111111111111111111111111111111111111111111111111111111100000000111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000000111111111111111100000000000000001111111111111111111111111111110000000011111111000000001111111111110001111111111111111111111100000111111111111111111111111111111111111111111111111111111111111111111111111111100000000111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000000011111111111111100001111111111111111111111111111111111111111110000000011111111000000111111111111110001111111111111111111111100000111111111111111111111111111111111111111111111111111111111111111111111111111100000000111111111111000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000111111111111111000111111111111111111111111111111111111111110000000011111111000000111111111110001111111111111111111111111100000111111111111111111111111111111111111111111111111111111111111111111111111111100000000111111111100000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000111111111111111000000000011111111111111111111111111111111110000000011111111111111111111111110001111111111111111111111111100000111111111111111111111111111111111111111111111111111111111111111111000111111111100011111111111100000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000111111111111111000000001111111111111111111111111111111111110000000011111111111111111111111110001111111111111111111111111100000111111111111111111111111111111111111111111111111111111111111111111000111111111100111111111111100000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000111111111111111111111111111111111111111111111111111111111110000001111111111111111111111111110001111111111111111111111111111100111111111111111111111111111111111111111111111111111111111111111100000001111111111111111111111100000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000111111111111111111000000000000111111111111111111111111111110000001111111111111111111111111110001111111111111111111111111111100111111111111111111111111111111111111111111111111111111111111111100000001111111111111111111111100000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000111111111111111111000000111111111111111111111111111111111110000011111111111111111111111111110001111111111111111111111111111100111111111111111111111111111111111111111111111111111111111111111000000001111111111111111111111100000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000001111111111111111111111111111100111111111111111111111111111111111111111111111111111111110001111111111111111111111111111111111000111111111111111111111111111111111111111111111111111111111111000000001111111111111111111100000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000001111111111111111111100000000000111111111111111111111111111111111110000000001111111111110001111111111111111111111111111111111000111111111111111111111111111111111111111111111111111111111111000000001111111111111111111100000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111110000000001111111111110001111111111111111111111111111111111100001111111111111111111111111111111111111111111111111111111111111000111111111111111111111100000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000001111111111111111111111111001111111111111111111111111111111111110000000001111111110001111111111111111111111111111111111111111000011111111111111111111111111111111111111111111111111111111111000111111111111111111110000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000011111111111111111110000000111110111111111111111111111111111110000000001111111110001111111111111111111111111111111111111111000011111111111111111111111111111111111111111111111111111111111101111111111111111111110000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111110000000001111111110001111111111111111111111111111111111111111000011111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000011111111111111111111111101111111100111111111111111111111111110000001111111111000001111111111111111111111111111111111111111111100011111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000011111111111111111111111000000000000011111111100111111111111110000001111111111000001111111111111111111111111111111111111111111110011111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000010000011111111111111111111111111111111111111100111111111111111111111111111111000000000001111111111111111111111111111111111110000001111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111111111110000000000011111111111111111111111111111111111000000000001111111111111111111111111111111111110000000111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000011111111111111111111111110000000000011111111111111111111111111111111111000000000001111111111111111111111111111111111110000000111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111110000100000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111110000000100000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111110000000010000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000111000001100000000111111111111111111111111111111111111111111111111111111111111110000110001110000000000000000000000000000000000000011000111111111111111111111111111111111111111111111111111111111111011111000000000110000111000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000000111000011100000001111100000000111110000011111111111111111111111000001111111111110001110001110000000000000000000000000000000000000111000111111111110000011111111111111111111111111111111111100001000111111100000000111000111000000000000000000000000000000000000000000",
            "000000000000000000000000000000000000001111000011100000001111100000000111110000011111111111111111111111000001111111111110001110001110000000000000000000000000000000000000111000111111111110000011111111111111111111111111111111111100001000111111100000000111000111000000000000000000000000000000000000000000",
            "000000000000000000000011110111111011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100111100111100000111100111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110011111011110000000000000000000000000",
            "000000000000000000000011110111111011111101111110111111111111111111111111111111111111111111111111111111111111111111111111111011111011111100111100111100000111100111111111101111111111111111111111111111111111111111111111111111111111111111111111111111111101111101111111011111011110000000000000000000000000",
            "000000000000000000000011110111111011111101111110111111111111111111111111111111111111111111111111111111111111111111111111111011111011111100111100111100000111100111111111101111111111111111111111111111111111111111111111111111111111111111111111111111111101111101111110011111011110000000000000000000000000",
            "000000000000000000000000000000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000000000000000000000000000000000000100111111111000000000000000000001100000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000");
                       
photovisible <= (vpos > 130) and (vpos < 392) and (hpos < 300) and (photo(vpos-131)(hpos) = '1');


song <= (   "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111110000000011111111111000000001111111111100000000011111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111110000000011111111111000000001111111111100000000011111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010110000000110100001011000000011010000101100000001101000000011000000110100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000001111110011111000000011111000111110000001111100011111000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011110000000111100001111000000011111000111110000001101100011011000000110110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000000011111000000011111000111110000001111100011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000000011111000000111111000111110000001111100011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010110000000000000001011000000011110000111100000001101100011011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111110011111000000011111000111110000001111100011111000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111110011111100000011111000111110000001111100011111000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111100001011000000011110000111100000001101100011011000000110110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110011111000000011111000111110000001111100011111000000111110001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110011111000000011111000111110000001111100011111000000111110001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111100001011000000011110000111100000001101100011011000000110110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000001111110011111000000011111000111110000001111100011111000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000111110011111000000011111000111110000001111100011111000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110110100110000000011011011011000000111100000001101100000011010010110000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111110000000011111111111000000111110000001111100000011111111110000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111110000000011011111111000000111110000001111100000011111111110000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
                        
songvisible <= (vpos>133) and (vpos<153) and (hpos>299) and (song(vpos-134)(hpos-300) = '1');


thunderstruck<= ("0000000000000000000000000000000000000000000000000011011010110110110001101000000010110000101100000011011000000110101101100000011010110110110000001011011011010000101101101011000000000110111101100000011010110110110100001011011011010000001101100000011011000000111101101100000011010000000101100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000011111111111111110011111100000111111001111100000011111000000111111111100000011111111111110000011111111111111001111111111111100000000111111111100000011111111111111110011111111111111000001111100000011111000001111111111100000111111000001111110000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000011011010110110100001101000000010110000101100000011011000000110101101100000011010110110110000001011011011010000101101101011000000000110100101100000011010110110100100001011011011010000001101100000011011000000110101101100000011010000000101100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000111110000000001111000000111110001111100000011111000111110000001111100011111000000111110011111000000000001111100000011111000111110000001111100000000111110000000011111000000111110001111100000011111000111110000001111100011110000001111100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000111110000000011111100000111110001111100000011111000111110000001111100011111000000111110011111000000000001111100000011111000111110000001111100000000111110000000011111000000111110001111100000011111000111110000001111100111111000001111100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000010110000000001101000000010110000101100000011011000110110000001101100011010000000110100001011000000000000101100000011011000110110000000000000000000110110000000001011000000010110001101100000011011000110100000000000000011010000000101100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000111110000000001111100000111110001111100000011111000111110000001111100011111000000111110011111000000000001111100000011111000111110000000000000000000111110000000011111000000111110001111100000011111000111110000000000000011111000001111100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000111110000000001111000000111110001111100000011111000111110000001111100011111000000111110011111000000000001111100000011111000111110000000000000000000111110000000011111000000111110001111100000011111000111110000000000000011110000001111100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000010110000000001101001010010110000101100000011011000110110000001101100011010000000110100001011000010000000101100001011000000110110100100001000000000110110000000001011000010010000001101100000011011000110100000000000000011010010100100000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000111110000000011111111111111111001111100000011111000111110000001111100011111000001111110011111111111000001111111111111100000111111111111111100000000111110000000011111111111111000001111100000011111000111110000000000000111111111111110000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000111110000000001111011111011110001101100000011011000111110000001101100011111000000111100001111111011000001101111101111000000111110111101101100000000111110000000001111111011110000001101100000011111000110110000000000000011110111110110000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000011110000000001111000000011110001101100000011011000110110000001101100011110000000111100001111000000000001101100000011011000000000000001101100000000110110000000001111000000110110001101100000011011000110110000000000000011110000000111100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000111110000000011111100000111111001111100000011111000111110000001111100011111000001111110011111000000000001111100000011111000000000000001111100000000111110000000011111000000111110001111100000011111000111110000000000000111111000001111110000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000010110000000001101000000010110000101100000011011000110110000001101100011010000000110100001011000000000000101100000011011000000000000001101100000000110110000000001011000000010110001101100000011011000110100000000000000011010000000101100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000111110000000001111000000111110001111100000011111000111110000001111100011111000000111110011111000000000001111100000011111000111110000001111100000000111110000000011111000000111110001111100000011111000111110000001111100011110000001111100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000111110000000001111100000111110001111100000011111000111110000001111100011111000000111110011111000000000001111100000011111000111110000001111100000000111110000000011111000000111110001111100000011111000111110000001111100011111000001111100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000010110000000001101000000010110000001100000011000000110110000001101100011010000000110000001011000000000000101100000011011000000110000001100000000000110110000000001011000000010110000001100000011000000000100000001100000011010000000101100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000111110000000001111100000111110000001111111111000000111110000001111100011111111111110000011111111111111001111100000011111000000111111111100000000000111110000000011111000000111110000001111111111000000001111111111100000011111000001111100000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000111110000000001111100000111110000001111111111000000111110000001111100011111111111110000011111111111111001111100000011111000000111111111100000000000111110000000011111000000111110000001111111111000000000111111111100000011111000001111100000000000000000000000000000000000000000000000000000");                                
thunderstruckvisible <= (vpos > 172) and (vpos < 192) and (hpos > 299) and (thunderstruck(vpos-173)(hpos-300) = '1') and (select_song = '0');


smoke<=    ("0000000000001101011011000000000101101100001011011010000000001101101011000000110110000001101100011010110110110000000000000001101111011000000000101101101100000000000000011010110110110100001011000000010110001101101101011000000000000010110000000101100000011011000000110111101100000011011110110110100001011011011010000101101101101000000000000000",
            "0000000000001111111111000000001111111100011111111111000000001111111111100000111110000001111100011111111111110000000000000001111111111000000001111111111100000000000000011111111111111110011111000000111110001111111111111000000000000111110000001111100000011111000000111111111100000011111111111111110011111111111111001111111111111100000000000000",
            "0000000000001101011011000000000101101100001011011010000000001101101011000000110110000001101100011010110110110000000000000001101001011000000000101101101100000000000000011010110110100100001011000000010110001101101101011000000000000010110000000101100000011011000000110100101100000011010110110110100001011011011010000101101101101000000000000000",
            "0000000001111100000011111000111110000001111100000011110001111100000011111000111110000001111100011111000000000000000000001111100000011111000111110000001111100000000000000000111110000000011111000000111110001111100000000000000000000111110000001111100000011111000111110000001111100000000111110000000011111000000000001111100000011111000000000000",
            "0000000001111100000011111000111110000001111100000111111001111100000011111000111110000001111100011111000000000000000000001111100000011111000111110000001111100000000000000000111110000000011111000000111110001111100000000000000000000111110000001111100000011111000111110000001111100000000111110000000011111000000000001111100000011111000000000000",
            "0000000001101100000000000000110100000001101000000010110000101100000011011000110110000001101100011010000000000000000000001101100000011011000110100000001101000000000000000000110110000000001011000000010110001101100000000000000000000010110000000101100000001011000110110000001101100000000010110000000001011000000000000101100000001011000000000000",
            "0000000001111100000000000000111110000001111100000111110001111100000011111000111110000001111100011111000000000000000000001111100000011111000111110000001111100000000000000000111110000000011111000000111110001111100000000000000000000111110000001111100000011111000111110000001111100000000111110000000011111000000000001111100000011111000000000000",
            "0000000001111100000000000000111110000001111100000111110001111100000011111000111110000001111100011111000000000000000000001111100000011111000111110000001111100000000000000000111110000000011111000000111110001111100000000000000000000111110000001111100000011111000111110000001111100000000111110000000011111000000000001111100000011111000000000000",
            "0000000001101101001000010000110100000001101000000010110000101100000011011000110110100101100000011010010010000000000000001101100000011011000110100000001101000000000000000000110110000000001011000010010110001101101001000000000000000010110000000101100000001011000110110100101101100000000010110000000001011000010000000101100001001000000000000000",
            "0000000001111111111111111000111110000011111100000111111001111100000011111000111111111111100000011111111110000000000000001111100000011111000111110000011111100000000000000000111110000000011111111111111110001111111111100000000000000111110000001111100000011111000111111111111111100000000111110000000011111111111000001111111111111100000000000000",
            "0000000001111111111011011000111110000001111000000011110001101100000011011000111111111111100000011111110110000000000000001111100000011111000111110000001111000000000000000000111110000000001111111011111110001101101111000000000000000011110000001111100000011011000111110111101111100000000110110000000001111111011000000111111101111000000000000000",
            "0000000000000000000011011000111100000001111000000011110001101100000011011000110110000001101100011110000000000000000000001101100000011011000111100000001111000000000000000000110110000000001111000000110110001101100000000000000000000011110000001101100000011011000110110000001101100000000110110000000001111000000000000111100000011011000000000000",
            "0000000000000000000011111000111110000011111100000111111001111100000011111000111110000001111100011111000000000000000000001111100000011111000111110000011111100000000000000000111110000000011111000000111110001111100000000000000000000111110000001111100000011111000111110000001111100000000111110000000011111000000000001111100000011111000000000000",
            "0000000000000000000011011000110100000001101000000010110000101100000011011000110110000001101100011010000000000000000000001101100000011011000110100000001101000000000000000000110110000000001011000000010110001101100000000000000000000010110000000101100000001011000110110000001101100000000010110000000001011000000000000101100000001011000000000000",
            "0000000001111100000011111000111110000001111100000011110001111100000011111000111110000001111100011111000000000000000000001111100000011111000111110000001111100000000000000000111110000000011111000000111110001111100000000000000000000111110000001111100000011111000111110000001111100000000111110000000011111000000000001111100000011111000000000000",
            "0000000001111100000011111000111110000001111100000111110001111100000011111000111110000001111100011111000000000000000000001111100000011111000111110000001111100000000000000000111110000000011111000000111110001111100000000000000000000111110000001111100000011111000111110000001111100000000111110000000011111000000000001111100000011111000000000000",
            "0000000000001100000011000000110100000001101000000010110000001100000011000000110110000001101100011010000000000000000000000001100000011000000110100000001101000000000000000000110110000000001011000000010110001101100000000000000000000000110000000000000000001000000110110000001101100000000010110000000001011000000000000101100000001011000000000000",
            "0000000000001111111111000000111110000001111100000111110000001111111111000000111110000001111100011111111111110000000000000001111111111000000111110000001111100000000000000000111110000000011111000000111110001111111111111000000000000000111111110000001111111100000111110000001111100000000111110000000011111111111111001111100000011111000000000000",
            "0000000000001111111111000000111110000001111100000111110000001111111111000000111110000001111100011111111111110000000000000001111111111000000111110000001111100000000000000000111110000000011111000000111110001111111111111000000000000000111111110000001111111000000111110000001111100000000111110000000011111111111111001111100000011111000000000000");                    
smokevisible <= (vpos > 172) and (vpos < 192) and (hpos > 299) and (smoke(vpos-173)(hpos-300) = '1') and (select_song = '1');


difficulty_2 <=("0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111000000111111111110001111111111111000111111111111110011111111111000000111111111110000011111000000111111001111110000000000011111111111111110001111100000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111000000111111111110001111111111111000111111111111100001111111111000000111111111110000011111000000111111000111110000000000011111111111111110001111100000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100000011011000000110110000001101100000000000110110000000000000001011000000010110000001100100011011000000011010000111100000000000000000011110000000001101100000011011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000000111110000001111100000000000111110000000000000011111000000111110000001111100011111000000111111001111110000000000000000111111000000001111100000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100000011011000000110110000001101100000000000110110000000000000011011000000110110000001111100011011000000011110000111100000000000000000011110000000001101100000011011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000000111110000001111100000000000111110000000000000011111000000111110000000000000011111000000011111000111110000000000000000111110000000001111100000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000000111110000001111100000000000111110000000000000011111000000111110000000000000011111000000111111001111110000000000000000111111000000001111100000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100000011011000000110110000001101000000000000110110000000000000001011000000110110000000000000001011000000011010000110100000000000000000011010000000001101100000011011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000000111110000001111111111000000111111111110000000011111000000111110000000000000011111000000111111001111110000000000000000111110000000000001111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000000111110000001111111111000000111111111110000000011111000000111110000000000000011111000000111111001111110000000000000000111111000000000001111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100000011011000000110110000001101100000000000110110000000000000001011000000110110000000000000011011000000011010000111100000000000000000011110000000000000001101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000000111110000001111100000000000111110000000000000011111000000111110000000000000011111000000111111001111110000000000000000111110000000000000001111100000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000000111110000001111100000000000111110000000000000011111000000111110000000000000011111000000111111001111110000000000000000111111000000000000001111100000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100000011011000000110110000001101100000000000110110000000000000011011000000110110000000000000011011000000011010000111100000000000000000011110000000000000001101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000000111110000001111100000000000111110000000000000011111000000111110000001111100011111000000111111001111110000000000000000111111000000000000001111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000000111110000001111100000000000111110000000000000011111000000111110000001111100011111000000111111001111110000000000000000111110000000000000001111100000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001101101001011000000010110110100001101100000000000110110000000000001011011011000000110100101100000000011011011011000000111110101101100000000011010000000000000001101000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111000000111111111110001111100000000000111110000000000011111111111000000111111111110000000011111111111000001111111111111100000000111111000000000000001111100000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111000000111110111110001111100000000000111110000000000001111111111000000110111111110000000011111111111000000111111111111100000000111110000000000000001111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
                                
difficultyvisible <= (vpos > 247) and (vpos < 267) and (hpos > 299) and (difficulty_2(vpos-248)(hpos-300) = '1');


easy <=("0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111110000011111111111000000001111111111100000011111000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111100000011111111111000000001111111111100000011111000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110110000000000001011000000011010000100110000001101100011011000000110110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000011111100000011111000111110000001111100011111000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110110000000000001111000000011111000111110000001101100011111000000110110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000001111100000011111000111110000000000000011111000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000011111100000011111000111110000000000000011111000000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110110000000000001111000000011011000111110000000000000011011000000110110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111110000001111111111111111000111111111111111100000011111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111110000011111111111111111000111111111111111100000011111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110110000000000001111000000011011000000000000001101100000000011010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000001111100000011111000000000000001111100000000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000001111100000011111000000000000001111100000000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110110000000000001111000000011111000000000000001101100000000011010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000011111100000011111000111110000001111100000000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000011111100000011111000111110000001111100000000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110110100101100001111000000011011000000110100101100000000000011010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111110011111100000011111000001111111111100000000000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111100001111100000011111000000111111111100000000000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
        
easyvisible <= (vpos > 286) and (vpos < 306) and (hpos > 299) and (easy(vpos-287)(hpos-300) = '1') and (difficulty = '0');


hard <=("0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000000111111111100000011111111111111000001111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000000111111111100000011111111111111000001111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101000000011011000110110000001101000011011000000110010001111100000001101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000111110000001111100011111000000111110001111100000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100000011111000110110000001111100011011000000111110001111100000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000111110000001111100011111000000111110001111100000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000111110000001111100011111000000111110001111100000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101000000011011000110110000001101100011011000000011110001111100000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111000111111111111111100011111111111111000001111100000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111000111111111111111100011111111111111000001111100000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100000011011000110110000001101100011011000000110000001111100000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000111110000001111100011111000000111110001111100000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000111110000001111100011111000000111110001111100000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101000000011011000110110000001101100011011000000011110001111100000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000111110000001111100011111000000111110001111100000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000111110000001111100011111000000111110001111100000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101000000011011000110110000001101100011011000000011110001101101101101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000111110000001111100011111000000111110001111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000011111000111110000001111100011111000000111110001111111101111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
               
hardvisible <= (vpos > 286) and (vpos < 306) and (hpos > 299) and (hard(vpos-287)(hpos-300) = '1') and (difficulty = '1');


startswitch <=( "0000000000000000000000000000000000001111111111000000111110000001111100000011111100111111111110001111111111111111000000111111111110000001111100000011111000000000000111111111111111110000011111111111000000000000000000111111111110000011111111111111111000001111111111100000011111111111110000001111111111111111000000000000000000000000000000000000",
                "0000000000000000000000000000000000001111111111000000111110000001111100000011111100011111111110001111111111111111000000111111111110000001111100000011111000000000000111111111111111100000011111111111000000000000000000111111111110000011111111111111111000001111111111100000011111111111110000001111111111111111000000000000000000000000000000000000",
                "0000000000000000000000000000000000001100000011011000110110000001101100000001101000000111110000000000001101100000000010110000000110100001111000000011011000000000000000000110110000000001011000000011010000000000000010110000000100100000000011011000000000101110000001101000011011000000110110000000001111000000000000000000000000000000000000000000",
                "0000000000000000000000000000000001111100000011111000111110000001111100000011111100000111110000000000001111100000000111110000001111110011111100000011111000000000000000000111110000000011111100000011111000000000000111110000001111110000000011111000000000111110000001111100011111000000111110000000001111100000000000000000000000000000000000000000",
                "0000000000000000000000000000000001111100000011011000110110000001101100000001111000000111110000000000001101100000000111110000000111100001111000000011111000000000000000000111110000000001111000000011111000000000000111110000000111100000000011011000000000111110000001101100011011000000110110000000001111100000000000000000000000000000000000000000",
                "0000000000000000000000000000000001111100000000000000111110000001111100000011111100000111110000000000001111100000000111110000000000000001111100000011111000000000000000000111110000000011111100000011111000000000000111110000000000000000000011111000000000111110000001111100011111000000111110000000001111100000000000000000000000000000000000000000",
                "0000000000000000000000000000000001111100000000000000111110000001111100000011111100000111110000000000001111100000000111110000000000000011111100000011111000000000000000000111110000000011111100000011111000000000000111110000000000000000000011111000000000111110000001111100011111000000111110000000001111100000000000000000000000000000000000000000",
                "0000000000000000000000000000000001101100000000000000110110000001101100000001101000000111110000000000001101100000000011110000000000000001111000000011011000000000000000000110110000000001111000000011010000000000000110110000000000000000000011011000000000111100000001101100011011000000110110000000001101000000000000000000000000000000000000000000",
                "0000000000000000000000000000000001111111111111111000111110000001111100000011111100000111110000000000001111100000000111110000000000000001111111111111111000000000000000000111110000000011111100000011111000000000000111111111111111100000000011111000000000111111111111111100011111111111110000000000001111100000000000000000000000000000000000000000",
                "0000000000000000000000000000000001111111111111111000111110000001111100000011111100000111110000000000001111100000000111110000000000000011111111111111111000000000000000000111110000000011111100000011111000000000000111111111111111110000000011111000000000111111111111111100011111111111110000000000001111100000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000011011000110110000001101100000001101000000111110000000000001101100000000011110000000000000001111000000011011000000000000000000110110000000001111000000011010000000000000000000000000101100000000011011000000000111110000001101100011011000000110000000000001101000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000011111000111110000001111100000011111100000111110000000000001111100000000111110000000000000001111100000011111000000000000000000111110000000011111100000011111000000000000000000000001111100000000011111000000000111110000001111100011111000000111110000000001111100000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000011111000111110000001111100000011111100000111110000000000001111100000000111110000000000000001111100000011111000000000000000000111110000000011111100000011111000000000000000000000001111100000000011111000000000111110000001111100011111000000111110000000001111100000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000000011011000110110000001101100000001101000000111110000000000001101100000000011110000000000000001111000000011011000000000000000000110110000000001111000000011010000000000000000000000000101100000000011011000000000111110000001101100011011000000110110000000001101000000000000000000000000000000000000000000",
                "0000000000000000000000000000000001111100000011111000111110000001111100000011111100000111110000000000001111100000000111110000001111110001111100000011111000000000000000000111110000000011111100000011111000000000000111110000001111110000000011111000000000111110000001111100011111000000111110000000001111100000000000000000000000000000000000000000",
                "0000000000000000000000000000000001111100000011111000111110000001111100000011111100000111110000000000001111100000000111110000000111110001111100000011111000000000000000000111110000000011111100000011111000000000000111110000001111100000000011111000000000111110000001111100011111000000111110000000001111100000000000000000000000000000000000000000",
                "0000000000000000000000000000000000001101001011000000000110100100000001001101100000010111110110000000001101100000000000110110100110000001111000000011011000000000000000000110110000000000011101011011000000000000000000110110100100000000000011011000000000111100000001101100011011000000110110000000001101000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000001111111111000000000111111110000001111111100000111111111110000000001111100000000000111111111110000011111100000011111000000000000000000111110000000000011111111111000000000000000000111111111110000000000011111000000000111110000001111100011111000000111110000000001111100000000000000000000000000000000000000000",
                "0000000000000000000000000000000000001111111111000000000111111110000001111111100000011111111110000000001111100000000000111111111110000001111100000011111000000000000000000111110000000000011111111011000000000000000000110111111110000000000011111000000000111110000001111100011111000000111110000000001111100000000000000000000000000000000000000000");
                                
startswitchvisible <= (vpos > 366) and (vpos<386) and (hpos>299) and (startswitch(vpos-367)(hpos-300)='1');

fatihmehmet <=( "000000000000111111111000000000000000000111100000011110000111100000000000000000001111110011111111000000000000000000111100000000000000000000000000000000000000000000000011110000110000000000000000000001110000011110000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000",
                "000000000000111111111000000000000000000011100000011110000111100000000000000000001111110011111111000000000000000000111100000000000000000000000000000000000000000000000011110000110000000000000000000001110000011110000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000",
                "000000000000111000000000000000000000000111100000000000000111100000000000000000111100001111000011110000000000000000111100000000000000000000000000000000000000000000000011110000110000000000000000000001111000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "000000000000111000000000000000000000000111100000000000000111100000000000000000111100001111000001110000000000000000111100000000000000000000000000000000000000000000000011110000110000000000000000000001111000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                "000000000000111000000000001111111110011111111001111111100111111111100000000000111100001111000001110000111111110000111111111100000011111100001111110000001111111100001111111100000000111111110000000001110000011110000111111110000001111111100000011111111001111111000001111111000000011111110000000000000000",
                "000000000000111000000000001111111110001111111001111111100111111111100000000000111100001111000001110000111111110000111111111100000011111100000111110000001111111100001111111100000000111111110000000001110000011110000111111110000001111111100000011111111001111111000001111111000000011111110000000000000000",
                "000000000000111111100000111000001110000111100000011110000111100001111000000000111100001111000001110011110000111100111100001111001111000011110000111100111100001111000011110000000011110000000000000001111000011110011100000111100111100001111001111000000000011100000111000001110001110000011100000000000000",
                "000000000000111111100001111000001110000111100000011110000111100001111000000000111100001111000001110011110000111100111100001111001111000011110000111100111100000111000011110000000011110000000000000001111000011110011100000111100111100001111001111000000000011100000111000001110001110000011100000000000000",
                "000000000000111000000000111000001110000011100000011110000111100001111000000000111100001111000001110011111111111100111100001111001111000011110000011100111111111111000011110000000011111111110000000001110000011110011111111111100111100001111001111111111000011100000111000001110001110000011100000000000000",
                "000000000000111000000001111000001110000111100000011110000111100001111000000000111100001111000001110011111111111100111100001111001111000011110000111100111111111111000011110000000011111111110000000001111000011110011111111111100111100001111001111111111000011100000111000001110001110000011100000000000000",
                "000000000000111000000000111000001110000011100000011110000111100001111000000000111100001111000001110011110000000000111100001111001111000011110000011100111100000000000011110000000000000011110000000000011111111000011100000000000111000000000000000001111000011100000111000001110001110000011100000000000000",
                "000000000000111000000001111000001110000111100000011110000111100001111000000000111100001111000001110011110000000000111100001111001111000011110000111100111100000000000011110000000000000011110000000000011111111000011100000000000111100000000000000001111000011100000111000001110001110000011100000000000000",
                "000000000000111000000000011111111110000111100001111111100111100001111000000000111100001111000001110000111111110000111100001111001111000011110000111100001111111100000011110000000011111111000000000000000111100000000111111100000111100000000001111111100001111111000001111111000001110000011100000000000000",
                "000000000000111000000000011111111110000111100001111111100111100001111000000000111100001111000011110000111111110000111100001111001111000011110000111100001111111100000011110000000011111111000000000000000111100000000111111110000111100000000001111111100001111111100001111111000001110000011100000000000000");
                         
fatihmehmetvisible<= (vpos>440) and (vpos<456) and (hpos<300) and (fatihmehmet(vpos-441)(hpos)='1');

lightning <=(   "0000000000000000000000000000000000001111111111110000010000000000000000000000000000000",
                "0000000000000000000000000000000000001111111111110000000000000000000000000000000000000",
                "0000000000000000000000000000000000001111111111110000000000000000000000000000000000000",
                "0000000000000000000000000000001000001111111111110000000000001000000001000000000000000",
                "0000000000000000000000001000000000001111111111110000000000001000000000000000000000000",
                "0000000000000000000100001000010000001111111111110000010000001000000000000000000000000",
                "0000000000000000000100001000010000001111111111110000010000001000001000000000000000000",
                "0000000000000000000000001000000000001111111111110000000000000000001000000000000000000",
                "0000000000000000000000001000000000001111111111110000000000000000000000000000000000000",
                "0000000000000000000000001000000000001111111111110000010000100000010000000000000000000",
                "0000000000000000000000001000000000001111111111110000010000100001100000000000000000000",
                "0000000000000000000000001000000000001111111111110000010000100010000000000000000000000",
                "0000000000000000000000001000010000001111111111110000010000000100000000000000000000000",
                "0000000000000001000000001000000000001111111111110000010000001100000000000000000000000",
                "0000000000000000000000001000000000001111111111110000000000011100000000000000000000000",
                "0000000000000000000001110000000000001111111111110000000000110000000000000000000000000",
                "0000000000000000000011100000000000001111111111110000000000100000000000000000000000000",
                "0000000000000000000011100000000000001111111111110000000000100000000000000000000000000",
                "0000000000000000000001110000010000001111111111110000000000100000000000000000000000000",
                "0000000000000000000000110000010000001111111111110000001000100000000000000000000000000",
                "0000000000000000000000011000010000001111111111110000000000100000000000000000000000000",
                "0000000000000000000000001000000000011111111111100000000000000000000000000000000000000",
                "0000000000000000000000001000000000111111111111000000000011000010000000000000000000000",
                "0000000000000000000000001000000001111111111110000000011100000100000001000000000000000",
                "0000000000000000000000011000000011111111111110000000111000001000001000000000000000000",
                "0000000000000000000000110000000011111111111100000001100000000000000000000000000000000",
                "0000000000000000000001110000000011111111111000000011000000000000010000000000000000000",
                "0000000000000000000001110000000111111111110000000110000000000011000000000000000000000",
                "0000000000000000000001110000000111111111100000001000000000000111000000000000000000000",
                "0000000000000000000001000000000111111111000000010000000001111110000000000000000000000",
                "0000000000000000000001000000001111111110000000100000001111111100000000000000000000000",
                "0000000000000000000011000000011111111110000001100000001111111000000000000000000000000",
                "0000000000000000000011000000111111111111111111111111111111110000000000000000000000000",
                "0000000000000000000100000001111111111111111111111111111111100000010000000000000000000",
                "0000000000000000001100000011111111111111111111111111111111000000100000000000000000000",
                "0000000000000000000000000111111111111111111111111111111110000000000000000000000000000",
                "0000000000000000000000000111111111111111111111111111111100000000000000000000000000000",
                "0000000000000000100000001111111000000000011111111111111000000000000000000000000000000",
                "0000000000000001000000001110000000000000001111111111110000000010000000000000000000000",
                "0000000000000000000000011110000001000000001111111111100000100000000000000000000000000",
                "0000000000000000000000111100000001000000011111111111000000100000000000000000000000000",
                "0000000000000000000001000000000001000000111111111111000000100000000000000000000000000",
                "0000000000000000000010000000000001000001111111111110000000010000000000000000000000000",
                "0000000000000000000100000000000001000011111111111100000000011000100000000000000000000",
                "0000000000000000010000000000000011000111111111111000000000011000000000000000000000000",
                "0000000000000000000000001000000110000111111111110000010000011000000000000000000000000",
                "0000000000000000000000001000001100000111111111100000010000000000100000000000000000000",
                "0000000000000000000000001000001000001111111111100000010000100000000000000000000000000",
                "0000000000000000000000010000011000011111111111000000010000100000000000000010000000000",
                "0000000000000000000000110001110000111111111110000000010000100000000000000000000000000",
                "0000000000000000000000100001100001111111111100000000000000100000000000000000000000000",
                "0000000000000000000010000001000011111111111000000001000000100000000000000000000000000",
                "0000000000000000000100000000000011111111111000000010000000000000000000000000000000000",
                "0000000000000000000000000000000011111111110000000000000000000000000100000000000000000",
                "0000000000000000000000001000000111111111100000001000000100000000001000000000000000000",
                "0000000000000000000000000000001111111111000000000000001000000000010000000000000000000",
                "0000000000000000000000000000011111111110000000000000000000000111100000000000000000000",
                "0000000000000000000000100000011111111100000000000000000000011111000000000000000000000",
                "0000000000000000000001000000111111111111111111111111111111111111000000000000000000000",
                "0000000000000000000010000001111111111111111111111111111111111100000000000000000000000",
                "0000000000000000000100000001111111111111111111111111111111111000000000000000000000000",
                "0000000000000000000000000011111111111111111111111111111111110000000000000000000000000",
                "0000000000000000000000000111111111111111111111111111111111100000000000000000000000000",
                "0000000000000000000000001111111111111111111111111111111111000000000000000000000000000",
                "0000000000000000000000001111000000000000000000111111111111000000001000000000000000000",
                "0000000000000000000000011100000000010000000001111111111110001000000000000000000000000",
                "0000000000000000000000011000000000010000000011111111111100011000000000000000000000000",
                "0000000000000000000001100000000000110000000011111111111000011000010000000000000000000",
                "0000000000000000000001000000000001100000000011111111111000011000000000000000000000000",
                "0000000000000000000010000000000111000000001111111111110000011000100000000000000000000",
                "0000000000000000000000000000000110000000011111111111100000011000000000000000000000000",
                "0000000000000000100000000000001100000000011111111111000000011000000000000000000000000",
                "0000000000000000000000000000011000000000011111111110000000011000000000000000000000000",
                "0000000000000000000000000000110000000000011111111100000000011000010000000000000000000",
                "0000000000000100000000000001000000000000111111111100000000011000001000000000000000000",
                "0000000000001000000000000011000000000001111111111000000000011000000000000000000000000",
                "0000000000000000000000000110000000000011111111110000000000011100000000000000000000000",
                "0000000000000000000000000110000000000111111111100000000000001100000000000000000000000",
                "0000000000000000000000000110000000001111111111000000000011000110000000000000000000000",
                "0000000000000000000000001110000000001111111110000000001110000111000000000000000000000",
                "0000000000000000000000010000000000011111111110000000111100000001100000000000000000000",
                "0000000000000000000000000000000000111111111111111111111100000000010000000000000000000",
                "0000000000000000000001000000000000111111111111111111111000000000010000000000000000000",
                "0000000000000000000011000000000001111111111111111111110000000000010000000000000000000",
                "0000000000000000011100000000000011111111111111111111100000000000001000000000000000000",
                "0000000000000000011000000000000111111111111111111111000001000000001000000000000000000",
                "0000000000000000010000000000000111111111011111111110000001100000000000000000000000000",
                "0000000000000000010000000000000111100000011111111100000001100000000000000000000000000",
                "0000000000000000010000000000001100000000111111111100000000011000100000000000000000000",
                "0000000000000000010000000000011000000001111111111001000000011000000000000000000000000",
                "0000000000000000010000000000110000000001111111110001100000011000000000000000000000000",
                "0000000000000000100000000001100000000001111111110000110000011000001000000000000000000",
                "0000000000000001000000000011000000000111111111100000111000011000000000000000000000000",
                "0000000000000000000000000110000000001111111111000000001000011000000000000000000000000",
                "0000000000000000000000001110000000001111111110000000001000011000000000000000000000000",
                "0000000000000000000000010000000000011111111110000000001000011000000000000000000000000",
                "0000000000000000000000000000000000111111111110000000001000011000000000000000000000000",
                "0000000000000000000001000000000001111111111100000000001000001100000000000000000000000",
                "0000000000000000000010000000000011111111111100000000001000000011000000000000000000000",
                "0000000000000000000100000000000111111111111111111100000000000000100000000000000000000",
                "0000000000000000000000000000000111110011111111111100000100000000100000000000000000000",
                "0000000000000000010000000000001111100001111111111110000000000000100000000000000000000",
                "0000000000000000010000000000001000000001111111111011000000000000100000000000000000000",
                "0000000000000000010000000000010000000001111111111001100000100000100000000000000000000",
                "0000000000000000000000000001000001000001111111110001110000100000010000000000000000000",
                "0000000000000000000000000001000001000001111111110000111000100000000000000000000000000",
                "0000000000000001000000000010000001000001111111110000011000100000000000000000000000000",
                "0000000000000000000000000000000010000001111111110000011000000000000000000000000000000",
                "0000000000001000000000000000000110000001111111100000011000000000000000000000000000000",
                "0000000000000000000000000000000100000001111111100000011000000000000000000000000000000",
                "0000000000000000000010000000001100000001111111100000001000000010000000000000000000000",
                "0000000000000000000000000000011100000001111111000000001000000000000000000000000000000",
                "0000000000000000000000000000110000000001111110000000000110000000000000000000000000000",
                "0000000000000000000000000001100000000001111110000000000011000000000000000000000000000",
                "0000000000000000000000000011000000000001111110000000000000100000000000000000000000000",
                "0000000000000000000000000111000000000001111111000000000000100000000000000000000000000",
                "0000000000000000000000000110000000000001111110000000000000100000000000000000000000000",
                "0000000000000000000000000110000000000001111110000000000000100000000000000000000000000",
                "0000000000000000000000000110000001000001111100000100000000100000000000000000000000000",
                "0000000000000000000000000000001001000001111100000100000000000000000000000000000000000",
                "0000000000000000000000000000001001000001111100000100000000000000000000000000000000000",
                "0000000000000000000000001000001001000001111100000100000000001000000000000000000000000",
                "0000000000000000000000001000001001000000111100000100001000000000000000000000000000000",
                "0000000000000000000000001000000001000001111000000100000000000000000000000000000000000",
                "0000000000000000000000000000010001000001111000000100000000001000000000000000000000000",
                "0000000000000000000000000000000001000001111000000100000000000000000000000000000000000",
                "0000000000000000000000000001000001000001111000000110000000000000000000000000000000000",
                "0000000000000000000000000000000001000001111000000011000000000000000000000000000000000",
                "0000000000000000000000000000000001000001111000000001000000000000000000000000000000000",
                "0000000000000000000000000000000001000001111000000001000000000000000000000000000000000",
                "0000000000000000000000000000000001000001111000000001000000000000000000000000000000000",
                "0000000000000000000000000000000001000001110000000001000000000000000000000000000000000",
                "0000000000000000000000000000000001000001110000000000000000000000000000000000000000000",
                "0000000000000000000000000000000001000001110000000100000000000000000000000000000000000",
                "0000000000000000000000000000000001000001110000000100000000000000000000000000000000000",
                "0000000000000000000000000000000001000000110000000100000000000000000000000000000000000",
                "0000000000000000000000000000000001000000010000000100000000000000000000000000000000000",
                "0000000000000000000000000000000001000000010000000100000000000000000000000000000000000",
                "0000000000000000000000000000000001000000010000000100000000000000000000000000000000000",
                "0000000000000000000000000000000000000000010000000100000000000000000000000000000000000",
                "0000000000000000000000000000000000000000010000000100000000000000000000000000000000000",
                "0000000000000000000000000000000000000000010000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000010000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000010000000000000000000000000000000000000000000",
                "0000000000000000000000000000000000000000010000000000000000000000000000000000000000000");

lightningvisible <= (((vpos>30) and (vpos<176) and (hpos<85) and (lightning(vpos-31)(hpos)='1')) or
                    ((vpos>250) and (vpos<396) and (hpos<85) and (lightning(vpos-251)(hpos)='1')) or
                    ((vpos>30) and (vpos<176) and (hpos>574) and (lightning(vpos-31)(84-(hpos-565))='1')) or
                    ((vpos>250) and (vpos<396) and (hpos>574) and (lightning(vpos-251)(84-(hpos-565))='1')));
                     
                     
--enjoy the game always rock&roll ;)
--yaþa fenerbahçe

end Behavioral;
