library verilog;
use verilog.vl_types.all;
entity IP_wrapper is
    port(
        iClk            : in     vl_logic;
        iReset_n        : in     vl_logic;
        iChipselect_n   : in     vl_logic;
        iWrite_n        : in     vl_logic;
        iRead_n         : in     vl_logic;
        iAddress        : in     vl_logic_vector(4 downto 0);
        iData           : in     vl_logic_vector(31 downto 0);
        oData           : out    vl_logic_vector(31 downto 0);
        DATA_IN         : out    vl_logic_vector(31 downto 0);
        DATA_VALID      : out    vl_logic;
        IP_OUT          : out    vl_logic_vector(255 downto 0);
        DONE            : out    vl_logic
    );
end IP_wrapper;
