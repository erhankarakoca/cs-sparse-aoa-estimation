import host


def create_evk(serialNumber='T582300517', freq=27e9, TxRx=None):
    Host = host.Host(serial_num=serialNumber, indent=2)
    rap0 = Host.rap0
    mode = 'BB'
    Host.reset(rap0)
    Host.misc.on(['VCXO', 'PLL']);
    Host.pwr.on('ALL')
    vcxo_freq = Host.pll.setup()['vcxo_freq']
    Host.chip.ref_clk.set(rap0, vcxo_freq)
    Host.chip.ram.fill(rap0)
    Host.chip.init(rap0, 'CHIP')
    Host.chip.init(rap0, 'SYNTH')
    Host.chip.init(rap0, 'VALIDATION')
    Host.chip.init(rap0, 'ADC')

    if TxRx is None:  # Rx mode
        rpol = "rvrh"
        Host.chip.init(rap0, "RX", printit=False)
        Host.spi.wrrd(rap0, "capval_0", 4)
        Host.spi.wrrd(rap0, "capval_1", 4)
        Host.chip.synth.setup(rap0)
        Host.chip.synth.set(rap0, freq, frac_mode=True, sd_order=2, printit=True)
        Host.chip.rx.setup(rap0, mode, rpol, ant_en_v=0xffff, ant_en_h=0xffff)
        Host.chip.trx.mode(rap0, rpol)
        Host.chip.rx.beam(rap0, 5, rpol)
        lna_gain = 9
        bf_gain = 13
        com_gain = 14
        iq_pga1 = 4
        iq_filter = 1
        q_filter = 6
        q_pga2 = 3
        i_filter = 4
        i_pga2 = 2
        Host.chip.ram.wr(rap0, "rx_ram_v", 0,
                         (lna_gain << 61) + (bf_gain << 55) + (com_gain << 49) + (iq_pga1 << 46) + (iq_filter << 42) + (
                                 q_filter << 39) + (q_pga2 << 37) + (i_filter << 34) + (i_pga2 << 32))
        Host.chip.ram.wr(rap0, "rx_ram_h", 0,
                         (lna_gain << 61) + (bf_gain << 55) + (com_gain << 49) + (iq_pga1 << 46) + (iq_filter << 42) + (
                                 q_filter << 39) + (q_pga2 << 37) + (i_filter << 34) + (i_pga2 << 32))
        Host.chip.rx.gain(rap0, 0, rpol)
        Host.chip.rx.dco.calibrate(rap0, "V", 0)
        Host.chip.rx.dco.calibrate(rap0, "H", 0)
        Host.ctrl.set_mode(rap0, 3)
        for i in range(17, 25):
            Host.gpio.dir_set(i, "I")
    else:
        tpol = "tvth"
        Host.chip.init(rap0, "TX", printit=False)
        Host.chip.synth.setup(rap0)
        Host.chip.synth.set(rap0, freq, frac_mode=True, sd_order=2, printit=True)
        Host.chip.tx.setup(rap0, mode, tpol, ant_en_v=0xffff, ant_en_h=0xffff)
        Host.chip.trx.mode(rap0, tpol)
        vga_v = 51
        com_gain = 15
        Host.chip.ram.wr(rap0, "tx_ram_v", 0, (vga_v << 6) + (com_gain))
        Host.chip.ram.wr(rap0, "tx_ram_h", 0, (vga_v << 6) + (com_gain))
        Host.chip.tx.gain_rf(rap0, 0, tpol)
        Host.chip.tx.beam(rap0, 5, tpol)
        Host.chip.tx.dco.calibrate(rap0, mode, "V")
        Host.chip.tx.dco.calibrate(rap0, mode, "H")
        Host.ctrl.set_mode(rap0, 3)
        for i in range(17, 25):
            Host.gpio.dir_set(i, "I")

    return Host

def write_RAM_row(Host,row,table_type = 'ram',index = 0):
    data, mask = Host.chip.ram._fielddict2data(table_type, row)
    Host.chip.ram.wr(Host.rap0, table_type, index, data)
    return Host


