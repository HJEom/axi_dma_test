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
if os.path.isdir(params_path + "/../../../test_file/") == False:
    os.makedirs(params_path +  "/../../../test_file/")
tested_image_path = params_path +  "/../../../test_file/"

def get_all_dataset(image_path, image_list):
    high_images = np.empty(len(image_list), dtype=object)
    low_images = np.empty(len(image_list), dtype=object)
    print("\ngetting all dataset for train and test...")
    for i in range(len(image_list)):
        image = cv2.imread(image_path+'/'+image_list[i])
        image = cv2.resize(image,(48,48))
        high_images[i] = tf.reshape(tf.image.rgb_to_grayscale(image),[image.shape[0],image.shape[1],1])
        low_images[i] = tf.image.resize_images(tf.image.resize_images(tf.reshape(tf.image.rgb_to_grayscale(image),[image.shape[0],image.shape[1],1]), (int(image.shape[0]/2),int(image.shape[1]/2)), method=tf.image.ResizeMethod.BICUBIC), (image.shape[0],image.shape[1]), method=tf.image.ResizeMethod.BICUBIC)
    return high_images, low_images

def random_crop(high_images, low_images, mini_batch_size, crop_size):
    crop_high_img = np.empty((mini_batch_size,crop_size,crop_size,1),dtype=np.uint8)
    crop_low_img= np.empty((mini_batch_size,crop_size,crop_size,1),dtype=np.uint8)
    for i in range(mini_batch_size):
        h_ = np.random.random_integers(0, high_images[0].shape[0]-crop_size)
        w_ = np.random.random_integers(0, high_images[0].shape[1]-crop_size)
        crop_high_img[i] = high_images[0][h_:h_+crop_size, w_:w_+crop_size, :]
        crop_low_img[i] = low_images[0][h_:h_+crop_size, w_:w_+crop_size, :]
    return crop_high_img, crop_low_img, crop_high_img/255.0, crop_low_img/255.0

crop_size = 48

sess = tf.Session()
saver = tf.train.import_meta_graph(params_path+'./train.ckpt.meta')
saver.restore(sess, tf.train.latest_checkpoint(params_path))

graph = tf.get_default_graph()
#################################### print tensor_name
for i in graph.get_operations():
    print(i.name)

#################################### print variables
w1 = graph.get_tensor_by_name("w1:0")
w2 = graph.get_tensor_by_name("w2:0")
w3 = graph.get_tensor_by_name("w3:0")
b1 = graph.get_tensor_by_name("b1:0")
b2 = graph.get_tensor_by_name("b2:0")
b3 = graph.get_tensor_by_name("b3:0")
#print("tensor shape : ", w3.get_shape())
#w1_, w2_, w3_, b1_, b2_, b3_ = sess.run([w1,w2,w3,b1,b2,b3])

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

#layer2_out = tf.nn.relu(conv2d(layer1_out,w2,b2))
#layer3_out = conv2d(layer2_out,w3,b3)

#################################### results
layer3_out = graph.get_tensor_by_name("layer3_out/add:0")

#################################### psnr
psnr = graph.get_tensor_by_name("psnr/Mean:0")

#################################### fetch dataset for test
test_img_list = os.listdir(test_img_path)
w1_flt, w2_flt, w3_flt, b1_flt, b2_flt, b3_flt = sess.run([w1,w2,w3,b1,b2,b3])

w1_fx = np.empty((w1_flt.shape[0],w1_flt.shape[1],w1_flt.shape[2],w1_flt.shape[3]))
w2_fx = np.empty((w2_flt.shape[0],w2_flt.shape[1],w2_flt.shape[2],w2_flt.shape[3]))
w3_fx = np.empty((w3_flt.shape[0],w3_flt.shape[1],w3_flt.shape[2],w3_flt.shape[3]))
b1_fx = np.empty((b1_flt.shape[0]))
b2_fx = np.empty((b2_flt.shape[0]))
b3_fx = np.empty((b3_flt.shape[0]))

for k_oc in range(w1_fx.shape[3]):
    for k_ic in range(w1_fx.shape[2]):
        for k_w in range(w1_fx.shape[1]):
            for k_h in range(w1_fx.shape[0]):
                w1_fx[k_h][k_w][k_ic][k_oc] = np.around(w1_flt[k_h][k_w][k_ic][k_oc]*64)/64

# 577 ~ 37440
for k_oc in range(w2_fx.shape[3]):
    for k_ic in range(w2_fx.shape[2]):
        for k_w in range(w2_fx.shape[1]):
            for k_h in range(w2_fx.shape[0]):
                w2_fx[k_h][k_w][k_ic][k_oc] = np.around(w2_flt[k_h][k_w][k_ic][k_oc]*64)/64

# 37441 ~ 38016
for k_oc in range(w3_fx.shape[3]):
    for k_ic in range(w3_fx.shape[2]):
        for k_w in range(w3_fx.shape[1]):
            for k_h in range(w3_fx.shape[0]):
                w3_fx[k_h][k_w][k_ic][k_oc] = np.around(w3_flt[k_h][k_w][k_ic][k_oc]*64)/64

for o_c in range(b1_flt.shape[0]):
    b1_fx[o_c] = np.around(b1_flt[o_c]*64)/64

for o_c in range(b2_flt.shape[0]):
    b2_fx[o_c] = np.around(b2_flt[o_c]*64)/64

for o_c in range(b3_flt.shape[0]):
    b3_fx[o_c] = np.around(b3_flt[o_c]*64)/64

layer1_out = tf.nn.conv2d(in_img_f,w1_fx,strides=[1,1,1,1], padding='SAME')

with tf.device('/cpu:0'):
    
    #sess.run(tf.global_variables_initializer())

    high_img, low_img = get_all_dataset(test_img_path, test_img_list)
    print("convert tensor to numpy array...")
    for number_img in range(len(test_img_list)):
        high_img[number_img] = (sess.run(high_img[number_img])).reshape(1,high_img[number_img].shape[0],high_img[number_img].shape[1],high_img[number_img].shape[2])
        low_img[number_img] = (sess.run(low_img[number_img])).reshape(1,low_img[number_img].shape[0],low_img[number_img].shape[1],low_img[number_img].shape[2])

for test_set_number in range(1):

    test_high_img_uint8, test_low_img_uint8, _, _ = random_crop(high_img[test_set_number], low_img[test_set_number], 1, crop_size)
    test_out_img_uint8 = sess.run(layer1_out, feed_dict={in_img_f : test_low_img_uint8})

    #################################### save result images
    test_out_img_uint8 = test_out_img_uint8[:,:,:,1].reshape(crop_size,crop_size,1)
    cv2.imwrite(tested_image_path + 'out_img_' + str(test_img_list[test_set_number])[:6] + '.jpg', test_out_img_uint8[:,:,:])

    test_low_img_uint8 = test_low_img_uint8.reshape(test_low_img_uint8.shape[1], test_low_img_uint8.shape[2], 1)
    cv2.imwrite(tested_image_path + 'in_img_' + str(test_img_list[test_set_number])[:6] + '.jpg', test_low_img_uint8[:,:,:])

#    low_img[test_set_number] = low_img[test_set_number].reshape(low_img[test_set_number].shape[1], low_img[test_set_number].shape[2], 1)
#    cv2.imwrite(tested_image_path + 'in_img_' + str(test_img_list[test_set_number])[:6] + '.jpg', low_img[test_set_number][:,:,:])
    
#    high_img[test_set_number] = high_img[test_set_number].reshape(high_img[test_set_number].shape[1], high_img[test_set_number].shape[2], 1)
#    cv2.imwrite(tested_image_path + 'label_img_' + str(test_img_list[test_set_number])[:6] + '.jpg', high_img[test_set_number][:,:,:])

#######################################
#######################################
# input, diff image save as .txt file

i_low_img = open(tested_image_path + 'i_low_img.txt','w')
ii_low_img = open(tested_image_path + 'ii_low_img.txt','w')
d_low_img = open(tested_image_path + 'd_low_img.txt','w')
param_w = open(tested_image_path + 'param_w.txt','w')
param_b = open(tested_image_path + 'param_b.txt','w')

for h in range(12):
    for w in range(48):
        for h_partial in range(4):
            i_low_img.write(str(int(test_low_img_uint8[h_partial+h*4][w][0]))+'\n')

for h in range(48):
    for w in range(48):
        ii_low_img.write(str(int(test_low_img_uint8[h][w][0]))+'\n')

for h in range(48):
    for w in range(48):
        d_low_img.write(str(int(test_out_img_uint8[h][w][0]))+'\n')

for k_oc in range(w1_fx.shape[3]):
    for k_ic in range(w1_fx.shape[2]):
        for k_h in range(w1_fx.shape[1]):
            for k_w in range(w1_fx.shape[0]):
                param_w.write(str(int(w1_fx[k_h][k_w][k_ic][k_oc]*64))+'\n')

for k_oc in range(w2_fx.shape[3]):
    for k_ic in range(w2_fx.shape[2]):
        for k_h in range(w2_fx.shape[1]):
            for k_w in range(w2_fx.shape[0]):
                param_w.write(str(int(w2_fx[k_h][k_w][k_ic][k_oc]*64))+'\n')

for k_oc in range(w3_fx.shape[3]):
    for k_ic in range(w3_fx.shape[2]):
        for k_h in range(w3_fx.shape[1]):
            for k_w in range(w3_fx.shape[0]):
                param_w.write(str(int(w3_fx[k_h][k_w][k_ic][k_oc]*64))+'\n')

for k_oc in range(b1_fx.shape[0]):
	param_b.write(str(int(b1_fx[k_oc]*64))+'\n')
for k_oc in range(b2_fx.shape[0]):
	param_b.write(str(int(b2_fx[k_oc]*64))+'\n')
for k_oc in range(b3_fx.shape[0]):
	param_b.write(str(int(b3_fx[k_oc]*64))+'\n')
