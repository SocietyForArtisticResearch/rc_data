from PIL import Image
from os import path, chdir, mkdir, listdir
import os


def scaleByWidth(img, w):
    basewidth = w
    wpercent = basewidth / float(img.size[0])
    hsize = int((float(img.size[1]) * float(wpercent)))
    img = img.resize((basewidth, hsize), Image.LANCZOS)
    return img, basewidth, hsize


def cycle_screenshots(starting_directory):
    json = {}  # we want to also have a json index file of all of this.
    for root, dirs, files in os.walk(starting_directory):
        print(f"Current directory: {root}")
        print("Subdirectories:")
        for directory in dirs:
            print(os.path.join(root, directory))
        print("Files:")
        for file in files:
            if file.endswith(".png"):
                file_name = path.basename(file)
                img = Image.open(os.path.join(root, file))
                img = img.convert("RGB")

                # path split
                myPath = root
                normalized_path = path.normpath(myPath)
                components = normalized_path.split(os.sep)
                print("components", components)
                exp = components[0]
                page = components[1]

                resizedFileName = (
                    os.path.join(root)
                    + "/"
                    + path.splitext(file_name)[0]
                    + "-"
                    + str(scaled[1])
                    + "x"
                    + str(scaled[2])
                    + ".jpg"
                )

                ((json[exp])[page])[normal] = file_name

                scaled = scaleByWidth(img, 600)
                scaled[0].save(
                    os.path.join(root)
                    + "/"
                    + path.splitext(file_name)[0]
                    + "-"
                    + str(scaled[1])
                    + "x"
                    + str(scaled[2])
                    + ".jpg"
                )
                scaled[0].save(
                    os.path.join(root)
                    + "/"
                    + path.splitext(file_name)[0]
                    + "-"
                    + str(scaled[1])
                    + "x"
                    + str(scaled[2])
                    + "-compressed.jpg",
                    "JPEG",
                    quality=50,
                )
                scaled = scaleByWidth(img, 450)
                scaled[0].save(
                    os.path.join(root)
                    + "/"
                    + path.splitext(file_name)[0]
                    + "-"
                    + str(scaled[1])
                    + "x"
                    + str(scaled[2])
                    + ".jpg"
                )
                scaled[0].save(
                    os.path.join(root)
                    + "/"
                    + path.splitext(file_name)[0]
                    + "-"
                    + str(scaled[1])
                    + "x"
                    + str(scaled[2])
                    + "-compressed.jpg",
                    "JPEG",
                    quality=50,
                )
                print(os.path.join(root, file))


screenshots = "./screenshots"
cycle_screenshots(screenshots)
