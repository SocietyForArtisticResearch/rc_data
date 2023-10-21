#test different expositions
from selenium import webdriver
from rc_selenium import *
import pandas as pd
import json
import os

#res = ["https://www.researchcatalogue.net/view/1756075/1756076"]
#res = ["https://www.researchcatalogue.net/view/2260456/2260457"]#graphical with TOC
res = ["https://www.researchcatalogue.net/view/81827/81828"]#graphical no TOC

for exposition in res:
    print("")
    print(exposition)
    num = getExpositionId(exposition)
    print("id: " + num)
    driver = webdriver.Chrome(options=OPTIONS)
    driver.get(exposition)
    print("type: " + getExpositionType(driver))
    pages = getAllPages(exposition, driver)
    print("pages: " + str(pages))
    for page in pages:
        driver.get(page)
        #images = getImages(driver)
        #print(getPageNumber(page), "images: ", images)
        #videos = getVideos(driver)
        #print(getPageNumber(page), "videos: ", videos)
        texts = getTexts(driver)
        print(getPageNumber(page), "texts: ", texts)