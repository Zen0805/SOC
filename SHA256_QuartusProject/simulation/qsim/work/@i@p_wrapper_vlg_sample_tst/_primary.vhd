library verilog;
use verilog.vl_types.all;
entity IP_wrapper_vlg_sample_tst is
    port(
        iAddress        : in     vl_logic_vector(4 downto 0);
        iChipselect_n   : in     vl_logic;
        iClk            : in     vl_logic;
        iData           : in     vl_logic_vector(31 downto 0);
        iRead_n         : in     vl_logic;
        iReset_n        : in     vl_logic;
        iWrite_n        : in     vl_logic;
        sampler_tx      : out    vl_logic
    );
end IP_wrapper_vlg_sample_tst;
