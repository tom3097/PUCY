library ieee;
use IEEE.std_logic_1164.all;

entity bpd2 is
port (
    CLK, CLR, PS_CLK_CPY, PS_DATA_IN_CPY  : in std_logic;
    LCD_DATA: out std_logic_vector (7 downto 0);
    LCD_RW, LCD_RS, LCD_EN : out std_logic;
    DATAL : out std_logic_vector(7 downto 0) -- ledy
);
end entity bpd2;

architecture bpd2_arch of bpd2 is
    signal WEL_GO: std_logic; 
    signal WEL_OK: std_logic; 
    signal WYL_GO: std_logic;
    signal WYL_OK: std_logic;
    signal WEL_DATA: std_logic_vector(7 downto 0);
    signal WYL_DATA: std_logic_vector(7 downto 0);
    type state_type is (S0, S1, S2);
    signal state : state_type;
    
    component wel is
    generic (n : positive := 8; i : positive := 8);
    port (CLK, PS_CLK_CPY, PS_DATA_IN_CPY, CLR, WEL_GO : in std_logic;
        WEL_DATA : out std_logic_vector (i-1 downto 0);
        WEL_OK : out std_logic);
    end component wel;
    
    component wyl is
    generic (n: positive :=8; i: positive :=8; z: natural := 0);
    port(CLK, CLR, WYL_GO: in std_logic;
        WYL_DATA : in std_logic_vector (i-1 downto 0);
        WYL_OK: out std_logic;
        LCD_DATA: out std_logic_vector (n-1 downto 0);
        LCD_RW, LCD_RS, LCD_EN : out std_logic
    );
    end component wyl;
    
    begin
    e0:  
    wel port map
    (CLK, PS_CLK_CPY, PS_DATA_IN_CPY, CLR, WEL_GO, WEL_DATA, WEL_OK);
    
    e1:
    wyl port map
    (CLK, CLR, WYL_GO, WYL_DATA, WYL_OK, LCD_DATA, LCD_RW, LCD_RS, LCD_EN);
    
    aut:
    process (CLK, CLR) is
    type aut_states is (S0, S1, S2, S3);
    variable state : aut_states := S0;
    begin
        if CLR='0' then 
            state:=S0; WEL_GO<='0'; DATAL<=(others => '0'); 
        elsif rising_edge(CLK) then 
            case state is
            when S0 => 
            if WEL_OK = '0' or WYL_OK = '0' then
                state:=S0;
            else
                state:=S1;
            end if;
            when S1 =>
                WEL_GO<='1';
                if WEL_OK='0' then
                    state:=S2;
                else
                    state:=S1;
                end if;
            when S2 => 
                if WEL_OK='1' then
                    WYL_DATA<=WEL_DATA;
                    DATAL<=WEL_DATA;
                    WYL_GO<='1';
                    if WYL_OK='1'then
                        state:=S2;
                    else
                        WYL_GO<='0';
                        state:=S3;
                    end if;
                else
                    WEL_GO<='0';
                    state:=S2;
                end if;
            when S3 =>
                if WYL_OK='0' then
                    state:=S3;
                else
                    state:=S0;
                end if;
            end case;
        end if;
    end process aut;

end architecture bpd2_arch;
