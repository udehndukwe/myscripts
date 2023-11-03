#Search discography of artist by typing in their name

#wikipedia module documentation citation: https://pypi.org/project/wikipedia/

import wikipedia

var = input("Enter artist name: ")
var = str(var)
try:
    content = wikipedia.page(var, auto_suggest=False).section("Discography")
    print(content)
    
except wikipedia.exceptions.DisambiguationError as list:
    print(list)
    nextinput = input("Oops, which " + var + " were you referring to? Type it in here: ")
    content = wikipedia.WikipediaPage(nextinput).section("Discography")
    
    print(content)


 
