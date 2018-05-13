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
  type OPERATION is array(14 downto 0) of STD_LOGIC_VECTOR(2 downto 0);
  type DESTINATION is array(14 downto 0) of STD_LOGIC_VECTOR(5 downto 0);
  type SOURCE1 is array(14 downto 0) of STD_LOGIC_VECTOR(5 downto 0);
  type SOURCE2 is array(14 downto 0) of STD_LOGIC_VECTOR(5 downto 0);
  type VALUE is array(31 downto 0) of INTEGER;
  BEGIN
    PROCESS
      FILE in_file : TEXT OPEN READ_MODE IS "input/1.txt";
      VARIABLE in_line : LINE;
      VARIABLE count : INTEGER := 0;
      VARIABLE instructions : INSTRUCTION;
      VARIABLE operations : OPERATION;
      VARIABLE destinations : DESTINATION;
      VARIABLE sources1 : SOURCE1;
      VARIABLE sources2 : SOURCE2;
      VARIABLE values : VALUE;
      VARIABLE registers : STD_LOGIC_VECTOR(31 downto 0);

      VARIABLE opcode : STD_LOGIC_VECTOR(20 downto 0);

      VARIABLE inst : INTEGER := 0;
      VARIABLE clock_cycle : INTEGER := 0;

      VARIABLE fetched : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE decoded : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE executed : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE memoried : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE writebacked : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE stalled : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
      VARIABLE reading : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
      VARIABLE writing : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

      VARIABLE value1 : INTEGER;
      VARIABLE value2 : INTEGER;
      VARIABLE all_done : STD_LOGIC;
      VARIABLE no_hazard : STD_LOGIC;
      VARIABLE always_true : STD_LOGIC := '1';
      VARIABLE dest : STD_LOGIC_VECTOR(4 downto 0);

      VARIABLE PC : INTEGER := 0;
      VARIABLE FETCH : STD_LOGIC := '0';
      VARIABLE DECODE : STD_LOGIC := '0';
      VARIABLE EXECUTE : STD_LOGIC := '0';
      VARIABLE MEMORY : STD_LOGIC := '0';
      VARIABLE WRITEBACK : STD_LOGIC := '0';

    BEGIN

      WHILE NOT ENDFILE(in_file) LOOP --do this till out of data
      READLINE(in_file, in_line); --get line of input stimulus
      READ(in_line, opcode); --get instruction

      instructions(count) := opcode;  --store instruction in array

      count := count + 1;
      END LOOP;

      L1: WHILE always_true = '1' LOOP
        all_done := '1';

        FOR i IN 0 TO count-1 LOOP
          IF writebacked(i) = '0' THEN
            all_done := '0';
          END IF;
        END LOOP;
        EXIT L1 WHEN all_done = '1';

        clock_cycle := clock_cycle + 1;
        clock_cycle_out <= STD_LOGIC_VECTOR(to_unsigned(clock_cycle, 4));

        FOR i IN 0 TO count-1 LOOP
          IF writebacked(i) = '1' AND WRITEBACK = '1' THEN
            WRITEBACK := '0';
            stage(0) <= '0';
            writing(to_integer(unsigned(destinations(i)(4 downto 0)))) := '0';
            reading(to_integer(unsigned(sources1(i)(4 downto 0)))) := '0';
            IF to_integer(unsigned(operations(i))) /= 0 THEN
              reading(to_integer(unsigned(sources2(i)(4 downto 0)))) := '0';
            END IF;
          END IF;

          IF memoried(i) = '1' AND writebacked(i) = '0' THEN
            IF WRITEBACK = '0' THEN
              writebacked(i) := '1';
              WRITEBACK := '1';
              MEMORY := '0';
              stage(0) <= '1';
            ELSE
              stage(1) <= '1';
              stalled(1) := '1';
            END IF;
          END IF;

          IF executed(i) = '1' AND memoried(i) = '0' THEN
            IF MEMORY = '0' THEN
              memoried(i) := '1';
              MEMORY := '1';
              EXECUTE := '0';
              stage(1) <= '1';
            ELSE
              stage(2) <= '1';
              stalled(2) := '1';
            END IF;
          END IF;

          IF decoded(i) = '1' AND executed(i) ='0' THEN
            IF EXECUTE = '0' THEN
              executed(i) := '1';
              EXECUTE := '1';
              DECODE := '0';
              stage(2) <= '1';

              IF to_integer(unsigned(operations(i))) = 0 THEN
                IF sources1(i)(5) = '0' THEN
                  values(to_integer(unsigned(destinations(i)(4 downto 0)))) := values(to_integer(unsigned(sources1(i)(4 downto 0))));
                ELSE
                  values(to_integer(unsigned(destinations(i)(4 downto 0)))) := to_integer(unsigned(sources1(i)(1 downto 0)));
                END IF;
              ELSE
                IF sources1(i)(5) = '0' THEN
                  value1 := values(to_integer(unsigned(sources1(i)(4 downto 0))));
                ELSE
                  value1 := to_integer(unsigned(sources1(i)(1 downto 0)));
                END IF;

                IF sources2(i)(5) = '0' THEN
                  value2 := values(to_integer(unsigned(sources2(i)(4 downto 0))));
                ELSE
                  value2 := to_integer(unsigned(sources2(i)(1 downto 0)));
                END IF;
                IF to_integer(unsigned(operations(i))) = 1 THEN
                  values(to_integer(unsigned(destinations(i)(4 downto 0)))) := value1 + value2;
                ELSIF to_integer(unsigned(operations(i))) = 2 THEN
                  values(to_integer(unsigned(destinations(i)(4 downto 0)))) := value1 - value2;
                ELSIF to_integer(unsigned(operations(i))) = 3 THEN
                  values(to_integer(unsigned(destinations(i)(4 downto 0)))) := value1 * value2;
                ELSIF to_integer(unsigned(operations(i))) = 4 THEN
                  values(to_integer(unsigned(destinations(i)(4 downto 0)))) := value1 / value2;
                ELSIF to_integer(unsigned(operations(i))) = 5 THEN
                  values(to_integer(unsigned(destinations(i)(4 downto 0)))) := value1 mod value2;
                END IF;
              END IF;
            ELSE
              stage(3) <= '1';
              stalled(3) := '1';
            END IF;
          END IF;

          IF fetched(i) = '1' AND decoded(i) = '0' AND DECODE = '0' THEN
            operations(i) := instructions(i)(20 downto 18);
            IF to_integer(unsigned(instructions(i)(20 downto 12))) = 0 THEN
              destinations(i) := instructions(i)(11 downto 6);
            ELSE
              destinations(i) := instructions(i)(17 downto 12);
            END IF;

            no_hazard := '1';

            IF writing(to_integer(unsigned(destinations(i)(4 downto 0)))) = '1' OR reading(to_integer(unsigned(destinations(i)(4 downto 0)))) = '1' THEN
              no_hazard := '0';
            END IF;

            IF no_hazard = '1' THEN

              IF to_integer(unsigned(operations(i))) = 0 THEN
                sources1(i) := instructions(i)(5 downto 0);
                IF sources1(i)(5) = '0' THEN
                  IF writing(to_integer(unsigned(sources1(i)(4 downto 0)))) = '1' THEN
                    no_hazard := '0';
                  END IF;
                END IF;
              ELSE
                sources1(i) := instructions(i)(11 downto 6);
                sources2(i) := instructions(i)(5 downto 0);
                IF sources1(i)(5) = '0' THEN
                  IF writing(to_integer(unsigned(sources1(i)(4 downto 0)))) = '1' THEN
                    no_hazard := '0';
                  END IF;
                END IF;
                IF sources2(i)(5) = '0' THEN
                  IF writing(to_integer(unsigned(sources2(i)(4 downto 0)))) = '1' THEN
                    no_hazard := '0';
                  END IF;
                END IF;
              END IF;
 
              IF no_hazard = '1' THEN
                writing(to_integer(unsigned(destinations(i)(4 downto 0)))) := '1';

                decoded(i) := '1';
                FETCH := '0';
                DECODE := '1';
                stage(3) <= '1';
              ELSE
                stage(4) <= '1';
                stalled(4) := '1';
              END IF;
            ELSE
              stage(4) <= '1';
              stalled(4) := '1';
            END IF;
          END IF;

          IF fetched(i) = '0' AND FETCH = '0' THEN
            fetched(i) := '1';
            FETCH := '1';
            stage(4) <= '1';
          END IF;

        END LOOP;
        PC := PC + 1;

        pc_out <= STD_LOGIC_VECTOR(to_unsigned(PC, 4));

        wait for 1 ns;
        stage <= stalled;
        wait for 1 ns;
        stalled := (others => '0');


      END LOOP L1;

      ASSERT FALSE REPORT "Simulation done" SEVERITY NOTE;
      WAIT; --allows the simulation to halt!
  END PROCESS;
END behaviorial;