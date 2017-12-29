library verilog;
use verilog.vl_types.all;
entity tb is
    generic(
        nShots          : integer := 10
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of nShots : constant is 1;
end tb;
