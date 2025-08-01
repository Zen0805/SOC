library verilog;
use verilog.vl_types.all;
entity sha256_optimizePowerAreaVerilog is
    port(
        CLK             : in     vl_logic;
        RESET_N         : in     vl_logic;
        START           : in     vl_logic;
        DATA_VALID      : in     vl_logic;
        DATA_IN         : in     vl_logic_vector(31 downto 0);
        done            : out    vl_logic;
        output_sha256top: out    vl_logic_vector(255 downto 0)
    );
end sha256_optimizePowerAreaVerilog;
