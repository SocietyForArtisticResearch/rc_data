#get all images in folder, remove alpha channel, rescale to 1920x1080, convert to jpg
from PIL import Image
from os import path, chdir, mkdir, listdir

dir_path = r'/home/poz/Works/2023_ongoing/experiment/scan/'
chdir(dir_path)
mkdir('resized')

def scaleByWidth(img):
    basewidth = 1920
    wpercent = (basewidth / float(img.size[0]))
    hsize = int((float(img.size[1]) * float(wpercent)))
    img = img.resize((basewidth, hsize), Image.LANCZOS)
    return img, basewidth, hsize
    
def scaleByHeight(img):
    baseheight = 1080
    hpercent = (baseheight / float(img.size[1]))
    wsize = int((float(img.size[0]) * float(hpercent)))
    img = img.resize((wsize, baseheight), Image.LANCZOS)
    return img, wsize, baseheight

images = []
for file in listdir(dir_path):
    if (file.endswith('.png') or file.endswith(".jpg") or file.endswith(".jpeg")):
        images.append(file)
print(images)

i = 0

for image in images:
    i = i + 1
    print(str(i) + '/' + str(len(images)))
    print(image)
    file = image
    file_name = path.basename(file)
    img = Image.open(file)
    img = img.convert('RGB')
    if img.size[0] < img.size[1]:
        img = scaleByHeight(img)
    else:
        img = scaleByWidth(img)
    img[0].save('resized/' + path.splitext(file_name)[0] + '_' + str(img[1]) + 'x' + str(img[2]) + '.jpg')