library verilog;
use verilog.vl_types.all;
entity sha256_optimizePowerArea is
    port(
        done            : out    vl_logic;
        CLK             : in     vl_logic;
        RESET_N         : in     vl_logic;
        START           : in     vl_logic;
        DATA_VALID      : in     vl_logic;
        DATA_IN         : in     vl_logic_vector(31 downto 0);
        output          : out    vl_logic_vector(255 downto 0)
    );
end sha256_optimizePowerArea;
