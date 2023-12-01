import requests
from flask import Flask
from bs4 import BeautifulSoup
from rc_soup_pages import *
from rc_soup_tools import *
import json
import sys

app = Flask(__name__)

def rcDict(num):
    d = {
        "id": int(num),
        "default-page-type": "",
        "pages": [],
        "page-type": {},
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

@app.route('/rcget/<expnum>/<defaultpage>')
def parseExposition(expnum, defaultpage):
    URL = 'https://www.researchcatalogue.net/view/' + str(expnum) + '/' + str(defaultpage)
    DEBUG = 0
    expo = requests.get(URL)
    parsed = BeautifulSoup(expo.content, 'html.parser')

    num = getExpositionId(URL)
    exp_dict = rcDict(num)
    if DEBUG: print("")
    if DEBUG: print(URL)
    if DEBUG: print("id: " + num)
    expositionType = getPageType(parsed)
    exp_dict["default-page-type"] = expositionType[0]
    if DEBUG: print("type: " + expositionType[0])

    pages = getAllPages(URL, parsed)
    exp_dict["pages"] = pages
    if DEBUG: print(pages)

    for page in pages:
        subpage = requests.get(page)
        parsed = BeautifulSoup(subpage.content, 'html.parser')
        
        #page_dict = rcDict(num)
        pageType = getPageType(parsed)
        #page_dict["type"] = pageType
        pageNumber = getPageNumber(page)
        pageType = getPageType(parsed)
        exp_dict["page-type"][pageNumber] = pageType[0]
        #page_dict["pages"] = pageNumber
        if DEBUG: print("-----------------------------------")
        if DEBUG: print(page)
        
        for tool in TEXTTOOLS:
            elements = getTexts(parsed, tool, DEBUG)
            #page_dict[tool] = elements
            exp_dict[tool][pageNumber] = elements
                        
        for tool in TOOLS:
            elements = getTools(parsed, tool, DEBUG)
            #page_dict[tool] = elements
            exp_dict[tool][pageNumber] = elements
            
    #print(exp_dict)
    exp_json = json.dumps(exp_dict)
    #print(exp_json)
    with open("data.json", "w") as outfile:
        outfile.write(exp_json)
    return exp_dict

if __name__ == "rc_data":
    from waitress import serve
    serve(app, host="0.0.0.0", port=5001)

#https://www.digitalocean.com/community/tutorials/how-to-create-your-first-web-application-using-flask-and-python-3#step-4-routes-and-view-functions
