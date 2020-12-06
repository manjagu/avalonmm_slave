# avalonmm_slave
This demonstrates what I believe to be an error in the memory package of
VUnit 4.4.0. Notice that the 8-bit wide tests pass, but as the data bus
widths increase the tests fail. They don't seem to fail with the same
results either. It is best to look at these in GUI mode. 

My configuration:
VUnit 4.4.0
Python 3.8.5
Modelsim DE 2019.2