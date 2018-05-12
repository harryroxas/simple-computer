LIBRARY IEEE,STD;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE STD.TEXTIO.ALL;

ENTITY computer IS
END computer;

ARCHITECTURE behaviorial OF computer IS
  type INSTRUCTION is array(14 downto 0) of STD_LOGIC_VECTOR(20 downto 0);

  BEGIN
    PROCESS
      FILE in_file : TEXT OPEN READ_MODE IS "in_values";
      VARIABLE in_line : LINE;
      VARIABLE count : INTEGER := 0;
      VARIABLE instructions : INSTRUCTION;

      VARIABLE opcode : STD_LOGIC_VECTOR(20 downto 0);

      VARIABLE inst : INTEGER := 0;
    BEGIN

      WHILE NOT ENDFILE(in_file) LOOP --do this till out of data
      READLINE(in_file, in_line); --get line of input stimulus
      READ(in_line, opcode); --get instruction

      instructions(count) := opcode;  --store instruction in array

      count := count + 1;
      END LOOP;

      WHILE inst /= count LOOP

      

      END LOOP;

      ASSERT FALSE REPORT "Simulation done" SEVERITY NOTE;
      WAIT; --allows the simulation to halt!
  END PROCESS;
END behaviorial;