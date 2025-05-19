library verilog;
use verilog.vl_types.all;
entity sha256_optimizePowerAreaVerilog_vlg_check_tst is
    port(
        done            : in     vl_logic;
        output_sha256top: in     vl_logic_vector(255 downto 0);
        sampler_rx      : in     vl_logic
    );
end sha256_optimizePowerAreaVerilog_vlg_check_tst;
