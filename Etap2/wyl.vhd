library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity wyl is
    generic (n: positive :=8; i: positive :=8; z: natural := 0);
    port(CLK, CLR, WYL_GO: in std_logic;
        WYL_DATA : in std_logic_vector (i-1 downto 0);
        WYL_OK: out std_logic;
        LCD_DATA: out std_logic_vector (n-1 downto 0);
        LCD_RW, LCD_RS, LCD_EN : out std_logic
    );
end entity wyl;

architecture wyl_arch of wyl is
signal WYF_GO, WYF_OK: std_logic; 
signal WYF_D: std_logic_vector (n-1 downto 0);
signal TEST : std_logic_vector (n-1 downto 0);

component wyf is
    port (CLK, CLR, WYF_GO: in std_logic;
        WYF_OK : out std_logic;
        WYF_D : in std_logic_vector (n-1 downto 0);
        LCD_DATA: out std_logic_vector(n-1 downto 0);
        LCD_RW, LCD_RS, LCD_EN : out std_logic);
end component wyf;

function to_bcd ( bin : std_logic_vector(7 downto 0) ) return std_logic_vector is
variable i : integer:=0;
variable bcd : std_logic_vector(11 downto 0) := (others => '0');
variable bint : std_logic_vector(7 downto 0) := bin;

begin
for i in 0 to 7 loop  -- repeating 8 times.
bcd(11 downto 1) := bcd(10 downto 0);  --shifting the bits.
bcd(0) := bint(7);
bint(7 downto 1) := bint(6 downto 0);
bint(0) :='0';


if(i < 7 and bcd(3 downto 0) > "0100") then --add 3 if BCD digit is greater than 4.
    bcd(3 downto 0) := std_logic_vector(signed(bcd(3 downto 0)) + "0011");
end if;

if(i < 7 and bcd(7 downto 4) > "0100") then --add 3 if BCD digit is greater than 4.
    bcd(7 downto 4) := std_logic_vector(signed(bcd(7 downto 4)) + "0011");
end if;

if(i < 7 and bcd(11 downto 8) > "0100") then  --add 3 if BCD digit is greater than 4.
    bcd(11 downto 8) := std_logic_vector(signed(bcd(11 downto 8)) + "0011");
end if;

end loop;
return bcd;
end to_bcd;

begin
e0:  wyf port map(CLK, CLR, WYF_GO, WYF_OK, WYF_D, LCD_DATA, LCD_RW, LCD_RS, LCD_EN);

next_state:
process(CLK, CLR) is
type aut_states is (S0, S1, S2, S3, S4, S6, SC1, SC2);
variable state : aut_states := S0;
variable DATA : signed (i-1 downto 0);
variable BCD : std_logic_vector (8 downto 0);
variable counter: unsigned (6 downto 0);
variable BCD_OUT: std_logic_vector(11 downto 0);
variable zero_counter: unsigned(7 downto 0):=(others => '0');

begin
    if CLR='0' then 
        state := S0;
        zero_counter:=(others => '0');
    elsif rising_edge(CLK) then
        case state is
        when S0 =>
            counter := "0000000";
            if WYF_OK = '0' then 
                state:=S0;
                WYL_OK<='0'; 
            else 
                if WYL_GO = '1' then
                    state:=S1;
                    DATA := signed(WYL_DATA);
                else
                    state:=S0;
                    WYL_OK<= '1';
                end if;
            end if;
        when S1 =>
            zero_counter:="01001111";
            WYL_OK<= '0';
            WYF_GO<= '1';
            if signed(DATA) < 0 then
                WYF_D <= "00101101";
                DATA:=(not DATA)+1;
            else
                WYF_D <= "00101011";
            end if;
            if WYF_OK='1' then
                state:=S1;
            else
                state:=S2;
            end if;
        when S2 => WYF_GO<='0'; 
            if WYF_OK='0' then
                state:=S2;
            else
                state:=S6;
            end if;
            BCD_OUT := to_bcd(std_logic_vector(DATA));
        when S6 => 
            if counter < "10" and unsigned(BCD_OUT(11 downto 8)) = 0 then
                counter := counter + "1" ;
                BCD_OUT := std_logic_vector(signed(BCD_OUT) sll 4);
                state := S6;
            else
                state := S3;
            end if;
        when S3 =>
            WYF_D<= "00110000" or BCD_OUT(11 downto 8);
            WYF_GO<='1';
            if WYF_OK='1' then
                state:=S3;
            else
                state:=S4;
            end if; -- s4, s3
        when S4 => WYF_GO <= '0';
            if WYF_OK='0' then
                state:=S4;
            else
                zero_counter:=zero_counter-"1";
                counter:= counter + "1";
                BCD_OUT := std_logic_vector(signed(BCD_OUT) sll 4);
                if counter < "11" then
                    state:= S3;
                else
                    state:=SC1;
                end if;
            end if;
        when SC1 =>
            WYL_OK<= '0';
            WYF_GO<= '1';
            WYF_D <= "00100000";
            if WYF_OK='1' then
                state:=SC1;
            else
                zero_counter:=zero_counter-"1";
                state:=SC2;
            end if;
        when SC2 =>
            WYF_GO <= '0';
            if WYF_OK='0' then
                state:=SC2;
            elsif zero_counter > "0" then
                state:=SC1;
            else
                state:=S0;
            end if;
        end case;
    end if;
end process next_state;

end architecture wyl_arch;    

