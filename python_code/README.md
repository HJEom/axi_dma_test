# trainNtest_291_attempts02.py :
# 		training SRCNN using SR_dataset/291/ data set.
#
# make_inputNdiffNparam.py : 
# 		make zcu104 input image data as 32-bit hex ( pixel1[31:24], pixel2[23:16], pixel3[15:8], pixel4[7:0])
# 		make diff image that is gonna be compare with zcu104 output image.
# 		make quantized parameter(MSB : sign bit, MSB-1 : int bit, MSB-2 to LSB : fraction bit)
#
# odata2img.py :
# 		make output hex data to image.
