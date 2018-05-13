# How to use:
# $ chmod +x run2.sh
# $ ./run2.sh

ghdl -a --ieee=synopsys -Wa,--32 computer.vhdl && \
ghdl -e --ieee=synopsys -Wa,--32 -Wl,-m32 computer && \
ghdl -r --ieee=synopsys -Wa,--32 -Wl,-m32 computer --vcd=computer.vcd && \
gtkwave computer.vcd &