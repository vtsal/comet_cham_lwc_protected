-- and_3TI

library ieee;
use ieee.std_logic_1164.ALL;

entity and_3TI is
    port (

	xa, xb, xc, ya, yb, yc, m  : in  std_logic;
	o1, o2, o3		: out std_logic
	);

end entity and_3TI;

architecture structural of and_3TI is

attribute keep : string;
attribute keep of xa, xb, xc, ya, yb, yc, o1, o2, o3 : signal is "true";

begin
	
anda: entity work.and_3TI_a(dataflow)

	port map(
	xa => xb,
	xb => xc,
	m => m,
	ya => yb, 
	yb => yc,
	o  => o1

	);

andb: entity work.and_3TI_b(dataflow)

	port map(
	xa => xc,
	xb => xa,
	m => m,
	ya => yc, 
	yb => ya,
	o  => o2

	);

andc: entity work.and_3TI_c(dataflow)

	port map(
	xa => xa,
	xb => xb,
	m => m,
	ya => ya, 
	yb => yb,
	o  => o3

	);


end structural;