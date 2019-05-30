import numpy as np
import cv2 as cv
import string

def twocomp(hexstr, bits):
	value = int(hexstr, 16)
	if value & (1 << (bits-1)):
		value -= 1<<bits
	return value

f = open("../test_file/odata.txt","r")

lines = f.read().splitlines()

o_img = np.empty((48,48,1))
tmp = []

for h in range(48):
	for w in range(48):
		tmp.append(str('0x')+str(lines[w+h*48]))

for h in range(48):
	for w in range(48):
		o_img[h][w] = twocomp(tmp[w+h*48],8)

o_img = o_img.reshape(48,48,1).astype(np.uint8)
print(o_img[0][0][0])

cv.imwrite('../test_file/odata_image.jpg', o_img)
