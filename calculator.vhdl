library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity calculator is
  port (
    clock     : out STD_LOGIC;
    stage     : out STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    flag      : out STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    pc        : out STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    registers : out STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    instruction : out STD_LOGIC_VECTOR(20 downto 0)
  );
end entity;

architecture bev of calculator is
  -- Data Types
  type INSTRUCTIONS is array(14 downto 0) of STD_LOGIC_VECTOR(20 downto 0);

  -- Signals
  --signal instr_cache : INSTRUCTIONS;

  begin
    process
      FILE content       : TEXT;
      CONSTANT filename  : STRING := "input.txt";
      VARIABLE buff      : LINE;
      VARIABLE ins       : INTEGER := 0;
      VARIABLE clk       : INTEGER := 0;

      VARIABLE instr_cache : INSTRUCTIONS;

      -- Flags
      VARIABLE fetched   : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE decoded   : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE executed  : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE memorized : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE writed    : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE stalled   : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
      VARIABLE write_reg : STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); -- flags if reg is to be written

      VARIABLE decoder   : INTEGER := 0;
      VARIABLE executor  : INTEGER := 0;
      VARIABLE memct     : INTEGER := 0;
      VARIABLE writer    : INTEGER := 0;
      VARIABLE progCt    : INTEGER := 0;

      VARIABLE destination : STD_LOGIC_VECTOR(5 downto 0);

      CONSTANT FETCH     : INTEGER := 4;
      CONSTANT DECODE    : INTEGER := 3;
      CONSTANT EXECUTE   : INTEGER := 2;
      CONSTANT MEMORY    : INTEGER := 1;
      CONSTANT WRITEBACK : INTEGER := 0;

      VARIABLE opcode    : STD_LOGIC_VECTOR(20 downto 0);
    begin
      -- [ File Reading ]
        file_open(content, filename, READ_MODE);

        while not endfile(content) loop
          readline(content, buff);
          read(buff, opcode);

          instr_cache(ins) := opcode;

          ins := ins + 1;
        end loop;

        file_close(content);
      -- [/ File Reading ]

      while writer /= ins loop
        clock <= '1';

        -- Write Back
        if memorized(writer) = '1' then
          stage(WRITEBACK) <= '1';

          writed(writer) := '1';
          writer := writer + 1;
        end if;

        -- Memory
        if executed(memct) = '1' then
          stage(MEMORY) <= '1';

          memorized(memct) := '1';
          memct := memct + 1;
        end if;

        -- Execute
        if decoded(executor) = '1' then
          stage(EXECUTE) <= '1';

          executed(executor) := '1';
          executor := executor + 1;
        end if;

        -- Decode
        if fetched(decoder) = '1' then
          -- Check if instruction is LOAD
          if to_integer(unsigned(instr_cache(decoder)(8 downto 0))) = 1 then
            destination := instr_cache(decoder)(14 downto 9);
          else
            destination := instr_cache(decoder)(8 downto 3);
          end if;

          stage(DECODE) <= '1';
          --if write_reg(to_integer(unsigned(destination))) = '1' then
          --  -- We stall decode stage
          --  stalled(DECODE) := '1';
          --else
            decoded(decoder) := '1';
            decoder := decoder + 1;

            -- Lock down write access to register
            write_reg(to_integer(unsigned(destination))) := '1';
          --end if;
        end if;

        -- Fetch
        if progCt < ins then
          stage(FETCH) <= '1';
          fetched(progCt) := '1';

          instruction <= instr_cache(progCt);
        end if;

        -- Program Counter
        progCt := progCt + 1;
        pc <= std_logic_vector(to_unsigned(progCt, 4));

        wait for 1 ns;

        -- Reset Skip
        clock <= '0';
        instruction <= std_logic_vector(to_unsigned(0, 21));
        stage <= stalled;
        pc <= std_logic_vector(to_unsigned(0, 4));
        flag <= std_logic_vector(to_unsigned(0, 3));

        wait for 1 ns;
      end loop;
      wait;
  end process;
end bev;