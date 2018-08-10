

create_clock -period 40.000 -name ETH0_MII_rx_clk -waveform {0.000 20.000} [get_ports ETH0_MII_rx_clk]
create_clock -period 40.000 -name ETH0_MII_tx_clk -waveform {0.000 20.000} [get_ports ETH0_MII_tx_clk]
set_input_delay -clock [get_clocks ETH0_MII_rx_clk] -min -add_delay 10.000 [get_ports {ETH0_MII_rx_dv {ETH0_MII_rxd[0]} {ETH0_MII_rxd[1]} {ETH0_MII_rxd[2]} {ETH0_MII_rxd[3]}}]
set_input_delay -clock [get_clocks ETH0_MII_rx_clk] -max -add_delay 30.000 [get_ports {ETH0_MII_rx_dv {ETH0_MII_rxd[0]} {ETH0_MII_rxd[1]} {ETH0_MII_rxd[2]} {ETH0_MII_rxd[3]}}]
set_output_delay -clock [get_clocks ETH0_MII_tx_clk] -max -add_delay 0.000 [get_ports -filter { NAME =~  "*ETH0_MII_t*" && DIRECTION == "OUT" }]
set_output_delay -clock [get_clocks ETH0_MII_tx_clk] -min -add_delay 30.000 [get_ports -filter { NAME =~  "*ETH0_MII_t*" && DIRECTION == "OUT" }]
