import requests
from bs4 import BeautifulSoup
from rc_soup_pages import *
from rc_soup_tools import *
import json
import sys
 
URL = str(sys.argv[1])
DEBUG = int(sys.argv[2])

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

#URL = 'https://www.researchcatalogue.net/view/835089/835129' 
expo = requests.get(URL)
parsed = BeautifulSoup(expo.content, 'html.parser')

num = getExpositionId(URL)
exp_dict = rcDict(num)
if DEBUG: print("")
if DEBUG: print(URL)
if DEBUG: print("id: " + num)
expositionType = getPageType(parsed)
exp_dict["type"] = expositionType[0]
if DEBUG: print("type: " + expositionType[0])

pages = getAllPages(URL, parsed)
exp_dict["pages"] = pages
if DEBUG: print(pages)

for page in pages:
    subpage = requests.get(page)
    parsed = BeautifulSoup(subpage.content, 'html.parser')
    
    page_dict = rcDict(num)
    pageType = getPageType(parsed)
    page_dict["type"] = pageType
    pageNumber = getPageNumber(page)
    page_dict["pages"] = pageNumber
    if DEBUG: print("-----------------------------------")
    if DEBUG: print(page)
    
    for tool in TEXTTOOLS:
        elements = getTexts(parsed, tool, DEBUG)
        page_dict[tool] = elements
        exp_dict[tool][pageNumber] = elements
                    
    for tool in TOOLS:
        elements = getTools(parsed, tool, DEBUG)
        page_dict[tool] = elements
        exp_dict[tool][pageNumber] = elements
        
#print(exp_dict)
exp_json = json.dumps(exp_dict)
print(exp_json)
with open("data.json", "w") as outfile:
    outfile.write(exp_json)