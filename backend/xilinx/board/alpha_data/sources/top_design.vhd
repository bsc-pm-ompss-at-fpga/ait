library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity MCXX_TOP_DESIGN is
  port (
    C0_DDR3_addr : out STD_LOGIC_VECTOR ( 15 downto 0 );
    C0_DDR3_ba : out STD_LOGIC_VECTOR ( 2 downto 0 );
    C0_DDR3_cas_n : out STD_LOGIC;
    C0_DDR3_ck_n : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C0_DDR3_ck_p : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C0_DDR3_cke : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C0_DDR3_cs_n : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C0_DDR3_dq : inout STD_LOGIC_VECTOR ( 71 downto 0 );
    C0_DDR3_dqs_n : inout STD_LOGIC_VECTOR ( 8 downto 0 );
    C0_DDR3_dqs_p : inout STD_LOGIC_VECTOR ( 8 downto 0 );
    C0_DDR3_odt : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C0_DDR3_ras_n : out STD_LOGIC;
    C0_DDR3_reset_n : out STD_LOGIC;
    C0_DDR3_we_n : out STD_LOGIC;
    C1_DDR3_addr : out STD_LOGIC_VECTOR ( 15 downto 0 );
    C1_DDR3_ba : out STD_LOGIC_VECTOR ( 2 downto 0 );
    C1_DDR3_cas_n : out STD_LOGIC;
    C1_DDR3_ck_n : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C1_DDR3_ck_p : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C1_DDR3_cke : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C1_DDR3_cs_n : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C1_DDR3_dq : inout STD_LOGIC_VECTOR ( 71 downto 0 );
    C1_DDR3_dqs_n : inout STD_LOGIC_VECTOR ( 8 downto 0 );
    C1_DDR3_dqs_p : inout STD_LOGIC_VECTOR ( 8 downto 0 );
    C1_DDR3_odt : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C1_DDR3_ras_n : out STD_LOGIC;
    C1_DDR3_reset_n : out STD_LOGIC;
    C1_DDR3_we_n : out STD_LOGIC;
    -- Refclk Top Level Signals Added
    refclk400m0_p    : in    std_logic;
    refclk400m0_n    : in    std_logic;
    refclk400m1_p    : in    std_logic;
    refclk400m1_n    : in    std_logic;
    -- Model Inout Signal name changed
    model_inout : inout STD_LOGIC_VECTOR ( 55 downto 0 );
    pci_exp_rxn : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pci_exp_rxp : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pci_exp_txn : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pci_exp_txp : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pcie100_clk_n : in STD_LOGIC;
    pcie100_clk_p : in STD_LOGIC;
    perst_n : in STD_LOGIC;
    refclk200_clk_n : in STD_LOGIC;
    refclk200_clk_p : in STD_LOGIC;
    -- DRAM Power Supply signals, Data Masks and LEDs added
    c0_ddr3_dm       : out   std_logic_vector(8 downto 0);
    c1_ddr3_dm       : out   std_logic_vector(8 downto 0);
    dram_0_on : out std_logic;
    dram_1_on : out std_logic;
    usr_led : out std_logic_vector(5 downto 0) 
  );
end MCXX_TOP_DESIGN;

architecture STRUCTURE of MCXX_TOP_DESIGN is
  component MCXX_DESIGN_WRAPPER is
  port (
    C0_DDR3_dq : inout STD_LOGIC_VECTOR ( 71 downto 0 );
    C0_DDR3_dqs_p : inout STD_LOGIC_VECTOR ( 8 downto 0 );
    C0_DDR3_dqs_n : inout STD_LOGIC_VECTOR ( 8 downto 0 );
    C0_DDR3_addr : out STD_LOGIC_VECTOR ( 15 downto 0 );
    C0_DDR3_ba : out STD_LOGIC_VECTOR ( 2 downto 0 );
    C0_DDR3_ras_n : out STD_LOGIC;
    C0_DDR3_cas_n : out STD_LOGIC;
    C0_DDR3_we_n : out STD_LOGIC;
    C0_DDR3_reset_n : out STD_LOGIC;
    C0_DDR3_ck_p : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C0_DDR3_ck_n : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C0_DDR3_cke : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C0_DDR3_cs_n : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C0_DDR3_odt : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C1_DDR3_dq : inout STD_LOGIC_VECTOR ( 71 downto 0 );
    C1_DDR3_dqs_p : inout STD_LOGIC_VECTOR ( 8 downto 0 );
    C1_DDR3_dqs_n : inout STD_LOGIC_VECTOR ( 8 downto 0 );
    C1_DDR3_addr : out STD_LOGIC_VECTOR ( 15 downto 0 );
    C1_DDR3_ba : out STD_LOGIC_VECTOR ( 2 downto 0 );
    C1_DDR3_ras_n : out STD_LOGIC;
    C1_DDR3_cas_n : out STD_LOGIC;
    C1_DDR3_we_n : out STD_LOGIC;
    C1_DDR3_reset_n : out STD_LOGIC;
    C1_DDR3_ck_p : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C1_DDR3_ck_n : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C1_DDR3_cke : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C1_DDR3_cs_n : out STD_LOGIC_VECTOR ( 1 downto 0 );
    C1_DDR3_odt : out STD_LOGIC_VECTOR ( 1 downto 0 );
    c0_sys_clk_i : in STD_LOGIC;
    c1_sys_clk_i : in STD_LOGIC;
    c0_init_calib_complete : out STD_LOGIC;
    c1_mmcm_locked : out STD_LOGIC;
    c1_init_calib_complete : out STD_LOGIC;
    c0_mmcm_locked : out STD_LOGIC;
    pci_exp_txn : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pci_exp_rxn : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pci_exp_txp : out STD_LOGIC_VECTOR ( 7 downto 0 );
    pci_exp_rxp : in STD_LOGIC_VECTOR ( 7 downto 0 );
    pcie100_clk_p : in STD_LOGIC;
    pcie100_clk_n : in STD_LOGIC;
    refclk200_clk_p : in STD_LOGIC;
    refclk200_clk_n : in STD_LOGIC;
    perst_n : in STD_LOGIC;
    model_inout_tri_o : out STD_LOGIC_VECTOR ( 55 downto 0 );
    model_inout_tri_t : out STD_LOGIC_VECTOR ( 55 downto 0 );
    model_inout_tri_i : in STD_LOGIC_VECTOR ( 55 downto 0 )
  );
  end component MCXX_DESIGN_WRAPPER;
  component IOBUF is
  port (
    I : in STD_LOGIC;
    O : out STD_LOGIC;
    T : in STD_LOGIC;
    IO : inout STD_LOGIC
  );
  end component IOBUF;
  signal model_inout_tri_i_0 : STD_LOGIC_VECTOR ( 0 to 0 );
  signal model_inout_tri_i_1 : STD_LOGIC_VECTOR ( 1 to 1 );
  signal model_inout_tri_i_10 : STD_LOGIC_VECTOR ( 10 to 10 );
  signal model_inout_tri_i_11 : STD_LOGIC_VECTOR ( 11 to 11 );
  signal model_inout_tri_i_12 : STD_LOGIC_VECTOR ( 12 to 12 );
  signal model_inout_tri_i_13 : STD_LOGIC_VECTOR ( 13 to 13 );
  signal model_inout_tri_i_14 : STD_LOGIC_VECTOR ( 14 to 14 );
  signal model_inout_tri_i_15 : STD_LOGIC_VECTOR ( 15 to 15 );
  signal model_inout_tri_i_16 : STD_LOGIC_VECTOR ( 16 to 16 );
  signal model_inout_tri_i_17 : STD_LOGIC_VECTOR ( 17 to 17 );
  signal model_inout_tri_i_18 : STD_LOGIC_VECTOR ( 18 to 18 );
  signal model_inout_tri_i_19 : STD_LOGIC_VECTOR ( 19 to 19 );
  signal model_inout_tri_i_2 : STD_LOGIC_VECTOR ( 2 to 2 );
  signal model_inout_tri_i_20 : STD_LOGIC_VECTOR ( 20 to 20 );
  signal model_inout_tri_i_21 : STD_LOGIC_VECTOR ( 21 to 21 );
  signal model_inout_tri_i_22 : STD_LOGIC_VECTOR ( 22 to 22 );
  signal model_inout_tri_i_23 : STD_LOGIC_VECTOR ( 23 to 23 );
  signal model_inout_tri_i_24 : STD_LOGIC_VECTOR ( 24 to 24 );
  signal model_inout_tri_i_25 : STD_LOGIC_VECTOR ( 25 to 25 );
  signal model_inout_tri_i_26 : STD_LOGIC_VECTOR ( 26 to 26 );
  signal model_inout_tri_i_27 : STD_LOGIC_VECTOR ( 27 to 27 );
  signal model_inout_tri_i_28 : STD_LOGIC_VECTOR ( 28 to 28 );
  signal model_inout_tri_i_29 : STD_LOGIC_VECTOR ( 29 to 29 );
  signal model_inout_tri_i_3 : STD_LOGIC_VECTOR ( 3 to 3 );
  signal model_inout_tri_i_30 : STD_LOGIC_VECTOR ( 30 to 30 );
  signal model_inout_tri_i_31 : STD_LOGIC_VECTOR ( 31 to 31 );
  signal model_inout_tri_i_32 : STD_LOGIC_VECTOR ( 32 to 32 );
  signal model_inout_tri_i_33 : STD_LOGIC_VECTOR ( 33 to 33 );
  signal model_inout_tri_i_34 : STD_LOGIC_VECTOR ( 34 to 34 );
  signal model_inout_tri_i_35 : STD_LOGIC_VECTOR ( 35 to 35 );
  signal model_inout_tri_i_36 : STD_LOGIC_VECTOR ( 36 to 36 );
  signal model_inout_tri_i_37 : STD_LOGIC_VECTOR ( 37 to 37 );
  signal model_inout_tri_i_38 : STD_LOGIC_VECTOR ( 38 to 38 );
  signal model_inout_tri_i_39 : STD_LOGIC_VECTOR ( 39 to 39 );
  signal model_inout_tri_i_4 : STD_LOGIC_VECTOR ( 4 to 4 );
  signal model_inout_tri_i_40 : STD_LOGIC_VECTOR ( 40 to 40 );
  signal model_inout_tri_i_41 : STD_LOGIC_VECTOR ( 41 to 41 );
  signal model_inout_tri_i_42 : STD_LOGIC_VECTOR ( 42 to 42 );
  signal model_inout_tri_i_43 : STD_LOGIC_VECTOR ( 43 to 43 );
  signal model_inout_tri_i_44 : STD_LOGIC_VECTOR ( 44 to 44 );
  signal model_inout_tri_i_45 : STD_LOGIC_VECTOR ( 45 to 45 );
  signal model_inout_tri_i_46 : STD_LOGIC_VECTOR ( 46 to 46 );
  signal model_inout_tri_i_47 : STD_LOGIC_VECTOR ( 47 to 47 );
  signal model_inout_tri_i_48 : STD_LOGIC_VECTOR ( 48 to 48 );
  signal model_inout_tri_i_49 : STD_LOGIC_VECTOR ( 49 to 49 );
  signal model_inout_tri_i_5 : STD_LOGIC_VECTOR ( 5 to 5 );
  signal model_inout_tri_i_50 : STD_LOGIC_VECTOR ( 50 to 50 );
  signal model_inout_tri_i_51 : STD_LOGIC_VECTOR ( 51 to 51 );
  signal model_inout_tri_i_52 : STD_LOGIC_VECTOR ( 52 to 52 );
  signal model_inout_tri_i_53 : STD_LOGIC_VECTOR ( 53 to 53 );
  signal model_inout_tri_i_54 : STD_LOGIC_VECTOR ( 54 to 54 );
  signal model_inout_tri_i_55 : STD_LOGIC_VECTOR ( 55 to 55 );
  signal model_inout_tri_i_6 : STD_LOGIC_VECTOR ( 6 to 6 );
  signal model_inout_tri_i_7 : STD_LOGIC_VECTOR ( 7 to 7 );
  signal model_inout_tri_i_8 : STD_LOGIC_VECTOR ( 8 to 8 );
  signal model_inout_tri_i_9 : STD_LOGIC_VECTOR ( 9 to 9 );
  signal model_inout_tri_io_0 : STD_LOGIC_VECTOR ( 0 to 0 );
  signal model_inout_tri_io_1 : STD_LOGIC_VECTOR ( 1 to 1 );
  signal model_inout_tri_io_10 : STD_LOGIC_VECTOR ( 10 to 10 );
  signal model_inout_tri_io_11 : STD_LOGIC_VECTOR ( 11 to 11 );
  signal model_inout_tri_io_12 : STD_LOGIC_VECTOR ( 12 to 12 );
  signal model_inout_tri_io_13 : STD_LOGIC_VECTOR ( 13 to 13 );
  signal model_inout_tri_io_14 : STD_LOGIC_VECTOR ( 14 to 14 );
  signal model_inout_tri_io_15 : STD_LOGIC_VECTOR ( 15 to 15 );
  signal model_inout_tri_io_16 : STD_LOGIC_VECTOR ( 16 to 16 );
  signal model_inout_tri_io_17 : STD_LOGIC_VECTOR ( 17 to 17 );
  signal model_inout_tri_io_18 : STD_LOGIC_VECTOR ( 18 to 18 );
  signal model_inout_tri_io_19 : STD_LOGIC_VECTOR ( 19 to 19 );
  signal model_inout_tri_io_2 : STD_LOGIC_VECTOR ( 2 to 2 );
  signal model_inout_tri_io_20 : STD_LOGIC_VECTOR ( 20 to 20 );
  signal model_inout_tri_io_21 : STD_LOGIC_VECTOR ( 21 to 21 );
  signal model_inout_tri_io_22 : STD_LOGIC_VECTOR ( 22 to 22 );
  signal model_inout_tri_io_23 : STD_LOGIC_VECTOR ( 23 to 23 );
  signal model_inout_tri_io_24 : STD_LOGIC_VECTOR ( 24 to 24 );
  signal model_inout_tri_io_25 : STD_LOGIC_VECTOR ( 25 to 25 );
  signal model_inout_tri_io_26 : STD_LOGIC_VECTOR ( 26 to 26 );
  signal model_inout_tri_io_27 : STD_LOGIC_VECTOR ( 27 to 27 );
  signal model_inout_tri_io_28 : STD_LOGIC_VECTOR ( 28 to 28 );
  signal model_inout_tri_io_29 : STD_LOGIC_VECTOR ( 29 to 29 );
  signal model_inout_tri_io_3 : STD_LOGIC_VECTOR ( 3 to 3 );
  signal model_inout_tri_io_30 : STD_LOGIC_VECTOR ( 30 to 30 );
  signal model_inout_tri_io_31 : STD_LOGIC_VECTOR ( 31 to 31 );
  signal model_inout_tri_io_32 : STD_LOGIC_VECTOR ( 32 to 32 );
  signal model_inout_tri_io_33 : STD_LOGIC_VECTOR ( 33 to 33 );
  signal model_inout_tri_io_34 : STD_LOGIC_VECTOR ( 34 to 34 );
  signal model_inout_tri_io_35 : STD_LOGIC_VECTOR ( 35 to 35 );
  signal model_inout_tri_io_36 : STD_LOGIC_VECTOR ( 36 to 36 );
  signal model_inout_tri_io_37 : STD_LOGIC_VECTOR ( 37 to 37 );
  signal model_inout_tri_io_38 : STD_LOGIC_VECTOR ( 38 to 38 );
  signal model_inout_tri_io_39 : STD_LOGIC_VECTOR ( 39 to 39 );
  signal model_inout_tri_io_4 : STD_LOGIC_VECTOR ( 4 to 4 );
  signal model_inout_tri_io_40 : STD_LOGIC_VECTOR ( 40 to 40 );
  signal model_inout_tri_io_41 : STD_LOGIC_VECTOR ( 41 to 41 );
  signal model_inout_tri_io_42 : STD_LOGIC_VECTOR ( 42 to 42 );
  signal model_inout_tri_io_43 : STD_LOGIC_VECTOR ( 43 to 43 );
  signal model_inout_tri_io_44 : STD_LOGIC_VECTOR ( 44 to 44 );
  signal model_inout_tri_io_45 : STD_LOGIC_VECTOR ( 45 to 45 );
  signal model_inout_tri_io_46 : STD_LOGIC_VECTOR ( 46 to 46 );
  signal model_inout_tri_io_47 : STD_LOGIC_VECTOR ( 47 to 47 );
  signal model_inout_tri_io_48 : STD_LOGIC_VECTOR ( 48 to 48 );
  signal model_inout_tri_io_49 : STD_LOGIC_VECTOR ( 49 to 49 );
  signal model_inout_tri_io_5 : STD_LOGIC_VECTOR ( 5 to 5 );
  signal model_inout_tri_io_50 : STD_LOGIC_VECTOR ( 50 to 50 );
  signal model_inout_tri_io_51 : STD_LOGIC_VECTOR ( 51 to 51 );
  signal model_inout_tri_io_52 : STD_LOGIC_VECTOR ( 52 to 52 );
  signal model_inout_tri_io_53 : STD_LOGIC_VECTOR ( 53 to 53 );
  signal model_inout_tri_io_54 : STD_LOGIC_VECTOR ( 54 to 54 );
  signal model_inout_tri_io_55 : STD_LOGIC_VECTOR ( 55 to 55 );
  signal model_inout_tri_io_6 : STD_LOGIC_VECTOR ( 6 to 6 );
  signal model_inout_tri_io_7 : STD_LOGIC_VECTOR ( 7 to 7 );
  signal model_inout_tri_io_8 : STD_LOGIC_VECTOR ( 8 to 8 );
  signal model_inout_tri_io_9 : STD_LOGIC_VECTOR ( 9 to 9 );
  signal model_inout_tri_o_0 : STD_LOGIC_VECTOR ( 0 to 0 );
  signal model_inout_tri_o_1 : STD_LOGIC_VECTOR ( 1 to 1 );
  signal model_inout_tri_o_10 : STD_LOGIC_VECTOR ( 10 to 10 );
  signal model_inout_tri_o_11 : STD_LOGIC_VECTOR ( 11 to 11 );
  signal model_inout_tri_o_12 : STD_LOGIC_VECTOR ( 12 to 12 );
  signal model_inout_tri_o_13 : STD_LOGIC_VECTOR ( 13 to 13 );
  signal model_inout_tri_o_14 : STD_LOGIC_VECTOR ( 14 to 14 );
  signal model_inout_tri_o_15 : STD_LOGIC_VECTOR ( 15 to 15 );
  signal model_inout_tri_o_16 : STD_LOGIC_VECTOR ( 16 to 16 );
  signal model_inout_tri_o_17 : STD_LOGIC_VECTOR ( 17 to 17 );
  signal model_inout_tri_o_18 : STD_LOGIC_VECTOR ( 18 to 18 );
  signal model_inout_tri_o_19 : STD_LOGIC_VECTOR ( 19 to 19 );
  signal model_inout_tri_o_2 : STD_LOGIC_VECTOR ( 2 to 2 );
  signal model_inout_tri_o_20 : STD_LOGIC_VECTOR ( 20 to 20 );
  signal model_inout_tri_o_21 : STD_LOGIC_VECTOR ( 21 to 21 );
  signal model_inout_tri_o_22 : STD_LOGIC_VECTOR ( 22 to 22 );
  signal model_inout_tri_o_23 : STD_LOGIC_VECTOR ( 23 to 23 );
  signal model_inout_tri_o_24 : STD_LOGIC_VECTOR ( 24 to 24 );
  signal model_inout_tri_o_25 : STD_LOGIC_VECTOR ( 25 to 25 );
  signal model_inout_tri_o_26 : STD_LOGIC_VECTOR ( 26 to 26 );
  signal model_inout_tri_o_27 : STD_LOGIC_VECTOR ( 27 to 27 );
  signal model_inout_tri_o_28 : STD_LOGIC_VECTOR ( 28 to 28 );
  signal model_inout_tri_o_29 : STD_LOGIC_VECTOR ( 29 to 29 );
  signal model_inout_tri_o_3 : STD_LOGIC_VECTOR ( 3 to 3 );
  signal model_inout_tri_o_30 : STD_LOGIC_VECTOR ( 30 to 30 );
  signal model_inout_tri_o_31 : STD_LOGIC_VECTOR ( 31 to 31 );
  signal model_inout_tri_o_32 : STD_LOGIC_VECTOR ( 32 to 32 );
  signal model_inout_tri_o_33 : STD_LOGIC_VECTOR ( 33 to 33 );
  signal model_inout_tri_o_34 : STD_LOGIC_VECTOR ( 34 to 34 );
  signal model_inout_tri_o_35 : STD_LOGIC_VECTOR ( 35 to 35 );
  signal model_inout_tri_o_36 : STD_LOGIC_VECTOR ( 36 to 36 );
  signal model_inout_tri_o_37 : STD_LOGIC_VECTOR ( 37 to 37 );
  signal model_inout_tri_o_38 : STD_LOGIC_VECTOR ( 38 to 38 );
  signal model_inout_tri_o_39 : STD_LOGIC_VECTOR ( 39 to 39 );
  signal model_inout_tri_o_4 : STD_LOGIC_VECTOR ( 4 to 4 );
  signal model_inout_tri_o_40 : STD_LOGIC_VECTOR ( 40 to 40 );
  signal model_inout_tri_o_41 : STD_LOGIC_VECTOR ( 41 to 41 );
  signal model_inout_tri_o_42 : STD_LOGIC_VECTOR ( 42 to 42 );
  signal model_inout_tri_o_43 : STD_LOGIC_VECTOR ( 43 to 43 );
  signal model_inout_tri_o_44 : STD_LOGIC_VECTOR ( 44 to 44 );
  signal model_inout_tri_o_45 : STD_LOGIC_VECTOR ( 45 to 45 );
  signal model_inout_tri_o_46 : STD_LOGIC_VECTOR ( 46 to 46 );
  signal model_inout_tri_o_47 : STD_LOGIC_VECTOR ( 47 to 47 );
  signal model_inout_tri_o_48 : STD_LOGIC_VECTOR ( 48 to 48 );
  signal model_inout_tri_o_49 : STD_LOGIC_VECTOR ( 49 to 49 );
  signal model_inout_tri_o_5 : STD_LOGIC_VECTOR ( 5 to 5 );
  signal model_inout_tri_o_50 : STD_LOGIC_VECTOR ( 50 to 50 );
  signal model_inout_tri_o_51 : STD_LOGIC_VECTOR ( 51 to 51 );
  signal model_inout_tri_o_52 : STD_LOGIC_VECTOR ( 52 to 52 );
  signal model_inout_tri_o_53 : STD_LOGIC_VECTOR ( 53 to 53 );
  signal model_inout_tri_o_54 : STD_LOGIC_VECTOR ( 54 to 54 );
  signal model_inout_tri_o_55 : STD_LOGIC_VECTOR ( 55 to 55 );
  signal model_inout_tri_o_6 : STD_LOGIC_VECTOR ( 6 to 6 );
  signal model_inout_tri_o_7 : STD_LOGIC_VECTOR ( 7 to 7 );
  signal model_inout_tri_o_8 : STD_LOGIC_VECTOR ( 8 to 8 );
  signal model_inout_tri_o_9 : STD_LOGIC_VECTOR ( 9 to 9 );
  signal model_inout_tri_t_0 : STD_LOGIC_VECTOR ( 0 to 0 );
  signal model_inout_tri_t_1 : STD_LOGIC_VECTOR ( 1 to 1 );
  signal model_inout_tri_t_10 : STD_LOGIC_VECTOR ( 10 to 10 );
  signal model_inout_tri_t_11 : STD_LOGIC_VECTOR ( 11 to 11 );
  signal model_inout_tri_t_12 : STD_LOGIC_VECTOR ( 12 to 12 );
  signal model_inout_tri_t_13 : STD_LOGIC_VECTOR ( 13 to 13 );
  signal model_inout_tri_t_14 : STD_LOGIC_VECTOR ( 14 to 14 );
  signal model_inout_tri_t_15 : STD_LOGIC_VECTOR ( 15 to 15 );
  signal model_inout_tri_t_16 : STD_LOGIC_VECTOR ( 16 to 16 );
  signal model_inout_tri_t_17 : STD_LOGIC_VECTOR ( 17 to 17 );
  signal model_inout_tri_t_18 : STD_LOGIC_VECTOR ( 18 to 18 );
  signal model_inout_tri_t_19 : STD_LOGIC_VECTOR ( 19 to 19 );
  signal model_inout_tri_t_2 : STD_LOGIC_VECTOR ( 2 to 2 );
  signal model_inout_tri_t_20 : STD_LOGIC_VECTOR ( 20 to 20 );
  signal model_inout_tri_t_21 : STD_LOGIC_VECTOR ( 21 to 21 );
  signal model_inout_tri_t_22 : STD_LOGIC_VECTOR ( 22 to 22 );
  signal model_inout_tri_t_23 : STD_LOGIC_VECTOR ( 23 to 23 );
  signal model_inout_tri_t_24 : STD_LOGIC_VECTOR ( 24 to 24 );
  signal model_inout_tri_t_25 : STD_LOGIC_VECTOR ( 25 to 25 );
  signal model_inout_tri_t_26 : STD_LOGIC_VECTOR ( 26 to 26 );
  signal model_inout_tri_t_27 : STD_LOGIC_VECTOR ( 27 to 27 );
  signal model_inout_tri_t_28 : STD_LOGIC_VECTOR ( 28 to 28 );
  signal model_inout_tri_t_29 : STD_LOGIC_VECTOR ( 29 to 29 );
  signal model_inout_tri_t_3 : STD_LOGIC_VECTOR ( 3 to 3 );
  signal model_inout_tri_t_30 : STD_LOGIC_VECTOR ( 30 to 30 );
  signal model_inout_tri_t_31 : STD_LOGIC_VECTOR ( 31 to 31 );
  signal model_inout_tri_t_32 : STD_LOGIC_VECTOR ( 32 to 32 );
  signal model_inout_tri_t_33 : STD_LOGIC_VECTOR ( 33 to 33 );
  signal model_inout_tri_t_34 : STD_LOGIC_VECTOR ( 34 to 34 );
  signal model_inout_tri_t_35 : STD_LOGIC_VECTOR ( 35 to 35 );
  signal model_inout_tri_t_36 : STD_LOGIC_VECTOR ( 36 to 36 );
  signal model_inout_tri_t_37 : STD_LOGIC_VECTOR ( 37 to 37 );
  signal model_inout_tri_t_38 : STD_LOGIC_VECTOR ( 38 to 38 );
  signal model_inout_tri_t_39 : STD_LOGIC_VECTOR ( 39 to 39 );
  signal model_inout_tri_t_4 : STD_LOGIC_VECTOR ( 4 to 4 );
  signal model_inout_tri_t_40 : STD_LOGIC_VECTOR ( 40 to 40 );
  signal model_inout_tri_t_41 : STD_LOGIC_VECTOR ( 41 to 41 );
  signal model_inout_tri_t_42 : STD_LOGIC_VECTOR ( 42 to 42 );
  signal model_inout_tri_t_43 : STD_LOGIC_VECTOR ( 43 to 43 );
  signal model_inout_tri_t_44 : STD_LOGIC_VECTOR ( 44 to 44 );
  signal model_inout_tri_t_45 : STD_LOGIC_VECTOR ( 45 to 45 );
  signal model_inout_tri_t_46 : STD_LOGIC_VECTOR ( 46 to 46 );
  signal model_inout_tri_t_47 : STD_LOGIC_VECTOR ( 47 to 47 );
  signal model_inout_tri_t_48 : STD_LOGIC_VECTOR ( 48 to 48 );
  signal model_inout_tri_t_49 : STD_LOGIC_VECTOR ( 49 to 49 );
  signal model_inout_tri_t_5 : STD_LOGIC_VECTOR ( 5 to 5 );
  signal model_inout_tri_t_50 : STD_LOGIC_VECTOR ( 50 to 50 );
  signal model_inout_tri_t_51 : STD_LOGIC_VECTOR ( 51 to 51 );
  signal model_inout_tri_t_52 : STD_LOGIC_VECTOR ( 52 to 52 );
  signal model_inout_tri_t_53 : STD_LOGIC_VECTOR ( 53 to 53 );
  signal model_inout_tri_t_54 : STD_LOGIC_VECTOR ( 54 to 54 );
  signal model_inout_tri_t_55 : STD_LOGIC_VECTOR ( 55 to 55 );
  signal model_inout_tri_t_6 : STD_LOGIC_VECTOR ( 6 to 6 );
  signal model_inout_tri_t_7 : STD_LOGIC_VECTOR ( 7 to 7 );
  signal model_inout_tri_t_8 : STD_LOGIC_VECTOR ( 8 to 8 );
  signal model_inout_tri_t_9 : STD_LOGIC_VECTOR ( 9 to 9 );

  signal c0_init_calib_complete :  STD_LOGIC;
     signal c0_mmcm_locked :  STD_LOGIC;
     signal c0_sys_clk_i : STD_LOGIC;
     signal c1_init_calib_complete :  STD_LOGIC;
     signal c1_mmcm_locked :  STD_LOGIC;
     signal c1_sys_clk_i :STD_LOGIC;
     signal clk_ref_i : STD_LOGIC;

begin
MCXX_DESIGN_WRAPPER_i: component MCXX_DESIGN_WRAPPER
    port map (
      C0_DDR3_addr(15 downto 0) => C0_DDR3_addr(15 downto 0),
      C0_DDR3_ba(2 downto 0) => C0_DDR3_ba(2 downto 0),
      C0_DDR3_cas_n => C0_DDR3_cas_n,
      C0_DDR3_ck_n(1 downto 0) => C0_DDR3_ck_n(1 downto 0),
      C0_DDR3_ck_p(1 downto 0) => C0_DDR3_ck_p(1 downto 0),
      C0_DDR3_cke(1 downto 0) => C0_DDR3_cke(1 downto 0),
      C0_DDR3_cs_n(1 downto 0) => C0_DDR3_cs_n(1 downto 0),
      C0_DDR3_dq(71 downto 0) => C0_DDR3_dq(71 downto 0),
      C0_DDR3_dqs_n(8 downto 0) => C0_DDR3_dqs_n(8 downto 0),
      C0_DDR3_dqs_p(8 downto 0) => C0_DDR3_dqs_p(8 downto 0),
      C0_DDR3_odt(1 downto 0) => C0_DDR3_odt(1 downto 0),
      C0_DDR3_ras_n => C0_DDR3_ras_n,
      C0_DDR3_reset_n => C0_DDR3_reset_n,
      C0_DDR3_we_n => C0_DDR3_we_n,
      C1_DDR3_addr(15 downto 0) => C1_DDR3_addr(15 downto 0),
      C1_DDR3_ba(2 downto 0) => C1_DDR3_ba(2 downto 0),
      C1_DDR3_cas_n => C1_DDR3_cas_n,
      C1_DDR3_ck_n(1 downto 0) => C1_DDR3_ck_n(1 downto 0),
      C1_DDR3_ck_p(1 downto 0) => C1_DDR3_ck_p(1 downto 0),
      C1_DDR3_cke(1 downto 0) => C1_DDR3_cke(1 downto 0),
      C1_DDR3_cs_n(1 downto 0) => C1_DDR3_cs_n(1 downto 0),
      C1_DDR3_dq(71 downto 0) => C1_DDR3_dq(71 downto 0),
      C1_DDR3_dqs_n(8 downto 0) => C1_DDR3_dqs_n(8 downto 0),
      C1_DDR3_dqs_p(8 downto 0) => C1_DDR3_dqs_p(8 downto 0),
      C1_DDR3_odt(1 downto 0) => C1_DDR3_odt(1 downto 0),
      C1_DDR3_ras_n => C1_DDR3_ras_n,
      C1_DDR3_reset_n => C1_DDR3_reset_n,
      C1_DDR3_we_n => C1_DDR3_we_n,
      c0_init_calib_complete => c0_init_calib_complete,
      c0_mmcm_locked => c0_mmcm_locked,
      c0_sys_clk_i => c0_sys_clk_i,
      c1_init_calib_complete => c1_init_calib_complete,
      c1_mmcm_locked => c1_mmcm_locked,
      c1_sys_clk_i => c1_sys_clk_i,
      model_inout_tri_i(55) => model_inout_tri_i_55(55),
      model_inout_tri_i(54) => model_inout_tri_i_54(54),
      model_inout_tri_i(53) => model_inout_tri_i_53(53),
      model_inout_tri_i(52) => model_inout_tri_i_52(52),
      model_inout_tri_i(51) => model_inout_tri_i_51(51),
      model_inout_tri_i(50) => model_inout_tri_i_50(50),
      model_inout_tri_i(49) => model_inout_tri_i_49(49),
      model_inout_tri_i(48) => model_inout_tri_i_48(48),
      model_inout_tri_i(47) => model_inout_tri_i_47(47),
      model_inout_tri_i(46) => model_inout_tri_i_46(46),
      model_inout_tri_i(45) => model_inout_tri_i_45(45),
      model_inout_tri_i(44) => model_inout_tri_i_44(44),
      model_inout_tri_i(43) => model_inout_tri_i_43(43),
      model_inout_tri_i(42) => model_inout_tri_i_42(42),
      model_inout_tri_i(41) => model_inout_tri_i_41(41),
      model_inout_tri_i(40) => model_inout_tri_i_40(40),
      model_inout_tri_i(39) => model_inout_tri_i_39(39),
      model_inout_tri_i(38) => model_inout_tri_i_38(38),
      model_inout_tri_i(37) => model_inout_tri_i_37(37),
      model_inout_tri_i(36) => model_inout_tri_i_36(36),
      model_inout_tri_i(35) => model_inout_tri_i_35(35),
      model_inout_tri_i(34) => model_inout_tri_i_34(34),
      model_inout_tri_i(33) => model_inout_tri_i_33(33),
      model_inout_tri_i(32) => model_inout_tri_i_32(32),
      model_inout_tri_i(31) => model_inout_tri_i_31(31),
      model_inout_tri_i(30) => model_inout_tri_i_30(30),
      model_inout_tri_i(29) => model_inout_tri_i_29(29),
      model_inout_tri_i(28) => model_inout_tri_i_28(28),
      model_inout_tri_i(27) => model_inout_tri_i_27(27),
      model_inout_tri_i(26) => model_inout_tri_i_26(26),
      model_inout_tri_i(25) => model_inout_tri_i_25(25),
      model_inout_tri_i(24) => model_inout_tri_i_24(24),
      model_inout_tri_i(23) => model_inout_tri_i_23(23),
      model_inout_tri_i(22) => model_inout_tri_i_22(22),
      model_inout_tri_i(21) => model_inout_tri_i_21(21),
      model_inout_tri_i(20) => model_inout_tri_i_20(20),
      model_inout_tri_i(19) => model_inout_tri_i_19(19),
      model_inout_tri_i(18) => model_inout_tri_i_18(18),
      model_inout_tri_i(17) => model_inout_tri_i_17(17),
      model_inout_tri_i(16) => model_inout_tri_i_16(16),
      model_inout_tri_i(15) => model_inout_tri_i_15(15),
      model_inout_tri_i(14) => model_inout_tri_i_14(14),
      model_inout_tri_i(13) => model_inout_tri_i_13(13),
      model_inout_tri_i(12) => model_inout_tri_i_12(12),
      model_inout_tri_i(11) => model_inout_tri_i_11(11),
      model_inout_tri_i(10) => model_inout_tri_i_10(10),
      model_inout_tri_i(9) => model_inout_tri_i_9(9),
      model_inout_tri_i(8) => model_inout_tri_i_8(8),
      model_inout_tri_i(7) => model_inout_tri_i_7(7),
      model_inout_tri_i(6) => model_inout_tri_i_6(6),
      model_inout_tri_i(5) => model_inout_tri_i_5(5),
      model_inout_tri_i(4) => model_inout_tri_i_4(4),
      model_inout_tri_i(3) => model_inout_tri_i_3(3),
      model_inout_tri_i(2) => model_inout_tri_i_2(2),
      model_inout_tri_i(1) => model_inout_tri_i_1(1),
      model_inout_tri_i(0) => model_inout_tri_i_0(0),
      model_inout_tri_o(55) => model_inout_tri_o_55(55),
      model_inout_tri_o(54) => model_inout_tri_o_54(54),
      model_inout_tri_o(53) => model_inout_tri_o_53(53),
      model_inout_tri_o(52) => model_inout_tri_o_52(52),
      model_inout_tri_o(51) => model_inout_tri_o_51(51),
      model_inout_tri_o(50) => model_inout_tri_o_50(50),
      model_inout_tri_o(49) => model_inout_tri_o_49(49),
      model_inout_tri_o(48) => model_inout_tri_o_48(48),
      model_inout_tri_o(47) => model_inout_tri_o_47(47),
      model_inout_tri_o(46) => model_inout_tri_o_46(46),
      model_inout_tri_o(45) => model_inout_tri_o_45(45),
      model_inout_tri_o(44) => model_inout_tri_o_44(44),
      model_inout_tri_o(43) => model_inout_tri_o_43(43),
      model_inout_tri_o(42) => model_inout_tri_o_42(42),
      model_inout_tri_o(41) => model_inout_tri_o_41(41),
      model_inout_tri_o(40) => model_inout_tri_o_40(40),
      model_inout_tri_o(39) => model_inout_tri_o_39(39),
      model_inout_tri_o(38) => model_inout_tri_o_38(38),
      model_inout_tri_o(37) => model_inout_tri_o_37(37),
      model_inout_tri_o(36) => model_inout_tri_o_36(36),
      model_inout_tri_o(35) => model_inout_tri_o_35(35),
      model_inout_tri_o(34) => model_inout_tri_o_34(34),
      model_inout_tri_o(33) => model_inout_tri_o_33(33),
      model_inout_tri_o(32) => model_inout_tri_o_32(32),
      model_inout_tri_o(31) => model_inout_tri_o_31(31),
      model_inout_tri_o(30) => model_inout_tri_o_30(30),
      model_inout_tri_o(29) => model_inout_tri_o_29(29),
      model_inout_tri_o(28) => model_inout_tri_o_28(28),
      model_inout_tri_o(27) => model_inout_tri_o_27(27),
      model_inout_tri_o(26) => model_inout_tri_o_26(26),
      model_inout_tri_o(25) => model_inout_tri_o_25(25),
      model_inout_tri_o(24) => model_inout_tri_o_24(24),
      model_inout_tri_o(23) => model_inout_tri_o_23(23),
      model_inout_tri_o(22) => model_inout_tri_o_22(22),
      model_inout_tri_o(21) => model_inout_tri_o_21(21),
      model_inout_tri_o(20) => model_inout_tri_o_20(20),
      model_inout_tri_o(19) => model_inout_tri_o_19(19),
      model_inout_tri_o(18) => model_inout_tri_o_18(18),
      model_inout_tri_o(17) => model_inout_tri_o_17(17),
      model_inout_tri_o(16) => model_inout_tri_o_16(16),
      model_inout_tri_o(15) => model_inout_tri_o_15(15),
      model_inout_tri_o(14) => model_inout_tri_o_14(14),
      model_inout_tri_o(13) => model_inout_tri_o_13(13),
      model_inout_tri_o(12) => model_inout_tri_o_12(12),
      model_inout_tri_o(11) => model_inout_tri_o_11(11),
      model_inout_tri_o(10) => model_inout_tri_o_10(10),
      model_inout_tri_o(9) => model_inout_tri_o_9(9),
      model_inout_tri_o(8) => model_inout_tri_o_8(8),
      model_inout_tri_o(7) => model_inout_tri_o_7(7),
      model_inout_tri_o(6) => model_inout_tri_o_6(6),
      model_inout_tri_o(5) => model_inout_tri_o_5(5),
      model_inout_tri_o(4) => model_inout_tri_o_4(4),
      model_inout_tri_o(3) => model_inout_tri_o_3(3),
      model_inout_tri_o(2) => model_inout_tri_o_2(2),
      model_inout_tri_o(1) => model_inout_tri_o_1(1),
      model_inout_tri_o(0) => model_inout_tri_o_0(0),
      model_inout_tri_t(55) => model_inout_tri_t_55(55),
      model_inout_tri_t(54) => model_inout_tri_t_54(54),
      model_inout_tri_t(53) => model_inout_tri_t_53(53),
      model_inout_tri_t(52) => model_inout_tri_t_52(52),
      model_inout_tri_t(51) => model_inout_tri_t_51(51),
      model_inout_tri_t(50) => model_inout_tri_t_50(50),
      model_inout_tri_t(49) => model_inout_tri_t_49(49),
      model_inout_tri_t(48) => model_inout_tri_t_48(48),
      model_inout_tri_t(47) => model_inout_tri_t_47(47),
      model_inout_tri_t(46) => model_inout_tri_t_46(46),
      model_inout_tri_t(45) => model_inout_tri_t_45(45),
      model_inout_tri_t(44) => model_inout_tri_t_44(44),
      model_inout_tri_t(43) => model_inout_tri_t_43(43),
      model_inout_tri_t(42) => model_inout_tri_t_42(42),
      model_inout_tri_t(41) => model_inout_tri_t_41(41),
      model_inout_tri_t(40) => model_inout_tri_t_40(40),
      model_inout_tri_t(39) => model_inout_tri_t_39(39),
      model_inout_tri_t(38) => model_inout_tri_t_38(38),
      model_inout_tri_t(37) => model_inout_tri_t_37(37),
      model_inout_tri_t(36) => model_inout_tri_t_36(36),
      model_inout_tri_t(35) => model_inout_tri_t_35(35),
      model_inout_tri_t(34) => model_inout_tri_t_34(34),
      model_inout_tri_t(33) => model_inout_tri_t_33(33),
      model_inout_tri_t(32) => model_inout_tri_t_32(32),
      model_inout_tri_t(31) => model_inout_tri_t_31(31),
      model_inout_tri_t(30) => model_inout_tri_t_30(30),
      model_inout_tri_t(29) => model_inout_tri_t_29(29),
      model_inout_tri_t(28) => model_inout_tri_t_28(28),
      model_inout_tri_t(27) => model_inout_tri_t_27(27),
      model_inout_tri_t(26) => model_inout_tri_t_26(26),
      model_inout_tri_t(25) => model_inout_tri_t_25(25),
      model_inout_tri_t(24) => model_inout_tri_t_24(24),
      model_inout_tri_t(23) => model_inout_tri_t_23(23),
      model_inout_tri_t(22) => model_inout_tri_t_22(22),
      model_inout_tri_t(21) => model_inout_tri_t_21(21),
      model_inout_tri_t(20) => model_inout_tri_t_20(20),
      model_inout_tri_t(19) => model_inout_tri_t_19(19),
      model_inout_tri_t(18) => model_inout_tri_t_18(18),
      model_inout_tri_t(17) => model_inout_tri_t_17(17),
      model_inout_tri_t(16) => model_inout_tri_t_16(16),
      model_inout_tri_t(15) => model_inout_tri_t_15(15),
      model_inout_tri_t(14) => model_inout_tri_t_14(14),
      model_inout_tri_t(13) => model_inout_tri_t_13(13),
      model_inout_tri_t(12) => model_inout_tri_t_12(12),
      model_inout_tri_t(11) => model_inout_tri_t_11(11),
      model_inout_tri_t(10) => model_inout_tri_t_10(10),
      model_inout_tri_t(9) => model_inout_tri_t_9(9),
      model_inout_tri_t(8) => model_inout_tri_t_8(8),
      model_inout_tri_t(7) => model_inout_tri_t_7(7),
      model_inout_tri_t(6) => model_inout_tri_t_6(6),
      model_inout_tri_t(5) => model_inout_tri_t_5(5),
      model_inout_tri_t(4) => model_inout_tri_t_4(4),
      model_inout_tri_t(3) => model_inout_tri_t_3(3),
      model_inout_tri_t(2) => model_inout_tri_t_2(2),
      model_inout_tri_t(1) => model_inout_tri_t_1(1),
      model_inout_tri_t(0) => model_inout_tri_t_0(0),
      pci_exp_rxn(7 downto 0) => pci_exp_rxn(7 downto 0),
      pci_exp_rxp(7 downto 0) => pci_exp_rxp(7 downto 0),
      pci_exp_txn(7 downto 0) => pci_exp_txn(7 downto 0),
      pci_exp_txp(7 downto 0) => pci_exp_txp(7 downto 0),
      pcie100_clk_n => pcie100_clk_n,
      pcie100_clk_p => pcie100_clk_p,
      perst_n => perst_n,
      refclk200_clk_n => refclk200_clk_n,
      refclk200_clk_p => refclk200_clk_p
    );
model_inout_tri_iobuf_0: component IOBUF
     port map (
      I => model_inout_tri_o_0(0),
      IO => model_inout(0),
      O => model_inout_tri_i_0(0),
      T => model_inout_tri_t_0(0)
    );
model_inout_tri_iobuf_1: component IOBUF
     port map (
      I => model_inout_tri_o_1(1),
      IO => model_inout(1),
      O => model_inout_tri_i_1(1),
      T => model_inout_tri_t_1(1)
    );
model_inout_tri_iobuf_10: component IOBUF
     port map (
      I => model_inout_tri_o_10(10),
      IO => model_inout(10),
      O => model_inout_tri_i_10(10),
      T => model_inout_tri_t_10(10)
    );
model_inout_tri_iobuf_11: component IOBUF
     port map (
      I => model_inout_tri_o_11(11),
      IO => model_inout(11),
      O => model_inout_tri_i_11(11),
      T => model_inout_tri_t_11(11)
    );
model_inout_tri_iobuf_12: component IOBUF
     port map (
      I => model_inout_tri_o_12(12),
      IO => model_inout(12),
      O => model_inout_tri_i_12(12),
      T => model_inout_tri_t_12(12)
    );
model_inout_tri_iobuf_13: component IOBUF
     port map (
      I => model_inout_tri_o_13(13),
      IO => model_inout(13),
      O => model_inout_tri_i_13(13),
      T => model_inout_tri_t_13(13)
    );
model_inout_tri_iobuf_14: component IOBUF
     port map (
      I => model_inout_tri_o_14(14),
      IO => model_inout(14),
      O => model_inout_tri_i_14(14),
      T => model_inout_tri_t_14(14)
    );
model_inout_tri_iobuf_15: component IOBUF
     port map (
      I => model_inout_tri_o_15(15),
      IO => model_inout(15),
      O => model_inout_tri_i_15(15),
      T => model_inout_tri_t_15(15)
    );
model_inout_tri_iobuf_16: component IOBUF
     port map (
      I => model_inout_tri_o_16(16),
      IO => model_inout(16),
      O => model_inout_tri_i_16(16),
      T => model_inout_tri_t_16(16)
    );
model_inout_tri_iobuf_17: component IOBUF
     port map (
      I => model_inout_tri_o_17(17),
      IO => model_inout(17),
      O => model_inout_tri_i_17(17),
      T => model_inout_tri_t_17(17)
    );
model_inout_tri_iobuf_18: component IOBUF
     port map (
      I => model_inout_tri_o_18(18),
      IO => model_inout(18),
      O => model_inout_tri_i_18(18),
      T => model_inout_tri_t_18(18)
    );
model_inout_tri_iobuf_19: component IOBUF
     port map (
      I => model_inout_tri_o_19(19),
      IO => model_inout(19),
      O => model_inout_tri_i_19(19),
      T => model_inout_tri_t_19(19)
    );
model_inout_tri_iobuf_2: component IOBUF
     port map (
      I => model_inout_tri_o_2(2),
      IO => model_inout(2),
      O => model_inout_tri_i_2(2),
      T => model_inout_tri_t_2(2)
    );
model_inout_tri_iobuf_20: component IOBUF
     port map (
      I => model_inout_tri_o_20(20),
      IO => model_inout(20),
      O => model_inout_tri_i_20(20),
      T => model_inout_tri_t_20(20)
    );
model_inout_tri_iobuf_21: component IOBUF
     port map (
      I => model_inout_tri_o_21(21),
      IO => model_inout(21),
      O => model_inout_tri_i_21(21),
      T => model_inout_tri_t_21(21)
    );
model_inout_tri_iobuf_22: component IOBUF
     port map (
      I => model_inout_tri_o_22(22),
      IO => model_inout(22),
      O => model_inout_tri_i_22(22),
      T => model_inout_tri_t_22(22)
    );
model_inout_tri_iobuf_23: component IOBUF
     port map (
      I => model_inout_tri_o_23(23),
      IO => model_inout(23),
      O => model_inout_tri_i_23(23),
      T => model_inout_tri_t_23(23)
    );
model_inout_tri_iobuf_24: component IOBUF
     port map (
      I => model_inout_tri_o_24(24),
      IO => model_inout(24),
      O => model_inout_tri_i_24(24),
      T => model_inout_tri_t_24(24)
    );
model_inout_tri_iobuf_25: component IOBUF
     port map (
      I => model_inout_tri_o_25(25),
      IO => model_inout(25),
      O => model_inout_tri_i_25(25),
      T => model_inout_tri_t_25(25)
    );
model_inout_tri_iobuf_26: component IOBUF
     port map (
      I => model_inout_tri_o_26(26),
      IO => model_inout(26),
      O => model_inout_tri_i_26(26),
      T => model_inout_tri_t_26(26)
    );
model_inout_tri_iobuf_27: component IOBUF
     port map (
      I => model_inout_tri_o_27(27),
      IO => model_inout(27),
      O => model_inout_tri_i_27(27),
      T => model_inout_tri_t_27(27)
    );
model_inout_tri_iobuf_28: component IOBUF
     port map (
      I => model_inout_tri_o_28(28),
      IO => model_inout(28),
      O => model_inout_tri_i_28(28),
      T => model_inout_tri_t_28(28)
    );
model_inout_tri_iobuf_29: component IOBUF
     port map (
      I => model_inout_tri_o_29(29),
      IO => model_inout(29),
      O => model_inout_tri_i_29(29),
      T => model_inout_tri_t_29(29)
    );
model_inout_tri_iobuf_3: component IOBUF
     port map (
      I => model_inout_tri_o_3(3),
      IO => model_inout(3),
      O => model_inout_tri_i_3(3),
      T => model_inout_tri_t_3(3)
    );
model_inout_tri_iobuf_30: component IOBUF
     port map (
      I => model_inout_tri_o_30(30),
      IO => model_inout(30),
      O => model_inout_tri_i_30(30),
      T => model_inout_tri_t_30(30)
    );
model_inout_tri_iobuf_31: component IOBUF
     port map (
      I => model_inout_tri_o_31(31),
      IO => model_inout(31),
      O => model_inout_tri_i_31(31),
      T => model_inout_tri_t_31(31)
    );
model_inout_tri_iobuf_32: component IOBUF
     port map (
      I => model_inout_tri_o_32(32),
      IO => model_inout(32),
      O => model_inout_tri_i_32(32),
      T => model_inout_tri_t_32(32)
    );
model_inout_tri_iobuf_33: component IOBUF
     port map (
      I => model_inout_tri_o_33(33),
      IO => model_inout(33),
      O => model_inout_tri_i_33(33),
      T => model_inout_tri_t_33(33)
    );
model_inout_tri_iobuf_34: component IOBUF
     port map (
      I => model_inout_tri_o_34(34),
      IO => model_inout(34),
      O => model_inout_tri_i_34(34),
      T => model_inout_tri_t_34(34)
    );
model_inout_tri_iobuf_35: component IOBUF
     port map (
      I => model_inout_tri_o_35(35),
      IO => model_inout(35),
      O => model_inout_tri_i_35(35),
      T => model_inout_tri_t_35(35)
    );
model_inout_tri_iobuf_36: component IOBUF
     port map (
      I => model_inout_tri_o_36(36),
      IO => model_inout(36),
      O => model_inout_tri_i_36(36),
      T => model_inout_tri_t_36(36)
    );
model_inout_tri_iobuf_37: component IOBUF
     port map (
      I => model_inout_tri_o_37(37),
      IO => model_inout(37),
      O => model_inout_tri_i_37(37),
      T => model_inout_tri_t_37(37)
    );
model_inout_tri_iobuf_38: component IOBUF
     port map (
      I => model_inout_tri_o_38(38),
      IO => model_inout(38),
      O => model_inout_tri_i_38(38),
      T => model_inout_tri_t_38(38)
    );
model_inout_tri_iobuf_39: component IOBUF
     port map (
      I => model_inout_tri_o_39(39),
      IO => model_inout(39),
      O => model_inout_tri_i_39(39),
      T => model_inout_tri_t_39(39)
    );
model_inout_tri_iobuf_4: component IOBUF
     port map (
      I => model_inout_tri_o_4(4),
      IO => model_inout(4),
      O => model_inout_tri_i_4(4),
      T => model_inout_tri_t_4(4)
    );
model_inout_tri_iobuf_40: component IOBUF
     port map (
      I => model_inout_tri_o_40(40),
      IO => model_inout(40),
      O => model_inout_tri_i_40(40),
      T => model_inout_tri_t_40(40)
    );
model_inout_tri_iobuf_41: component IOBUF
     port map (
      I => model_inout_tri_o_41(41),
      IO => model_inout(41),
      O => model_inout_tri_i_41(41),
      T => model_inout_tri_t_41(41)
    );
model_inout_tri_iobuf_42: component IOBUF
     port map (
      I => model_inout_tri_o_42(42),
      IO => model_inout(42),
      O => model_inout_tri_i_42(42),
      T => model_inout_tri_t_42(42)
    );
model_inout_tri_iobuf_43: component IOBUF
     port map (
      I => model_inout_tri_o_43(43),
      IO => model_inout(43),
      O => model_inout_tri_i_43(43),
      T => model_inout_tri_t_43(43)
    );
model_inout_tri_iobuf_44: component IOBUF
     port map (
      I => model_inout_tri_o_44(44),
      IO => model_inout(44),
      O => model_inout_tri_i_44(44),
      T => model_inout_tri_t_44(44)
    );
model_inout_tri_iobuf_45: component IOBUF
     port map (
      I => model_inout_tri_o_45(45),
      IO => model_inout(45),
      O => model_inout_tri_i_45(45),
      T => model_inout_tri_t_45(45)
    );
model_inout_tri_iobuf_46: component IOBUF
     port map (
      I => model_inout_tri_o_46(46),
      IO => model_inout(46),
      O => model_inout_tri_i_46(46),
      T => model_inout_tri_t_46(46)
    );
model_inout_tri_iobuf_47: component IOBUF
     port map (
      I => model_inout_tri_o_47(47),
      IO => model_inout(47),
      O => model_inout_tri_i_47(47),
      T => model_inout_tri_t_47(47)
    );
model_inout_tri_iobuf_48: component IOBUF
     port map (
      I => model_inout_tri_o_48(48),
      IO => model_inout(48),
      O => model_inout_tri_i_48(48),
      T => model_inout_tri_t_48(48)
    );
model_inout_tri_iobuf_49: component IOBUF
     port map (
      I => model_inout_tri_o_49(49),
      IO => model_inout(49),
      O => model_inout_tri_i_49(49),
      T => model_inout_tri_t_49(49)
    );
model_inout_tri_iobuf_5: component IOBUF
     port map (
      I => model_inout_tri_o_5(5),
      IO => model_inout(5),
      O => model_inout_tri_i_5(5),
      T => model_inout_tri_t_5(5)
    );
model_inout_tri_iobuf_50: component IOBUF
     port map (
      I => model_inout_tri_o_50(50),
      IO => model_inout(50),
      O => model_inout_tri_i_50(50),
      T => model_inout_tri_t_50(50)
    );
model_inout_tri_iobuf_51: component IOBUF
     port map (
      I => model_inout_tri_o_51(51),
      IO => model_inout(51),
      O => model_inout_tri_i_51(51),
      T => model_inout_tri_t_51(51)
    );
model_inout_tri_iobuf_52: component IOBUF
     port map (
      I => model_inout_tri_o_52(52),
      IO => model_inout(52),
      O => model_inout_tri_i_52(52),
      T => model_inout_tri_t_52(52)
    );
model_inout_tri_iobuf_53: component IOBUF
     port map (
      I => model_inout_tri_o_53(53),
      IO => model_inout(53),
      O => model_inout_tri_i_53(53),
      T => model_inout_tri_t_53(53)
    );
model_inout_tri_iobuf_54: component IOBUF
     port map (
      I => model_inout_tri_o_54(54),
      IO => model_inout(54),
      O => model_inout_tri_i_54(54),
      T => model_inout_tri_t_54(54)
    );
model_inout_tri_iobuf_55: component IOBUF
     port map (
      I => model_inout_tri_o_55(55),
      IO => model_inout(55),
      O => model_inout_tri_i_55(55),
      T => model_inout_tri_t_55(55)
    );
model_inout_tri_iobuf_6: component IOBUF
     port map (
      I => model_inout_tri_o_6(6),
      IO => model_inout(6),
      O => model_inout_tri_i_6(6),
      T => model_inout_tri_t_6(6)
    );
model_inout_tri_iobuf_7: component IOBUF
     port map (
      I => model_inout_tri_o_7(7),
      IO => model_inout(7),
      O => model_inout_tri_i_7(7),
      T => model_inout_tri_t_7(7)
    );
model_inout_tri_iobuf_8: component IOBUF
     port map (
      I => model_inout_tri_o_8(8),
      IO => model_inout(8),
      O => model_inout_tri_i_8(8),
      T => model_inout_tri_t_8(8)
    );
model_inout_tri_iobuf_9: component IOBUF
     port map (
      I => model_inout_tri_o_9(9),
      IO => model_inout(9),
      O => model_inout_tri_i_9(9),
      T => model_inout_tri_t_9(9)
    );
    
     ddr3_clk_dif_0 : IBUFGDS
       port map(
         I  => refclk400m0_p,
         IB => refclk400m0_n,
         O  => c0_sys_clk_i);
   
     ddr3_clk_dif_1 : IBUFGDS
       port map(
         I  => refclk400m1_p,
         IB => refclk400m1_n,
         O  => c1_sys_clk_i);
     
     c0_ddr3_dm <= (others => '0');
     c1_ddr3_dm <= (others => '0');      
   
     dram_0_on <= '1';
     dram_1_on <= '1';
   
     usr_led(5) <= not c0_init_calib_complete;
     usr_led(0) <= c0_mmcm_locked;
     usr_led(4) <= not c1_init_calib_complete;
     usr_led(1) <= c1_mmcm_locked;
     usr_led(2) <= '0';
     usr_led(3) <= '0';
end STRUCTURE;
