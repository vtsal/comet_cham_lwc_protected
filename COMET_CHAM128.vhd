----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/09/2019 12:19:32 PM
-- Design Name: 
-- Module Name: COMET_CHAM128 - Behavioral
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
use work.SomeFunction.all;
use work.design_pkg.all;

-- Entity
----------------------------------------------------------------------------------
entity COMET_CHAM128 is
    Port(
        clk             : in std_logic;
        rst             : in std_logic;
        -- Data Input
        key0            : in std_logic_vector(31 downto 0); -- SW = 32
        key1            : in std_logic_vector(31 downto 0);
        key2            : in std_logic_vector(31 downto 0);
        bdi0            : in std_logic_vector(31 downto 0); -- W = 32
        bdi1            : in std_logic_vector(31 downto 0);
        bdi2            : in std_logic_vector(31 downto 0);
        m				: in std_logic_vector(RW - 1 downto 0); -- Random input
        -- Key Control
        key_valid       : in std_logic;
        key_ready       : out std_logic;
        key_update      : in std_logic;
        -- BDI Control
        bdi_valid       : in std_logic;
        bdi_ready       : out std_logic;
        bdi_pad_loc     : in std_logic_vector(3 downto 0); -- W/8 = 4
        bdi_valid_bytes : in std_logic_vector(3 downto 0); -- W/8 = 4
        bdi_size        : in std_logic_vector(2 downto 0); -- W/(8+1) = 3
        bdi_eot         : in std_logic;
        bdi_eoi         : in std_logic;
        bdi_type        : in std_logic_vector(3 downto 0);
        hash_in         : in std_logic;
        decrypt_in      : in std_logic;
        -- Data Output
        bdo0            : out std_logic_vector(31 downto 0); -- W = 32
        bdo1            : out std_logic_vector(31 downto 0);
        bdo2            : out std_logic_vector(31 downto 0);
        -- BDO Control
        bdo_valid       : out std_logic;
        bdo_ready       : in std_logic;
        bdo_valid_bytes : out std_logic_vector(3 downto 0); -- W/8 = 4
        end_of_block    : out std_logic;
        bdo_type        : out std_logic_vector(3 downto 0);
        -- Tag Verification
        msg_auth        : out std_logic;
        msg_auth_valid  : out std_logic;
        msg_auth_ready  : in std_logic    
    );
end COMET_CHAM128;

-- Architecture
----------------------------------------------------------------------------------
architecture Behavioral of COMET_CHAM128 is
    
    -- Keep architecture ---------------------------------------------------------
    attribute keep_hierarchy : string;
    attribute keep_hierarchy of Behavioral: architecture is "true"; 

    -- Constants -----------------------------------------------------------------
    --bdi_type and bdo_type encoding
    constant HDR_AD         : std_logic_vector(3 downto 0) := "0001";
    constant HDR_MSG        : std_logic_vector(3 downto 0) := "0100";
    constant HDR_CT         : std_logic_vector(3 downto 0) := "0101";
    constant HDR_TAG        : std_logic_vector(3 downto 0) := "1000";
    constant HDR_KEY        : std_logic_vector(3 downto 0) := "1100";
    constant HDR_NPUB       : std_logic_vector(3 downto 0) := "1101";
    
    -- All zero constants
    constant zero            : std_logic_vector(127 downto 0) := (others => '0');
    constant zero123         : std_logic_vector(122 downto 0) := (others => '0');
    constant zero120         : std_logic_vector(119 downto 0) := (others => '0');
    
    -- Types ---------------------------------------------------------------------
    type fsm is (idle, wait_key, load_key, wait_Npub, load_Npub, process_Npub, wait_AD,
                 load_AD, process_AD, wait_data, load_data, process_data, prepare_output_data,
                 output_data, process_tag, output_tag, wait_tag, load_tag, verify_tag1,
                 verify_tag2, verify_tag3, verify_tag4, verify_tag5, verify_tag6, verify_tag7);

    -- Signals -------------------------------------------------------
    -- CHAM signals
    signal CHAM_key0        : std_logic_vector(127 downto 0);
    signal CHAM_key1        : std_logic_vector(127 downto 0);
    signal CHAM_key2        : std_logic_vector(127 downto 0);
    signal CHAM_in0         : std_logic_vector(127 downto 0);
    signal CHAM_in1         : std_logic_vector(127 downto 0);
    signal CHAM_in2         : std_logic_vector(127 downto 0);
    signal CHAM_out0        : std_logic_vector(127 downto 0);
    signal CHAM_out1        : std_logic_vector(127 downto 0);
    signal CHAM_out2        : std_logic_vector(127 downto 0);
    signal CHAM_start       : std_logic;
    signal CHAM_done        : std_logic;

    -- Data signals
    signal KeyReg0_rst      : std_logic;
    signal KeyReg0_en       : std_logic;
    signal KeyReg0_in       : std_logic_vector(127 downto 0);
    signal KeyReg0_out      : std_logic_vector(127 downto 0);
    
    signal KeyReg1_rst      : std_logic;
    signal KeyReg1_en       : std_logic;
    signal KeyReg1_in       : std_logic_vector(127 downto 0);
    signal KeyReg1_out      : std_logic_vector(127 downto 0);
    
    signal KeyReg2_rst      : std_logic;
    signal KeyReg2_en       : std_logic;
    signal KeyReg2_in       : std_logic_vector(127 downto 0);
    signal KeyReg2_out      : std_logic_vector(127 downto 0);
    
    signal iDataReg0_rst    : std_logic;
    signal iDataReg0_en     : std_logic;
    signal iDataReg0_in     : std_logic_vector(127 downto 0);
    signal iDataReg0_out    : std_logic_vector(127 downto 0);
    
    signal iDataReg1_rst    : std_logic;
    signal iDataReg1_en     : std_logic;
    signal iDataReg1_in     : std_logic_vector(127 downto 0);
    signal iDataReg1_out    : std_logic_vector(127 downto 0);
    
    signal iDataReg2_rst    : std_logic;
    signal iDataReg2_en     : std_logic;
    signal iDataReg2_in     : std_logic_vector(127 downto 0);
    signal iDataReg2_out    : std_logic_vector(127 downto 0);
    
    signal oDataReg0_rst    : std_logic;
    signal oDataReg0_en     : std_logic;
    signal oDataReg0_in     : std_logic_vector(127 downto 0);
    signal oDataReg0_out    : std_logic_vector(127 downto 0);
    
    signal oDataReg1_rst    : std_logic;
    signal oDataReg1_en     : std_logic;
    signal oDataReg1_in     : std_logic_vector(127 downto 0);
    signal oDataReg1_out    : std_logic_vector(127 downto 0);
    
    signal oDataReg2_rst    : std_logic;
    signal oDataReg2_en     : std_logic;
    signal oDataReg2_in     : std_logic_vector(127 downto 0);
    signal oDataReg2_out    : std_logic_vector(127 downto 0);   
    
    signal ZstateReg0_rst   : std_logic;
    signal ZstateReg0_en    : std_logic;
    signal ZstateReg0_in    : std_logic_vector(127 downto 0);
    signal ZstateReg0_out   : std_logic_vector(127 downto 0);
    
    signal ZstateReg1_rst   : std_logic;
    signal ZstateReg1_en    : std_logic;
    signal ZstateReg1_in    : std_logic_vector(127 downto 0);
    signal ZstateReg1_out   : std_logic_vector(127 downto 0);
    
    signal ZstateReg2_rst   : std_logic;
    signal ZstateReg2_en    : std_logic;
    signal ZstateReg2_in    : std_logic_vector(127 downto 0);
    signal ZstateReg2_out   : std_logic_vector(127 downto 0);
    
    signal YstateReg0_rst   : std_logic;
    signal YstateReg0_en    : std_logic;
    signal YstateReg0_in    : std_logic_vector(127 downto 0);
    signal YstateReg0_out   : std_logic_vector(127 downto 0);
    
    signal YstateReg1_rst   : std_logic;
    signal YstateReg1_en    : std_logic;
    signal YstateReg1_in    : std_logic_vector(127 downto 0);
    signal YstateReg1_out   : std_logic_vector(127 downto 0);
    
    signal YstateReg2_rst   : std_logic;
    signal YstateReg2_en    : std_logic;
    signal YstateReg2_in    : std_logic_vector(127 downto 0);
    signal YstateReg2_out   : std_logic_vector(127 downto 0);

    signal ra, rb           : std_logic_vector(63 downto 0);
    signal raReg_en         : std_logic;
    signal rbReg_en         : std_logic;
    
    signal c1a_en           : std_logic;
    signal c1a_in, c1a_out  : std_logic_vector(63 downto 0);
    signal c2a_en           : std_logic;
    signal c2a_in, c2a_out  : std_logic_vector(63 downto 0);
    signal c3a_en           : std_logic;
    signal c3a_in, c3a_out  : std_logic_vector(63 downto 0);
    
    signal c1b_en           : std_logic;
    signal c1b_in, c1b_out  : std_logic_vector(63 downto 0);
    signal c2b_en           : std_logic;
    signal c2b_in, c2b_out  : std_logic_vector(63 downto 0);
    signal c3b_en           : std_logic;
    signal c3b_in, c3b_out  : std_logic_vector(63 downto 0);
    
    signal d1a_en           : std_logic;
    signal d1a_in, d1a_out  : std_logic_vector(63 downto 0);
    signal d2a_en           : std_logic;
    signal d2a_in, d2a_out  : std_logic_vector(63 downto 0);
    
    signal d1b_en           : std_logic;
    signal d1b_in, d1b_out  : std_logic_vector(63 downto 0);
    signal d2b_en           : std_logic;
    signal d2b_in, d2b_out  : std_logic_vector(63 downto 0);
    
    -- Control Signals
    signal init             : std_logic; -- For initialization state
    
    signal ValidBytesReg_rst: std_logic;
    signal ValidBytesReg_en : std_logic;
    signal ValidBytesReg_out: std_logic_vector(3 downto 0);

    signal decrypt_rst      : std_logic;
    signal decrypt_set      : std_logic;
    signal decrypt_reg      : std_logic;
    
    signal first_AD_reg     : std_logic;
    signal first_AD_rst     : std_logic;
    signal first_AD_set     : std_logic;
    
    signal last_AD_reg      : std_logic;
    signal last_AD_rst      : std_logic;
    signal last_AD_set      : std_logic;
    
    signal no_AD_reg        : std_logic;
    signal no_AD_rst        : std_logic;
    signal no_AD_set        : std_logic;
    
    signal first_M_reg      : std_logic;
    signal first_M_rst      : std_logic;
    signal first_M_set      : std_logic;
    
    signal last_M_reg       : std_logic;
    signal last_M_rst       : std_logic;
    signal last_M_set       : std_logic;
    
    signal no_M_reg         : std_logic;
    signal no_M_rst         : std_logic;
    signal no_M_set         : std_logic;
    
    -- Counter signals
    signal ctr_words_rst    : std_logic;
    signal ctr_words_inc    : std_logic;
    signal ctr_words        : std_logic_vector(2 downto 0);
    
    signal ctr_bytes_rst    : std_logic;
    signal ctr_bytes_inc    : std_logic;
    signal ctr_bytes_dec    : std_logic;
    signal ctr_bytes        : std_logic_vector(4 downto 0); -- Truncate the output based on this counter value
    
    -- State machine signals
    signal state            : fsm;
    signal next_state       : fsm;
    
    -- Keep signals -----------------------------------------------
    attribute keep : string;
    attribute keep of CHAM_key0, CHAM_key1, CHAM_key2                                   : signal is "true";
    attribute keep of CHAM_in0,  CHAM_in1,  CHAM_in2                                    : signal is "true";
    attribute keep of CHAM_out0, CHAM_out1, CHAM_out2                                   : signal is "true";
    attribute keep of CHAM_start,CHAM_done                                              : signal is "true";
    
    attribute keep of KeyReg0_rst, KeyReg0_en, KeyReg0_in, KeyReg0_out                  : signal is "true";
    attribute keep of KeyReg1_rst, KeyReg1_en, KeyReg1_in, KeyReg1_out                  : signal is "true";
    attribute keep of KeyReg2_rst, KeyReg2_en, KeyReg2_in, KeyReg2_out                  : signal is "true";
    
    attribute keep of iDataReg0_rst, iDataReg0_en, iDataReg0_in, iDataReg0_out          : signal is "true";
    attribute keep of iDataReg1_rst, iDataReg1_en, iDataReg1_in, iDataReg1_out          : signal is "true";
    attribute keep of iDataReg2_rst, iDataReg2_en, iDataReg2_in, iDataReg2_out          : signal is "true";
    
    attribute keep of oDataReg0_rst, oDataReg0_en, oDataReg0_in, oDataReg0_out          : signal is "true";
    attribute keep of oDataReg1_rst, oDataReg1_en, oDataReg1_in, oDataReg1_out          : signal is "true";
    attribute keep of oDataReg2_rst, oDataReg2_en, oDataReg2_in, oDataReg2_out          : signal is "true";
    
    attribute keep of ZstateReg0_rst, ZstateReg0_en, ZstateReg0_in, ZstateReg0_out      : signal is "true";
    attribute keep of ZstateReg1_rst, ZstateReg1_en, ZstateReg1_in, ZstateReg1_out      : signal is "true";
    attribute keep of ZstateReg2_rst, ZstateReg2_en, ZstateReg2_in, ZstateReg2_out      : signal is "true";
    
    attribute keep of YstateReg0_rst, YstateReg0_en, YstateReg0_in, YstateReg0_out      : signal is "true";
    attribute keep of YstateReg1_rst, YstateReg1_en, YstateReg1_in, YstateReg1_out      : signal is "true";
    attribute keep of YstateReg2_rst, YstateReg2_en, YstateReg2_in, YstateReg2_out      : signal is "true";
    
    attribute keep of raReg_en, ra, rbReg_en, rb                                        : signal is "true";
    attribute keep of c1a_en, c2a_en, c3a_en                                            : signal is "true";
    attribute keep of c1a_in, c1a_out, c2a_in, c2a_out, c3a_in, c3a_out                 : signal is "true";
    attribute keep of c1b_en, c2b_en, c3b_en                                            : signal is "true";
    attribute keep of c1b_in, c1b_out, c2b_in, c2b_out, c3b_in, c3b_out                 : signal is "true";
    attribute keep of d1a_en, d2a_en, d1b_en, d2b_en                                    : signal is "true";
    attribute keep of d1a_in, d1a_out, d2a_in, d2a_out                                  : signal is "true";  
    attribute keep of d1b_in, d1b_out, d2b_in, d2b_out                                  : signal is "true"; 
    
    attribute keep of init, state, next_state                                           : signal is "true";
    
    attribute keep of ValidBytesReg_rst, ValidBytesReg_en, ValidBytesReg_out            : signal is "true";
    
    attribute keep of decrypt_rst, decrypt_set, decrypt_reg                             : signal is "true";
    
    attribute keep of first_AD_reg, first_AD_rst, first_AD_set                          : signal is "true";
    attribute keep of last_AD_reg,  last_AD_rst,  last_AD_set                           : signal is "true";
    attribute keep of no_AD_reg,    no_AD_rst,    no_AD_set                             : signal is "true";
    
    attribute keep of first_M_reg, first_M_rst, first_M_set                             : signal is "true";
    attribute keep of last_M_reg,  last_M_rst,  last_M_set                              : signal is "true";
    attribute keep of no_M_reg,    no_M_rst,    no_M_set                                : signal is "true";
    
    attribute keep of ctr_words_rst, ctr_words_inc, ctr_words                           : signal is "true";
    
    attribute keep of ctr_bytes_rst, ctr_bytes_inc, ctr_bytes_dec, ctr_bytes            : signal is "true";

----------------------------------------------------------------------------------    
begin

    CHAM_in0    <= iDataReg0_out when (init = '1') else
                   YstateReg0_out(31 downto 0)  & YstateReg0_out(63 downto 32) &
                   YstateReg0_out(95 downto 64) & YstateReg0_out(127 downto 96);
    
    CHAM_in1    <= iDataReg1_out when (init = '1') else
                   YstateReg1_out(31 downto 0)  & YstateReg1_out(63 downto 32) &
                   YstateReg1_out(95 downto 64) & YstateReg1_out(127 downto 96);
                   
    CHAM_in2    <= iDataReg2_out when (init = '1') else
                   YstateReg2_out(31 downto 0)  & YstateReg2_out(63 downto 32) &
                   YstateReg2_out(95 downto 64) & YstateReg2_out(127 downto 96);
    
    CHAM_key0   <= KeyReg0_out when (init = '1') else
                   ZstateReg0_out(31 downto 0)  & ZstateReg0_out(63 downto 32) &
                   ZstateReg0_out(95 downto 64) & ZstateReg0_out(127 downto 96);
                   
    CHAM_key1   <= KeyReg1_out when (init = '1') else
                   ZstateReg1_out(31 downto 0)  & ZstateReg1_out(63 downto 32) &
                   ZstateReg1_out(95 downto 64) & ZstateReg1_out(127 downto 96);
    
    CHAM_key2   <= KeyReg2_out when (init = '1') else
                   ZstateReg2_out(31 downto 0)  & ZstateReg2_out(63 downto 32) &
                   ZstateReg2_out(95 downto 64) & ZstateReg2_out(127 downto 96);
    
    Ek: entity work.CHAM128     -- The underlying cipher
    Port map(
        clk         => clk,
        rst         => rst,
        start       => CHAM_start,
        m           => m,
        Key0        => CHAM_key0,
        Key1        => CHAM_key1,
        Key2        => CHAM_key2,
        CHAM_in0    => CHAM_in0,
        CHAM_in1    => CHAM_in1,
        CHAM_in2    => CHAM_in2,
        CHAM_out0   => CHAM_out0,
        CHAM_out1   => CHAM_out1,
        CHAM_out2   => CHAM_out2,
        done        => CHAM_done
    );
   
    KeyReg0: entity work.myReg -- For registering the 128-bit secret key
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => KeyReg0_rst,
        en      => KeyReg0_en,
        D_in    => KeyReg0_in,
        D_out   => KeyReg0_out
    );
    
    KeyReg1: entity work.myReg
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => KeyReg1_rst,
        en      => KeyReg1_en,
        D_in    => KeyReg1_in,
        D_out   => KeyReg1_out
    );
    
    KeyReg2: entity work.myReg
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => KeyReg2_rst,
        en      => KeyReg2_en,
        D_in    => KeyReg2_in,
        D_out   => KeyReg2_out
    );
     
    iDataReg0: entity work.myReg -- For registering Npub, AD, PT/CT, input Tag
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => iDataReg0_rst,
        en      => iDataReg0_en,
        D_in    => iDataReg0_in,
        D_out   => iDataReg0_out
    );
    
    iDataReg1: entity work.myReg
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => iDataReg1_rst,
        en      => iDataReg1_en,
        D_in    => iDataReg1_in,
        D_out   => iDataReg1_out
    );
    
    iDataReg2: entity work.myReg
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => iDataReg2_rst,
        en      => iDataReg2_en,
        D_in    => iDataReg2_in,
        D_out   => iDataReg2_out
    );
    
    oDataReg0: entity work.myReg -- For registering CT/PT and output Tag
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => oDataReg0_rst,
        en      => oDataReg0_en,
        D_in    => oDataReg0_in,
        D_out   => oDataReg0_out
    );
    
    oDataReg1: entity work.myReg
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => oDataReg1_rst,
        en      => oDataReg1_en,
        D_in    => oDataReg1_in,
        D_out   => oDataReg1_out
    );
    
    oDataReg2: entity work.myReg
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => oDataReg2_rst,
        en      => oDataReg2_en,
        D_in    => oDataReg2_in,
        D_out   => oDataReg2_out
    );
    
    ZstateReg0: entity work.myReg -- For registering the Z state (the key state)
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => ZstateReg0_rst,
        en      => ZstateReg0_en,
        D_in    => ZstateReg0_in,
        D_out   => ZstateReg0_out
    );
    
    ZstateReg1: entity work.myReg
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => ZstateReg1_rst,
        en      => ZstateReg1_en,
        D_in    => ZstateReg1_in,
        D_out   => ZstateReg1_out
    );
    
    ZstateReg2: entity work.myReg
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => ZstateReg2_rst,
        en      => ZstateReg2_en,
        D_in    => ZstateReg2_in,
        D_out   => ZstateReg2_out
    );
    
    YstateReg0: entity work.myReg -- For registering the Y state (the input of CHAM)
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => YstateReg0_rst,
        en      => YstateReg0_en,
        D_in    => YstateReg0_in,
        D_out   => YstateReg0_out
    );
    
    YstateReg1: entity work.myReg
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => YstateReg1_rst,
        en      => YstateReg1_en,
        D_in    => YstateReg1_in,
        D_out   => YstateReg1_out
    );
    
    YstateReg2: entity work.myReg
    generic map( b => 128)
    Port map(
        clk     => clk,
        rst     => YstateReg2_rst,
        en      => YstateReg2_en,
        D_in    => YstateReg2_in,
        D_out   => YstateReg2_out
    );
    
    ----------------------------------------------------   
    raReg: entity work.myReg -- Register random share for 64-MSB of the Tag
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => raReg_en,
        D_in    => m(63 downto 0),
        D_out   => ra
    );
    
    rbReg: entity work.myReg -- Register random share for 64-LSB of the Tag
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => rbReg_en,
        D_in    => m(63 downto 0),
        D_out   => rb
    );
    
    c1aReg: entity work.myReg 
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => c1a_en,
        D_in    => c1a_in,
        D_out   => c1a_out
    );
    
    c2aReg: entity work.myReg
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => c2a_en,
        D_in    => c2a_in,
        D_out   => c2a_out
    );
    
    c3aReg: entity work.myReg
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => c3a_en,
        D_in    => c3a_in,
        D_out   => c3a_out
    );
    
    c1bReg: entity work.myReg
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => c1b_en,
        D_in    => c1b_in,
        D_out   => c1b_out
    );
    
    c2bReg: entity work.myReg
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => c2b_en,
        D_in    => c2b_in,
        D_out   => c2b_out
    );
    
    c3bReg: entity work.myReg
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => c3b_en,
        D_in    => c3b_in,
        D_out   => c3b_out
    );
    
    d1aReg: entity work.myReg
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => d1a_en,
        D_in    => d1a_in,
        D_out   => d1a_out
    );
    
    d2aReg: entity work.myReg
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => d2a_en,
        D_in    => d2a_in,
        D_out   => d2a_out
    );
    
    d1bReg: entity work.myReg
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => d1b_en,
        D_in    => d1b_in,
        D_out   => d1b_out
    );
    
    d2bReg: entity work.myReg
    generic map( b => 64)
    Port map(
        clk     => clk,
        rst     => '0',
        en      => d2b_en,
        D_in    => d2b_in,
        D_out   => d2b_out
    );  
    ---------------------------------------------------
    
    ValidBytesReg: entity work.myReg
    generic map( b => 4)
    Port map(
        clk     => clk,
        rst     => ValidBytesReg_rst,
        en      => ValidBytesReg_en,
        D_in    => bdi_valid_bytes,
        D_out   => ValidBytesReg_out
    );

    ---------------------------------------------------------------------------------
    Sync: process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                state   <= idle;
            else
                state   <= next_state;
            
                if (ctr_words_rst = '1') then
                    ctr_words   <= "000";
                elsif (ctr_words_inc = '1') then
                    ctr_words   <= ctr_words + 1;
                end if;
                
                if (ctr_bytes_rst = '1') then
                    ctr_bytes   <= "00000";
                elsif (ctr_bytes_inc = '1') then
                    ctr_bytes   <= ctr_bytes + bdi_size;
                elsif (ctr_bytes_dec = '1') then
                    ctr_bytes   <= ctr_bytes - 4;
                end if;
                
                if (decrypt_rst = '1') then
                    decrypt_reg <= '0';
                elsif (decrypt_set = '1') then
                    decrypt_reg <= '1';
                end if;
                
                if (first_AD_rst = '1') then
                    first_AD_reg <= '0';
                elsif (first_AD_set = '1') then
                    first_AD_reg <= '1';
                end if;
                
                if (last_AD_rst = '1') then
                    last_AD_reg <= '0';
                elsif (last_AD_set = '1') then
                    last_AD_reg <= '1';
                end if;
                
                if (no_AD_rst = '1') then
                    no_AD_reg   <= '0';
                elsif (no_AD_set = '1') then
                    no_AD_reg   <= '1';
                end if;
                
                if (first_M_rst = '1') then
                    first_M_reg <= '0';
                elsif (first_M_set = '1') then
                    first_M_reg <= '1';
                end if;
                
                if (last_M_rst = '1') then
                    last_M_reg  <= '0';
                elsif (last_M_set = '1') then
                    last_M_reg  <= '1';
                end if;
                
                if (no_M_rst = '1') then
                    no_M_reg   <= '0';
                elsif (no_M_set = '1') then
                    no_M_reg   <= '1';
                end if;
                
            end if;
        end if;
    end process;
    
    Controller: process(state, key0, key1, key2, key_valid, key_update, bdi0, bdi1, bdi2, bdi_valid,
                        bdi_eot, bdi_eoi, bdi_type, ctr_words, ctr_bytes, CHAM_done, bdo_ready, msg_auth_ready)
                       
    begin
        init                <= '0';
        next_state          <= idle;
        key_ready           <= '0';
        bdi_ready           <= '0';
        ctr_words_rst       <= '0';
        ctr_words_inc       <= '0';
        ctr_bytes_rst       <= '0';
        ctr_bytes_inc       <= '0';
        ctr_bytes_dec       <= '0';
        KeyReg0_rst         <= '0';
        KeyReg0_en          <= '0';
        KeyReg0_in          <= (others => '0');
        KeyReg1_rst         <= '0';
        KeyReg1_en          <= '0';
        KeyReg1_in          <= (others => '0');
        KeyReg2_rst         <= '0';
        KeyReg2_en          <= '0';
        KeyReg2_in          <= (others => '0');
        iDataReg0_rst       <= '0';
        iDataReg0_en        <= '0';
        iDataReg0_in        <= (others => '0');
        iDataReg1_rst       <= '0';
        iDataReg1_en        <= '0';
        iDataReg1_in        <= (others => '0');
        iDataReg2_rst       <= '0';
        iDataReg2_en        <= '0';
        iDataReg2_in        <= (others => '0');
        oDataReg0_rst       <= '0';
        oDataReg0_en        <= '0';
        oDataReg0_in        <= (others => '0');
        oDataReg1_rst       <= '0';
        oDataReg1_en        <= '0';
        oDataReg1_in        <= (others => '0');
        oDataReg2_rst       <= '0';
        oDataReg2_en        <= '0';
        oDataReg2_in        <= (others => '0');
        ZstateReg0_rst      <= '0';
        ZstateReg0_en       <= '0';
        ZstateReg0_in       <= (others => '0');
        ZstateReg1_rst      <= '0';
        ZstateReg1_en       <= '0';
        ZstateReg1_in       <= (others => '0');
        ZstateReg2_rst      <= '0';
        ZstateReg2_en       <= '0';
        ZstateReg2_in       <= (others => '0');
        YstateReg0_rst      <= '0';
        YstateReg0_en       <= '0';
        YstateReg0_in       <= (others => '0');
        YstateReg1_rst      <= '0';
        YstateReg1_en       <= '0';
        YstateReg1_in       <= (others => '0');
        YstateReg2_rst      <= '0';
        YstateReg2_en       <= '0';
        YstateReg2_in       <= (others => '0');
        raReg_en            <= '0';
        rbReg_en            <= '0';
        c1a_en              <= '0';
        c1a_in              <= (others => '0');
        c2a_en              <= '0';
        c2a_in              <= (others => '0');
        c3a_en              <= '0';
        c3a_in              <= (others => '0');
        c1b_en              <= '0';
        c1b_in              <= (others => '0');
        c2b_en              <= '0';
        c2b_in              <= (others => '0');
        c3b_en              <= '0';
        c3b_in              <= (others => '0');
        d1a_en              <= '0';
        d1a_in              <= (others => '0');
        d2a_en              <= '0';
        d2a_in              <= (others => '0');
        d1b_en              <= '0';
        d1b_in              <= (others => '0');
        d2b_en              <= '0';
        d2b_in              <= (others => '0');
        ValidBytesReg_rst   <= '0';
        ValidBytesReg_en    <= '0';
        decrypt_rst         <= '0';
        decrypt_set         <= '0';
        first_AD_rst        <= '0';
        first_AD_set        <= '0';
        last_AD_rst         <= '0';
        last_AD_set         <= '0';
        no_AD_rst           <= '0';
        no_AD_set           <= '0';
        first_M_rst         <= '0';
        first_M_set         <= '0';
        last_M_rst          <= '0';
        last_M_set          <= '0';
        no_M_rst            <= '0';
        no_M_set            <= '0'; 
        bdo_valid           <= '0';                   
        end_of_block        <= '0';
        bdo_valid_bytes     <= (others => '0');
        msg_auth            <= '0';
        msg_auth_valid      <= '0'; 
        CHAM_start          <= '0';
        
        case state is
            when idle =>
                ctr_words_rst   <= '1';
                ctr_bytes_rst   <= '1';
                iDataReg0_rst   <= '1';
                iDataReg1_rst   <= '1';
                iDataReg2_rst   <= '1';
                oDataReg0_rst   <= '1';
                oDataReg1_rst   <= '1';
                oDataReg2_rst   <= '1';
                ZstateReg0_rst  <= '1';
                ZstateReg1_rst  <= '1';
                ZstateReg2_rst  <= '1';
                YstateReg0_rst  <= '1';
                YstateReg1_rst  <= '1';
                YstateReg2_rst  <= '1';
                decrypt_rst     <= '1';
                first_AD_rst    <= '1';
                last_AD_rst     <= '1';
                no_AD_rst       <= '1';
                first_M_rst     <= '1';
                last_M_rst      <= '1';
                no_M_rst        <= '1';
                next_state      <= wait_key;
                
            when wait_key =>
                if (key_valid = '1' and key_update = '1') then
                    KeyReg0_rst     <= '1'; -- No need to keep the previous key
                    KeyReg1_rst     <= '1';
                    KeyReg2_rst     <= '1';
                    next_state      <= load_key;
                elsif (bdi_valid = '1') then
                    next_state      <= wait_Npub;
                else
                    next_state      <= wait_key;
                end if;
                
            when load_key =>
                key_ready       <= '1';
                if (key_valid = '1') then
                    KeyReg0_en      <= '1';
                    KeyReg1_en      <= '1';
                    KeyReg2_en      <= '1';
                    KeyReg0_in      <= KeyReg0_out(95 downto 0) & key0(7 downto 0) & key0(15 downto 8) & key0(23 downto 16) & key0(31 downto 24);
                    KeyReg1_in      <= KeyReg1_out(95 downto 0) & key1(7 downto 0) & key1(15 downto 8) & key1(23 downto 16) & key1(31 downto 24);
                    KeyReg2_in      <= KeyReg2_out(95 downto 0) & key2(7 downto 0) & key2(15 downto 8) & key2(23 downto 16) & key2(31 downto 24);
                    ctr_words_inc   <= '1';
                end if;
                if (ctr_words = 3 and key_valid = '1') then
                    ctr_words_rst   <= '1';
                    next_state      <= wait_Npub;
                else
                    next_state      <= load_key;
                end if;
                
            when wait_Npub =>
                if (bdi_type = HDR_NPUB) then
                    next_state  <= load_Npub;
                else
                    next_state  <= wait_Npub;
                end if;
                
            when load_Npub =>
                bdi_ready           <= '1';
                if (bdi_valid = '1') then
                    iDataReg0_en        <= '1';
                    iDataReg1_en        <= '1';
                    iDataReg2_en        <= '1';
                    iDataReg0_in        <= iDataReg0_out(95 downto 0) & bdi0(7 downto 0) & bdi0(15 downto 8) & bdi0(23 downto 16) & bdi0(31 downto 24);
                    iDataReg1_in        <= iDataReg1_out(95 downto 0) & bdi1(7 downto 0) & bdi1(15 downto 8) & bdi1(23 downto 16) & bdi1(31 downto 24);
                    iDataReg2_in        <= iDataReg2_out(95 downto 0) & bdi2(7 downto 0) & bdi2(15 downto 8) & bdi2(23 downto 16) & bdi2(31 downto 24);
                    ctr_words_inc       <= '1';
                end if;
                if (decrypt_in = '1') then -- Decryption
                    decrypt_set     <= '1';
                else                       -- Encryption
                    decrypt_rst     <= '1';
                end if;
                if (bdi_eoi = '1') then -- No AD and no data
                    no_AD_set       <= '1';
                    no_M_set        <= '1';
                end if;
                if (ctr_words = 3 and bdi_valid = '1') then 
                    ctr_words_rst   <= '1';
                    next_state      <= process_Npub;
                else
                    next_state      <= load_Npub;
                end if;
                
            when process_Npub =>
                init                <= '1';
                CHAM_start          <= '1';
                if (CHAM_done = '1') then
                    CHAM_start          <= '0';
                    ZstateReg0_en       <= '1';
                    ZstateReg1_en       <= '1';
                    ZstateReg2_en       <= '1';
                    ZstateReg0_in       <= CHAM_out0; -- Z0 = E(N, key)
                    ZstateReg1_in       <= CHAM_out1;
                    ZstateReg2_in       <= CHAM_out2;
                    YstateReg0_en       <= '1';
                    YstateReg1_en       <= '1';
                    YstateReg2_en       <= '1';
                    YstateReg0_in       <= KeyReg0_out(31 downto 0)  & KeyReg0_out(63 downto 32) & -- Y0 = key
                                           KeyReg0_out(95 downto 64) & KeyReg0_out(127 downto 96); 
                    YstateReg1_in       <= KeyReg1_out(31 downto 0)  & KeyReg1_out(63 downto 32) &
                                           KeyReg1_out(95 downto 64) & KeyReg1_out(127 downto 96); 
                    YstateReg2_in       <= KeyReg2_out(31 downto 0)  & KeyReg2_out(63 downto 32) &
                                           KeyReg2_out(95 downto 64) & KeyReg2_out(127 downto 96);                        
                    if (no_AD_reg = '1' and no_M_reg = '1') then  -- No AD and no data
                        ZstateReg0_en   <= '1';
                        ZstateReg1_en   <= '1';
                        ZstateReg2_en   <= '1';
                        ZstateReg0_in   <= phi(CHAM_out0 xor ("10000" & zero123)); -- Go to process tag
                        ZstateReg1_in   <= phi(CHAM_out1);
                        ZstateReg2_in   <= phi(CHAM_out2);
                        next_state      <= process_tag;
                    elsif (bdi_type = HDR_AD) then
                        first_AD_set    <= '1';
                        next_state      <= wait_AD;
                    elsif ((bdi_type = HDR_MSG) or (bdi_type = HDR_CT)) then -- No AD
                        no_AD_set       <= '1';
                        first_M_set     <= '1';
                        next_state      <= wait_data; 
                    end if;
                else
                    next_state          <= process_Npub;
                end if;
                
            when wait_AD =>
                if (first_AD_reg = '1') then
                    first_AD_rst    <= '1';
                    ZstateReg0_en   <= '1';
                    ZstateReg0_in   <= ZstateReg0_out xor ("00001" & zero123); -- Start of non-empty AD
                end if;
                if (bdi_type = HDR_AD) then                    
                    iDataReg0_rst   <= '1'; -- Reset the register for the new input
                    iDataReg1_rst   <= '1';
                    iDataReg2_rst   <= '1';
                    next_state      <= load_AD;
                else
                    next_state  <= wait_AD;
                end if;    
            
            when load_AD =>
                bdi_ready       <= '1';
                if (bdi_valid = '1') then
                    ctr_words_inc   <= '1';
                    ctr_bytes_inc   <= '1';
                    iDataReg0_en    <= '1';
                    iDataReg1_en    <= '1';
                    iDataReg2_en    <= '1';
                    iDataReg0_in    <= myMux(iDataReg0_out, bdi0(7 downto 0) & bdi0(15 downto 8) & bdi0(23 downto 16) & bdi0(31 downto 24), ctr_words);
                    iDataReg1_in    <= myMux(iDataReg1_out, bdi1(7 downto 0) & bdi1(15 downto 8) & bdi1(23 downto 16) & bdi1(31 downto 24), ctr_words);
                    iDataReg2_in    <= myMux(iDataReg2_out, bdi2(7 downto 0) & bdi2(15 downto 8) & bdi2(23 downto 16) & bdi2(31 downto 24), ctr_words);
                end if;
                if (bdi_eot = '1' and bdi_eoi = '1') then -- No data
                    no_M_set        <= '1';
                end if;
                if (bdi_eot = '1') then -- Last block of AD
                    last_AD_set     <= '1';
                end if;
                if ((bdi_eot = '1' or ctr_words = 3) and bdi_valid = '1') then -- Have gotten a full block of AD
                    ctr_words_rst   <= '1';
                    ZstateReg0_en   <= '1';
                    ZstateReg1_en   <= '1';
                    ZstateReg2_en   <= '1';
                    if ((ctr_words /= 3) or (bdi_size /= "100")) then -- Last partial block
                        ZstateReg0_in   <= phi(ZstateReg0_out xor ("00010" & zero123));
                        ZstateReg1_in   <= phi(ZstateReg1_out);
                        ZstateReg2_in   <= phi(ZstateReg2_out);
                    else
                        ZstateReg0_in   <= phi(ZstateReg0_out);
                        ZstateReg1_in   <= phi(ZstateReg1_out);
                        ZstateReg2_in   <= phi(ZstateReg2_out);
                    end if;
                    next_state      <= process_AD;
                else
                    next_state      <= load_AD;
                end if;                   
            
            when process_AD =>
                CHAM_start          <= '1';
                if (CHAM_done = '1') then
                    CHAM_start      <= '0';
                    ctr_bytes_rst   <= '1';
                    YstateReg0_en   <= '1';
                    YstateReg1_en   <= '1';
                    YstateReg2_en   <= '1';
                    YstateReg0_in   <= CHAM_out0 xor pad(iDataReg0_out, conv_integer(ctr_bytes)); -- CHAM_out: X, iDataReg_out: AD, Y: CHAM input
                    YstateReg1_in   <= CHAM_out1 xor pad(iDataReg1_out, conv_integer(ctr_bytes));
                    YstateReg2_in   <= CHAM_out2 xor pad(iDataReg2_out, conv_integer(ctr_bytes));
                    if (no_M_reg = '1' and last_AD_reg = '1') then -- No data, go to process tag
                        iDataReg0_rst   <= '1';
                        iDataReg1_rst   <= '1';
                        iDataReg2_rst   <= '1';
                        ZstateReg0_en   <= '1';
                        ZstateReg1_en   <= '1';
                        ZstateReg2_en   <= '1';
                        ZstateReg0_in   <= phi(ZstateReg0_out xor ("10000" & zero123));
                        ZstateReg1_in   <= phi(ZstateReg1_out);
                        ZstateReg2_in   <= phi(ZstateReg2_out);
                        next_state      <= process_tag;
                    elsif (last_AD_reg = '0') then -- Still loading AD
                        next_state  <= wait_AD;
                    elsif (no_M_reg = '0') then -- No AD, start loading data
                        first_M_set <= '1';
                        next_state  <= wait_data;
                    end if;
                else
                    next_state      <= process_AD;
                end if;
                
             when wait_data =>
                if (first_M_reg = '1') then
                    first_M_rst     <= '1';
                    ZstateReg0_en   <= '1';
                    ZstateReg0_in   <= ZstateReg0_out xor (zero120 & "00100000"); -- Start of non-empty M
                end if;
                if (bdi_type = HDR_MSG or bdi_type = HDR_CT) then
                    iDataReg0_rst   <= '1'; 
                    iDataReg1_rst   <= '1'; 
                    iDataReg2_rst   <= '1';                
                    next_state      <= load_data;
                else
                    next_state      <= wait_data;
                end if;
                
            when load_data =>
                bdi_ready           <= '1'; 
                if (bdi_valid = '1') then
                    ctr_words_inc       <= '1';
                    ctr_bytes_inc       <= '1';
                    ValidBytesReg_en    <= '1'; -- Register bdi_valid_bytes for outputting CT
                    iDataReg0_en        <= '1';
                    iDataReg1_en        <= '1';
                    iDataReg2_en        <= '1';
                    iDataReg0_in        <= myMux(iDataReg0_out, bdi0(7 downto 0) & bdi0(15 downto 8) & bdi0(23 downto 16) & bdi0(31 downto 24), ctr_words);
                    iDataReg1_in        <= myMux(iDataReg1_out, bdi1(7 downto 0) & bdi1(15 downto 8) & bdi1(23 downto 16) & bdi1(31 downto 24), ctr_words);
                    iDataReg2_in        <= myMux(iDataReg2_out, bdi2(7 downto 0) & bdi2(15 downto 8) & bdi2(23 downto 16) & bdi2(31 downto 24), ctr_words);
                end if;            
                if (bdi_eot = '1') then -- Last block of data
                    last_M_set      <= '1';
                end if;
                if ((bdi_eot = '1' or ctr_words = 3) and bdi_valid = '1') then -- Have gotten a block of M
                    ctr_words_rst   <= '1';
                    ZstateReg0_en    <= '1';
                    ZstateReg1_en    <= '1';
                    ZstateReg2_en    <= '1';
                    if ((ctr_words /= 3) or (bdi_size /= "100")) then -- Last partial block
                        ZstateReg0_in    <= phi(ZstateReg0_out xor ("01000" & zero123));
                    else
                        ZstateReg0_in    <= phi(ZstateReg0_out);
                    end if;
                    ZstateReg1_in   <= phi(ZstateReg1_out);
                    ZstateReg2_in   <= phi(ZstateReg2_out);
                    next_state      <= process_data;
                else
                    next_state      <= load_data;
                end if;
            
            when process_data =>
                CHAM_start          <= '1';
                if (CHAM_done = '1') then
                    CHAM_start      <= '0';
                    YstateReg0_en   <= '1';
                    YstateReg1_en   <= '1';
                    YstateReg2_en   <= '1';
                    if (decrypt_reg = '0') then -- Encryption 
                        YstateReg0_in   <= CHAM_out0 xor pad(iDataReg0_out, conv_integer(ctr_bytes)); -- CHAM_out: X, iDataReg_out: M, Y: CHAM input
                        YstateReg1_in   <= CHAM_out1 xor pad(iDataReg1_out, conv_integer(ctr_bytes));
                        YstateReg2_in   <= CHAM_out2 xor pad(iDataReg2_out, conv_integer(ctr_bytes));
                    else                        -- Decryption
                        YstateReg0_in   <= CHAM_out0 xor pad((shuffle(CHAM_out0) xor iDataReg0_out), conv_integer(ctr_bytes)); -- CHAM_out: X, iDataReg_out: CT, Y: CHAM input
                        YstateReg1_in   <= CHAM_out1 xor pad((shuffle(CHAM_out1) xor iDataReg1_out), conv_integer(ctr_bytes));
                        YstateReg2_in   <= CHAM_out2 xor pad((shuffle(CHAM_out2) xor iDataReg2_out), conv_integer(ctr_bytes));
                    end if;
                    oDataReg0_en    <= '1';
                    oDataReg1_en    <= '1';
                    oDataReg2_en    <= '1';
                    oDataReg0_in    <= shuffle(CHAM_out0) xor iDataReg0_out; -- Enc: CT = shuffle(X) xor M, Dec: M = shuffle(X) xor CT
                    oDataReg1_in    <= shuffle(CHAM_out1) xor iDataReg1_out;
                    oDataReg2_in    <= shuffle(CHAM_out2) xor iDataReg2_out;
                    next_state      <= output_data;
                else
                    next_state      <= process_data;
                end if;
                
            when output_data =>
                if (bdo_ready = '1') then
                    bdo_valid           <= '1';  
                    bdo_type            <= HDR_CT;
                    ctr_words_inc       <= '1';
                    if (ctr_bytes <= 4) then -- Last 4 bytes of data
                        end_of_block    <= last_M_reg;
                    else
                        end_of_block    <= '0';
                    end if;
                end if;
                if (bdo_ready = '1' and last_M_reg = '1' and ctr_bytes <= 4) then -- Last word of last block of output
                    ctr_words_rst       <= '1';
                    ctr_bytes_rst       <= '1';
                    iDataReg0_rst       <= '1';
                    iDataReg1_rst       <= '1';
                    iDataReg2_rst       <= '1';
                    bdo_valid_bytes     <= ValidBytesReg_out;
                    bdo0                <= chop(BE2LE(oDataReg0_out((conv_integer(ctr_words)*32 + 31) downto (conv_integer(ctr_words)*32))), ctr_bytes);
                    bdo1                <= chop(BE2LE(oDataReg1_out((conv_integer(ctr_words)*32 + 31) downto (conv_integer(ctr_words)*32))), ctr_bytes);
                    bdo2                <= chop(BE2LE(oDataReg2_out((conv_integer(ctr_words)*32 + 31) downto (conv_integer(ctr_words)*32))), ctr_bytes);
                    ZstateReg0_en       <= '1';
                    ZstateReg1_en       <= '1';
                    ZstateReg2_en       <= '1';
                    ZstateReg0_in       <= phi(ZstateReg0_out xor ("10000" & zero123)); -- Process tag
                    ZstateReg1_in       <= phi(ZstateReg1_out);
                    ZstateReg2_in       <= phi(ZstateReg2_out);
                    next_state          <= process_tag; -- No more M and no more CT, go to process tag
                elsif (bdo_ready = '1') then
                    bdo_valid_bytes     <= "1111";
                    bdo0                <= BE2LE(oDataReg0_out((conv_integer(ctr_words)*32 + 31) downto (conv_integer(ctr_words)*32)));
                    bdo1                <= BE2LE(oDataReg1_out((conv_integer(ctr_words)*32 + 31) downto (conv_integer(ctr_words)*32)));
                    bdo2                <= BE2LE(oDataReg2_out((conv_integer(ctr_words)*32 + 31) downto (conv_integer(ctr_words)*32)));
                    ctr_bytes_dec       <= '1';
                    if (ctr_words = 3) then -- 4 words of CT are done
                        ctr_words_rst   <= '1';
                        ctr_bytes_rst   <= '1';
                        next_state      <= wait_data;
                    else
                        next_state      <= output_data;
                    end if;
                else
                    next_state          <= output_data;
                end if;

            when process_tag =>
                CHAM_start          <= '1';
                if (CHAM_done = '1') then
                    CHAM_start      <= '0';
                    oDataReg0_en    <= '1';
                    oDataReg1_en    <= '1';
                    oDataReg2_en    <= '1';
                    oDataReg0_in    <= CHAM_out0(7 downto 0)    & CHAM_out0(15 downto 8)    & CHAM_out0(23 downto 16)   & CHAM_out0(31 downto 24) &
                                       CHAM_out0(39 downto 32)  & CHAM_out0(47 downto 40)   & CHAM_out0(55 downto 48)   & CHAM_out0(63 downto 56) &
                                       CHAM_out0(71 downto 64)  & CHAM_out0(79 downto 72)   & CHAM_out0(87 downto 80)   & CHAM_out0(95 downto 88) &
                                       CHAM_out0(103 downto 96) & CHAM_out0(111 downto 104) & CHAM_out0(119 downto 112) & CHAM_out0(127 downto 120);
                                       
                    oDataReg1_in    <= CHAM_out1(7 downto 0)    & CHAM_out1(15 downto 8)    & CHAM_out1(23 downto 16)   & CHAM_out1(31 downto 24) &
                                       CHAM_out1(39 downto 32)  & CHAM_out1(47 downto 40)   & CHAM_out1(55 downto 48)   & CHAM_out1(63 downto 56) &
                                       CHAM_out1(71 downto 64)  & CHAM_out1(79 downto 72)   & CHAM_out1(87 downto 80)   & CHAM_out1(95 downto 88) &
                                       CHAM_out1(103 downto 96) & CHAM_out1(111 downto 104) & CHAM_out1(119 downto 112) & CHAM_out1(127 downto 120);
                                       
                    oDataReg2_in    <= CHAM_out2(7 downto 0)    & CHAM_out2(15 downto 8)    & CHAM_out2(23 downto 16)   & CHAM_out2(31 downto 24) &
                                       CHAM_out2(39 downto 32)  & CHAM_out2(47 downto 40)   & CHAM_out2(55 downto 48)   & CHAM_out2(63 downto 56) &
                                       CHAM_out2(71 downto 64)  & CHAM_out2(79 downto 72)   & CHAM_out2(87 downto 80)   & CHAM_out2(95 downto 88) &
                                       CHAM_out2(103 downto 96) & CHAM_out2(111 downto 104) & CHAM_out2(119 downto 112) & CHAM_out2(127 downto 120);
                    if (decrypt_reg = '0') then -- Encryption
                        next_state  <= output_tag;
                    else                        -- Decryption
                        next_state  <= wait_tag;   
                    end if;
                else
                    next_state      <= process_tag;
                end if;
                
            when output_tag =>
                if (bdo_ready = '1') then 
                    bdo_valid <= '1';                  
                    bdo_valid_bytes <= "1111";
                    bdo_type        <= HDR_TAG;
                    bdo0            <= oDataReg0_out((127 - conv_integer(ctr_words)*32) downto (96 - conv_integer(ctr_words)*32)); -- Here, oDataReg_out is the output tag
                    bdo1            <= oDataReg1_out((127 - conv_integer(ctr_words)*32) downto (96 - conv_integer(ctr_words)*32));
                    bdo2            <= oDataReg2_out((127 - conv_integer(ctr_words)*32) downto (96 - conv_integer(ctr_words)*32));                
                    ctr_words_inc   <= '1';
                end if;
                 if (ctr_words = 3 and bdo_ready = '1') then
                    end_of_block <= '1'; -- Last 4 bytes of Tag
                    ctr_words_rst    <= '1';
                    next_state       <= idle;
                 else
                    end_of_block <= '0';
                    next_state       <= output_tag;
                 end if; 
                 
           when wait_tag =>
                if (bdi_type = HDR_TAG) then
                    iDataReg0_rst   <= '1'; 
                    iDataReg1_rst   <= '1';
                    iDataReg2_rst   <= '1';
                    next_state      <= load_tag;
                else
                    next_state      <= wait_tag;
                end if;
             
            when load_tag =>
                bdi_ready               <= '1';
                if (bdi_valid = '1') then
                    iDataReg0_en        <= '1';
                    iDataReg1_en        <= '1';
                    iDataReg2_en        <= '1';
                    iDataReg0_in        <= iDataReg0_out(95 downto 0) & bdi0; -- Here, iDataReg_out is the input tag
                    iDataReg1_in        <= iDataReg1_out(95 downto 0) & bdi1;
                    iDataReg2_in        <= iDataReg2_out(95 downto 0) & bdi2;
                    ctr_words_inc       <= '1';
                end if;
                if (ctr_words = 3 and bdi_valid = '1') then
                    ctr_words_rst       <= '1';
                    next_state          <= verify_tag1;
                else
                    next_state          <= load_tag;
                end if;   
            
            when verify_tag1 =>
                c1a_en      <= '1';
                c1a_in      <= iDataReg0_out(127 downto 64) xor oDataReg0_out(127 downto 64);
                next_state  <= verify_tag2;
                
            when verify_tag2 =>    
                c2a_en      <= '1';
                c1b_en      <= '1';
                c2a_in      <= iDataReg1_out(127 downto 64) xor oDataReg1_out(127 downto 64);   
                c1b_in      <= iDataReg0_out(63 downto 0) xor oDataReg0_out(63 downto 0);
                next_state  <= verify_tag3;
                
            when verify_tag3 =>  
                raReg_en    <= '1';  
                c3a_en      <= '1';
                c2b_en      <= '1';
                c3a_in      <= iDataReg2_out(127 downto 64) xor oDataReg2_out(127 downto 64);    
                c2b_in      <= iDataReg1_out(63 downto 0) xor oDataReg1_out(63 downto 0);
                next_state  <= verify_tag4;
                
            when verify_tag4 => 
                rbReg_en    <= '1';                  
                d1a_en      <= '1';
                c3b_en      <= '1';
                d1a_in      <= c1a_out xor c2a_out xor ra;
                c3b_in      <= iDataReg2_out(63 downto 0) xor oDataReg2_out(63 downto 0);
                next_state  <= verify_tag5;
                
            when verify_tag5 =>                    
                d2a_en      <= '1';
                d1b_en      <= '1';
                d2a_in      <= d1a_out xor c3a_out xor ra;
                d1b_in      <= c1b_out xor c2b_out xor rb;
                next_state  <= verify_tag6;
                
           when verify_tag6 =>   
                d2b_en      <= '1';
                d2b_in      <= d1b_out xor c3b_out xor rb;
                next_state  <= verify_tag7; 
           
           when verify_tag7 =>                   
                if (msg_auth_ready = '1' and (d2a_out = 0) and (d2b_out = 0)) then
                    ctr_words_rst   <= '1';
                    msg_auth_valid  <= '1';
                    msg_auth        <= '1';
                    next_state      <= idle; 
                elsif (msg_auth_ready = '1') then
                    ctr_words_rst   <= '1';
                    msg_auth_valid  <= '1';
                    msg_auth        <= '0';
                    next_state      <= idle; 
                else
                    next_state      <= verify_tag7;
                end if;
                
           when others => null;
        end case;
    end process;


end Behavioral;
