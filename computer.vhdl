LIBRARY IEEE,STD;

use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE STD.TEXTIO.ALL;

ENTITY computer IS
  port (
    clock_cycle_out : out STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    stage : out STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    pc_out : out STD_LOGIC_VECTOR(3 downto 0) := (others => '0')
  );
END computer;

ARCHITECTURE behaviorial OF computer IS
  type INSTRUCTION is array(14 downto 0) of STD_LOGIC_VECTOR(20 downto 0);

  BEGIN
    PROCESS
      FILE in_file : TEXT OPEN READ_MODE IS "in_values.txt";
      VARIABLE in_line : LINE;
      VARIABLE count : INTEGER := 0;
      VARIABLE instructions : INSTRUCTION;

      VARIABLE opcode : STD_LOGIC_VECTOR(20 downto 0);

      VARIABLE inst : INTEGER := 0;
      VARIABLE clock_cycle : INTEGER := 0;

      VARIABLE fetched : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE decoded : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE executed : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE memoried : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE writebacked : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE stalled : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');

      VARIABLE PC : INTEGER := 0;
      VARIABLE DECODE : INTEGER := 0;
      VARIABLE EXECUTE : INTEGER := 0;
      VARIABLE MEMORY : INTEGER := 0;
      VARIABLE WRITEBACK : INTEGER := 0;

    BEGIN

      WHILE NOT ENDFILE(in_file) LOOP --do this till out of data
      READLINE(in_file, in_line); --get line of input stimulus
      READ(in_line, opcode); --get instruction

      instructions(count) := opcode;  --store instruction in array

      count := count + 1;
      END LOOP;

      WHILE inst /= count LOOP
        clock_cycle := clock_cycle + 1;
        clock_cycle_out <= STD_LOGIC_VECTOR(to_unsigned(clock_cycle, 4));

        IF memoried(inst) = '1' THEN
          writebacked(inst) := '1';
          stage(0) <= '1';

          inst := inst + 1;
        END IF;

        IF executed(MEMORY) = '1' THEN
          memoried(MEMORY) := '1';
          stage(1) <= '1';

          MEMORY := MEMORY + 1;
        END IF;

        IF decoded(EXECUTE) = '1' THEN
          executed(EXECUTE) := '1';
          stage(2) <= '1';

          EXECUTE := EXECUTE + 1;
        END IF;

        IF fetched(DECODE) = '1' THEN
          decoded(DECODE) := '1';
          stage(3) <= '1';

          DECODE := DECODE + 1;
        END IF;

        IF PC < count THEN
          fetched(PC) := '1';
          stage(4) <= '1';

          PC := PC + 1;
        END IF;

        pc_out <= STD_LOGIC_VECTOR(to_unsigned(PC, 4));

        wait for 10 ns;

        stage <= stalled;

        wait for 10 ns;

      END LOOP;

      ASSERT FALSE REPORT "Simulation done" SEVERITY NOTE;
      WAIT; --allows the simulation to halt!
  END PROCESS;
END behaviorial;