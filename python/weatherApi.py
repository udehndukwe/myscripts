#Simple script to demonstrate API interaction

import json
import requests

r = requests.get('http://api.openweathermap.org/data/2.5/weather?zip=45231,us&appid=4449d0a3ef2826afe35d8ec97edae5a0')

data=r.json()

print(data['visibility'])