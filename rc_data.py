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
        "simpletexts": [],
        "texts": [],
        "images": [],
        "videos": [],
        "audios": []
        }
    return d

if not os.path.exists('toc.json'):
    tocs_dict = {}
else:
    with open('toc.json') as toc:
        tocs_dict = json.load(toc)
        
#res = ["https://www.researchcatalogue.net/view/381571/381572"]
#res = ["https://www.researchcatalogue.net/view/1813623/1838695"] #video
#res = ["https://www.researchcatalogue.net/view/1912894/1912895"] #audio
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
            dict_simpletexts = {}
            dict_texts = {}
            dict_images = {}
            dict_videos = {}
            dict_audios = {}
            for page in pages:
                driver.get(page)
                page_dict = rcDict(num)
                pageType = getExpositionType(driver)
                page_dict["type"] = pageType
                pageNumber = getPageNumber(page)
                page_dict["pages"] = pageNumber
                print(page)
                pagePath = path + "/" + str(pageNumber)
                os.makedirs(pagePath)
                try:
                    images = getImages(driver)
                    print(pageNumber, "images: ", images)
                    page_dict["images"] = images
                    dict_images[pageNumber] = images
                except:
                    print("no images found")
                try:
                    videos = getVideos(driver)
                    page_dict["videos"] = videos
                    dict_videos[pageNumber] = videos
                    print(pageNumber, "videos: ", videos)
                except:
                    print("no videos found")
                try:
                    texts = getTexts(driver)
                    print(pageNumber, "texts: ", texts)
                    page_dict["texts"] = texts
                    dict_texts[pageNumber] = texts
                except:
                    print("no texts found")
                try:
                    audios = getAudios(driver)
                    print(pageNumber, "audios: ", audios)
                    page_dict["audios"] = audios
                    dict_audios[pageNumber] = audios
                except:
                    print("no audios found")
                try:
                    simpletexts = getSimpleTexts(driver)
                    print(getPageNumber(page), "simpletexts: ", simpletexts)
                    page_dict["simpletexts"] = simpletexts
                    dict_simpletexts[pageNumber] = simpletexts
                except:
                    print("no simpletetxts found")
                page_json = json.dumps(page_dict)
                with open(pagePath + "/" + "data.json", "w") as outfile:
                    outfile.write(page_json)
            print(dict_images)
            exp_dict["simpletexts"] = dict_simpletexts
            exp_dict["texts"] = dict_texts
            exp_dict["images"] = dict_images
            exp_dict["videos"] = dict_videos
            exp_dict["audios"] = dict_audios
            print(exp_dict)
            exp_json = json.dumps(exp_dict)
            print(exp_json)
            with open(path + "/" + "data.json", "w") as outfile:
                outfile.write(exp_json)
        except:
            print("Failed to get exposition: " + exposition)
        driver.quit()
    else:
        print("Folder " + num + " already exists")