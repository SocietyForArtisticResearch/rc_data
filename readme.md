# IMPORTANT:

This only works if you have RC_API repo in a parallel folder!

# Purpose

This is a command line tool to merge some JSON metadata together, so we don't have to do that on the client side.
Specifically we match any keywords that can be found in the abstract so we can render it later as hyperlinks.
Later, we can also merge all the screenshot paths into this.

The script is built using [Elm Posix](https://github.com/albertdahlin/elm-posixhttps://github.com/albertdahlin/elm-posix), which is an NPM package to write CLI tools in elm.
Once it will work you can run it using 

```bash
elm-cli run src/Main.elm
``` 


# screenshots and TOC
- [x] increased image size to 1920 x 1440
- [x] added inferred subpages search in default page (subpages not listed in TOC)
- [x] download path mirrors rc path
- [x] Have a list of expositions identified by id, and include the toc info:
- [x] Screenshot folder structure: exposition_id/page_id/index.png
- [x] "smart" zoom
- [ ] make it smarter
- [x] force download
- [x] wait to load pdf if "weave-text" found
- [ ] ? scroll (maybe not possible in --headless with chrome-driver)

# RC data
- [x] tools: get tool ID, position, size, rotation
- [x] text and simpletext: get tool ID, position, size, rotation + content
- [x] tested "tool-text", "tool-simpletext", "tool-picture", "tool-audio", "tool-video", "tool-shape", "tool-pdf","tool-slideshow",
- [x] works for weave-graphical and weave-block
- [ ] pdf, embed, iframe are untested
- [ ] extend to weave-text, weave-html
- [ ] include external hyperlinks in json
- [ ] detect scrollbars
- [ ] make exectuable with exposition ID
- [ ] transform: rotate(0deg) it's the user defined rotation

# RC metadata
- [ ] number of tools
- [ ] overlap (%)
- [ ] number of links to external content
- [ ] whitespace
- [ ] surface area of tools
- [ ] biggest tool 
- [ ] aspect ratio
- [ ] density
- [ ] regularity
- [ ] tool types
- [ ] number of rotated tools
- [ ] number of shapes 
- [ ] customized style settings (background, padding etc..)


## TODO's

[x] Are default positions correctly included in internal_research.json? (casper: yes)




# second step, include tool info:

content = {
    type_ : string
    , url / string / complex 
}

[
    {
        id : exposition_id (int)
        ,toc : [ { page_id (int) , page_title, url (string), screenshot (string)}]
        ,tools : [ tool_id (int) , tool_type (string), content  ]
    }
]

