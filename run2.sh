# How to use:
# $ chmod +x run2.sh
# $ ./run2.sh filename

ghdl -a --ieee=synopsys -Wa,--32 $1.vhdl && \
ghdl -e --ieee=synopsys -Wa,--32 -Wl,-m32 $1 && \
ghdl -r --ieee=synopsys -Wa,--32 -Wl,-m32 $1 --vcd=$1.vcd && \
gtkwave $1.vcd &