import numpy as np
import pandas as pd
import math
from flask import Flask, jsonify, request, make_response

data = pd.read_excel("newnew_1.xlsx")
df = pd.DataFrame(data)

for label, content in df.items():
    if pd.api.types.is_string_dtype(content):
        df[label] = content.astype("category").cat.as_ordered()

for label, content in df.items():
    if pd.api.types.is_numeric_dtype(content):
        if pd.isnull(content).sum():
            data[label+"_missing"] = pd.isnull(content)
            data[label] = content.fillna(content.median())

app = Flask(__name__)

@app.route('/graph/<string:crop>/<string:dis>', methods = ['GET'])
def method_name(crop,dis):
   res = yield__(crop, dis)
   return jsonify(res)

def yield__(crop,dis):
    a = df[(df['Crop'] == crop) & (df['District_name'] == dis)]

    a = a.sort_values(by = 'Year', ascending = False)
    
    b = []
    for i in (a['Year']).iteritems():
        b.append(int(i[1]))
    b = list(set(b))
    b.reverse()

    c = []
    for (i, j) in zip(b, range(5)):
        c.append(i)
    b = c

    pr=[]
    for i in range(len(b)):
            ai = a[(a['Year'] == b[i])]
            ai = float((ai['Production']).max())
            pr.append(ai)

    lst = [str(i) for i in b]
    rst = [str(i) for i in pr]
    res = dict(zip(lst, rst))
    return res

if __name__=='__main__':
    app.run(debug=True)