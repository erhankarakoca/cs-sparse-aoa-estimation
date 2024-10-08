import adc
import amux
import chip_info
import ctrl
import evk_logger
import init
import i2c
import ram
import rapspi
import rcu
import ref_clk
import register
import synth
import temp
import block.rx as rx
import block.tx as tx
import trx
import rx_dco
import tx_dco
import evk_logger
from common import *

class Chip():
    __instance = None

    def __new__(cls, conn, fref, indent=None):
        if cls.__instance is None:
            cls.__instance = super(Chip, cls).__new__(cls)
            cls.__instance.__initialized = False
        return cls.__instance

    def __init__(self, conn, fref, indent=None):
        if self.__initialized != True:
            if indent is None:
                self.indent = evk_logger.evk_logger._indent
            else:
                self.indent = indent
            self._reg_map   = register.Register()
            self._conn      = conn
            self.spi        = rapspi.RapSPI(self._conn, self._reg_map)
            self.ctrl       = ctrl.Ctrl(self._conn, self.spi)
            self._chip_info = chip_info.Chip_info(self.spi,indent=self.indent+2)
            self.spi._set_chip_info(self._chip_info)
            num_devs        = self._chip_info.get_num_devs()
            if num_devs == 0:
                evk_logger.evk_logger.log_info('Expecting 0 devices.',self.indent)
            elif num_devs == 1:
                evk_logger.evk_logger.log_info('Expecting {} device. Trying to connect to it ...'.format(num_devs),self.indent)
            else:
                evk_logger.evk_logger.log_info('Expecting {} devices. Trying to connect to them ...'.format(num_devs),self.indent)
            self._init      = init.Init(self.spi)
            self.amux       = amux.Amux(self.spi)
            self.adc        = adc.Adc(self.spi)
            self.i2c        = i2c.I2c(self.spi, self._chip_info)
            self.ram        = ram.Ram(self.spi)
            self.rcu        = rcu.Rcu(self.spi)
            self.ref_clk    = ref_clk.Ref_clk(self.spi, fref)
            self.synth      = synth.Synth(self.spi, self.ram, fref)
            self.temp       = temp.Temp(self.spi)
            self.rx         = rx.Rx(self.spi, self.ram)
            self.rx.dco     = rx_dco.RxDco(self.rx, self.ram, self.adc)
            self.tx         = tx.Tx(self.spi, self.ram)
            self.tx.dco     = tx_dco.TxDco(self)
            self.trx        = trx.Trx(self.spi)
            self.__initialized = True


    @evk_logger.log_call
    def init(self, devs, grps=['CHIP','EN VCC HIGH w OVR'], printit=False):
        """Initialise registers.
        Init values are defined in the file init.py.
        Each set of init values can be grouped depending on use case, e.g
        only init values for the group 'SYNTH'.
        The default group 'CHIP' must always exist.
        Examples:
        # Init chip rap0 with values from group 'CHIP'
        init(rap0)
        # Init chip rap0 with values from groups ADC and EFC
        init(rap0, ['ADC', 'EFC'])
        # Init chip rap0 with values from group 'MY GROUP' given on command line
        init(rap0, {'MY GROUP': {'bist_config': {'cmd': 'WR', 'data' : 0x20}}})
        # Init chips rap0 and rap1 with values from group 'CHIP'
        init([rap0, rap1],'CHIP')
        """
        if grps is not None:
            return self._init.set(devs, grps, printit)

    @evk_logger.log_call
    def init_get(self, devs, grps=None, printit=False):
        return self._init.get(devs, grps, printit)

    @evk_logger.log_call
    def init_get_grps(self, devs, printit=False):
        return self._init.get_grps(devs, printit)


    @evk_logger.log_call
    def info(self, devs, printit=False):
        return self._chip_info.get(devs, printit)
            
