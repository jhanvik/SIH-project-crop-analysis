from flask import request
from flask import jsonify
from flask import Flask, url_for, redirect, render_template
import json
import pickle
import numpy as np
import flask
import ipinfo
import datetime
import requests
import zipfile
import pandas as pd
from zipfile import ZipFile
global crop_year, area, state_name, district_name, crop, season, rainfall, prediction, __data_columns, __model
global cropp, data
app = Flask(__name__)

data = pd.read_excel("newnew_1.xlsx")

@app.route('/')
def home():
    return render_template("index.html")


@app.route('/yeild_predictor_api',methods=['GET'])
def predict():
    global crop_year, n_crop_year, n_area, crop, district_name
    global prediction, cropp
    global __data_columns
    global __model
    global y
    global d
    global wjdata
    d = {}


    with open('yield_june_to_sep_rainfall.pickle', 'rb') as f:
        __model = pickle.load(f)

    with open("columns_of_yeild_june_to_sep_rainfall.json", 'r') as f:
        __data_columns = json.load(f)['data_columns']

    if request.method == 'GET':
        #crop_year = flask.request.args.get('crop_year')
        area = flask.request.args.get('area')
        state_name = flask.request.args.get('state_name')
        district_name = flask.request.args.get('district_name')
        crop = flask.request.args.get('crop')
        season = flask.request.args.get('season')
        #rainfall = flask.request.args.get('rainfall')
        crop_year = int(2010)
        n_area = float(area)

        cropp = crop
        access_token = '47d69098973e6d'
        handler = ipinfo.getHandler(access_token)
        details = handler.getDetails()
        latitude = details.latitude
        longitude = details.longitude
        #city = details.city

        url = 'https://api.openweathermap.org/data/2.5/onecall?lat={}&lon={}&exclude=hourly,minutely&appid=3beefac5e601b7bb443f36aede55e80c&units=metric'.format(latitude, longitude)

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
        d["rain_daywise"] = rain_daywise
        y = json.dumps(rain_daywise)
        wjdata = json.loads(y)
        add = (wjdata['Friday'] +
               wjdata['Saturday'] +
               wjdata['Sunday'] +
               wjdata['Monday'] +
               wjdata['Tuesday'] +
               wjdata['Wednesday'] +
               wjdata['Thursday'])
        roundoff = round(add, 2)
        four_months = roundoff * 4 * 4
        d["roundoff"] = roundoff
        d["four_months_rainfall"] = four_months
        june_sep_rainfall = four_months

        try:
            state_index = __data_columns.index(state_name.lower())
            season_index = __data_columns.index(season.lower())
            crop_index = __data_columns.index(crop.lower())
            district_index = __data_columns.index(district_name.lower())
        except:
            state_index = -1
            season_index = -1
            crop_index = -1
            district_index = -1

        x = np.zeros(len(__data_columns))
        x[0] = crop_year
        x[1] = n_area
        x[2] = june_sep_rainfall

        if state_index >= 0:
            x[state_index] = 1
        if season_index >= 0:
            x[season_index] = 1
        if crop_index >= 0:
            x[crop_index] = 1
        if district_index >= 0:
            x[district_index] = 1

        d["prediction"] = __model.predict([x])[0]
        
        return jsonify(d)

@app.route('/yeildpredictor_graph', methods=['GET'])
def yeildpredictor_graph():
    global cropp, crop
    global graph
    global data
    graph = {}
    dis = district_name
    cropp = crop
    cropp = cropp.title()
    print(cropp)
    df = pd.DataFrame(data)

    for label, content in df.items():
        if pd.api.types.is_string_dtype(content):
            df[label] = content.astype("category").cat.as_ordered()

    for label, content in df.items():
        if pd.api.types.is_numeric_dtype(content):
            if pd.isnull(content).sum():
                data[label + "_missing"] = pd.isnull(content)
                data[label] = content.fillna(content.median())

    a = df[(df['District_name'] == dis)]
    k = 0
    for i in (a['Crop']).iteritems():
        if str(i[1]) == cropp:
            k = k + 1
    if k == 0:
        err = "You cannot find graphs for the crop you requested"
        graph['error'] = err

    a = df[(df['Crop'] == cropp) & (df['District_name'] == dis)]

    a = a.sort_values(by='Year', ascending=False)

    b = []
    for i in (a['Year']).iteritems():
        b.append(int(i[1]))
    b = list(set(b))
    b.reverse()

    c = []
    for (i, j) in zip(b, range(5)):
        c.append(i)
    b = c

    pr = []
    for i in range(len(b)):
        ai = a[(a['Year'] == b[i])]
        ai = float((ai['Production']).max())
        pr.append(ai)

    lst = [str(i) for i in b]
    rst = [str(i) for i in pr]
    graph['crop_year_for_graph'] = lst
    graph['production_for_graph'] = rst
        #res = dict(zip(lst, rst))

    return jsonify(graph)















if __name__ == "__main__":
    print("Its up and runnning!")
    app.run(port=7000)


























