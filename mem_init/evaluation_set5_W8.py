import tensorflow as tf
import numpy as np
import cv2   # (h, w, c) , cv2.imread fcn stores image in (h, w, BGR) by default.
import sys
import os

try:
    os.path.exists(sys.argv[1])
except:
    print("usage : $1 /<dataset>/<directory>/<path>/SR_dataset/Set5/")
    print("usage : $2 /<parameter>/<path>/params/")
    sys.exit(1)

test_img_path = sys.argv[1]
params_path = sys.argv[2]

def var_init(name_, shape_):
    return tf.get_variable(name_, shape=shape_, initializer=tf.contrib.layers.xavier_initializer_conv2d())

def conv2d(in_, w_, b_):
    return tf.nn.conv2d(in_,w_,strides=[1,1,1,1], padding='SAME') + b_


#################################### to save tested images.
if os.path.isdir(params_path + "/../tested_images") == False:
    os.makedirs(params_path +  "/../tested_images")
tested_image_path = params_path +  "/../tested_images/"

def get_all_dataset(image_path, image_list):
    high_images = np.empty(len(image_list), dtype=object)
    low_images = np.empty(len(image_list), dtype=object)
    print("\ngetting all dataset for train and test...")
    for i in range(len(image_list)):
        image = cv2.imread(image_path+'/'+image_list[i])
        high_images[i] = tf.reshape(tf.image.rgb_to_grayscale(image),[image.shape[0],image.shape[1],1])
        low_images[i] = tf.image.resize_images(tf.image.resize_images(tf.reshape(tf.image.rgb_to_grayscale(image),[image.shape[0],image.shape[1],1]), (int(image.shape[0]/2),int(image.shape[1]/2)), method=tf.image.ResizeMethod.BICUBIC), (image.shape[0],image.shape[1]), method=tf.image.ResizeMethod.BICUBIC)
    return high_images, low_images

def standardization(images):
    img_avr = np.mean(images, axis=(0,1,2), keepdims=True)
    img_var = np.var(images, axis=(0,1,2), keepdims=True)
    images = (images-img_avr)/img_var
    return images, img_avr, img_var

sess = tf.Session()
saver = tf.train.import_meta_graph(params_path+'./train.ckpt.meta')
saver.restore(sess, tf.train.latest_checkpoint(params_path))

graph = tf.get_default_graph()
#################################### print tensor_name
#for i in graph.get_operations():
#    print(i.name)

#################################### print variables
w1 = graph.get_tensor_by_name("w1:0")
w2 = graph.get_tensor_by_name("w2:0")
w3 = graph.get_tensor_by_name("w3:0")
b1 = graph.get_tensor_by_name("b1:0")
b2 = graph.get_tensor_by_name("b2:0")
b3 = graph.get_tensor_by_name("b3:0")
#print("tensor shape : ", w3.get_shape())
w1_flt, w2_flt, w3_flt, b1_flt, b2_flt, b3_flt = sess.run([w1,w2,w3,b1,b2,b3])

w1_fx = np.empty((w1_flt.shape[0],w1_flt.shape[1],w1_flt.shape[2],w1_flt.shape[3]))
w2_fx = np.empty((w2_flt.shape[0],w2_flt.shape[1],w2_flt.shape[2],w2_flt.shape[3]))
w3_fx = np.empty((w3_flt.shape[0],w3_flt.shape[1],w3_flt.shape[2],w3_flt.shape[3]))
b1_fx = np.empty((b1_flt.shape[0]))
b2_fx = np.empty((b2_flt.shape[0]))
b3_fx = np.empty((b3_flt.shape[0]))

for i in range(w1_flt.shape[0]):
    for ii in range(w1_flt.shape[1]):
        for iii in range(w1_flt.shape[2]):
            for iiii in range(w1_flt.shape[3]):
                w1_fx[i][ii][iii][iiii] = np.around(w1_flt[i][ii][iii][iiii]*64)/64

for i in range(w2_flt.shape[0]):
    for ii in range(w2_flt.shape[1]):
        for iii in range(w2_flt.shape[2]):
            for iiii in range(w2_flt.shape[3]):
                w2_fx[i][ii][iii][iiii] = np.around(w2_flt[i][ii][iii][iiii]*64)/64

for i in range(w3_flt.shape[0]):
    for ii in range(w3_flt.shape[1]):
        for iii in range(w3_flt.shape[2]):
            for iiii in range(w3_flt.shape[3]):
                w3_fx[i][ii][iii][iiii] = np.around(w3_flt[i][ii][iii][iiii]*64)/64

for i in range(b1_flt.shape[0]):
    b1_fx[i] = np.around(b1_flt[i]*64)/64

for i in range(b2_flt.shape[0]):
    b2_fx[i] = np.around(b2_flt[i]*64)/64

for i in range(b3_flt.shape[0]):
    b3_fx[i] = np.around(b3_flt[i]*64)/64

#w1 = var_init("w1",[3,3,1,64])
#b1 = var_init("b1",[64])
#w2 = var_init("w2",[3,3,64,64])
#b2 = var_init("b2",[64])
#w3 = var_init("w3",[3,3,64,1])
#b3 = var_init("b3",[1])

#################################### for forward
in_img_f = graph.get_tensor_by_name("in_img_f:0")
label_img_f = graph.get_tensor_by_name("label_img_f:0")

#################################### for psnr
out_img_uint8 = graph.get_tensor_by_name("out_img_uint8:0")
label_img_uint8 = graph.get_tensor_by_name("label_img_uint8:0")

layer1_out_flt = tf.nn.relu(conv2d(in_img_f,w1_flt,b1_flt))
layer2_out_flt = tf.nn.relu(conv2d(layer1_out_flt,w2_flt,b2_flt))
layer3_out_flt = conv2d(layer2_out_flt,w3_flt,b3_flt)

layer1_out_fx = tf.nn.relu(conv2d(in_img_f,w1_fx,b1_fx))
layer2_out_fx = tf.nn.relu(conv2d(layer1_out_fx,w2_fx,b2_fx))
layer3_out_fx = conv2d(layer2_out_fx,w3_fx,b3_fx)

#################################### results
#layer3_out = graph.get_tensor_by_name("layer3_out/add:0")

#################################### psnr
psnr = graph.get_tensor_by_name("psnr/Mean:0")

#################################### fetch dataset for test
test_img_list = os.listdir(test_img_path)

with tf.device('/cpu:0'):
    
    #sess.run(tf.global_variables_initializer())

    high_img, low_img = get_all_dataset(test_img_path, test_img_list)
    print("convert tensor to numpy array...")
    for number_img in range(len(test_img_list)):
        high_img[number_img] = (sess.run(high_img[number_img])).reshape(1,high_img[number_img].shape[0],high_img[number_img].shape[1],high_img[number_img].shape[2])
        low_img[number_img] = (sess.run(low_img[number_img])).reshape(1,low_img[number_img].shape[0],low_img[number_img].shape[1],low_img[number_img].shape[2])

for test_set_number in range(high_img.shape[0]):
    #################################### forward pass to calculate psnr and to save result img.
    high_img_float32 = (high_img[test_set_number]/255.0).astype(np.float32)    # for original version
    low_img_float32 = (low_img[test_set_number]/255.0).astype(np.float32)    # for original version
#    high_img_float32, _, _ = standardization(high_img[test_set_number])    # for attemps01 version
#    low_img_float32, l_avr, l_var  = standardization(low_img[test_set_number])    # for attemps01 version

    high_img_float32 = high_img_float32.astype(np.float32)
    low_img_float32 = low_img_float32.astype(np.float32)

    high_img_fx = np.around(high_img_float32*64)/64
    low_img_fx = np.around(low_img_float32*64)/64

    print(high_img_float32[0][0][0][0])
    print(high_img_fx[0][0][0][0])

    test_out_img_f_flt = sess.run(layer3_out_flt, feed_dict={in_img_f : low_img_float32})
    test_out_img_f_fx = sess.run(layer3_out_fx, feed_dict={in_img_f : low_img_float32})
    test_out_img_uint8_flt = (test_out_img_f_flt*255.0).astype(np.uint8)    # for original version
    test_out_img_uint8_fx = (test_out_img_f_fx*255.0).astype(np.uint8)    # for original version
#    test_out_img_uint8 = ((test_out_img_f*l_var)+l_avr).astype(np.uint8)    # for attemps01 version

    #################################### calculate psnr
    psnr_flt = sess.run(psnr,feed_dict={label_img_uint8 : high_img[test_set_number], out_img_uint8 : test_out_img_uint8_flt})
    psnr_fx = sess.run(psnr,feed_dict={label_img_uint8 : high_img[test_set_number], out_img_uint8 : test_out_img_uint8_fx})
    print("image name :", test_img_list[test_set_number], "  psnr_flt :", psnr_flt, "  psnr_fx :", psnr_fx)
    
    #################################### save result images
    test_out_img_uint8_flt = test_out_img_uint8_flt.reshape(test_out_img_uint8_flt.shape[1],test_out_img_uint8_flt.shape[2],1)    # reduce the dims from (1, h, w, 1) to (h, w, 1)
    cv2.imwrite(tested_image_path + 'out_img_flt' + str(test_img_list[test_set_number])[:6] + '.jpg', test_out_img_uint8_flt[:,:,:])

    test_out_img_uint8_fx = test_out_img_uint8_fx.reshape(test_out_img_uint8_fx.shape[1],test_out_img_uint8_fx.shape[2],1)    # reduce the dims from (1, h, w, 1) to (h, w, 1)
    cv2.imwrite(tested_image_path + 'out_img_fx' + str(test_img_list[test_set_number])[:6] + '.jpg', test_out_img_uint8_fx[:,:,:])

    low_img[test_set_number] = low_img[test_set_number].reshape(low_img[test_set_number].shape[1], low_img[test_set_number].shape[2], 1)
    cv2.imwrite(tested_image_path + 'in_img_' + str(test_img_list[test_set_number])[:6] + '.jpg', low_img[test_set_number][:,:,:])
    
    high_img[test_set_number] = high_img[test_set_number].reshape(high_img[test_set_number].shape[1], high_img[test_set_number].shape[2], 1)
    cv2.imwrite(tested_image_path + 'label_img_' + str(test_img_list[test_set_number])[:6] + '.jpg', high_img[test_set_number][:,:,:])

fo_param_fx8 = open("./param_fx8.txt", 'w')

# 1 ~ 576
for i in range(w1_fx.shape[0]):
    for ii in range(w1_fx.shape[1]):
        for iii in range(w1_fx.shape[2]):
            for iiii in range(w1_fx.shape[3]):
                fo_param_fx8.write(str(w1_fx[i][ii][iii][iiii]))
                fo_param_fx8.write('\n')
# 577 ~ 37440
for i in range(w2_fx.shape[0]):
    for ii in range(w2_fx.shape[1]):
        for iii in range(w2_fx.shape[2]):
            for iiii in range(w2_fx.shape[3]):
                fo_param_fx8.write(str(w2_fx[i][ii][iii][iiii]))
                fo_param_fx8.write('\n')
# 37441 ~ 38016
for i in range(w3_fx.shape[0]):
    for ii in range(w3_fx.shape[1]):
        for iii in range(w3_fx.shape[2]):
            for iiii in range(w3_fx.shape[3]):
                fo_param_fx8.write(str(w3_fx[i][ii][iii][iiii]))
                fo_param_fx8.write('\n')
# 38017 ~ 38080
for i in range(b1_fx.shape[0]):
    fo_param_fx8.write(str(b1_fx[i]))
    fo_param_fx8.write('\n')
# 38081 ~ 38144
for i in range(b2_fx.shape[0]):
    fo_param_fx8.write(str(b2_fx[i]))
    fo_param_fx8.write('\n')
# 38145
for i in range(b3_fx.shape[0]):
    fo_param_fx8.write(str(b3_fx[i]))
    fo_param_fx8.write('\n')
