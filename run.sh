# How to use:
# $ chmod +x run.sh
# $ ./run.sh

ghdl -a --ieee=synopsys calculator.vhdl && \
ghdl -e --ieee=synopsys calculator && \
ghdl -r --ieee=synopsys calculator --vcd=calculator.vcd && \
gtkwave calculator.vcd &