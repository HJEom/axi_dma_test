import numpy as np
import cv2 as cv
import string

def twocomp(hexstr, bits):
	value = int(hexstr, 16)
	if value & (1 << (bits-1)):
		value -= 1<<bits
	return value

f = open("../test_file/o_low_img.txt","r")

lines = f.read().splitlines()

tmp = np.asarray(lines)

tmp = tmp.reshape(12,48,4)

print(tmp)
print(tmp.shape)

o_img = np.empty((48,48,1), dtype=np.uint8)

for h in range(12):
	for w in range(48):
		for h_p in range(4):
			o_img[h_p+h*4][w][0] = tmp[h][w][h_p]

#for h in range(48):
#	for w in range(48):
#		tmp.append(str('0x')+str(lines[w+h*48]))

#for h in range(48):
#	for w in range(48):
#		o_img[h][w] = twocomp(tmp[w+h*48],8)


cv.imwrite('../test_file/o_low_img.jpg', o_img)
