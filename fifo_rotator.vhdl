library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_rotator is
	generic(
		DEPTH: natural;
		BITS: positive
	);
	port(
		clk_in: in std_logic;
		sreset_in: in std_logic;
		
		a_ready_out: out std_logic;
		a_valid_in: in std_logic;
		a_tlast_in: in std_logic := '0';
		a_data_in: in std_logic_vector(BITS-1 downto 0) := (others => '0');

		b_ready_in: in std_logic;
		b_valid_out: out std_logic;
		b_tlast_out: out std_logic;
		b_data_out: out std_logic_vector(BITS-1 downto 0)
	);
end;

architecture formal_rtl of fifo_rotator is
	type mem_t is array(0 to DEPTH-1) of std_logic_vector(BITS downto 0);
	signal mem: mem_t;
	signal rd_pos: std_logic_vector(0 to DEPTH) := (0 => '1', others => '0');
begin
	mem_pr: process(clk_in)
		variable v_rd_pos: std_logic_vector(0 to DEPTH);
	begin
		if rising_edge(clk_in) then
			v_rd_pos := rd_pos;
			
			if b_ready_in = '1' and b_valid_out = '1' then
				v_rd_pos(0 to DEPTH-1) := v_rd_pos(1 to DEPTH);
			end if;
			
			if a_ready_out = '1' and a_valid_in = '1' then
				mem(1 to DEPTH-1) <= mem(0 to DEPTH-2);
				mem(0)(BITS-1 downto 0) <= a_data_in;
				mem(0)(BITS) <= a_tlast_in;
				v_rd_pos(1 to DEPTH) := v_rd_pos(0 to DEPTH-1);
				v_rd_pos(0) := '0';
			end if;
		
			rd_pos <= v_rd_pos;
			
			if sreset_in = '1' then
				rd_pos <= (others => '0');
				rd_pos(0) <= '1';
			end if;
		end if;
	end process;
	
	out_pr: process(all)
		variable v_rd_res: std_logic_vector(BITS downto 0);
	begin
		v_rd_res := (others => '0');
		for i in mem'range loop
			for k in v_rd_res'range loop
				v_rd_res(k) := v_rd_res(k) or (mem(i)(k) and rd_pos(i+1));
			end loop;
		end loop;
		b_data_out <= v_rd_res(BITS-1 downto 0);
		b_tlast_out <= v_rd_res(BITS);
	end process;
	
	status_pr: process(all)
	begin
		a_ready_out <= not rd_pos(DEPTH);
		b_valid_out <= not rd_pos(0);
	end process;
	
	-- PSL =>
	
	f_rd_pos_onehot: assert always onehot(rd_pos) @rising_edge(clk_in);
end;
