from common import *
import evk_logger

class RapSPI:

    __instance = None

    def __init__(self, connection, register_map=None):
        self._connection = connection
        self.register_map = register_map
        self.reg_groups = {}
        for reg_name in sorted(self.register_map.regs):
            if self._group(reg_name) in self.reg_groups:
                self.reg_groups[self._group(reg_name)].append(reg_name)
            else:
                self.reg_groups[self._group(reg_name)]=[reg_name]

    def _set_chip_info(self, chip_info):
        self._chip_info = chip_info

    def _group(self, reg_name):
        return self.register_map.regs[reg_name]['group']

    def __addr_and_size(self, reg_name_or_addr, bsize=None):
        if isinstance(reg_name_or_addr,int):
            address = reg_name_or_addr
            if bsize is None:
                bsize = self._size(self._name(address))
        else:
            address = self._addr(reg_name_or_addr)
            if bsize is None:
                bsize = self._size(reg_name_or_addr)
        return address,bsize

    def _addr_and_size(self, reg_name_or_addr, bsize=None):
        if not isinstance(reg_name_or_addr,list):
            address,size = self.__addr_and_size(reg_name_or_addr, bsize)
        else:
            address = []
            size    = []
            for i,addr in enumerate(reg_name_or_addr):
                if bsize == None:
                    ad,si = self.__addr_and_size(addr, bsize)
                else:
                    ad,si = self.__addr_and_size(addr, bsize[i])
                address.append(ad)
                size.append(si)
        return address,size

    def _addr(self, reg_name):
        """Return decimal address for symbolic address"""
        return self.register_map.regs[reg_name]['addr']

    def _size(self, reg_name):
        """Return size of symbolic address"""
        return self.register_map.regs[reg_name]['length']

    def _name(self, addr):
        reg_name  = None
        for key,reg in self.register_map.regs.items():
            if (reg['addr'] <= addr) and (reg['addr']+reg['length'] > addr):
                reg_name  = key
        return reg_name

    def _fieldstr2data(self, address, fields_string):
        if isinstance(address,int):
            address = self._name(address)
        words=fields_string.split(',')
        data=0
        mask=2**(self._size(address)*8)-1
        for wd in words:
            field=wd.split('=')
            field[0]=field[0].strip()
            field[1]=field[1].strip()
            if not field[0] in self.register_map.reg_map[address]:
                print('Warning: field not valid. {} {}'.format(address,data))
            else:
                data+=int(field[1],0)<<self.register_map.reg_map[address][field[0]]['Lsb']
                mask-=(2**(self.register_map.reg_map[address][field[0]]['Msb']+1)-2**self.register_map.reg_map[address][field[0]]['Lsb'])
        return int(data),int(mask)

    def _fielddict2data(self,address,fields_dict):
        if isinstance(address,int):
            address = self._name(address)
        data=0
        mask=2**(self._size(address)*8)-1
        for field,val in fields_dict.items():
            if not field in self.register_map.reg_map[address]:
                print('Warning: field not valid. {} {}'.format(address,data))
            else:
                data+=val<<self.register_map.reg_map[address][field]['Lsb']
                mask-=(2**(self.register_map.reg_map[address][field]['Msb']+1)-2**self.register_map.reg_map[address][field]['Lsb'])
        return int(data),int(mask)


    def type(self, addr, field=None):
        if isinstance(addr,int):
            addr = self._name(addr)
        if isinstance(field,str):
            fields = field.split(',')
        elif isinstance(field,list):
            fields = field
        elif isinstance(field,set) or isinstance(field,tuple):
            fields = list(field)
        elif field is None:
            fields = self.register_map.reg_map[addr].keys()
        else:
            fields = []
        resp={}
        for field in fields:
            resp[field] = self.register_map.reg_map[addr][field]['Type']
        return resp

    @evk_logger.log_call
    def rd(self, devs, reg_name_or_addr, bsize=None):
        """Read new contents from devices <devs>, registers <reg_name_or_addr> and integer, list of integers or list with lists of integers.
           reg_name_or_addr can be symbolic register name or register address in any integer number format (hex, dec, bin, oct ...)
           devs:             rap0 or [rap0, rap1, ...]
           reg_name_or_addr: 'chip_id', 0x0000, ['chip_id', 'chip_num', ...]
           return value:     0x1234 or [0x1234, 0x5678, ...] or [[0x1234, 0x5678, ...], [0x4321, 0x8765, ...], ...]
           Example: rd(rap0, 'chip_id')
                    rd(rap0, ['chip_id', 'chip_num'])
                    rd([rap0, rap1], ['chip_id', 'chip_num'])
        """
        address, bsize = self._addr_and_size(reg_name_or_addr, bsize)
        if isinstance(devs,list):
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'list'
                address     = [address]
                bsize       = [bsize]
        else:
            devs = [devs]
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'int'
                address     = [address]
                bsize       = [bsize]

        resp = []
        for dev in devs:
            for i,addr in enumerate(address):
                send_data = dev.format_rci_read(addr)
                resp.append(intlist2int(self._connection.mb.spi_read(self._connection.board_id, dev.chip_select, send_data, bsize[i])))

        if return_type == 'int':
            return resp[0]
        else:
            return resp


    @evk_logger.log_call
    def wr(self, devs, reg_name_or_addr, data, bsize=None):
        """Write new contents to register 'addr' and return old contents
           as integer. Register name or address can be given as memory destination.
           Example: wr('chip_id',0x01020304)
                    wr(0x0160, 0x01020304)
        """
        address, bsize = self._addr_and_size(reg_name_or_addr, bsize)
        read_first     = False
        if isinstance(data,str):
            if not isinstance(address,list):
                data,mask  = self._fieldstr2data(reg_name_or_addr,data)
                read_first = True
            else:
                print("Error: Address must be a single address, when data is a string: {}".format(reg_name_or_addr))
        elif isinstance(data,dict):
            if not isinstance(address,list):
                data,mask = self._fielddict2data(reg_name_or_addr,data)
                read_first = True
            else:
                print("Error: Address must be a single address, when data is a dict: {}".format(reg_name_or_addr))

        if isinstance(data,int):
            data = [data]

        if isinstance(devs,list):
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'list'
                address     = [address]
                bsize       = [bsize]
        else:
            devs = [devs]
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'int'
                address     = [address]
                bsize       = [bsize]

        resp = []
        for dev in devs:
            for i,addr in enumerate(address):
                if read_first:
                    send_data = dev.format_rci_read(addr)
                    old_data = intlist2int(self._connection.mb.spi_read(self._connection.board_id, dev.chip_select, send_data, bsize[i]))
                    data[i]  = data[i] | mask & old_data
                send_data = dev.format_rci_write(addr, int2intlist(data[i],256,bsize[i]))
                resp.append(intlist2int(self._connection.mb.spi_read_write(self._connection.board_id, dev.chip_select, send_data)))

        if return_type == 'int':
            return resp[0]
        else:
            return resp


    @evk_logger.log_call
    def wrrd(self, devs, reg_name_or_addr, data, bsize=None, printit=True):
        """Write new contents to register at 'addr' and then read the same register.
           Returns a string looking like: '<old contents> -> <new contents>'.
           Example: wrrd('chip_id',0x01020304)
        """
        address, bsize = self._addr_and_size(reg_name_or_addr, bsize)
        read_first     = False
        if isinstance(data,str):
            if not isinstance(address,list):
                data,mask  = self._fieldstr2data(reg_name_or_addr,data)
                read_first = True
            else:
                print("Error: Address must be a single address, when data is a string: {}".format(reg_name_or_addr))
        elif isinstance(data,dict):
            if not isinstance(address,list):
                data,mask = self._fielddict2data(reg_name_or_addr,data)
                read_first = True
            else:
                print("Error: Address must be a single address, when data is a dict: {}".format(reg_name_or_addr))

        if isinstance(data,int):
            data = [data]

        if isinstance(devs,list):
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'list'
                address     = [address]
                bsize       = [bsize]
        else:
            devs = [devs]
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'int'
                address     = [address]
                bsize       = [bsize]

        resp = []
        for dev in devs:
            for i,addr in enumerate(address):
                if read_first:
                    send_data = dev.format_rci_read(addr)
                    old_data = intlist2int(self._connection.mb.spi_read(self._connection.board_id, dev.chip_select, send_data, bsize[i]))
                    data[i]  = data[i] | mask & old_data
                send_data = dev.format_rci_write(addr, int2intlist(data[i],256,bsize[i]))
                previous_value = intlist2int(self._connection.mb.spi_read_write(self._connection.board_id, dev.chip_select, send_data))
                send_data = dev.format_rci_read(addr)
                updated_value  = intlist2int(self._connection.mb.spi_read(self._connection.board_id, dev.chip_select, send_data, bsize[i]))
                if printit:
                    resp.append(fhex(previous_value, 2 * bsize[i]) + " -> " + fhex(updated_value, 2 * bsize[i]))
                else:
                    resp.append([previous_value, updated_value])

        if return_type == 'int':
            return resp[0]
        else:
            return resp


    @evk_logger.log_call
    def tgl(self, devs, reg_name_or_addr, data, bsize=None):
        """Write new contents to register 'addr' and return old contents
           as integer. Register name or address can be given as memory destination.
           Example: wr('chip_id',0x01020304)
                    wr(0x0160, 0x01020304)
        """
        address, bsize = self._addr_and_size(reg_name_or_addr, bsize)
        if isinstance(data,str):
            if not isinstance(address,list):
                data,mask  = self._fieldstr2data(reg_name_or_addr,data)
            else:
                print("Error: Address must be a single address, when data is a string: {}".format(reg_name_or_addr))
        elif isinstance(data,dict):
            if not isinstance(address,list):
                data,mask = self._fielddict2data(reg_name_or_addr,data)
            else:
                print("Error: Address must be a single address, when data is a dict: {}".format(reg_name_or_addr))

        if isinstance(data,int):
            data = [data]

        if isinstance(devs,list):
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'list'
                address     = [address]
                bsize       = [bsize]
        else:
            devs = [devs]
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'int'
                address     = [address]
                bsize       = [bsize]

        resp = []
        for dev in devs:
            for i,addr in enumerate(address):
                if 'Issue#87' in self._chip_info.get(dev)['workaround']:
                    send_data = dev.format_rci_read(addr)
                    read_data = intlist2int(self._connection.mb.spi_read(self._connection.board_id, dev.chip_select, send_data, bsize[i]))
                    data[i]   = data[i] ^ read_data
                    send_data = dev.format_rci_write(addr, int2intlist(data[i],256,bsize[i]))
                else:
                    send_data = dev.format_rci_tgl(addr, int2intlist(data[i],256,bsize[i]))
                resp.append(intlist2int(self._connection.mb.spi_read_write(self._connection.board_id, dev.chip_select, send_data)))

        if return_type == 'int':
            return resp[0]
        else:
            return resp


    @evk_logger.log_call
    def clr(self, devs, reg_name_or_addr, data, bsize=None):
        """Write new contents to register 'addr' and return old contents
           as integer. Register name or address can be given as memory destination.
           Example: wr('chip_id',0x01020304)
                    wr(0x0160, 0x01020304)
        """
        address, bsize = self._addr_and_size(reg_name_or_addr, bsize)
        if isinstance(data,str):
            if not isinstance(address,list):
                data,mask  = self._fieldstr2data(reg_name_or_addr,data)
            else:
                print("Error: Address must be a single address, when data is a string: {}".format(reg_name_or_addr))
        elif isinstance(data,dict):
            if not isinstance(address,list):
                data,mask = self._fielddict2data(reg_name_or_addr,data)
            else:
                print("Error: Address must be a single address, when data is a dict: {}".format(reg_name_or_addr))

        if isinstance(data,int):
            data = [data]

        if isinstance(devs,list):
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'list'
                address     = [address]
                bsize       = [bsize]
        else:
            devs = [devs]
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'int'
                address     = [address]
                bsize       = [bsize]

        resp = []
        for dev in devs:
            for i,addr in enumerate(address):
                if 'Issue#87' in self._chip_info.get(dev)['workaround']:
                    send_data = dev.format_rci_read(addr)
                    read_data = intlist2int(self._connection.mb.spi_read(self._connection.board_id, dev.chip_select, send_data, bsize[i]))
                    data[i]   = ~data[i] & read_data
                    send_data = dev.format_rci_write(addr, int2intlist(data[i],256,bsize[i]))
                else:
                    send_data = dev.format_rci_clr(addr, int2intlist(data[i],256,bsize[i]))
                resp.append(intlist2int(self._connection.mb.spi_read_write(self._connection.board_id, dev.chip_select, send_data)))

        if return_type == 'int':
            return resp[0]
        else:
            return resp


    @evk_logger.log_call
    def set(self, devs, reg_name_or_addr, data, bsize=None):
        """Write new contents to register 'addr' and return old contents
           as integer. Register name or address can be given as memory destination.
           Example: wr('chip_id',0x01020304)
                    wr(0x0160, 0x01020304)
        """
        address, bsize = self._addr_and_size(reg_name_or_addr, bsize)
        if isinstance(data,str):
            if not isinstance(address,list):
                data,mask  = self._fieldstr2data(reg_name_or_addr,data)
            else:
                print("Error: Address must be a single address, when data is a string: {}".format(reg_name_or_addr))
        elif isinstance(data,dict):
            if not isinstance(address,list):
                data,mask = self._fielddict2data(reg_name_or_addr,data)
            else:
                print("Error: Address must be a single address, when data is a dict: {}".format(reg_name_or_addr))

        if isinstance(data,int):
            data = [data]

        if isinstance(devs,list):
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'list'
                address     = [address]
                bsize       = [bsize]
        else:
            devs = [devs]
            if isinstance(address,list):
                return_type = 'list'
            else:
                return_type = 'int'
                address     = [address]
                bsize       = [bsize]

        resp = []
        for dev in devs:
            for i,addr in enumerate(address):
                if 'Issue#87' in self._chip_info.get(dev)['workaround']:
                    send_data = dev.format_rci_read(addr)
                    read_data = intlist2int(self._connection.mb.spi_read(self._connection.board_id, dev.chip_select, send_data, bsize[i]))
                    data[i]   = data[i] | read_data
                    send_data = dev.format_rci_write(addr, int2intlist(data[i],256,bsize[i]))
                else:
                    send_data = dev.format_rci_set(addr, int2intlist(data[i],256,bsize[i]))
                resp.append(intlist2int(self._connection.mb.spi_read_write(self._connection.board_id, dev.chip_select, send_data)))

        if return_type == 'int':
            return resp[0]
        else:
            return resp


    @evk_logger.log_call
    def dump(self, devs, group=None):
        """List all available registers and their contents"""
        res = {}
        if not isinstance(devs, list):
            devs = [devs]
        if group == None:
            groups = self.reg_groups
        else:
            groups={}
        if  not isinstance(group, list):
            group = [group]
        for grp in group:
            if isinstance(grp,str):
                grp = grp.upper()
                if grp in self.reg_groups:
                    groups[grp] = self.reg_groups[grp]
                else:
                    print ("Group '{:}' does not exist!".format(grp))
                    return
        print ('{:^29}|'.format('Device'),end='')
        for dev in devs:
            print ('{:^36}|'.format('rap{:}'.format(dev.chip_num)),end='')
        print('')
        print ('{:^29}|'.format(29*'='),end='')
        for dev in devs:
            print ('{:^36}|'.format(36*'='),end='')
        print('')
        for group_name in sorted(groups):
            print ('{:<29}|'.format(group_name),end='')
            for dev in devs:
                print ('{:^36}|'.format(36*' '),end='')
            print('')
            regs = groups[group_name]
            for reg_name in sorted(regs):
                data = self.rd(devs, reg_name)
                width = 2 * self._size(reg_name)                
                print ('  {:<27}|'.format(reg_name),end='')
                for item in data:
                    print (' {:>34} |'.format('0x{:0{}X}'.format(item, width)),end='')
                print('')
