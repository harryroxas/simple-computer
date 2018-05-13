-- Members: Canonizado, Ganayo, Roxas, Sunga | ST-7L
-- Program Description: A calculator that supports up to two bits operands only

-- REFERENCES:
-- File reading - http://web.engr.oregonstate.edu/~traylor/ece474/vhdl_lectures/text_io

-- Necessary imports
LIBRARY IEEE,STD;

use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
USE IEEE.STD_LOGIC_1164.ALL;

-- For file reading
USE IEEE.STD_LOGIC_TEXTIO.ALL;
USE STD.TEXTIO.ALL;

ENTITY computer IS
  -- To be shown in GTKWave
  port (
    clock_cycle_out : out STD_LOGIC_VECTOR(3 downto 0) := (others => '0'); -- Current clock cycle
    stage : out STD_LOGIC_VECTOR(4 downto 0) := (others => '0'); -- F/D/X/M/W
    pc_out : out STD_LOGIC_VECTOR(3 downto 0) := (others => '0'); -- Incremented PC
    signals : out STD_LOGIC_VECTOR(3 downto 0) := (others => '0') -- ZF/SF/UF/OF
  );
END computer;

ARCHITECTURE behaviorial OF computer IS
  type INSTRUCTION is array(14 downto 0) of STD_LOGIC_VECTOR(20 downto 0); -- Array of instructions
  type OPERATION is array(14 downto 0) of STD_LOGIC_VECTOR(2 downto 0); -- LD/ADD/SUB/MUL/DIV/MOD
  type DESTINATION is array(14 downto 0) of STD_LOGIC_VECTOR(5 downto 0); -- First address
  type SOURCE1 is array(14 downto 0) of STD_LOGIC_VECTOR(5 downto 0); -- Second address
  type SOURCE2 is array(14 downto 0) of STD_LOGIC_VECTOR(5 downto 0); -- Third address
  type VALUE is array(31 downto 0) of INTEGER; -- Array of values | i is ith register

  BEGIN
    PROCESS
      FILE in_file : TEXT OPEN READ_MODE IS "input/file-bits.txt"; -- Change filename here
      VARIABLE in_line : LINE; -- Current line
      VARIABLE count : INTEGER := 0; -- Number of instructions from text file
      VARIABLE instructions : INSTRUCTION; -- Array of instructions
      VARIABLE operations : OPERATION; -- Array of operations
      VARIABLE destinations : DESTINATION; -- Array of destination register
      VARIABLE sources1 : SOURCE1; -- Array of source register / value
      VARIABLE sources2 : SOURCE2; -- Array of source register / value
      VARIABLE values : VALUE; -- Array of values
      
      VARIABLE opcode : STD_LOGIC_VECTOR(20 downto 0); -- Instruction with opcode
      VARIABLE clock_cycle : INTEGER := 0; -- Tracks current clock cycle

      -- To check if current instruction is done with the stage
      VARIABLE fetched : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE decoded : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE executed : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE memoried : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      VARIABLE writebacked : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
      
      -- To check if current stage is being stalled
      VARIABLE stalled : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
      
      -- To check if a certain register is being read or written (for checking stalls)
      VARIABLE reading : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
      VARIABLE writing : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

      -- For holding the values from source registers / immediate values
      VARIABLE value1 : INTEGER;
      VARIABLE value2 : INTEGER;

      -- Necessary flags
      VARIABLE all_done : STD_LOGIC;
      VARIABLE no_hazard : STD_LOGIC;
      VARIABLE always_true : STD_LOGIC := '1';

      VARIABLE PC : INTEGER := 0; -- To increment the PC
      
      -- To check what stage the instruction is (not necessarily done)
      VARIABLE FETCH : STD_LOGIC := '0';
      VARIABLE DECODE : STD_LOGIC := '0';
      VARIABLE EXECUTE : STD_LOGIC := '0';
      VARIABLE MEMORY : STD_LOGIC := '0';
      VARIABLE WRITEBACK : STD_LOGIC := '0';

    BEGIN

      WHILE NOT ENDFILE(in_file) LOOP -- Loop until all lines are finished
        READLINE(in_file, in_line); --Get current line
        READ(in_line, opcode); -- Get instruction with opcode
        instructions(count) := opcode;  -- Store instruction with opcode in array
        count := count + 1; -- Increment total number of instructions 
      END LOOP;

      -- While all instructions are not done
      L1: WHILE always_true = '1' LOOP
        all_done := '1';

        -- Checks every instruction if it is done with the writeback stage
        -- If all instructions are done with W that means the program is done
        FOR i IN 0 TO count-1 LOOP
          IF writebacked(i) = '0' THEN
            all_done := '0';
          END IF;
        END LOOP;
        EXIT L1 WHEN all_done = '1'; -- Break outer loop

        clock_cycle := clock_cycle + 1; -- Increment clock cycle count
        clock_cycle_out <= STD_LOGIC_VECTOR(to_unsigned(clock_cycle, 4)); -- Converts CC to binary

        -- Inner loop
        FOR i IN 0 TO count-1 LOOP

          -- If instruction is done - set writeback to 0
          IF writebacked(i) = '1' AND WRITEBACK = '1' THEN
            WRITEBACK := '0';

            -- Reset writing and reading flags
            writing(to_integer(unsigned(destinations(i)(4 downto 0)))) := '0';
            reading(to_integer(unsigned(sources1(i)(4 downto 0)))) := '0';
            
            -- If instruction is not load - also reset the 2nd source
            IF to_integer(unsigned(operations(i))) /= 0 THEN
              reading(to_integer(unsigned(sources2(i)(4 downto 0)))) := '0';
            END IF;
          END IF;

          -- ============================== WRITEBACK ==============================
          IF memoried(i) = '1' AND writebacked(i) = '0' AND WRITEBACK = '0' THEN
            writebacked(i) := '1';
            WRITEBACK := '1';
            MEMORY := '0';
            stage(0) <= '1';
          END IF;

          IF memoried(i) = '1' AND writebacked(i) = '0' AND WRITEBACK = '1' THEN
            stage(1) <= '1';
            stalled(1) := '1';
            MEMORY := '1';
          END IF;

          -- ============================== MEMORY ==============================
          IF executed(i) = '1' AND memoried(i) = '0' AND MEMORY = '0' THEN
            memoried(i) := '1';
            MEMORY := '1';
            EXECUTE := '0';
            stage(1) <= '1';
          END IF;

          IF executed(i) = '1' AND memoried(i) = '0' AND MEMORY = '1' THEN
            stage(2) <= '1';
            stalled(2) := '1';
            EXECUTE := '1';
          END IF;

          -- ============================== EXECUTE ==============================
          IF decoded(i) = '1' AND executed(i) ='0' AND EXECUTE = '0' THEN
            executed(i) := '1';
            EXECUTE := '1';
            DECODE := '0';
            stage(2) <= '1';

            -- LD
            IF to_integer(unsigned(operations(i))) = 0 THEN
              IF sources1(i)(5) = '0' THEN
                -- Source is a register - get value from register
                values(to_integer(unsigned(destinations(i)(4 downto 0)))) := values(to_integer(unsigned(sources1(i)(4 downto 0))));
              ELSE
                -- Source is an immediate value
                values(to_integer(unsigned(destinations(i)(4 downto 0)))) := to_integer(unsigned(sources1(i)(4 downto 0)));
              END IF;

              IF values(to_integer(unsigned(destinations(i)(4 downto 0)))) = 0 THEN
                signals(3) <= '1'; -- Set zero flag
              END IF;
              IF values(to_integer(unsigned(destinations(i)(4 downto 0)))) > 0 THEN
                signals(2) <= '1'; -- Set sign flag
              END IF;
              IF values(to_integer(unsigned(destinations(i)(4 downto 0)))) < -3 THEN
                signals(1) <= '1'; -- Set underflow flag
              END IF;
              IF values(to_integer(unsigned(destinations(i)(4 downto 0)))) > 3 THEN
                signals(0) <= '1'; -- Set overflow flag
              END IF;
            
            -- Other operations (not LD)
            ELSE
              -- Store first source to value1
              IF sources1(i)(5) = '0' THEN
                -- Get value from register
                value1 := values(to_integer(unsigned(sources1(i)(4 downto 0))));
              ELSE
                -- Immediate value (get 2 bits)
                value1 := to_integer(unsigned(sources1(i)(1 downto 0)));
              END IF;

              -- Store second source to value2
              IF sources2(i)(5) = '0' THEN
                -- Get value from register
                value2 := values(to_integer(unsigned(sources2(i)(4 downto 0))));
              ELSE
                -- Immediate value (get 2 bits)
                value2 := to_integer(unsigned(sources2(i)(1 downto 0)));
              END IF;

              -- Convert binary operations to integers
              -- Equivalent values of the operations:
              -- 1 ADD | 2 SUB | 3 MUL | 4 DIV | 5 MOD

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

              -- Check flags again and set the necessary ones
              IF values(to_integer(unsigned(destinations(i)(4 downto 0)))) = 0 THEN
                signals(3) <= '1'; -- Set zero flag
              END IF;
              IF values(to_integer(unsigned(destinations(i)(4 downto 0)))) > 0 THEN
                signals(2) <= '1'; -- Set sign flag
              END IF;
              IF values(to_integer(unsigned(destinations(i)(4 downto 0)))) < -3 THEN
                signals(1) <= '1'; -- Set underflow flag
              END IF;
              IF values(to_integer(unsigned(destinations(i)(4 downto 0)))) > 3 THEN
                signals(0) <= '1'; -- Set overflow flag
              END IF;

            END IF;
          END IF;

          IF decoded(i) = '1' AND executed(i) = '0' AND EXECUTE = '1' THEN
            stage(3) <= '1';
            stalled(3) := '1';
            DECODE := '1';
          END IF;

          -- ============================== DECODE ==============================
          IF fetched(i) = '1' AND decoded(i) = '0' THEN
            DECODE := '1';
            -- Store first 3 bits (of instruction to operation)
            operations(i) := instructions(i)(20 downto 18);

            -- This represents the LD opcode 00000000
            IF to_integer(unsigned(instructions(i)(20 downto 12))) = 0 THEN
              -- Destination will be moved to technically the second address
              destinations(i) := instructions(i)(11 downto 6);
            ELSE
              destinations(i) := instructions(i)(17 downto 12);
            END IF;

            no_hazard := '1';

            IF writing(to_integer(unsigned(destinations(i)(4 downto 0)))) = '1' OR reading(to_integer(unsigned(destinations(i)(4 downto 0)))) = '1' THEN
              no_hazard := '0';
            END IF;

            IF no_hazard = '1' THEN
              -- If operation is LD
              IF to_integer(unsigned(operations(i))) = 0 THEN
                -- Only source is technically from the third address
                sources1(i) := instructions(i)(5 downto 0);
                IF sources1(i)(5) = '0' THEN
                  -- Source is a register - if it is currently being written - hazard 
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
                stage(3) <= '1';
                stalled(3) := '1';
              END IF;
            ELSE
              stage(3) <= '1';
              stalled(3) := '1';
            END IF;
          END IF;

          IF fetched(i) = '1' AND decoded(i) = '0' AND DECODE = '1' THEN
            stage(4) <= '1';
            stalled(4) := '1';
            FETCH := '1';
          END IF;

          -- ============================== FETCH ==============================
          IF fetched(i) = '0' AND FETCH = '0' THEN
            fetched(i) := '1';
            FETCH := '1';
            stage(4) <= '1';
          END IF;

        END LOOP; -- Inner Loop

        PC := PC + 1; -- Increment program counter
        pc_out <= STD_LOGIC_VECTOR(to_unsigned(PC, 4)); -- Convert PC to binary
        wait for 1 ns;

        stage <= stalled; -- Reflect signals that are stalled
        signals <= STD_LOGIC_VECTOR(to_unsigned(0, 4));
        pc_out <= STD_LOGIC_VECTOR(to_unsigned(0, 4));
        wait for 1 ns;
        
        stalled := (others => '0');

      END LOOP L1; -- Outer loop

      ASSERT FALSE REPORT "Simulation done" SEVERITY NOTE;
      WAIT; -- Allows the simulation to halt

  END PROCESS;
END behaviorial;