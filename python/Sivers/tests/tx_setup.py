mode   = 'BB'
pol    = 'V'
rx_pol = 'H'
tpol   = 'tv'

#host.chip.ref_clk.set(rap0, 245.76e6)

#host.reset(rap0)

host.misc.on(['VCXO', 'PLL'])
host.pwr.on('ALL')

host.pll.setup()  # Lock the MB2-VCXO to 245.76 MHz
vcxo_freq=host.pll.setup()['vcxo_freq'] #Read back the exact frequency (typically 245759996.9474969 Hz)
host.chip.ref_clk.set(rap0, vcxo_freq) #Set the Rapinoe clock to vcxo_freq.

host.chip.ram.fill(rap0) # Loads gain tables from file to RAM
host.chip.ram.fill(rap0, 'BS28GHz') # Loads boresight beam for 28GHz from file to RAM
freq_rff = 28e9
host.chip.init(rap0, 'CHIP')
host.chip.init(rap0, 'SYNTH')
host.chip.init(rap0, 'VALIDATION')
host.chip.init(rap0, 'ADC')
host.chip.init(rap0, 'TX', printit=False)
host.chip.synth.setup(rap0)
host.chip.synth.set(rap0,freq_rff, frac_mode=True, sd_order=2, printit=True)
host.chip.tx.setup(rap0, mode, tpol, ant_en_v=0xFFFF, ant_en_h=0x0000)
host.chip.trx.mode(rap0,tpol)
host.chip.tx.beam(rap0, 0, tpol)
host.chip.tx.gain_rf(rap0, 0, tpol)

#host.chip.tx.dco.calibrate(rap0, mode, pol, rx_pol)
#gain_com = 48
#gain_bf = 100
#host.chip.ram.wr(rap0, 'tx_ram_v', 0, (gain_bf<<6)+(gain_com<<0))
