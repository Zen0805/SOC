library verilog;
use verilog.vl_types.all;
entity IP_wrapper_vlg_check_tst is
    port(
        DATA_IN         : in     vl_logic_vector(31 downto 0);
        DATA_VALID      : in     vl_logic;
        START           : in     vl_logic;
        load_counter    : in     vl_logic_vector(3 downto 0);
        oData           : in     vl_logic_vector(31 downto 0);
        state_ctrl      : in     vl_logic;
        sampler_rx      : in     vl_logic
    );
end IP_wrapper_vlg_check_tst;
