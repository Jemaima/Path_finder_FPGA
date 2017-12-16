library verilog;
use verilog.vl_types.all;
entity student_block is
    generic(
        center          : integer := 16;
        windowSize      : integer := 33
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        mode            : in     vl_logic_vector(1 downto 0);
        video_frame_valid: in     vl_logic;
        video_line_valid: in     vl_logic;
        video_data_valid: in     vl_logic;
        video_data_in   : in     vl_logic_vector(7 downto 0);
        video_address   : in     vl_logic_vector(19 downto 0);
        video_data_ready: out    vl_logic;
        video_data_out  : out    vl_logic_vector(7 downto 0)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of center : constant is 1;
    attribute mti_svvh_generic_type of windowSize : constant is 1;
end student_block;