library verilog;
use verilog.vl_types.all;
entity topmodule_nios2 is
    port(
        altera_reserved_tms: in     vl_logic;
        altera_reserved_tck: in     vl_logic;
        altera_reserved_tdi: in     vl_logic;
        altera_reserved_tdo: out    vl_logic;
        CLOCK_50        : in     vl_logic;
        KEY             : in     vl_logic_vector(0 downto 0)
    );
end topmodule_nios2;
