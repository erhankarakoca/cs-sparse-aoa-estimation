
import os

f = open('freq.txt')
freq_rff = float(f.readline())
f.close()

f = open('rx_config.txt','w')

f.write('mode   = "BB"\n')
f.write('rpol   = "rvrh"\n')
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
f.write('host.chip.init(rap0, "RX", printit=False)\n')
f.write('host.spi.wrrd(rap0,"capval_0",4)\n')
f.write('host.spi.wrrd(rap0,"capval_1",4)\n')
f.write('host.chip.synth.setup(rap0)\n')
f.write('host.chip.synth.set(rap0,%e, frac_mode=True, sd_order=2, printit=True)\n' % (freq_rff))
f.write('host.chip.rx.setup(rap0, mode, rpol, ant_en_v=0xffff, ant_en_h=0xffff)\n')
f.write('host.chip.trx.mode(rap0,rpol)\n')
f.write('host.chip.rx.beam(rap0, 5, rpol)\n')
    
#register settings, only applied if AGC not used
    
f.write('lna_gain = 9\n')
    
f.write('bf_gain = 13\n')
  
f.write('com_gain = 14\n')
    
f.write('iq_pga1 = 4\n')
    
f.write('iq_filter = 1\n')
   
f.write('q_filter = 6\n')
    
f.write('q_pga2 = 3\n')
    
f.write('i_filter = 4\n')
    
f.write('i_pga2 = 2\n')
    
    
    
f.write('host.chip.ram.wr(rap0, "rx_ram_v", 0, (lna_gain<<61)+(bf_gain<<55)+(com_gain<<49)+(iq_pga1<<46)+(iq_filter<<42)+(q_filter<<39)+(q_pga2<<37)+(i_filter<<34)+(i_pga2<<32))\n')
f.write('host.chip.ram.wr(rap0, "rx_ram_h", 0, (lna_gain<<61)+(bf_gain<<55)+(com_gain<<49)+(iq_pga1<<46)+(iq_filter<<42)+(q_filter<<39)+(q_pga2<<37)+(i_filter<<34)+(i_pga2<<32))\n')
    
    
    
f.write('host.chip.rx.gain(rap0, 0, rpol)\n')
    
f.write('host.chip.rx.dco.calibrate(rap0, "V", 0)\n')
f.write('host.chip.rx.dco.calibrate(rap0, "H", 0)\n')
    
f.write('host.ctrl.set_mode(rap0,3)\n') #Enables external beam steering and gain ctrl
    
#Set control pins to inputs
f.write('for i in range(17,25):\n')
f.write('    host.gpio.dir_set(i,"I")\n')
    
#Write beamangles which are read in demo_gui.m
f.write('\ncwd = "%s"\n' % (os.getcwd().replace('\\','/')))
f.write('f = open("%s/rx_beams.txt" % (cwd),"w")\n')
f.write('best_beambook = host.chip.synth.loaded_beambook_id\n')
f.write('idx=host.chip.ram.rf._id_to_idx(best_beambook)\n')
f.write('rows = host.chip.ram.rf.tables[idx].findall("ROW")\n')
f.write('for row in rows:\n')
f.write('     f.write(row.find("AZIMUTH").text)\n')
f.write('\nf.close()\n')

f.close()
