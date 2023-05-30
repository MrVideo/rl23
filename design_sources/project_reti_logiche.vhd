library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity project_reti_logiche is
port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_w : in std_logic;
    o_z0 : out std_logic_vector(7 downto 0);
    o_z1 : out std_logic_vector(7 downto 0);
    o_z2 : out std_logic_vector(7 downto 0);
    o_z3 : out std_logic_vector(7 downto 0);
    o_done : out std_logic;
    o_mem_addr : out std_logic_vector(15 downto 0);
    i_mem_data : in std_logic_vector(7 downto 0);
    o_mem_we : out std_logic;
    o_mem_en : out std_logic
);
end project_reti_logiche;

architecture behavioural of project_reti_logiche is
    -- FSM States
    type S is (INIT, ADDR, MEMREAD, MEMWAIT, OUTSEL, OUTEN);
    signal cur_state, next_state : S;

    -- Memory address management
    signal addr_shift_register : std_logic_vector(15 downto 0);
    signal header_shift_register : std_logic_vector(1 downto 0);
    
    -- Output management
    signal data0, data1, data2, data3 : std_logic_vector(7 downto 0);

    -- Counter management
    signal counter : integer range 0 to 2;
    signal counter_en : std_logic;

begin

 o_mem_we <= '0';

-- Clock process
process(i_clk, i_rst)
begin
    if i_rst = '1' then
        cur_state <= INIT;
    end if;
    
    if rising_edge(i_clk) then
        cur_state <= next_state;
    end if;
end process;

-- Next state process
process(cur_state, i_start, i_rst)
begin
    next_state <= cur_state;

    case cur_state is
        when INIT => -- Start reading the header and address
            if i_start = '1' then
                next_state <= ADDR;
            end if;
        when ADDR => -- End of memory address
            if i_start = '0' then
                next_state <= MEMREAD;
            end if;
        when MEMREAD => -- When the address is sent to the memory module
            next_state <= MEMWAIT;
        when MEMWAIT => -- Wait for memory data
            next_state <= OUTSEL;
        when OUTSEL => -- Output is selected
            next_state <= OUTEN;
        when OUTEN => -- o_done is 1 and the machine returns to INIT
            next_state <= INIT;
    end case;
    
    if i_rst = '1' then
        next_state <= INIT;
    end if;
end process;

-- Current state process
process(cur_state)
begin
    case cur_state is
        when MEMREAD => -- Send to memory module
            o_mem_addr <= addr_shift_register;
            o_mem_en <= '1';

            o_z0 <= "00000000";
            o_z1 <= "00000000";
            o_z2 <= "00000000";
            o_z3 <= "00000000";

            o_done <= '0';
        when OUTEN => -- Enable output ports and set o_done to 1
            o_mem_addr <= "0000000000000000";
            o_mem_en <= '0';

            o_z0 <= data0;
            o_z1 <= data1;
            o_z2 <= data2;
            o_z3 <= data3;

            o_done <= '1';
        when others =>
            o_mem_addr <= "0000000000000000";
            o_mem_en <= '0';

            o_z0 <= "00000000";
            o_z1 <= "00000000";
            o_z2 <= "00000000";
            o_z3 <= "00000000";

            o_done <= '0';
    end case;
end process;

-- Address shift register process
process(i_clk, i_start, i_rst)
begin
    -- Register operation
    if rising_edge(i_clk) then
        if i_start = '1' and counter = 2 then
            addr_shift_register <= addr_shift_register(14 downto 0) & i_w;
        elsif i_start = '0' then
            addr_shift_register <= addr_shift_register;
        elsif cur_state = INIT then
            addr_shift_register <= "0000000000000000"; 
        end if;
    end if;
    
    -- Asynchronous reset
    if i_rst = '1' then
        addr_shift_register <= "0000000000000000";
    end if;
end process;

-- Header shift register process
process(i_clk, i_rst)
begin
    -- Asynchronous reset
    if i_rst = '1' then
        header_shift_register <= "00";
        counter <= 0;
    end if;
        
    -- Register operation
    if rising_edge(i_clk) then
        if i_start = '1' then
            if counter_en = '1' and counter < 2 then
                header_shift_register(1) <= header_shift_register(0);
                header_shift_register(0) <= i_w;
                counter <= counter + 1;
            else
                header_shift_register <= header_shift_register;
            end if;
        elsif cur_state = INIT then
            header_shift_register <= "00";
            counter <= 0;
        else
            header_shift_register <= header_shift_register;
        end if;
    end if;

end process;

-- Data register process
process(i_clk, i_rst)
begin
    -- Register operation
    if rising_edge(i_clk) then
        if cur_state = OUTSEL then
            case header_shift_register is
                when "00" =>
                    data0 <= i_mem_data;
                when "01" =>
                    data1 <= i_mem_data;
                when "10" =>
                    data2 <= i_mem_data;
                when "11" =>
                    data3 <= i_mem_data;
                when others => -- Do nothing
            end case;
        end if;
    end if;

    -- Register reset
    if i_rst = '1' then
        data0 <= "00000000";
        data1 <= "00000000";
        data2 <= "00000000";
        data3 <= "00000000";
    end if;
end process;

-- Counter enable process
process(i_start, i_rst)
begin
    if i_start = '1' then
        counter_en <= '1';
    else
        counter_en <= '0';
    end if;
    
    if i_rst = '1' then
        counter_en <= '0';
    end if;
end process;

end behavioural;