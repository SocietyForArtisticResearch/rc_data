from PIL import Image
from os import path, chdir, mkdir, listdir
import os
import json


def scaleByWidth(img, w):
    basewidth = w
    wpercent = basewidth / float(img.size[0])
    hsize = int((float(img.size[1]) * float(wpercent)))
    img = img.resize((basewidth, hsize), Image.LANCZOS)
    return img, basewidth, hsize


def cycle_screenshots(starting_directory):
    json_dump = {}  # we want to also have a json_dump index file of all of this.
    for root, dirs, files in os.walk(starting_directory):
        print(f"Current directory: {root}")
        print("Subdirectories:")
        for directory in dirs:
            print(os.path.join(root, directory))
        print("Files:")

        for file in files:
            if file.endswith(".png"):
                file_name = path.basename(file)
                without_ext = path.splitext(file)[0]

                img = Image.open(os.path.join(root, file))
                img = img.convert("RGB")

                # path split
                myPath = root
                normalized_path = path.normpath(myPath)
                components = normalized_path.split(os.sep)
                print("components", components)
                exp = components[1]
                page = components[2]
                if exp in json_dump:
                    print("exp in jsondump")
                    if page in json_dump[exp]:
                        print("page in j[exp]")
                        json_dump[exp][page][without_ext] = {}
                    else:
                        json_dump[exp][page] = {without_ext: {}}

                else:
                    json_dump[exp] = {page: {without_ext: {}}}

                json_dump[exp][page][without_ext]["normal"] = file_name

                scaled = scaleByWidth(img, 600)
                medium_file_name = (
                    os.path.join(root)
                    + "/"
                    + path.splitext(file_name)[0]
                    + "-"
                    + str(scaled[1])
                    + "x"
                    + str(scaled[2])
                    + ".jpg"
                )
                scaled[0].save(medium_file_name)
                json_dump[exp][page][without_ext]["medium"] = medium_file_name

                compressed_file_name = (
                    os.path.join(root)
                    + "/"
                    + path.splitext(file_name)[0]
                    + "-"
                    + str(scaled[1])
                    + "x"
                    + str(scaled[2])
                    + "-compressed.jpg"
                )

                json_dump[exp][page][without_ext][
                    "medium-compressed"
                ] = compressed_file_name
                scaled[0].save(
                    compressed_file_name,
                    "JPEG",
                    quality=50,
                )

                scaled = scaleByWidth(img, 450)
                mini_file_name = (
                    os.path.join(root)
                    + "/"
                    + path.splitext(file_name)[0]
                    + "-"
                    + str(scaled[1])
                    + "x"
                    + str(scaled[2])
                    + ".jpg"
                )
                scaled[0].save(mini_file_name)
                json_dump[exp][page][without_ext]["mini"] = mini_file_name

                mini_file_compressed = (
                    os.path.join(root)
                    + "/"
                    + path.splitext(file_name)[0]
                    + "-"
                    + str(scaled[1])
                    + "x"
                    + str(scaled[2])
                    + "-compressed.jpg"
                )
                scaled[0].save(
                    mini_file_compressed,
                    "JPEG",
                    quality=50,
                )
                json_dump[exp][page][without_ext][
                    "mini-compressed"
                ] = mini_file_compressed
                print(os.path.join(root, file))
    with open("image_structure.json", "w") as json_file:
        json.dump(json_dump, json_file, indent=4)


screenshots = "./screenshots"
cycle_screenshots(screenshots)
