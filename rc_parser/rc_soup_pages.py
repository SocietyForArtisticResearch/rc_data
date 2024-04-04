#tools to parse hyperlinks in RC expositions and to locate subpages
from bs4 import BeautifulSoup

RCURL = 'https://www.researchcatalogue.net'

def getPageType(page):
    html = page.find("html");
    return html['class']

def getExpositionId(fullUrl):
    return fullUrl.split("/")[4]

def remove_query_part(url: str) -> str:
    """
    Remove everything after the '?' character in a given string.

    :param url: The input string potentially containing a '?' character.
    :return: The string with everything after the '?' character removed.
    """
    return url.split('?')[0]

def getPageNumber(url):
    url_without_query = remove_query_part(url)
    page = url_without_query.split("/")[5].split("#")[0]
    return int(page)

def isRelative(href):
    parts = href.split("/")
    if parts[1] == 'view':
        return True
    else:
        return False

def getHref(atag):
    try:
        href = atag['href']
        if isRelative(href):
            href = RCURL + href
    except:
        return "no href"
    return href

def getURL(atag):
    href = atag['href']
    if isRelative(href):
        href = RCURL + href
    return href

def findHrefsInPage(page):
    return page.find_all("a")

def notContainsHash(url):
    try:
        page = url.split("/")[5]
        if "#" not in page:
            return True
        else:
            return False
    except:
        return False

def notAnchorAtOrigin(url):
    try:
        anchor = "0".join(url.split("/")[6:])
        if anchor == "000":
            return False
        else:
            return True
    except:
        return True
    
def isSubPage(expositionUrl, url):
    try:
        expID = getExpositionId(expositionUrl)
        pageID = getExpositionId(url)
        if expID == pageID:
            return True
        else:
            return False
    except:
        return False
    
def getPages(expositionUrl, page):
    atags = findHrefsInPage(page) #find all links in page
    urls = list(map(getHref, atags))
    urls = list(set(urls))
    subpages = list(filter(lambda url: isSubPage(expositionUrl, url), urls)) #filter to get only exposition subpages
    subpages = list(filter(notAnchorAtOrigin, subpages)) #filter out urls with anchor at 0/0
    subpages = list(filter(notContainsHash, subpages)) #filter out urls with hash
    subpages.append(expositionUrl)
    subpages = list(set(subpages))
    return subpages

def getAllPages(expositionUrl, page): #now we don't make a difference anymore btw TOC and subpages
    try:
        pages = getPages(expositionUrl, page)
    except:
        return [expositionUrl]
    return pages

'''old

def notAuthor(atag):
    try:
        if atag['rel'] == ['author']:
            return False
        else:
            return True
    except: #no 'rel' found
        return True
    
def getTOC(page):
    try:
        nav = page.find("ul", class_="submenu menu-home")
        contents = nav.find_all("a")
        toc = list(filter(notAuthor, contents))
        toc = list(map(getURL, toc))
    except:
        print("| No nav found")
        return []
    return toc
'''
