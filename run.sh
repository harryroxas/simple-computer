# How to use:
# $ chmod +x run.sh
# $ ./run.sh

ghdl -a --ieee=synopsys computer.vhdl && \
ghdl -e --ieee=synopsys computer && \
ghdl -r --ieee=synopsys computer --vcd=computer.vcd && \
gtkwave computer.vcd &