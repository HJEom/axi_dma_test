# axi_dma_test

# DMA register map
# https://www.xilinx.com/support/documentation/ip_documentation/axi_dma/v7_1/pg021_axi_dma.pdf

# example01.c : DMA S.G mode read write.
# example02.c : DMA interrupt mode read write.

------------------------------------------------------

# dma.c
# 40 byte --> mm2s status = 00001001(halted, IOC_irq)
# 44 byte --> log03.txt : from 1 to 10
# 96 byte --> log02.txt : from 14 to 23
