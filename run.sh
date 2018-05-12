# How to use:
# $ chmod +x run.sh
# $ ./run.sh

ghdl -a --ieee=synopsys run.vhdl && \
ghdl -e --ieee=synopsys run && \
ghdl -r --ieee=synopsys run --vcd=run.vcd && \
gtkwave run.vcd &