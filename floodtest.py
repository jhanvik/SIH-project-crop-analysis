import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from flask import jsonify
from flask import Flask, url_for, redirect, render_template
import flask
from flask import request
import ipinfo
import requests
import datetime
import json

app = Flask(__name__)
df = pd.read_csv('subdivisionwise_rainfall.csv')

@app.route('/')
def render_html():
    return render_template("index.html")

@app.route('/floodtest')
def get_alert():
    d = {}
    access_token = '47d69098973e6d'
    handler = ipinfo.getHandler(access_token)
    details = handler.getDetails()
    ip = details.ip
    lat = details.latitude
    lon = details.longitude
    #print(ip,lat,lon)
    d["latitude"] = lat
    d["longitude"] = lon

    url = 'https://api.openweathermap.org/data/2.5/onecall?lat={}&lon={}&exclude=hourly,minutely&appid=3beefac5e601b7bb443f36aede55e80c&units=metric'.format(lat,lon)

    res = requests.get(url)
    data = res.json()
    rain_daywise = {}
    daily_data = data['daily']
    counter = -1
    for day in daily_data:
        counter = counter + 1
        try:
            rain_daywise[(datetime.date.today() + datetime.timedelta(days=counter)).strftime('%A')] = day['rain']
        except:
            day['rain'] = 0
            rain_daywise[(datetime.date.today() + datetime.timedelta(days=counter)).strftime('%A')] = day['rain']

    y = json.dumps(rain_daywise)
    wjdata = json.loads(y)
    add = (wjdata['Friday'] + wjdata['Saturday'] + wjdata['Sunday'] + wjdata['Monday'] + wjdata['Tuesday'] + wjdata['Wednesday'] + wjdata['Thursday'])
    roundoff = round(add, 2)
    four_months = roundoff * 4 * 4
    #print("Four Months ",four_months)
    d["expected four months rainfall in your area"] = four_months


    if request.method == 'GET':
        state = flask.request.args.get('state')
    df = pd.read_csv('subdivisionwise_rainfall.csv')

    #four_months = 1514
    rainfall = four_months
    df = df[df['SUBDIVISION'].str.contains(state, case=False)]
    #print(df)
    df = df['JJAS'][13:18]
    #print(df)
    rainfall_list = list(df)
    avg_rain = sum(rainfall_list)/len(rainfall_list)
    #print("Estimated Rainfall: ",rainfall)
    #print("Average Rainfall in your area: ",avg_rain)
    d["average rainfall of last 5 years"] = avg_rain
    change = ((rainfall-avg_rain)/avg_rain) * 100
    #print('% Change: ',change)
    d["% change"] = change
    if change >=50:
        #print("Pehli fursat me nikal!")
        d["final statement from us"] = "Caution: Heavy Rainfall Alert! Some parts of your subdivision might get flood."
    elif (change >=20) & (change <50):
        #print("There is a 50% chance of flooding")
        d["final statement from us"] = "You may receive 30% to 40% more rainfall than usual"
    elif (change >= -20) & (change <0):
        #print("It may rain lesser than usual")
        d["final statement from us"] = "It may rain lesser than usual"
    elif (change< -20):
        #print("Bhai sab sookha padne waala hai")
        d["final statement from us"] = "Chances of drought is between 0 - 20%"
    elif (change< -50):
        #print("Bhai sab sookha padne waala hai")
        d["final statement from us"] = "Caution: Very less rainfall than usual! More Than 40% chance of drought"
    else:
        print("You are safe")
    #print(rainfall_list)


    return jsonify(d)


if __name__ == "__main__":
    print("Its up and runnning!")
    app.run(debug=True)
