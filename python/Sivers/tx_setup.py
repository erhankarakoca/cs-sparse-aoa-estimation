import os

f = open('freq.txt')
freq_rff = float(f.readline())
f.close()

f = open('tx_config.txt','w')

f.write('mode   = "BB"\n')
f.write('tpol   = "tvth"\n')

f.write('host.reset(rap0)\n')

f.write('host.misc.on(["VCXO", "PLL"])\n')
f.write('host.pwr.on("ALL")\n')

f.write('host.pll.setup()\n')  # Lock the MB2-VCXO to 245.76 MHz
f.write('vcxo_freq=host.pll.setup()["vcxo_freq"]\n') #Read back the exact frequency (typically 245759996.9474969 Hz)
f.write('host.chip.ref_clk.set(rap0, vcxo_freq)\n') #Set the Rapinoe clock to vcxo_freq.

f.write('host.chip.ram.fill(rap0)\n') # Loads gain tables from file to RAM
f.write('host.chip.init(rap0, "CHIP")\n')
f.write('host.chip.init(rap0, "SYNTH")\n')
f.write('host.chip.init(rap0, "VALIDATION")\n')
f.write('host.chip.init(rap0, "ADC")\n')
f.write('host.chip.init(rap0, "TX", printit=False)\n')
f.write('host.chip.synth.setup(rap0)\n')
f.write('host.chip.synth.set(rap0,%e, frac_mode=True, sd_order=2, printit=True)\n' % (freq_rff))
f.write('host.chip.tx.setup(rap0, mode, tpol, ant_en_v=0xffff, ant_en_h=0xffff)\n')
f.write('host.chip.trx.mode(rap0,tpol)\n')

#register settings
f.write('vga_v = 51\n')
f.write('com_gain = 15\n')

f.write('host.chip.ram.wr(rap0, "tx_ram_v", 0, (vga_v<<6)+(com_gain))\n')
f.write('host.chip.ram.wr(rap0, "tx_ram_h", 0, (vga_v<<6)+(com_gain))\n')
f.write('host.chip.tx.gain_rf(rap0, 0, tpol)\n')
f.write('host.chip.tx.beam(rap0, 5, tpol)\n')

f.write('host.chip.tx.dco.calibrate(rap0, mode, "V")\n')
f.write('host.chip.tx.dco.calibrate(rap0, mode, "H")\n')

f.write('host.ctrl.set_mode(rap0,3)\n') #Enables external beam steering and gain ctrl

#Set control pins to input
f.write('for i in range(17,25):\n')
f.write('    host.gpio.dir_set(i,"I")\n')

#Write beamangles which are read by demo_gui.m
f.write('\ncwd = "%s"\n' % (os.getcwd().replace('\\','/')))
f.write('f = open("%s/tx_beams.txt" % (cwd),"w")\n')
f.write('best_beambook = host.chip.synth.loaded_beambook_id\n')
f.write('idx=host.chip.ram.rf._id_to_idx(best_beambook)\n')
f.write('rows = host.chip.ram.rf.tables[idx].findall("ROW")\n')
f.write('for row in rows:\n')
f.write('     f.write(row.find("AZIMUTH").text)\n')
f.write('\nf.close()\n')

f.close()