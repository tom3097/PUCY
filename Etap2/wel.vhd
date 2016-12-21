library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;

entity wel is
    generic (n: positive :=8; i: positive :=8);
    port(CLK, PS_CLK_CPY, PS_DATA_IN_CPY, CLR, WEL_GO : in std_logic;
        WEL_DATA : out std_logic_vector (i-1 downto 0);
        WEL_OK : out std_logic
    );
end entity wel;

architecture wel_arch of wel is
signal WEF_GO, WEF_OK: std_logic;
signal WEF_DATA: std_logic_vector (n-1 downto 0);
signal TEST : std_logic_vector (7 downto 0);
signal WEL_DATAx : std_logic_vector (i-1 downto 0);
signal WEF_DATAx: std_logic_vector (n-1 downto 0);

component wef is
    port (PS_CLK_CPY, CLK, CLR, PS_DATA_IN_CPY, WEF_GO : in std_logic;
        WEF_OK : out std_logic;
        WE_D : out std_logic_vector (7 downto 0) );
end component wef;

begin
e0:  wef port map(PS_CLK_CPY, CLK, CLR, PS_DATA_IN_CPY, WEF_GO, WEF_OK, WEF_DATA);

next_state:
process(CLK, CLR) is
type aut_states is (S0, S1, S2, S3);
variable state : aut_states := S0;
variable DATA : signed (i-1 downto 0) := (others => '0'); 
begin
    if CLR='0' then 
        state := S0;
    elsif rising_edge(CLK) then
        case state is
        when S0 =>
            WEL_OK <= '1';
            DATA:=(others => '0');
            if WEL_GO = '1' then
                state:=S1;
            else
                state:=S0;
            end if;
        when S1 => 
            WEL_OK<='0'; 
            WEF_GO<='1';  
            if WEF_OK='0' then
                state:=S2;
            else
                state:=S1;
            end if;
        when S2 => WEF_GO<='0'; 
            if WEF_OK='1' then
                state:=S3;
            else
                state:=S2;
            end if;
        when S3 => 
            if WEF_DATA = "00101011" then
                WEL_DATA<=std_logic_vector(DATA); state:=S0; -- odebrano + 
            elsif WEF_DATA = "00101101" then
                WEL_DATA<=std_logic_vector((not DATA)+1); state:=S0; -- odebrano - 
            else DATA:= (DATA sll 3) + (DATA sll 1) + signed(WEF_DATA)-"00110000";
            state:=S1;
            end if;
        end case;
    end if;
end process next_state;

end architecture wel_arch;    
