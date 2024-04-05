#RCEdit: https://github.com/grrrr/rcedit/tree/master
from PIL import Image
import numpy as np
import os
from rcedit import RCEdit

rc = RCEdit(1732852)
page_id = 2150796 
mediaset_id = 2150704

rc.login(username='', password='')

xsum = 0
pagelist=os.listdir('/path/to/folder/')

for file in pagelist[:]: 
    if not(file.endswith(".png")):
        pagelist.remove(file)

for page in pagelist:
    media_id = rc.media_add(page, "copyright", "image", "public-domain", mediaset_id)
    png = '/path/to/folder/' + page
    print(png)
    im = np.array(Image.open(png))
    height = im.shape[0]
    width = im.shape[1]
    print(im.shape)
    rc.media_upload(media_id, png)
    item_id = rc.item_add(page_id, media_id, xsum, 500, width/3, height/3, 'picture')
    xsum = xsum + (width/3)