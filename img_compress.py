#compress jpg in folder
from PIL import Image
from os import path, chdir, mkdir, listdir, walk

dir_path = r'/home/poz/Documents/simularr/lisbon/workshop/rc/'

def findImages(riectory):
    images = []
    for file in listdir(directory):
        if (file.endswith('.png') or file.endswith(".jpg") or file.endswith(".jpeg")):
            images.append(file)
    return images

for root, dirs, files in walk(dir_path):
    for dr in dirs:
        print(dr)
        directory = dir_path + dr 
        chdir(directory)
        mkdir('compressed')
        images = findImages(directory)
        i = 0
        for image in images:
            i = i + 1
            print(str(i) + '/' + str(len(images)))
            print(image)
            file = directory + '/' + image
            file_name = path.basename(file)
            img = Image.open(file)
            img = img.convert('RGB')
            img.save('compressed/' + path.splitext(file_name)[0] + '-compressed.jpg', "JPEG", quality=50)
