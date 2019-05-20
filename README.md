# axi_dma_test

# DMA register map
# https://www.xilinx.com/support/documentation/ip_documentation/axi_dma/v7_1/pg021_axi_dma.pdf

# axi protocol
# http://www.gstitt.ece.ufl.edu/courses/fall15/eel4720_5721/labs/refs/AXI4_specification.pdf 

# example01.c : DMA S.G mode read write.
# example02.c : DMA interrupt mode read write.

------------------------------------------------------

# dma.c
# 40 byte --> mm2s status = 00001001(halted, IOC_irq)
# 96 byte --> log02.txt : from 14 to 23
# 44 byte --> log03.txt : from 1 to 10
# 44 byte --> log04.txt : from 1 to 10
axi master : it may use bready on write channel.
