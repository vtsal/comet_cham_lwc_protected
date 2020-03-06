-- and_3TI_a

library ieee;
use ieee.std_logic_1164.ALL;

entity and_3TI_a is
    port (

	xa, xb, ya, yb, m  : in  std_logic;
	o		           : out std_logic
	);

end entity and_3TI_a;

architecture dataflow of and_3TI_a is

attribute keep_hierarchy : string;
attribute keep_hierarchy of dataflow: architecture is "true";

begin

	o <= (xb and ya) xor (xa and yb) xor (xa and ya) xor (xb and m) xor (m and yb) xor m;

end dataflow;