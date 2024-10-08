print ('RX script ...')
host.chip.ref_clk.set(rap0, 245.76e6)

#host.reset(rap0)
host.misc.on(['VCXO', 'PLL'])
host.pwr.on('ALL')
freq_rff = 28e9
host.chip.init(rap0, 'CHIP')
host.chip.init(rap0, 'SYNTH')
host.chip.init(rap0, 'VALIDATION')
host.chip.init(rap0, 'ADC')
host.chip.synth.setup(rap0)
host.chip.synth.set(rap0,freq_rff, frac_mode=True, sd_order=2)
host.chip.init(rap0, 'RX', printit=False)
host.chip.rx.setup(rap0, 'BB', 'rv', ant_en_v=0x0001, ant_en_h=0x0000)
#host.chip.rx.setup(rap0, 'IF', 'rv', ant_en_v=0x0001, ant_en_h=0x0000)
host.spi.wrrd(rap0, 'capval_0',0b101) #bandwidth bbrx-chain
#host.spi.wrrd(rap0, 'bb_rx_en_dco',  0b11110000)
#host.chip.adc.enable(rap0)
host.chip.rx.dco.calibrate(rap0, 'V', 0)

host.chip.rx.dco.report(rap0, 'V')




# TX
host.chip.ref_clk.set(rap0, 245.76e6)

#host.reset(rap0)
host.misc.on(['VCXO', 'PLL'])
host.pwr.on('ALL')
freq_rff = 28e9
host.chip.init(rap0, 'CHIP')
host.chip.init(rap0, 'SYNTH')
host.chip.init(rap0, 'VALIDATION')
host.chip.init(rap0, 'ADC')
host.chip.synth.setup(rap0)
host.chip.synth.set(rap0,freq_rff, frac_mode=True, sd_order=2)
host.chip.init(rap0, 'TX', printit=False)
host.chip.tx.setup(rap0, 'BB', 'tv', ant_en_v=0x0001, ant_en_h=0x0000)

host.chip.tx.dco._prepare_mode_params('BB')
host.chip.tx.dco._spi.wr(rap0, 'bb_tx_dco_v', 0x7ff07ff)
host.chip.tx.dco._backup_settings(rap0)
host.chip.tx.dco._rx_setup(rap0, 'V')
host.chip.tx.dco._pre_calibration_settings(rap0, 'V', 0)
