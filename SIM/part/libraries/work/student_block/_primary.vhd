library verilog;
use verilog.vl_types.all;
entity student_block is
    generic(
        centerV         : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0);
        centerH         : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi1, Hi1);
        windowSize      : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi1, Hi1, Hi1);
        fifoSize        : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0);
        lastPixH        : vl_logic_vector(0 to 9) := (Hi1, Hi0, Hi1, Hi0, Hi1, Hi1, Hi1, Hi1, Hi0, Hi1);
        firstPixH       : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0);
        lastPixV        : vl_logic_vector(0 to 9) := (Hi0, Hi1, Hi0, Hi0, Hi0, Hi1, Hi1, Hi1, Hi1, Hi1);
        firstPixV       : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0);
        timeStepRange   : integer := 2;
        stepH           : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0);
        stepV           : vl_logic_vector(0 to 9) := (Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0)
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
    attribute mti_svvh_generic_type of centerV : constant is 1;
    attribute mti_svvh_generic_type of centerH : constant is 1;
    attribute mti_svvh_generic_type of windowSize : constant is 1;
    attribute mti_svvh_generic_type of fifoSize : constant is 1;
    attribute mti_svvh_generic_type of lastPixH : constant is 1;
    attribute mti_svvh_generic_type of firstPixH : constant is 1;
    attribute mti_svvh_generic_type of lastPixV : constant is 1;
    attribute mti_svvh_generic_type of firstPixV : constant is 1;
    attribute mti_svvh_generic_type of timeStepRange : constant is 1;
    attribute mti_svvh_generic_type of stepH : constant is 1;
    attribute mti_svvh_generic_type of stepV : constant is 1;
end student_block;
