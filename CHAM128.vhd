----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/04/2019 05:25:12 PM
-- Design Name: 
-- Module Name: CHAM128 - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use work.design_pkg.all;


-- Entity
----------------------------------------------------------------------------------
entity CHAM128 is
    Port (
        clk         : in std_logic;
        rst         : in std_logic;
        start       : in std_logic;
        m			: in std_logic_vector(RW - 1 downto 0); -- Random input
        Key0        : in std_logic_vector (127 downto 0);
        Key1        : in std_logic_vector (127 downto 0);
        Key2        : in std_logic_vector (127 downto 0);
        CHAM_in0    : in std_logic_vector (127 downto 0);
        CHAM_in1    : in std_logic_vector (127 downto 0);
        CHAM_in2    : in std_logic_vector (127 downto 0);
        CHAM_out0   : out std_logic_vector (127 downto 0);
        CHAM_out1   : out std_logic_vector (127 downto 0);
        CHAM_out2   : out std_logic_vector (127 downto 0);
        done        : out std_logic        
    );

end CHAM128;

-- Architecture
----------------------------------------------------------------------------------
architecture Behavioral of CHAM128 is
    
    -- Keep architecture ---------------------------------------------------------
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of Behavioral: architecture is "true";  
    
    -- Arrays --------------------------------------------------------------------
    type RK_vector is array (0 to 7) of std_logic_vector(31 downto 0);
    
    -- Signals -------------------------------------------------------------------
    signal S0_0, S0_1, S0_2             : std_logic_vector(31 downto 0); -- S0, S1, S2, S3; Four 32-bit words of current state
    signal S1_0, S1_1, S1_2             : std_logic_vector(31 downto 0);
    signal S2_0, S2_1, S2_2             : std_logic_vector(31 downto 0);
    signal S3_0, S3_1, S3_2             : std_logic_vector(31 downto 0); 
    signal S0_Up0, S0_Up1, S0_Up2       : std_logic_vector(31 downto 0); -- S0_Up, S1_Up, S2_Up, S3_Up; Four 32-bit words of updated state
    signal S1_Up0, S1_Up1, S1_Up2       : std_logic_vector(31 downto 0);
    signal S2_Up0, S2_Up1, S2_Up2       : std_logic_vector(31 downto 0);
    signal S3_Up0, S3_Up1, S3_Up2       : std_logic_vector(31 downto 0); 
    signal S0_temp0, S3_temp1, S3_temp2 : std_logic_vector(31 downto 0);
    signal S1_temp0, S0_temp1, S0_temp2 : std_logic_vector(31 downto 0);
    signal S3_temp0, S1_temp1, S1_temp2 : std_logic_vector(31 downto 0);
    signal K0_0, K0_1, K0_2             : std_logic_vector(31 downto 0); -- K0, K1, K2, K3: Divide the input key into four 32-bit words
    signal K1_0, K1_1, K1_2             : std_logic_vector(31 downto 0);
    signal K2_0, K2_1, K2_2             : std_logic_vector(31 downto 0);
    signal K3_0, K3_1, K3_2             : std_logic_vector(31 downto 0);
    signal RK0, RK1, RK2                : RK_vector;                     -- RK: Eight 32-bit words of round key
    signal round_Num                    : natural range 0 to 80;         -- Round number
    signal KSA_ctr                      : std_logic_vector(2 downto 0);  -- Counter for counting 6CC
    
    -- Keep signals -----------------------------------------------
    attribute keep : string;
    attribute keep of S0_0, S0_1, S0_2, S1_0, S1_1, S1_2, S2_0, S2_1, S2_2, S3_0, S3_1, S3_2                         : signal is "true";
    attribute keep of S0_Up0, S0_Up1, S0_Up2, S1_Up0, S1_Up1, S1_Up2, S2_Up0, S2_Up1, S2_Up2, S3_Up0, S3_Up1, S3_Up2 : signal is "true";
    attribute keep of S0_temp0, S3_temp1, S3_temp2, S1_temp0, S0_temp1, S0_temp2, S3_temp0, S1_temp1, S1_temp2       : signal is "true";
    attribute keep of K0_0, K0_1, K0_2, K1_0, K1_1, K1_2, K2_0, K2_1, K2_2, K3_0, K3_1, K3_2                         : signal is "true";
    attribute keep of RK0, RK1, RK2, round_Num, KSA_ctr                                                              : signal is "true";

----------------------------------------------------------------------------------
begin

    -- Load 128-bit plaintext or updated state
    S0_0 <= CHAM_in0(127 downto 96) when (round_Num = 0) else S0_Up0;
    S0_1 <= CHAM_in1(127 downto 96) when (round_Num = 0) else S0_Up1;
    S0_2 <= CHAM_in2(127 downto 96) when (round_Num = 0) else S0_Up2;
    
    S1_0 <= CHAM_in0(95 downto 64) when (round_Num = 0) else S1_Up0;
    S1_1 <= CHAM_in1(95 downto 64) when (round_Num = 0) else S1_Up1;
    S1_2 <= CHAM_in2(95 downto 64) when (round_Num = 0) else S1_Up2;
    
    S2_0 <= CHAM_in0(63 downto 32) when (round_Num = 0) else S2_Up0;
    S2_1 <= CHAM_in1(63 downto 32) when (round_Num = 0) else S2_Up1;
    S2_2 <= CHAM_in2(63 downto 32) when (round_Num = 0) else S2_Up2;
    
    S3_0 <= CHAM_in0(31 downto 0) when (round_Num = 0) else S3_Up0;
    S3_1 <= CHAM_in1(31 downto 0) when (round_Num = 0) else S3_Up1;
    S3_2 <= CHAM_in2(31 downto 0) when (round_Num = 0) else S3_Up2;

    -- Key schedule
    K0_0    <= Key0(127 downto 96);
    K0_1    <= Key1(127 downto 96);
    K0_2    <= Key2(127 downto 96);
    
    K1_0    <= Key0(95 downto 64);
    K1_1    <= Key1(95 downto 64);
    K1_2    <= Key2(95 downto 64);
    
    K2_0    <= Key0(63 downto 32);
    K2_1    <= Key1(63 downto 32);
    K2_2    <= Key2(63 downto 32);
    
    K3_0    <= Key0(31 downto 0);
    K3_1    <= Key1(31 downto 0);
    K3_2    <= Key2(31 downto 0);
    
    RK0(0)   <= K0_0 xor (K0_0(30 downto 0) & K0_0(31)) xor (K0_0(23 downto 0) & K0_0(31 downto 24)); -- R0, R1, R2, R3: K xor (K <<< 1) xor (K <<< 8)
    RK1(0)   <= K0_1 xor (K0_1(30 downto 0) & K0_1(31)) xor (K0_1(23 downto 0) & K0_1(31 downto 24));
    RK2(0)   <= K0_2 xor (K0_2(30 downto 0) & K0_2(31)) xor (K0_2(23 downto 0) & K0_2(31 downto 24));
    
    RK0(1)   <= K1_0 xor (K1_0(30 downto 0) & K1_0(31)) xor (K1_0(23 downto 0) & K1_0(31 downto 24));
    RK1(1)   <= K1_1 xor (K1_1(30 downto 0) & K1_1(31)) xor (K1_1(23 downto 0) & K1_1(31 downto 24));
    RK2(1)   <= K1_2 xor (K1_2(30 downto 0) & K1_2(31)) xor (K1_2(23 downto 0) & K1_2(31 downto 24));
    
    RK0(2)   <= K2_0 xor (K2_0(30 downto 0) & K2_0(31)) xor (K2_0(23 downto 0) & K2_0(31 downto 24));
    RK1(2)   <= K2_1 xor (K2_1(30 downto 0) & K2_1(31)) xor (K2_1(23 downto 0) & K2_1(31 downto 24));
    RK2(2)   <= K2_2 xor (K2_2(30 downto 0) & K2_2(31)) xor (K2_2(23 downto 0) & K2_2(31 downto 24));
     
    RK0(3)   <= K3_0 xor (K3_0(30 downto 0) & K3_0(31)) xor (K3_0(23 downto 0) & K3_0(31 downto 24));
    RK1(3)   <= K3_1 xor (K3_1(30 downto 0) & K3_1(31)) xor (K3_1(23 downto 0) & K3_1(31 downto 24));
    RK2(3)   <= K3_2 xor (K3_2(30 downto 0) & K3_2(31)) xor (K3_2(23 downto 0) & K3_2(31 downto 24));
    
    RK0(5)   <= K0_0 xor (K0_0(30 downto 0) & K0_0(31)) xor (K0_0(20 downto 0) & K0_0(31 downto 21)); -- R5, R4, R7, R6: K xor (K <<< 1) xor (K <<< 11)
    RK1(5)   <= K0_1 xor (K0_1(30 downto 0) & K0_1(31)) xor (K0_1(20 downto 0) & K0_1(31 downto 21));
    RK2(5)   <= K0_2 xor (K0_2(30 downto 0) & K0_2(31)) xor (K0_2(20 downto 0) & K0_2(31 downto 21));
    
    RK0(4)   <= K1_0 xor (K1_0(30 downto 0) & K1_0(31)) xor (K1_0(20 downto 0) & K1_0(31 downto 21));
    RK1(4)   <= K1_1 xor (K1_1(30 downto 0) & K1_1(31)) xor (K1_1(20 downto 0) & K1_1(31 downto 21));
    RK2(4)   <= K1_2 xor (K1_2(30 downto 0) & K1_2(31)) xor (K1_2(20 downto 0) & K1_2(31 downto 21));
    
    RK0(7)   <= K2_0 xor (K2_0(30 downto 0) & K2_0(31)) xor (K2_0(20 downto 0) & K2_0(31 downto 21));
    RK1(7)   <= K2_1 xor (K2_1(30 downto 0) & K2_1(31)) xor (K2_1(20 downto 0) & K2_1(31 downto 21));
    RK2(7)   <= K2_2 xor (K2_2(30 downto 0) & K2_2(31)) xor (K2_2(20 downto 0) & K2_2(31 downto 21));
    
    RK0(6)   <= K3_0 xor (K3_0(30 downto 0) & K3_0(31)) xor (K3_0(20 downto 0) & K3_0(31 downto 21));
    RK1(6)   <= K3_1 xor (K3_1(30 downto 0) & K3_1(31)) xor (K3_1(20 downto 0) & K3_1(31 downto 21));
    RK2(6)   <= K3_2 xor (K3_2(30 downto 0) & K3_2(31)) xor (K3_2(20 downto 0) & K3_2(31 downto 21));
    
    -- ARX
    S0_temp0 <= S0_0 xor conv_std_logic_vector(round_Num,32);
    S0_temp1 <= S0_1;
    S0_temp2 <= S0_2;
    
    S1_temp0 <= (S1_0(30 downto 0) & S1_0(31)) xor RK0(round_Num mod 8) when (round_Num mod 2 = 0) else
                (S1_0(23 downto 0) & S1_0(31 downto 24)) xor RK0(round_Num mod 8);
                
    S1_temp1 <= (S1_1(30 downto 0) & S1_1(31)) xor RK1(round_Num mod 8) when (round_Num mod 2 = 0) else
                (S1_1(23 downto 0) & S1_1(31 downto 24)) xor RK1(round_Num mod 8);
                
    S1_temp2 <= (S1_2(30 downto 0) & S1_2(31)) xor RK2(round_Num mod 8) when (round_Num mod 2 = 0) else
                (S1_2(23 downto 0) & S1_2(31 downto 24)) xor RK2(round_Num mod 8);
               
    ksa_inst : entity work.KSA(structural)
	generic map (n => 32)
    port map(
        clk     => clk,
        m       => m,
        a0      => S0_temp0,
        a1      => S0_temp1,
        a2      => S0_temp2,
        b0      => S1_temp0,
        b1      => S1_temp1,
        b2      => S1_temp2,
        s0      => S3_temp0,
        s1      => S3_temp1,
        s2      => S3_temp2
    );
    
    -- Kogge-Stone adder process
    KSA_CC: process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1' or start = '0') then
                KSA_ctr <= "000";
            elsif (rst = '0' and start = '1' and KSA_ctr /= "110") then
                KSA_ctr <= KSA_ctr + 1;
            else
                KSA_ctr <= "000";
            end if;
        end if;
    end process KSA_CC;
                
    -- CHAM round function process
    RF: process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1' or start = '0') then
                round_Num    <= 0;
                done         <= '0';
                
            elsif (rst = '0' and start = '1' and KSA_ctr = "110") then
                round_Num    <= round_Num + 1;
            
                -- Update state
                if (round_Num mod 2 = 0) then
                    S3_Up0   <= S3_temp0(23 downto 0) & S3_temp0(31 downto 24); 
                    S3_Up1   <= S3_temp1(23 downto 0) & S3_temp1(31 downto 24); 
                    S3_Up2   <= S3_temp2(23 downto 0) & S3_temp2(31 downto 24); 
                else
                    S3_Up0   <= S3_temp0(30 downto 0) & S3_temp0(31);
                    S3_Up1   <= S3_temp1(30 downto 0) & S3_temp1(31);
                    S3_Up2   <= S3_temp2(30 downto 0) & S3_temp2(31);
                end if;
                
                S0_Up0   <= S1_0;
                S0_Up1   <= S1_1;
                S0_Up2   <= S1_2;
                
                S1_Up0   <= S2_0;
                S1_Up1   <= S2_1;
                S1_Up2   <= S2_2;
                
                S2_Up0   <= S3_0;
                S2_Up1   <= S3_1;
                S2_Up2   <= S3_2;
                
                case round_Num is
                    when 80 => 
                        round_Num   <= 0;
                        done        <= '1';                      
                        CHAM_out0   <= S3_Up0 & S2_Up0 & S1_Up0 & S0_Up0;
                        CHAM_out1   <= S3_Up1 & S2_Up1 & S1_Up1 & S0_Up1;
                        CHAM_out2   <= S3_Up2 & S2_Up2 & S1_Up2 & S0_Up2;
                    when others =>
                        done        <= '0';
                end case;
            end if;
        end if;
    end process RF;

end Behavioral;
 
