#RCEdit: https://github.com/grrrr/rcedit/tree/master
from rcedit import RCEdit
import numpy as np
import os

exposition = 1732852 
rc = RCEdit(exposition)

rc.login(username='', password='')

pages = rc.page_list()

pagesAsInts = []
itemsAsInts = []
globalItemDic = {}
itemInPageDic = {}

listPagesAsArray = np.array(list(pages.items()))

for page in listPagesAsArray:
    pagesAsInts.append(int(str(page)[:9][2:]))

for page in pagesAsInts:
    items = rc.item_list(page)
    globalItemDic.update(items)
    listItemsAsArray = np.array(list(items.items()), dtype=object)
    for item in listItemsAsArray:
        asInt = int(str(item)[:9][2:])
        itemsAsInts.append(asInt)
        newDicEntry = {asInt: page}
        itemInPageDic.update(newDicEntry)

itemsAsInts.sort(reverse=True)

def writeHTML():
    root = "/var/www/html"
    path = "/rc/whoposted"
    #with open(root + path + "/index.html", 'w') as f:
    with open("./index.html", 'w') as f:
        f.write("<!DOCTYPE html>\n<html>\n<body>\n<pre>\n")
        f.write("<pre>Fields are: index, item, weave, weave title, url.</pre>")
        
    for i in range(len(itemsAsInts)):
        idx = i
        print(idx)
        weave = itemInPageDic[itemsAsInts[idx]]
        item_id = itemsAsInts[idx]
        item = rc.item_get(item_id)
        left = item[1]['style']['left']
        top = item[1]['style']['top']
        url = "https://www.researchcatalogue.net/view/" + str(exposition) + "/" + str(weave) + "/" + str(left) + "/" + str(top)

        #with open(root + path + "/index.html", 'a') as f:        
        with open("./index.html", 'a') as f:
            f.write(str(i) + " " + str(item_id) + " " + str(itemInPageDic[item_id]) + " " + str(pages[str(itemInPageDic[item_id])]) + " " + str(globalItemDic[str(item_id)]) + " <a href=\"" + str(url) + "\">" + str(url) + "</a> \n")

    #with open(root + path + "/index.html", 'a') as f:        
    with open("./index.html", 'a') as f:
        f.write("</pre>\n</body>\n</html>")
        
writeHTML()
print("done")
