from newsapi import NewsApiClient
from pprint import pprint
import datetime
from googletrans import Translator
from flask import jsonify
from flask import request
from flask import jsonify
from flask import Flask, url_for, redirect, render_template
import json
import textutils
import pickle
import numpy as np
import flask
import ipinfo
import datetime
import requests
# Init
global hin,eng,a,b,filtered_articles_copy
app = Flask(__name__)

@app.route('/eng')
def eng():
    global a,b,filtered_articles_copy
    #return render_template("index.html")
    translator = Translator()

# Init
    newsapi = NewsApiClient(api_key='9933009e1f5842a4a71e9f927df871a3')

    # set dates for articles
    yesterday = (datetime.date.today() - datetime.timedelta(days=1)).strftime('%Y-%m-%d')
    buffer_date = (datetime.date.today() - datetime.timedelta(days=10)).strftime('%Y-%m-%d')
# print(yesterday)
# print(buffer_date)

# keywords or phrases for filtering news
    phrases = 'farmers OR farming OR agriculture OR (crop AND production) OR crops OR (organic AND farming) OR (food AND crop)'

    # /v2/everything
    all_articles = newsapi.get_everything(qintitle=phrases,
                                          sources='the-hindu',
                                          domains='jagran.com,bhaskar.com,hindustantimes.com',
                                          from_param=buffer_date,
                                          to=yesterday,
                                          sort_by='publishedAt',
                                          page=1,
                                          page_size=20)

# list for getting desired articles
    filtered_articles = []

    articles = all_articles['articles']

    # Get the filtered articles
    for article in articles:
        del article['author']
        del article['content']
        del article['publishedAt']
        del article['source']
        filtered_articles.append(article)
        if len(filtered_articles) == 5:
            break

    eng = {}
    eng["news_eng"] = filtered_articles
    a = jsonify(eng)
    pprint(a)
    # pprint(filtered_articles)

# Make a copy to translate filtered articles
    filtered_articles_copy = filtered_articles.copy()
# pprint(filtered_articles_copy)

# lists for storing source text
    decription_text = []
    title_text = []

# Get all descriptions and titles
    for article in filtered_articles:
        for k, v in article.items():
            if k == 'description':
                decription_text.append(article[k])
            elif k == 'title':
                title_text.append(article[k])

# print(description_text)
# print(title_text)


    def translate_to_hindi(source):
        global a,b,filtered_articles_copy
        translations = translator.translate(source, dest='hi')
        text_list = []
        for translation in translations:
            text_list.append(translation.text)
        return text_list


# list for translated texts
    titles_translated = translate_to_hindi(title_text)
    desc_translated = translate_to_hindi(decription_text)

    # print(titles_translated)
# print(desc_translated)

# to get the required text from specified postion
    def get_only_one(source,position):
        global a,b,filtered_articles_copy
        return source[position]


    pos = -1
    # fill the dictionary with translated texts
    for article in filtered_articles_copy:
        pos += 1
        for k in article:
            article['description'] = get_only_one(desc_translated, pos)
            article['title'] = get_only_one(titles_translated, pos)

    pprint(a)
    return a
@app.route('/hin')
def hin():
    global filtered_articles_copy
    hin = {}
    hin["news_hindi"]= filtered_articles_copy
    x = json.dumps(hin, ensure_ascii=False).encode('utf8')
    #b = jsonify(hin)
    #Html.fromhtml("\u0936\u093e\u092f\u0930\u0940 \u090f\u0938...");
    #.htmlEncode(b)
    return x
#pprint(filtered_articles_copy)

if __name__ == "__main__":
    print("Its up and runnning!")
    app.run(port=5000)