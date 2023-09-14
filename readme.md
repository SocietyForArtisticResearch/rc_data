
# first step
Have a list of expositions identified by id, and include the toc info:

[
    {
        id : exposition_id (int)
        ,toc : [ { page_id (int) , page_title, url (string), screenshot (string)}]
    }
]

Screenshot folder structure:

exposition_id/page_id/anchor

exposition_id/page_id/default_position.png

## TODO's

Are default positions correctly included in internal_research.json?


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

