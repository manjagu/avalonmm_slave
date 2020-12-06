import os
from os.path import join, dirname
from vunit import VUnit
from itertools import product

# Set the source path for MODELSIM. Modelsim will read it when it executes
# modelsim.ini
os.environ['SRC'] = os.getcwd()

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()
vu.add_osvvm()
vu.add_verification_components()

# Create the source paths for our libaries
quartusInstallDir = "C:/intelFpga_pro/19.3/quartus/"
quartusPath = "eda/sim_lib"
quartusLibRoot  = join(quartusInstallDir, quartusPath)
tb_path =  join(dirname(__file__), ".")

# Create and add files to the testbench library
tb_lib = vu.add_library("tb_lib")
tb_lib.add_source_files(join(tb_path, "*.vhd"))

def encode(tb_cfg):
    return ",".join(["%s:%s" % (key, str(tb_cfg[key])) for key in tb_cfg])

def gen_avalon_tests(obj, *args):
    for data_width, burst_count, cycles, readdatavalid_prob, waitrequest_prob in product(*args):
        tb_cfg = dict(
            data_width = data_width,
            burst_count = burst_count,
            cycles = cycles,
            readdatavalid_prob=readdatavalid_prob,
            waitrequest_prob=waitrequest_prob
        )
        config_name = encode(tb_cfg)
        obj.add_config(name=config_name, generics=dict(encoded_tb_cfg=encode(tb_cfg)))
   
  
tb_avalon_slave = tb_lib.test_bench("tb_avalonmm_slave")

# I recommend trying different data_widths. I get different results with different widths.
# WARNING: Make sure your data bus width is a power of 2!  
for test in tb_avalon_slave.get_tests():
    gen_avalon_tests(test, [8, 16, 128], [16], [1, 2, 3], [1.0], [0.0])

vu.set_sim_option('modelsim.init_files.after_load',[join(tb_path, "wave.do")])

# Run vunit function
vu.main()
