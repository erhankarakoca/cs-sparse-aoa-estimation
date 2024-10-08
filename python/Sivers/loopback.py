host.chip.ref_clk.set(rap0, 245.76e6)
host.misc.on(['VCXO', 'PLL'])
host.pwr.on('ALL')
freq_rff = 28e9
host.chip.init(rap0, 'CHIP')
host.chip.init(rap0, 'SYNTH')
host.chip.init(rap0, 'VALIDATION')
host.chip.init(rap0, 'ADC')
host.chip.synth.setup(rap0)
host.chip.synth.set(rap0,freq_rff, frac_mode=True, sd_order=2)

RX_GAIN_INDEX = 0
host.chip.init(rap0, 'RX', printit=False)
host.chip.rx.setup(rap0, 'BB', 'rv', ant_en_v=0x0000, ant_en_h=0x0000)
#host.spi.wrrd(rap0, 'capval_0',0b101) #bandwidth bbrx-chain
rx_ram_row_backup = host.chip.ram.rd(rap0, 'rx_ram_v', RX_GAIN_INDEX)
host.chip.ram.wr(rap0, 'rx_ram_v', RX_GAIN_INDEX, 0x003E00009FB10016A41C)
host.chip.rx.gain(rap0, RX_GAIN_INDEX, 'RV')
host.chip.rx.dco.calibrate(rap0, 'V', RX_GAIN_INDEX)

TX_GAIN_INDEX = 0
host.chip.init(rap0, 'TX', printit=False)
host.chip.tx.setup(rap0, 'BB', 'tv', ant_en_v=0x0000, ant_en_h=0x0000)
host.spi.wrrd(rap0, 'com_bias_trim', 0x666666666) # txvga txpa txmix rxvga rxmix lo_in lo_mid lo_out_tx lo_out_rx
tx_ram_row = host.chip.ram.rd(rap0, 'tx_ram_v', TX_GAIN_INDEX)
tx_ram_row_backup = tx_ram_row
bf_att_com = 0x1f
tx_ram_row = tx_ram_row & 0xf83fff
tx_ram_row = tx_ram_row | (bf_att_com << 14)
host.chip.ram.wr(rap0, 'tx_ram_v', TX_GAIN_INDEX, tx_ram_row)
host.chip.tx.gain_rf(rap0, TX_GAIN_INDEX, 'TV')
import tx_dco
host.chip.tx.bb_dco = tx_dco.TxDco(host.chip, 'BB')
host.chip.tx.bb_dco.sweep(rap0, 'V', TX_GAIN_INDEX, step=10)
