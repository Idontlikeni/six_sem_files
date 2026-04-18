create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {CLK}] 
set_property IOSTANDARD LVCMOS33 [get_ports {CLK}] 
set_property PACKAGE_PIN E3 [get_ports {CLK}] 

# RST
set_property PACKAGE_PIN C12 [get_ports SYS_NRST]
set_property IOSTANDARD LVCMOS33 [get_ports SYS_NRST]
set_property PULLUP true [get_ports SYS_NRST]

# BTN0
set_property PACKAGE_PIN M18 [get_ports BTN_0]
set_property IOSTANDARD LVCMOS33 [get_ports BTN_0]

# BTN1
set_property PACKAGE_PIN P18 [get_ports BTN_1]
set_property IOSTANDARD LVCMOS33 [get_ports BTN_1]

# UART_RXD
set_property PACKAGE_PIN C4 [get_ports UART_RXD]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RXD]

# UART_TXD
set_property PACKAGE_PIN D4 [get_ports UART_TXD]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TXD]
set_property DRIVE 8 [get_ports UART_TXD]
set_property SLEW FAST [get_ports UART_TXD]

