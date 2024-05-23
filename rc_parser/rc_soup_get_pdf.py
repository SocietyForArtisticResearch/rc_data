import requests
from bs4 import BeautifulSoup
from rc_soup_pages import *
from rc_soup_tools import *
import json
import sys
import os
import shutil
import pandas as pd
 
#URL = str(sys.argv[1])
DEBUG = True #int(sys.argv[2])
FORCE = True

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

def makeDir(num):
    path = "screenshots/" + num
    if FORCE :
        if os.path.exists(path):
            shutil.rmtree(path)
    if not os.path.exists(path):
        os.makedirs(path)
    return path

def parse_expo(url):
    URL = url 
    expo = requests.get(URL)
    parsed = BeautifulSoup(expo.content, 'html.parser')
    expositionType = getPageType(parsed)
    
    if expositionType[0] == 'weave-text':
        num = getExpositionId(URL)
        makeDir(num)
        exp_dict = rcDict(num)
        exp_dict["type"] = expositionType[0]
        if DEBUG: print("")
        if DEBUG: print(URL)
        if DEBUG: print("id: " + num)
        if DEBUG: print("type: " + expositionType[0])

        for tool in TEXTTOOLS:
            elements = getTexts(parsed, tool, DEBUG)
            exp_dict[tool] = elements
                            
        for tool in TOOLS:
            elements = getTools(parsed, tool, DEBUG)
            exp_dict[tool] = elements
                
        #print(exp_dict)
        exp_json = json.dumps(exp_dict)
        print(exp_json)
        with open("screenshots/" + num + "/" + "data.json", "w") as outfile:
            outfile.write(exp_json)
    else:
        print(expositionType[0])
        print("skip")
        
        
research = pd.read_json("internal_research.json")
print(research.to_string())
res = research["default-page"]
print(res)

for exposition in res:
    print("")
    parse_expo(exposition)