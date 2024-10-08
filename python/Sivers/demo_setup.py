print ('TX script ...')

#host.reset(rap0)
host.misc.on(['VCXO', 'PLL'])
host.pwr.on('ALL')
freq_rff = 26e9
host.chip.init(rap0, 'CHIP')
host.chip.init(rap0, 'SYNTH')
host.chip.init(rap0, 'VALIDATION')
host.chip.init(rap0, 'ADC')
host.chip.synth.setup(rap0)
host.chip.synth.set(rap0,freq_rff, frac_mode=True, sd_order=2)
host.chip.init(rap0, 'TX', printit=False)

# FOR RX
host.spi.wrrd(rap0, 'com_bias_trim', 0x666666666) # txvga txpa txmix rxvga rxmix lo_in lo_mid lo_out_tx lo_out_rx
host.spi.wrrd(rap0, 'bb_rx_config_v', 0b110000000) #bbrx_enable_bias_top_v, ptat_en_v (only for BB use?)
host.spi.wrrd(rap0, 'ssw_cfg_on_en_rx_v', 0b1100000000) #com_en_rx_v,bbrx_if_en_v
host.spi.wrrd(rap0, 'ssw_cfg_on_sel_rx', 0b1110000)

# FOR TX
host.spi.wrrd(rap0, 'ssw_cfg_on_sel_tx', 0b1110000)  #v and h pol active


host.chip.tx.setup(rap0, 'BB', 'tv', ant_en_v=0x0001, ant_en_h=0x0000)
#host.chip.rx.setup(rap0, 'IF', 'rv', ant_en_v=0x0001, ant_en_h=0x0000)
#host.spi.wrrd(rap0, 'capval_0',0b101) #bandwidth bbrx-chain
#host.spi.wrrd(rap0, 'bb_rx_en_dco',  0b11110000)
#host.chip.adc.enable(rap0)
host.chip.rx.dco.calibrate(rap0, 'V', 0)


import tx_dco
host.chip.tx.bb_dco = tx_dco.TxDco(host.chip, 'BB')
host.chip.tx.bb_dco.sweep(rap0, 'V', step=10)


##################################################################################
##  LOOPBACK SCRIPT FROM KRISTOFFER
#from host import Host
#from common import *

#host = Host(serial_num='SNSP200168', bsp='rapvalbsp')
#raps = evk.Rapinoe()
#rap0 = raps._conn.mb.bsp.rap0
#rap0=host.rap0
from typing import ForwardRef


host.reset(rap0)
print(type(host))

fhex(host.spi.rd(rap0, 'chip_id'), 8)

# Enable bias bist for avdd1v2 and vdd2v5
host.spi.wrrd(rap0, 'bist_config', 1)

#host.chip.synth.adc.init(rap0)
#host.chip.synth.adc.enable(rap0)
#host.chip.synth.adc.dump(rap0)


def sm_status():
    print("dig_tune:    ", fhex(host.spi.rd(rap0, 'vco_digtune_read'), 2))
    print("ibias:       ", fhex(host.spi.rd(rap0, 'vco_ibias_read'), 2))
    print("lock status: ", fhex(host.spi.rd(rap0, 'sm_config_status'), 2))
    print("lock status: ", fhex(host.spi.rd(rap0, 'sm_config_status'), 2))


freq_rf = 25e9
freq=freq_rf/3
ref_freq=245.76e6
n=round(freq/ref_freq)
print('Frequency = {:.0f} Hz'.format(3*ref_freq*n))

host.spi.wrrd(rap0, 'biastop_en', 0b111110)
host.spi.wrrd(rap0, 'vco_en', 0b01010100)  # vtune set disabled
host.spi.wrrd(rap0, 'vco_digtune_ibias_override', 0)
host.spi.wrrd(rap0, 'pll_ref_sel', 1)
host.spi.wrrd(rap0, 'pll_config', 0x02)
host.spi.wrrd(rap0, 'pll_ld_config', 0x10)
host.spi.wrrd(rap0, 'pll_en', (1 << 7)+(1 << 6)+(1 << 5)+(1 << 4)+(1 << 1)+1)
host.spi.wrrd(rap0, 'sm_clk_config', 25+(200 << 8)+(246 << 24)+(25 << 32))
host.spi.wrrd(rap0, 'sm_dac', 163)

host.spi.wrrd(rap0, 'sm_dac_cal', 8)
host.spi.wrrd(rap0, 'sm_en', 3)
host.spi.wrrd(rap0, 'sd_n', n)


# Trigger SM to lock PLL
host.spi.wrrd(rap0, 'sm_sd_fsm_ctrl', 0)
host.spi.wrrd(rap0, 'sm_sd_fsm_ctrl', 1)
# Print status
sm_status()

#Enabeling tx 

#host.spi.wrrd(rap0, 'bb_tx_config_h', 0b11011001111)# enable of:filter,if, ptat, q2,i2 ,qq,qi, iq,ii,cm_q, cm_i
host.spi.wrrd(rap0, 'bb_tx_config_v', 0b11011001111)# enable of:filter,if, ptat, q2,i2 ,qq,qi, iq,ii,cm_q, cm_i
host.spi.wrrd(rap0, 'com_misc', 0b000010)  # biasref_common active  NOT NEEDED
host.spi.wrrd(rap0, 'com_bias_trim', 0x666666666) # txvga txpa txmix rxvga rxmix lo_in lo_mid lo_out_tx lo_out_rx
#Enabeling rx
host.spi.wrrd(rap0, 'bb_rx_config_v', 0b110000000) #bbrx_enable_bias_top_v, ptat_en_v (only for BB use?)
host.spi.wrrd(rap0, 'ssw_cfg_on_en_rx_v', 0b1100000000) #com_en_rx_v,bbrx_if_en_v
host.spi.wrrd(rap0, 'ssw_cfg_on_sel_rx', 0b1110000)
# x3 and pll_biasref bias setting =6
host.spi.wrrd(rap0, 'vco_pll_bias_trim', 0x66)
host.spi.wrrd(rap0, 'en_vcc_high', 0b1111111)   # bbtc_vcm_v, bbt_vcm_h, bf_en_vcc_high,com_enable_vcc_high,bbtx_vcc_high_v, bbtx_vcc_high_h
# vga pa mix rxvga rxmix loin lomid loouttx loooutrx
host.spi.wrrd(rap0, 'bf_tx_biasref_trim', 0x661) # pa vga vpa vpa reduced in current according to sim
host.spi.wrrd(rap0, 'bf_biasref_en', 0b0110011)  # all bf bias enable
host.spi.wrrd(rap0, 'ssw_cfg_on_sel_tx', 0b1110000)  #v and h pol active
host.spi.wrrd(rap0, 'ssw_cfg_on_en_tx', 0b110000)    # bb and rf active
host.spi.wrrd(rap0, 'ssw_cfg_on_bf_en_tx_v', 0b0000000100000001)  # v-pol v0 aktive
host.spi.wrrd(rap0, 'bb_tx_ctune', 0x44)  #tuned to if opt according to sim 3 chosen in v to push self osc away vh
  #tuned to if opt according to sim 3 chosen in v to push self osc away vh
host.spi.wrrd(rap0, 'bb_tx_gain', 0x0000)  # v-plo, h-pol almost max gain in bbh
host.spi.wrrd(rap0, 'bb_tx_dco_bb_v', 0x8080)  #midvalues
host.spi.wrrd(rap0, 'bb_tx_dco_v', 0x4000300)  #optimish for ctune =3
host.spi.wrrd(rap0, 'tx_ram_v', 0x3fff)
host.spi.wrrd(rap0, 'rx_ram_v', 0x19ffe000000000000)
host.spi.wrrd(rap0, 'ram', (0x8100<<0)+(0x8100<<256))  #phaseshifter
command = 0

host.spi.wrrd(rap0,'trx_control_reg',0+(14<<8)+(1<<12)+(0<<13))  # beam index 0, w sync
host.spi.wrrd(rap0,'trx_control_reg',3+(14<<8)+(1<<12)+(3<<13))  # mode TX, w sync
host.spi.wrrd(rap0,'trx_control_reg',0+(10<<8)+(1<<12)+(1<<13))  # gain index 0 Tx V-pol  w sync

host.spi.wrrd(rap0,'trx_control_reg',0+(2<<8)+(1<<12)+(1<<13))  # gain index 0 Rx V-pol  w sync



#host.chip.synth.adc.init(rap0)
#host.chip.synth.adc.enable(rap0)
#host.chip.synth.adc.dump(rap0)