from flask import request
from flask import jsonify
from flask import Flask, redirect, render_template
import json
import pickle
import numpy as np
import requests
import flask
import ipinfo
import pandas as pd
import datetime
import pprint
global crop_year, area, state_name, district_name, crop, season, rainfall, prediction, __data_columns, __model
global main, crop_out, d, roundoff
global district, __yieldmodel, __yielddata_columns
global df, production_crop, june_sep_rainfall
app = Flask(__name__)

with open('artifacts/crop_predictor_final_tperha.pickle', 'rb') as f:
    __model = pickle.load(f)

with open("artifacts/columnsin_crop_predictor_tperha.json", 'r') as f:
    __data_columns = json.load(f)['data_columns']

with open('artifacts/yield_june_to_sep_rainfall.pickle', 'rb') as f:
    __yieldmodel = pickle.load(f)

with open("artifacts/columns_of_yeild_june_to_sep_rainfall.json", 'r') as f:
    __yielddata_columns = json.load(f)['data_columns']

@app.route('/')
def home():
    return render_template("index.html")


@app.route('/profitable_crop',methods=['GET'])
def predict():
    global crop_out, state_name, area, district_name, season
    global prediction, production_crop, roundoff
    global __data_columns, june_sep_rainfall
    global __model
    global y
    global d
    global wjdata
    global main, district, df
    global profitable_crop
    d = {}

    if request.method == 'GET':
        areaa = flask.request.args.get('area')
        area = float(areaa)
        yield_a = flask.request.args.get('yield')
        yield_aa = float(yield_a)
        state_name = flask.request.args.get('state_name')
        district_name = flask.request.args.get('district_name')
        season = flask.request.args.get('season')

        d["area"] = area
        d["yield"] = yield_aa
        d["state_name"] = state_name
        d["district_name"] = district_name
        d["season"] = season

        access_token = '47d69098973e6d'
        handler = ipinfo.getHandler(access_token)
        details = handler.getDetails()
        latitude = details.latitude
        longitude = details.longitude
        city = details.city

        url = 'https://api.openweathermap.org/data/2.5/onecall?lat={}&lon={}&exclude=hourly,minutely&appid=3beefac5e601b7bb443f36aede55e80c&units=metric'.format(
            latitude, longitude)

        res = requests.get(url)
        data = res.json()
        # pprint(data)

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
        #d["whole_year_rainfall"] = four_months
        june_sep_rainfall = four_months

        d["four_months_rainfall"] = june_sep_rainfall

        try:
            state_index = __data_columns.index(state_name.lower())
            season_index = __data_columns.index(season.lower())
            district_index = __data_columns.index(district_name.lower())
        except:
            state_index = -1
            season_index = -1
            district_index = -1

        x = np.zeros(len(__data_columns))
        x[0] = area
        x[1] = june_sep_rainfall
        x[2] = yield_aa

        if state_index >= 0:
            x[state_index] = 1
        if season_index >= 0:
            x[season_index] = 1
        if district_index >= 0:
            x[district_index] = 1

        prediction = __model.predict([x])[0]

        this_dict={
            0: 'Bajra', 1: 'Cotton(lint)', 2: 'Groundnut', 3: 'Jowar', 4: 'Maize', 5: 'Rice',
            6: 'Sugarcane', 7: 'Sunflower', 8: 'Tobacco', 9: 'Gram', 10: 'Wheat', 11: 'Sesamum',
            12: 'Linseed', 13: 'Small millets', 14: 'Turmeric', 15: 'Soyabean', 16: 'Rapeseed &Mustard',
            17: 'Dry ginger', 18: 'Jute', 19: 'Barley', 20: 'Black pepper', 21: 'Rubber', 22: 'Tea',
            23: 'Coffee'
        }
        crop_out=this_dict[prediction]
        d["profitable_crop"] = crop_out


        district = district_name
        district = district.upper()
        print(district)
        df = pd.read_csv("classification_crop.csv")
        df = df[(df['District'].str.contains(district, case=False)) & (df['Year'] >= 2010)]
        #q3 = df['Yield (t/ha)'].quantile(0.50)
        #Q3 = df['Production (t)'].quantile(0.50)
        df_tmp = df[ (df['Yield (t/ha)'] >= yield_aa)].Crop.value_counts()
        df_tmp = df_tmp.rename_axis("Crop").reset_index(name='Counts')
        crop_list = list(df_tmp['Crop'][:5])
        lst = [l.title() for l in crop_list]
        print(lst)
        d['also you can grow'] = lst
        print(crop_list)

        df = df[(df['District'].str.contains(district, case=False))  & (df['Year'] >= 2010)]
        production_crop = {}
        maxx=[]
        for crop in crop_list:
            max_produced = df[df["Crop"] == crop]["Yield (t/ha)"] .max()
            maxx.append(max_produced)
            production_crop[crop] = max_produced
            print(production_crop[crop])
        print(maxx)
        d['itsproduction'] = maxx
        print("YEH SAB UGAA :")
        for k, v in production_crop.items():
            print(k, v)

        #return jsonify(production_crop)


        return redirect("/profit_final_out?area={}&state_name={}&district_name={}&season={}&crop_out={}".format(area,state_name,district_name,season,crop_out))


@app.route('/profit_final_out', methods=["GET"])
def predict_yeild():
    global crop_year, area, state_name, district_name, crop_out, profitable_crop
    global prediction, crop_state_index, crop_season_index, crop_rainfall_index, profitable_crop_index
    global crop_district_index

    global y, roundoff
    global d , __yieldmodel, __yielddata_columns
    global wjdata, production_crop
    global main, crop_area, crop_state_name, crop_district_name, crop_season


    if request.method == 'GET':
        # crop_year = flask.request.args.get('crop_year')
        area = flask.request.args.get('area')
        state_name = flask.request.args.get('state_name')
        district_name = flask.request.args.get('district_name')
        crop = flask.request.args.get('crop_out')
        season = flask.request.args.get('season')
        # rainfall = flask.request.args.get('rainfall')
        crop_year = int(2010)
        n_area = float(area)
        june_sep_rainfall = roundoff*4*4

        try:
            state_index = __yielddata_columns.index(state_name.lower())
            season_index = __yielddata_columns.index(season.lower())
            crop_index = __yielddata_columns.index(crop.lower())
            district_index = __yielddata_columns.index(district_name.lower())
        except:
            state_index = -1
            season_index = -1
            crop_index = -1
            district_index = -1

        x = np.zeros(len(__yielddata_columns))
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

        d["profitable_crop_yeild_prediction"] = __yieldmodel.predict([x])[0]

    return jsonify(d,production_crop)


@app.route('/finalout')
def final_out():
    global d
    return jsonify(d)


if __name__ == "__main__":

    print("Its up and runnning!")

    app.run(port=3000)


























