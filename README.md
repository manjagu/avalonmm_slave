# avalonmm_slave
This demonstrates what I believe to be an error in the memory package of
VUnit 4.4.0. Notice that the 8-bit wide tests pass, but as the data bus
widths increase the tests fail. They don't seem to fail in the same
location either. It is best to look at these in GUI mode after an initial
run on the command line. The tests are controlled through compsite 
generics in and through run.py.

My configuration:
VUnit 4.4.0
Python 3.8.5
Modelsim DE 2019.2
