# get all images in folder, remove alpha channel, rescale to 1920x1080, convert to jpg
from PIL import Image
from os import path, chdir, mkdir, listdir, makedirs
from pathlib import Path


def create_directory_if_not_exists(directory_path):
    """
    Creates a directory if it does not already exist.

    Parameters:
    directory_path (str): The path of the directory to be created.
    """
    if not path.exists(directory_path):
        print("directory does not exist", directory_path)
        makedirs(directory_path)
        print(f"Directory '{directory_path}' created.")
    else:
        print(f"Directory '{directory_path}' already exists.")


def scaleByWidth(img):
    basewidth = 1920
    wpercent = basewidth / float(img.size[0])
    hsize = int((float(img.size[1]) * float(wpercent)))
    img = img.resize((basewidth, hsize), Image.LANCZOS)
    return img, basewidth, hsize


def scaleByHeight(img):
    baseheight = 1080
    hpercent = baseheight / float(img.size[1])
    wsize = int((float(img.size[0]) * float(hpercent)))
    img = img.resize((wsize, baseheight), Image.LANCZOS)
    return img, wsize, baseheight


def resizeScreenshot(pathh):
    directory = Path(pathh)
    i = 0
    pages = []

    for page in directory.iterdir():
        if page.is_dir():
            pages.append(page.name)

    chdir(pathh)

    for page in pages:
        create_directory_if_not_exists(page)
        create_directory_if_not_exists("compressed")
        images = []
        for file in listdir():
            if file.endswith(".png") or file.endswith(".jpg") or file.endswith(".jpeg"):
                images.append(file)

        for image in images:
            i = i + 1
            print(str(i) + "/" + str(len(images)))
            print(image)
            file = image
            file_name = path.basename(file)
            img = Image.open(file)
            img = img.convert("RGB")
            if img.size[0] < img.size[1]:
                img = scaleByHeight(img)
            else:
                img = scaleByWidth(img)
            img[0].save(
                "resized/"
                + path.splitext(file_name)[0]
                + "_"
                + str(img[1])
                # + "x"
                # + str(img[2])
                + ".jpg"
            )
            img[0].save(
                "compressed/" + path.splitext(file_name)[0] + "-compressed.jpg",
                "JPEG",
                quality=50,
            )

        chdir("..")
    chdir("..")
    chdir("..")
