from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup

XPATHNAV = "/html/body/div[5]/ul/li[1]/ul"
XPATHNAVFONTS = "/html/body/div[6]/ul/li[1]/ul" # this is the xpath when fonts not loaded
OPTIONS = Options()
OPTIONS.add_argument("--headless=new")
OPTIONS.add_argument("--hide-scrollbars");
OPTIONS.add_argument("window-size=1920,1609")

def getTitle(atag):
    return atag.get_attribute('innerHTML')

def getURL(atag):
    return atag.get_attribute('href')

def getExpositionId(fullUrl):
    return fullUrl.split("/")[4]

def getPageNumber(url):
    page = url.split("/")[5].split("#")[0]
    return int(page)

def getExpositionTitle(driver):
    return driver.title;
    
def getExpositionType(driver):
    html = driver.find_element(By.TAG_NAME, "html");
    return html.get_attribute("class")

def findHrefsInPage(driver):
    return driver.find_elements(By.TAG_NAME, "a")

def notAuthor(atag):
    if atag.get_attribute('rel') == 'author':
        return False
    else:
        return True
    
def notContainsHash(atag):
    url = getURL(atag)
    page = url.split("/")[5]
    if "#" not in page:
        return True
    else:
        return False

def notAnchorAtOrigin(atag):
    url = getURL(atag)
    try:
        anchor = "0".join(url.split("/")[6:])
        if anchor == "000":
            return False
        else:
            return True
    except:
        return True
    
def isSubPage(expositionUrl, atag):
    url = getURL(atag)
    try:
        expID = getExpositionId(expositionUrl)
        pageID = getExpositionId(url)
        if expID == pageID:
            return True
        else:
            return False
    except:
        return False

def getTOC(driver):
    try:
        nav = driver.find_element(By.XPATH, XPATHNAV) # nav > contents
    except:
        try:
            nav = driver.find_element(By.XPATH, XPATHNAVFONTS)
        except:
            print("| " + fullUrl)
            print("| No nav found at xpath")
            
    navList = nav.find_elements(By.TAG_NAME, "a") # list of toc hrefs
    toc = list(filter(notAuthor, navList)) # remove authors hrefs
    return toc
        
def getPages(expositionUrl, driver):
    atags = list(set(findHrefsInPage(driver))) #find all links in page
    subpages = list(filter(lambda href: isSubPage(expositionUrl, href), atags)) #filter to get only exposition subpages
    subpages = list(filter(notAnchorAtOrigin, subpages)) #filter out urls with anchor at 0/0
    subpages = list(filter(notContainsHash, subpages)) #filter out urls with hash
    return subpages

def getAllPages(expositionUrl, driver):
    try:
        toc = getTOC(driver)
        numEntries = len(toc)
        if toc and numEntries != 1: # TOC exists
            links = toc
        else:
            subpages = getPages(expositionUrl, driver)
            if len(subpages) > 1: # pages exist
                links = subpages
    except:# no TOC or pages found: single page exposition
        print("No TOC or inferred subpages found for: " + expositionUrl)
    
    #titles = list(map(getTitle, links))
    urls = list(map(getURL, links))
    #pages = list(map(getPageNumber, urls))
    #pages.insert(0, getPageNumber(expositionUrl))
    pages = set(urls)
    pages = list(urls)
    #return [pages, titles]
    return pages

def notMissingSrc(src):
    if src == 404:
        return False
    else:
        return True

def getImageSrc(image):
    try:
        image = image.find_element(By.CSS_SELECTOR, "img")
        src = image.get_attribute("src")
    except:
        src = 404
    return src

def getImages(driver):
    images = driver.find_elements(By.CLASS_NAME, "tool-picture")
    images = list(map(getImageSrc, images))
    images = list(filter(notMissingSrc, images))
    return images

def getVideoSrc(video):
    try:
        #print(video.get_attribute("innerHTML"))
        src = video.get_attribute("data-file")
        if src == None:
            try:
                video = video.find_element(By.TAG_NAME, "video")
                src = video.get_attribute("src")
            except:
                src = 404
    except:
        src = 404
    return src

def getVideos(driver):
    #videos = driver.find_elements(By.CSS_SELECTOR, "[id^=video]")
    videos = driver.find_elements(By.CLASS_NAME, "tool-video")
    videos = list(map(getVideoSrc, videos))
    return videos

def removeStyle(text):
    soup = BeautifulSoup(text, features="html.parser")
    for script in soup(["script", "style"]):
        script.extract()
    text = soup.get_text()
    # break into lines and remove leading and trailing space on each
    #lines = (line.strip() for line in text.splitlines())
    # break multi-headlines into a line each
    #chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
    # drop blank lines
    #text = '\n'.join(chunk for chunk in chunks if chunk)
    return text

def getStyledText(driver):
    text = driver.find_element(By.CLASS_NAME, "tool-content")
    text = text.get_attribute('innerHTML')
    return text
    
def getTexts(driver):
    texts = driver.find_elements(By.CLASS_NAME, "tool-text")
    texts = list(map(getStyledText, texts))
    texts = list(map(removeStyle, texts))
    return texts

def getSimpleTexts(driver):
    texts = driver.find_elements(By.CLASS_NAME, "tool-simpletext")
    texts = list(map(getStyledText, texts))
    texts = list(map(removeStyle, texts))
    return texts

def getAudioSrc(audio):
    #audio = driver.find_elements(By.CSS_SELECTOR, "[id^=audio]")
    audio = audio.find_element(By.TAG_NAME, "video")
    return audio.get_attribute("src")

def getAudios(driver):
    audios = driver.find_elements(By.CLASS_NAME, "tool-audio")
    audios = list(map(getAudioSrc, audios))
    return audios

#https://selenium-python.readthedocs.io/locating-elements.html