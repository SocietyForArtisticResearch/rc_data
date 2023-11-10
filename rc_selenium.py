from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup

XPATHNAV = "/html/body/div[5]/ul/li[1]/ul"
XPATHNAVFONTS = (
    "/html/body/div[6]/ul/li[1]/ul"  # this is the xpath when fonts not loaded
)
OPTIONS = Options()
OPTIONS.add_argument("--headless=new")
OPTIONS.add_argument("--hide-scrollbars")
OPTIONS.add_argument("window-size=1920,1609")

TOOLS = [
    "tool-picture",
    "tool-audio",
    "tool-video",
    "tool-shape",
    "tool-pdf",
    "tool-slideshow",
    "tool-embed",
    "tool-iframe",
]

TEXTTOOLS = ["tool-text", "tool-simpletext"]

PICTURETOOL = "tool-picture"

VIDEOTOOL = "tool-media"


def getTitle(atag):
    return atag.get_attribute("innerHTML")


def getURL(atag):
    return atag.get_attribute("href")


def getExpositionId(fullUrl):
    return fullUrl.split("/")[4]


def getPageNumber(url):
    page = url.split("/")[5].split("#")[0]
    return int(page)


def getExpositionTitle(driver):
    return driver.title


def getExpositionType(driver):
    html = driver.find_element(By.TAG_NAME, "html")
    return html.get_attribute("class")


def findHrefsInPage(driver):
    return driver.find_elements(By.TAG_NAME, "a")


def notAuthor(atag):
    if atag.get_attribute("rel") == "author":
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
        nav = driver.find_element(By.XPATH, XPATHNAV)  # nav > contents
    except:
        try:
            nav = driver.find_element(By.XPATH, XPATHNAVFONTS)
        except:
            print("| " + fullUrl)
            print("| No nav found at xpath")

    navList = nav.find_elements(By.TAG_NAME, "a")  # list of toc hrefs
    toc = list(filter(notAuthor, navList))  # remove authors hrefs
    return toc


def getPages(expositionUrl, driver):
    atags = list(set(findHrefsInPage(driver)))  # find all links in page
    subpages = list(
        filter(lambda href: isSubPage(expositionUrl, href), atags)
    )  # filter to get only exposition subpages
    subpages = list(
        filter(notAnchorAtOrigin, subpages)
    )  # filter out urls with anchor at 0/0
    subpages = list(filter(notContainsHash, subpages))  # filter out urls with hash
    return subpages


def getAllPages(expositionUrl, driver):
    try:
        toc = getTOC(driver)
        numEntries = len(toc)
        if toc and numEntries != 1:  # TOC exists
            links = toc
        else:
            subpages = getPages(expositionUrl, driver)
            if len(subpages) > 1:  # pages exist
                links = subpages
    except:  # no TOC or pages found: single page exposition
        print("No TOC or inferred subpages found for: " + expositionUrl)

    # titles = list(map(getTitle, links))
    urls = list(map(getURL, links))
    # pages = list(map(getPageNumber, urls))
    # pages.insert(0, getPageNumber(expositionUrl))
    pages = set(urls)
    pages = list(urls)
    # return [pages, titles]
    return pages


def removeStyle(text):
    soup = BeautifulSoup(text, features="html.parser")
    for script in soup(["script", "style"]):
        script.extract()
    text = soup.get_text()
    # break into lines and remove leading and trailing space on each
    # lines = (line.strip() for line in text.splitlines())
    # break multi-headlines into a line each
    # chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
    # drop blank lines
    # text = '\n'.join(chunk for chunk in chunks if chunk)
    return text


def getStyledText(driver):
    text = driver.find_element(By.CLASS_NAME, "tool-content")
    text = text.get_attribute("innerHTML")
    return text


def getId(tool):
    anchor = tool.find_element(By.CSS_SELECTOR, "a")
    tool_id = anchor.get_attribute("id")
    return tool_id


def getPosition(tool):
    left = tool.value_of_css_property("left")
    top = tool.value_of_css_property("top")
    return [left, top]


def getSize(tool):
    width = tool.value_of_css_property("width")
    height = tool.value_of_css_property("height")
    return [width, height]


def getRotation(tool):
    rotate = tool.value_of_css_property("transform")
    return rotate


def getStyle(tool):
    style = tool.get_attribute("style")
    return style


def getVideoUrl(tool):
    video_div = tool.find("div", {"data-file": True})
    url = video_div.get("data-file") if video_div else None
    return url


def getToolAttributes(tool):
    tool_id = getId(tool)
    tool_style = getStyle(tool)
    tool_position = getPosition(tool)
    tool_size = getSize(tool)
    tool_rotation = getRotation(tool)
    tool_dict = {
        "id": tool_id,
        "style": tool_style,
        "position": tool_position,
        "size": tool_size,
        "rotation": tool_rotation,
    }
    return tool_dict


def getTextAttributes(tool):
    tool_id = getId(tool)
    tool_style = getStyle(tool)
    tool_position = getPosition(tool)
    tool_size = getSize(tool)
    tool_rotation = getRotation(tool)
    content = getStyledText(tool)
    content = removeStyle(content)
    tool_dict = {
        "id": tool_id,
        "style": tool_style,
        "position": tool_position,
        "size": tool_size,
        "rotation": tool_rotation,
        "content": content,
    }
    return tool_dict


def getTools(driver, which):
    try:
        tools = driver.find_elements(By.CLASS_NAME, which)
        attributes = list(map(getToolAttributes, tools))
    except:
        pprint("found 0 " + which)
        return []
    print("found " + str(len(attributes)) + " " + which)
    return attributes


def getTexts(driver, which):
    try:
        texts = driver.find_elements(By.CLASS_NAME, which)
        attributes = list(map(getTextAttributes, texts))
    except:
        print("found 0 " + which)
        return []
    print("found " + str(len(attributes)) + " " + which)
    return attributes


# https://selenium-python.readthedocs.io/locating-elements.html

"""
def getImages(driver):
    images = driver.find_elements(By.CLASS_NAME, "tool-picture")
    #images = list(map(getImageSrc, images))
    #images = list(filter(notMissingSrc, images))
    images = list(map(getToolAttributes, images))
    return images

def getAudios(driver):
    audios = driver.find_elements(By.CLASS_NAME, "tool-audio")
    audios = list(map(getToolAttributes, audios))
    return audios

def getVideos(driver):
    #videos = driver.find_elements(By.CSS_SELECTOR, "[id^=video]")
    videos = driver.find_elements(By.CLASS_NAME, "tool-video")
    videos = list(map(getToolAttributes, videos))
    return videos

def getShapes(driver):
    shapes = getTools(driver, "tool-shape")
    return shapes

def getPDFs(driver):
    pdf = driver.find_elements(By.CLASS_NAME, "tool-pdf")
    pdfs_attributes = list(map(getToolAttributes, pdfs))
    return pdfs_attributes
    
def getAudioSrc(audio):
    #audio = driver.find_elements(By.CSS_SELECTOR, "[id^=audio]")
    audio = audio.find_element(By.TAG_NAME, "video")
    return audio.get_attribute("src")
    
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
"""
