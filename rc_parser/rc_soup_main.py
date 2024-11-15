import requests
from bs4 import BeautifulSoup
from rc_soup_pages import *
from rc_soup_tools import *
import json
import sys

def rcDict(num, url):
    return {
        "id": int(num),
        "url": url,
        "pages": {}
    }

def pageDict(num):
    return {
        "id": int(num),
        "type": "",
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

def main(url, debug):
    expo = requests.get(url)
    parsed = BeautifulSoup(expo.content, 'html.parser')

    num = getExpositionId(url)
    exp_dict = rcDict(num, url)
    if debug: print("")
    if debug: print(url)
    if debug: print("id: " + num)

    pages = getAllPages(url, parsed)
    exp_dict["pages"] = {getPageNumber(page): pageDict(getPageNumber(page)) for page in pages}
    if debug: print(pages)

    for page in pages:
        subpage = requests.get(page)
        parsed = BeautifulSoup(subpage.content, 'html.parser')
        
        if debug: print("-----------------------------------")
        if debug: print(page)
        
        page_dict = pageDict(getPageNumber(page))
        pageType = getPageType(parsed)
        page_dict["type"] = str(pageType[0])
        pageNumber = getPageNumber(page)
        page_dict["id"] = pageNumber
        
        for tool in TEXTTOOLS:
            elements = getTexts(parsed, tool, debug)
            page_dict[tool] = elements
                        
        for tool in TOOLS:
            elements = getTools(parsed, tool, debug)
            page_dict[tool] = elements
            
        exp_dict["pages"][pageNumber] = page_dict
            
    exp_json = json.dumps(exp_dict, indent=2)
    print(exp_json)
    with open("data.json", "w") as outfile:
        outfile.write(exp_json)

if __name__ == "__main__":
    url = str(sys.argv[1])
    debug = int(sys.argv[2])
    main(url, debug)