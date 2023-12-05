# readme
- rc_soup_main
```
  python rc_soup_main.py https://www.researchcatalogue.net/view/835089/835129 0
```
- rc_data
```
pip install flask
pip install waitress
export FLASK_APP=rc_data
flask run
```
then request exposition:
```
http://127.0.0.1:8080/rcget/835089/835129
```
TODO
[ ] check parsedAbstract
[ ] Currently pageurl and type are kept in seperated lists, which means I have to look up the type using the ID. I suggest we combine the url and type like so:
  pages : { 

DONE
- match dimensions (int, int, int, int)
- return page type (pageID, pagetype)
