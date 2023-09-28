from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
import pandas as pd
import json
import os

research = pd.read_json('internal_research.json')
print(research.to_string())
res = research['default-page']
print(res)

#res = ["https://www.researchcatalogue.net/view/1756075/1756076"]

options = Options()
options.add_argument("--headless=new")
options.add_argument("--hide-scrollbars");
options.add_argument("window-size=1920,1609") #change size to 1920 1440 -- height val found empirically because of inconsistet viewport behavior with the --headless flag

RESSIZE = len(res)
total = 0
failed = 0
counterTOC = 0
counterInferred = 0
counterSinglePage = 0
failedUrls = []
weaveFound = 0
weaveNotFound = 0
tocs_dict = {}

def getTitle(atag):
    return atag.get_attribute('innerHTML')

def getURL(atag):
    return atag.get_attribute('href')

def notAuthor(atag):
    if atag.get_attribute('rel') == 'author':
        return False
    else:
        return True

def getExpositionUrl(fullUrl):
    parts = fullUrl.split("/")[:5]
    url = "/".join(parts)
    return url

def getDomainView(fullUrl):
    parts = fullUrl.split("/")[:4]
    url = "/".join(parts)
    return url

def getExpositionId(fullUrl):
    return fullUrl.split("/")[4]

def getPageNumber(fullUrl):
    return fullUrl.split("/")[5].split("#")[0]

def notContainsHash(fullUrl):
    page = fullUrl.split("/")[5]
    if "#" not in page:
        return True
    else:
        return False

def notAnchorAtOrigin(fullUrl):
    try:
        anchor = "0".join(fullUrl.split("/")[6:])
        if anchor == "000":
            return False
        else:
            return True
    except:
        return True
    
def isSubPage(expositionUrl, url):
    try:
        base = getExpositionUrl(url)
        if base == expositionUrl:
            return True
        else:
            return False
    except:
        return False
    
def isDomainView(url):
    try:
        base = getDomainView(url)
        if base == "https://www.researchcatalogue.net/view":
            return True
        else:
            return False
    except:
        return False
    
def smartZoom(driver):
    try:
        weave = driver.find_element(By.ID, "weave")
        global weaveFound
        weaveFound = weaveFound + 1
        size = weave.size
        height = size["height"]
        width = size["width"]
        print("| weave size: " + str(size))
        if width < 1900:
            scale = 100
        elif height < 1440:
            scale = 100
        else:
            scale = int(max(100 - ((width * height) / (1920 * 1440)), 50))
    except:
        global weaveNotFound
        weaveNotFound = weaveNotFound + 1
        print("| no weave found")
        scale = 100
        size = "weave not found"
    return [scale, size]

def takeScreenshot(url, path, i, title, noTOC):
    #path = path + "/" + str(i) + " " + title + ".png" #uncomment to name with title
    page = getPageNumber(url)
    path = path + "/" + str(i) + ".png"
    print("| " + path)
    if not os.path.exists(path):
        try:
            driver.get(url)
            scale = smartZoom(driver)
            if noTOC:
                scal = scale[0] * 2
                zoom = str(scal) + "%"
                print("| zoom: " + zoom)
                driver.execute_script("document.body.style.zoom='" + zoom + "'")
            else:
                zoom = str(scale[0]) + "%"
                print("| zoom: " + zoom)
                driver.execute_script("document.body.style.zoom='" + zoom + "'")
            driver.save_screenshot(path)
            print("| ⬇ downloading")
            print("------------------")
        except:
            i = 404
            title = "failed"
            print("| download failed")
            print("------------------")
    else:
        print("| ✓ already available")
        print("------------------")
    return {"page": page, "page_title": title, "url": url, "file": str(i) + ".png", "weave_size": scale[1]}
    
def makeDir(num):
    path = "screenshots/" + num
    if not os.path.exists(path):
        os.makedirs(path)
    return path

def makeDirFromURL(url):
    num = getExpositionId(url)
    page = getPageNumber(url)
    path = "screenshots/" + num + "/" + page
    if not os.path.exists(path):
        os.makedirs(path)
    return path

def countElements():
    try:
        weave = driver.find_element(By.ID, "weave")
        print("weave size: " + str(weave.size))
    except:
        print("!!! weave not found !!!")
    
    try:
        contents = driver.find_element(By.XPATH, "/html/body/div[5]/ul/li[1]/ul")
        print("GRAPHICAL EXPOSITION")
    #except NoSuchElementException:
        #try:
         #   contents = driver.find_element(By.ID, "content")
          #  print("BLOCK EXPOSITION")
        #except:
         #   print("!!! contents not found !!!")
    except:
        print("!!! contents not found !!!")
        
    print("--------------------")
    #pages = contents.find_elements(By.TAG_NAME, "a")
    #print("weaves: " + str(len(pages)))
    pictures = driver.find_elements(By.CLASS_NAME, "tool-picture")
    print("pictures: " + str(len(pictures)))
    texts = driver.find_elements(By.CLASS_NAME, "tool-text")
    simpletexts = driver.find_elements(By.CLASS_NAME, "tool-simpletext")
    print("texts: " + str(len(texts)+len(simpletexts)))
    shapes = driver.find_elements(By.CLASS_NAME, "tool-shape")
    print("shapes: " + str(len(shapes)))
    videos = driver.find_elements(By.CLASS_NAME, "tool-video")
    print("videos: " + str(len(videos)))
    print("--------------------")
    
def findNav(driver):
    xpath = xpath
    try:
        nav = driver.find_element(By.XPATH, xpath)
        return nav
    except NoSuchElementException:
        print("| No nav found at xpath: " + xpath)
        
def findHrefsInPage(driver):
    links = driver.find_elements(By.TAG_NAME, "a")
    return list(map(getURL, links))

def screenShotPages(fullUrl):
    try:
        toc = []
        num = getExpositionId(fullUrl)
        path = makeDir(num)
        xpath = "/html/body/div[5]/ul/li[1]/ul"
        xpathFonts = "/html/body/div[6]/ul/li[1]/ul" # this is the xpath when fonts not loaded
        try:
            nav = driver.find_element(By.XPATH, xpath) # nav > contents
        except:
            try:
                nav = driver.find_element(By.XPATH, xpathFonts)
            except:
                print("| " + fullUrl)
                print("| No nav found at xpath")
                
        navList = nav.find_elements(By.TAG_NAME, "a") # list of content elements
        filteredList = list(filter(notAuthor, navList)) # remove authors URLS
        titles = list(map(getTitle, filteredList)) # get contents titles
        contents = list(map(getURL, filteredList)) # get contents urls
        numEntries = len(contents)
        if contents and numEntries != 1: # TOC exists. we cycle through TOC to get screenshots
            for i in range(numEntries) :
                url = contents[i]
                path = makeDirFromURL(url)
                print("| " + url)
                #countElements()
                j = takeScreenshot(url, path, i, titles[i], False)
                toc.append(j)
            global counterTOC
            counterTOC = counterTOC + 1
        else: # TOC not available or TOC available but single entry
            expositionUrl = getExpositionUrl(fullUrl)
            hrefs = list(set(findHrefsInPage(driver))) #find all links in page
            subpages = list(filter(lambda href: isSubPage(expositionUrl, href), hrefs)) #filter to get only exposition subpages
            subpages = list(filter(notAnchorAtOrigin, subpages)) #filter out urls with anchor at 0/0
            subpages = list(filter(notContainsHash, subpages)) #filter out urls with hash
            print(subpages)
            path = makeDirFromURL(fullUrl) 
            if len(subpages) > 1: # if subpages found takes screenshot
                for i in range(len(subpages)):
                    url = subpages[i]
                    path = makeDirFromURL(url)
                    print("| " + url)
                    #countElements()
                    j = takeScreenshot(url, path, i, "no title", False)
                    toc.append(j)
                global counterInferred
                counterInferred = counterInferred + 1
            else: # if no TOC and no subpages found take second screenshot
                print("no TOC or inferred subpages found")
                j = takeScreenshot(fullUrl, path, 0, "default page", False)
                toc.append(j)
                j = takeScreenshot(fullUrl, path, 1, "default page", True)
                toc.append(j)
                global counterSinglePage
                counterSinglePage = counterSinglePage + 1
    except:
        print("!!! screenshot failed for exposition: " + fullUrl)
        global failed
        failed = failed + 1
        global failedUrls
        failedUrls.append(fullUrl)
    toc_dict = {"id": num, "toc": toc}
    return toc_dict

for exposition in res:
    print("")
    print(exposition)
    driver = webdriver.Chrome(options=options)
    driver.get(exposition)
    driver.add_cookie({'name' : 'navigationtooltip', 'value': '1'})
    toc_dict = screenShotPages(exposition)
    tocs_dict.update({toc_dict["id"]: toc_dict["toc"]})
    tocs_json = json.dumps(tocs_dict)
    with open("toc.json", "w") as outfile:
        outfile.write(tocs_json)
    total = total + 1
    print("")
    print(tocs_dict)
    print(str(total) + "/" + str(RESSIZE))
    print("TOC: " + str(counterTOC))
    print("Inferred: " + str(counterInferred))
    print("Single Page: " + str(counterSinglePage))
    print("Failed: " + str(failed))
    print(failedUrls)
    print("Found Weaves: " + str(weaveFound))
    print("No Weaves: " + str(weaveNotFound))
    print("")
    driver.quit()