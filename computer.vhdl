LIBRARY IEEE,STD;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE STD.TEXTIO.ALL;
ENTITY computer IS
END computer;

ARCHITECTURE behaviorial OF computer IS

  BEGIN
    file_io:
    PROCESS IS
      FILE in_file : TEXT OPEN READ_MODE IS "in_values";
      FILE out_file : TEXT OPEN WRITE_MODE IS "out_values";
      VARIABLE out_line : LINE;
      VARIABLE in_line : LINE;
      VARIABLE inst : std_logic_vector(2 downto 0);
      VARIABLE dest : std_logic_vector(5 downto 0);
      VARIABLE src1 : std_logic_vector(5 downto 0);
      VARIABLE src2 : std_logic_vector(5 downto 0);
   BEGIN
      WHILE NOT ENDFILE(in_file) LOOP --do this till out of data
      READLINE(in_file, in_line); --get line of input stimulus
      READ(in_line, inst); --get first operand
      if (inst = "000") then
        READ(in_line, dest);
        READ(in_line, src1);
        WRITE(out_line, inst); --save results to line
        WRITE(out_line, dest);
        WRITE(out_line, src1);
      else
        READ(in_line, dest);
        READ(in_line, src1);
        READ(in_line, src2);
        WRITE(out_line, inst); --save results to line
        WRITE(out_line, dest);
        WRITE(out_line, src1);
        WRITE(out_line, src2);
      end if;
      WRITELINE(out_file, out_line); --write line to file
      END LOOP;
      ASSERT FALSE REPORT "Simulation done" SEVERITY NOTE;
      WAIT; --allows the simulation to halt!
  END PROCESS;
END behaviorial;