# this currently only works for graphical and block editor
# it creates 3 nested dictionaries: one per page, one per exposition, one per whole rc
# then dumps to json
from selenium import webdriver
from rc_selenium import *
import pandas as pd
import json
import os


def rcDict(num):
    d = {
        "id": int(num),
        "type": "",
        "pages": [],
        "tool-text": {},
        "tool-simpletext": {},
        "tool-picture": {},
        "tool-audio": {},
        "tool-video": {},
        "tool-shape": {},
        "tool-pdf": {},
        "tool-slideshow": {},
        "tool-embed": {},
        "tool-iframe": {},
    }
    return d


if not os.path.exists("rcdata.json"):
    rc_dict = {}
else:
    with open("rcdata.json") as rc:
        rc_dict = json.load(rc)

# res = ["https://www.researchcatalogue.net/view/1912684/1912683"] #text-based
# res = ["https://www.researchcatalogue.net/view/1731661/1731662"] #block
# res = ["https://www.researchcatalogue.net/view/381565/694354"] #graphical
# res = ["https://www.researchcatalogue.net/view/381571/381572"]
#res = ["https://www.researchcatalogue.net/view/1723425/1723422"]  # block & graphical
# res = ["https://www.researchcatalogue.net/view/1813623/1838695"] #video
# res = ["https://www.researchcatalogue.net/view/1912894/1912895"] #audio

# loading the data from file
research = pd.read_json('internal_research.json')
print(research.to_string())
res = research['default-page']

print(res)

for exposition in res:
    num = getExpositionId(exposition)
    path = "data/" + num
    if not os.path.exists(path):
        try:
            driver = webdriver.Chrome(options=OPTIONS)
            driver.get(exposition)
            os.makedirs(path)
            exp_dict = rcDict(num)
            print("")
            print(exposition)
            print("id: " + num)
            expositionType = getExpositionType(driver)
            exp_dict["type"] = expositionType
            print("type: " + expositionType)
            try:
                pages = getAllPages(exposition, driver)
            except:
                print("Default to single page exposition: " + exposition)
                pages = [exposition]
            exp_dict["pages"] = pages
            print("pages: " + str(pages))

            for page in pages:
                driver.get(page)
                page_dict = rcDict(num)
                pageType = getExpositionType(driver)
                page_dict["type"] = pageType
                pageNumber = getPageNumber(page)
                page_dict["pages"] = pageNumber
                print("-----------------------------------")
                print(page)
                pagePath = path + "/" + str(pageNumber)
                os.makedirs(pagePath)

                for tool in TEXTTOOLS:
                    elements = getTexts(driver, tool)
                    page_dict[tool] = elements
                    exp_dict[tool][pageNumber] = elements

                for tool in TOOLS:
                    elements = getTools(driver, tool)
                    page_dict[tool] = elements
                    exp_dict[tool][pageNumber] = elements

                page_json = json.dumps(page_dict)
                with open(pagePath + "/" + "data.json", "w") as outfile:
                    outfile.write(page_json)

            print(exp_dict)
            exp_json = json.dumps(exp_dict)
            print(exp_json)
            with open(path + "/" + "data.json", "w") as outfile:
                outfile.write(exp_json)
            rc_dict[str(num)] = exp_dict
            print(rc_dict)
            rc_json = json.dumps(rc_dict)
            with open("rcdata.json", "w") as outfile:
                outfile.write(rc_json)
        except:
            print("Failed to get exposition: " + exposition)
        driver.quit()
    else:
        print("Folder " + num + " already exists")
