import requests
from pprint import pprint
import ipinfo
import datetime
import json
from flask import request
from flask import jsonify
from flask import Flask, url_for, redirect, render_template
app = Flask(__name__)

@app.route('/')
def home():
    access_token = '47d69098973e6d'
    handler = ipinfo.getHandler(access_token)
    details = handler.getDetails()
    latitude = details.latitude
    longitude = details.longitude
    city = details.city
# data = details.all
# pprint(data)
# print('City : ', details.city)
# print('Latitude : ', latitude)
# print('Longitude: ', longitude)
    d={}
    url = 'https://api.openweathermap.org/data/2.5/onecall?lat={}&lon={}&exclude=hourly,minutely&appid=3beefac5e601b7bb443f36aede55e80c&units=metric'.format(latitude, longitude)

    res = requests.get(url)
    data = res.json()
# pprint(data)

    description_daywise = {}
    rain_daywise = {}
    main_rain_daywise = {}

    daily_data = data['daily']

    counter = -1
    for day in daily_data:
        counter = counter + 1
        try:
            rain_daywise[(datetime.date.today() + datetime.timedelta(days=counter)).strftime('%A')] = day['rain']

        except:
            day['rain'] = 0
            rain_daywise[(datetime.date.today() + datetime.timedelta(days=counter)).strftime('%A')] = day['rain']
    print("Day wise rainfall: \n", rain_daywise)
    d['Main_daily_rainfall_amt'] = rain_daywise

    counter1 = -1
    for day in daily_data:
        for main_key, main_value in day.items():
            if main_key == 'weather':
                for x in day[main_key]:
                    for key, value in x.items():
                        if key == 'description':
                            counter1 +=1
                            description_daywise[(datetime.date.today() + datetime.timedelta(days=counter1)).strftime('%A')] = x[key]

    print("Day wise rain: \n", description_daywise)
    d["Main_description"] = description_daywise

    counter2 = -1
    for day in daily_data:
        for main_key, main_value in day.items():
            if main_key == 'weather':
                for x in day[main_key]:
                    for key, value in x.items():
                        if key == 'main':
                            counter2 +=1
                        # main_rain_daywise['Day' + str(counter2)] = x[key]
                            main_rain_daywise[(datetime.date.today() + datetime.timedelta(days=counter2)).strftime('%A')] = x[key]
    print("Day wise Weather: \n", main_rain_daywise)
    #main=[]
    #for k, v in main_rain_daywise.items():
        ##main.append(u)
    d['Main_Weather'] = main_rain_daywise


    curr = 'https://api.openweathermap.org/data/2.5/onecall?lat={}&lon={}&exclude=hourly,minutely,daily&appid=3beefac5e601b7bb443f36aede55e80c&units=metric'.format(latitude, longitude)
    result = requests.get(curr)
    dta = result.json()
    d["current_weather"]=dta
    print(dta)
    return jsonify(d)
if __name__ == "__main__":
    print("Its up and runnning!")
    app.run(port=1500)

#y = json.dumps(daata)
#wjdata = json.loads(y)
