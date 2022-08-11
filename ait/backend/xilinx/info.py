import os

NAME = 'xilinx'

MIN_VITIS_HLS_VERSION = '2020.2'
MIN_VIVADO_HLS_VERSION = '2018.3'
MIN_VIVADO_VERSION = '2018.3'


def get_supported_boards():
    return sorted(next(os.walk(os.path.dirname(__file__) + '/board'))[1])


def get_available_hwruntimes():
    return sorted(next(os.walk(os.path.dirname(__file__) + '/IPs/hwruntime/'))[1])


info = dict()
info['boards'] = get_supported_boards()
info['hwruntimes'] = get_available_hwruntimes()
info['def_hwr'] = 'fom'
info['steps'] = ['HLS', 'design', 'synthesis', 'implementation', 'bitstream', 'boot']
info['initial_step'] = 'HLS'
info['final_step'] = 'bitstream'
