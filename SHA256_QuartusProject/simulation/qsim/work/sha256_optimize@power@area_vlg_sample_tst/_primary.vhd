library verilog;
use verilog.vl_types.all;
entity sha256_optimizePowerArea_vlg_sample_tst is
    port(
        CLK             : in     vl_logic;
        DATA_IN         : in     vl_logic_vector(31 downto 0);
        DATA_VALID      : in     vl_logic;
        RESET_N         : in     vl_logic;
        START           : in     vl_logic;
        sampler_tx      : out    vl_logic
    );
end sha256_optimizePowerArea_vlg_sample_tst;
