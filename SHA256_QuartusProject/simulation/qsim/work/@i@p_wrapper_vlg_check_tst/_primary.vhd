library verilog;
use verilog.vl_types.all;
entity IP_wrapper_vlg_check_tst is
    port(
        DATA_IN         : in     vl_logic_vector(31 downto 0);
        DATA_VALID      : in     vl_logic;
        DONE            : in     vl_logic;
        IP_OUT          : in     vl_logic_vector(255 downto 0);
        oData           : in     vl_logic_vector(31 downto 0);
        sampler_rx      : in     vl_logic
    );
end IP_wrapper_vlg_check_tst;
