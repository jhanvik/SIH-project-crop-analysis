import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sih/dropdownitems.dart';
import 'package:sih/language.dart';
import 'package:sih/persistent.dart';
import 'package:sih/main.dart';
import 'localization.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/* */

class Profitables extends StatefulWidget {
  @override
  _ProfitablesState createState() => _ProfitablesState();
}

class _ProfitablesState extends State<Profitables> {
  String url;
  String graphUrl;
  List<String> states = ['Maharashtra', 'Gujarat'];

  List<String> maharashtra = ['Thane', 'Mumbai'];
  List<String> gujarat = ['Surendranagar', 'Ahmedabad'];
  List cropList;
  List cropListProduction;
  String ip = '104';

  var data;
  String cropYear;
  String area;
  String expectedyield;
  String stateName;
  String districtName;
  String cropName;
  String season;
  String rainfall;
  String profitableCrop = '';
  String itsProduction = '';
  bool isLoading = true;
  bool show = false;
  bool showDistricts = false;
  bool isTranslated = false;
  String changed;
  List<String> translatedDistricts = [];
  Position _currentPosition;

  @override
  Widget build(BuildContext context) {
    Future getdata(url) async {
      print(url);
      http.Response response = await http.get(url);
      print('2 : ' + url);
      return response.body;
    }

    void _changeLanguage(Language language) async {
      Locale _temp = await setLocale(language.languageCode);

      MyApp.setLocale(context, _temp);
    }

    Future<Position> _getCurrentLocation() async {
      final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

      Position position = await geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _currentPosition = position;
      });

      return _currentPosition;
    }

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text(getTranslated(context, 'profitable crop')),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton(
                onChanged: (Language language) {
                  _changeLanguage(language);
                },
                icon: Icon(
                  Icons.language,
                  color: Colors.white,
                ),
                items: Language.languageList()
                    .map<DropdownMenuItem<Language>>((lang) => DropdownMenuItem(
                          value: lang,
                          child: Row(
                            children: <Widget>[Text(lang.name)],
                          ),
                        ))
                    .toList(),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  area = (num.parse(value) * 0.404685642).toString();
                  print(area);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        style: BorderStyle.none, color: Colors.green),
                  ),
                  hintText: DemoLocalization.of(context)
                      .getTranslatedValue('area(acre)'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  expectedyield = (num.parse(value) / 1000).toString();
                  print(expectedyield + ': expected yield');
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          style: BorderStyle.none, color: Colors.green),
                    ),
                    hintText:
                        'yield' + '(' + getTranslated(context, 'kg') + ')'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                height: 60,
                padding: EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    isExpanded: true,
                    hint: Text(getTranslated(context, 'state name')),
                    value: stateName == null ? null : stateName,
                    items: DropDownItems().states().map((value) {
                      return DropdownMenuItem(
                        child: new Text(getTranslated(context, value)),
                        value: value,
                        onTap: () {
                          setState(() {
                            districtName = null;
                          });
                        },
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        stateName = newValue;

                        showDistricts = true;
                        print(stateName);
                      });
                    },
                  ),
                ),
              ),
            ),
            showDistricts
                ? Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: DropdownButton(
                          isExpanded: true,
                          underline: Container(
                            height: 1,
                            color: Colors.transparent,
                          ),
                          hint: Text(getTranslated(context, 'district name')),
                          value: districtName == null ? null : districtName,
                          items:
                              DropDownItems().districts(stateName).map((value) {
                            return DropdownMenuItem(
                              child: Text(getTranslated(context, value)),
                              value: value,
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              districtName = newValue;
                              print(districtName);
                            });
                          },
                        ),
                      ),
                    ),
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                height: 60,
                padding: EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    isExpanded: true,
                    hint: Text(getTranslated(context, 'season')),
                    value: season == null ? null : season,
                    items: DropDownItems().seasons().map((value) {
                      return DropdownMenuItem(
                        child: new Text(getTranslated(context, value)),
                        value: value,
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        season = newValue;

                        print(season);
                      });
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: RaisedButton(
                color: Colors.green[400],
                onPressed: () async {
                  setState(() {
                    show = true;
                  });
                  _currentPosition = await _getCurrentLocation();
                  url = 'http://192.168.0.$ip:3000/profitable_crop?' +
                      'area=' +
                      area.toString() +
                      '&yield=' +
                      expectedyield.toString() +
                      '&state_name=' +
                      stateName.toString() +
                      '&district_name=' +
                      districtName.toString() +
                      '&season=' +
                      season.toString() +
                      '&latitude=' +
                      _currentPosition.latitude.toString() +
                      '&longitude=' +
                      _currentPosition.longitude.toString();

                  print('URL : ' + url);

                  data = await getdata(url);

                  // <========= Assigning values=============>

                  //<============== noraml data===========>

                  var decodedData = jsonDecode(data);
                  var crop = decodedData[0]['profitable_crop'];
                  var production =
                      decodedData[0]['profitable_crop_yeild_prediction'];
                  List otherCrops = decodedData[0]['also you can grow'];
                  List otherCropsProduction = decodedData[0]['itsproduction'];

                  //<============== graph data ===============>

                  print(crop.toString() + '==============');
                  print(otherCrops);

                  setState(() {
                    profitableCrop = crop.toString();
                    itsProduction =
                        (num.parse(production.toString().split('.')[0]) * 1000)
                            .toString();
                    print(itsProduction);
                    print(itsProduction.length);
                    cropList = otherCrops;
                    cropListProduction = otherCropsProduction;

                    isLoading = false;
                  });

                  Firestore.instance
                      .collection('profitablesinputs')
                      .document()
                      .setData({
                    'area': area,
                    'statename': stateName,
                    'districtname': districtName,
                    'yield': expectedyield,
                    'season': season
                  });
                },
                child: Text(
                  DemoLocalization.of(context)
                      .getTranslatedValue('profitable crop'),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            show
                ? isLoading
                    ? Container(
                        child: Center(
                        child: CircularProgressIndicator(),
                      ))
                    : Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Center(
                          child: Container(
                              height: MediaQuery.of(context).size.height * 0.25,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      style: BorderStyle.solid,
                                      color: Colors.greenAccent,
                                      width: 3),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5))),
                              child: Padding(
                                padding: EdgeInsets.all(5),
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(getTranslated(
                                                  context, 'profitable crop') +
                                              ' : ' +
                                              getTranslated(
                                                  context, profitableCrop)),
                                        ),
                                        Text(getTranslated(
                                                context, 'production') +
                                            ' : ' +
                                            getNumberTranslated(context,
                                                    itsProduction.toString())
                                                .toString() +
                                            getTranslated(context, 'kg'))
                                      ],
                                    ),
                                    Divider(
                                      thickness: 2,
                                      color: Colors.greenAccent,
                                    ),
                                    Text(getTranslated(
                                        context, 'other profitable crops')),
                                    Expanded(
                                      child: Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.13,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: ListView.builder(
                                          itemBuilder: (context, index) {
                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                Text(getTranslated(
                                                      context,
                                                      cropList[index]
                                                          .toString(),
                                                    ) ??
                                                    cropList[index].toString()),
                                              ],
                                            );
                                          },
                                          itemCount: cropList.length,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              )),
                        ),
                      )
                : Container()
          ],
        ),
      ),
    );
  }
}

/* class Profitables extends StatefulWidget {
  @override
  _ProfitablesState createState() => _ProfitablesState();
}

class _ProfitablesState extends State<Profitables> {
  String url;

  var data;
  String cropYear;
  String area;
  String stateName;
  String districtName;
  String cropName;
  String season;
  String rainfall;
  String profitableCropYeildProduction = 'loading';
  String profitableCrop;

  @override
  Widget build(BuildContext context) {
    Future getdata(url) async {
      http.Response response = await http.get(url);
      return response.body;
    }

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text(
          getTranslated(context, 'title'),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                area = value;
              },
              decoration: InputDecoration(
                hintText: getTranslated(context, 'area'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                stateName = value;
              },
              decoration: InputDecoration(
                hintText: getTranslated(context, 'state name'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                districtName = value;
              },
              decoration: InputDecoration(
                hintText: getTranslated(context, 'district name'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                season = value;
              },
              decoration: InputDecoration(
                hintText: getTranslated(context, 'season'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RaisedButton(
              onPressed: () async {
                url = 'http://192.168.0.$ip:3000/profitable_crop?' +
                    'area=' +
                    area.toString() +
                    '&state_name=' +
                    stateName.toString() +
                    '&district_name=' +
                    districtName.toString() +
                    '&season=' +
                    season.toString();

                print('URL : ' + url);

                data = await getdata(url);
                var decodedData = jsonDecode(data);
                var crop = decodedData[0]['profitable_crop'];

                var production =
                    decodedData[0]['profitable_crop_yeild_prediction'];

                print(crop.toString() + '==============');
                print(production.toString() + '==============');

                setState(() {
                  profitableCrop = crop.toString();
                  profitableCropYeildProduction = production.toString();
                });
              },
              child: Text(getTranslated(context, 'profitable crop')),
            ),
          ),
          Text('profitable crop : ' + profitableCrop),
          Text('Proitable crop yeild : ' + profitableCropYeildProduction),
          Container(
            height: 200,
          )
        ],
      ),
    );
  }
}

/* class Profitables extends StatefulWidget {
  @override
  _ProfitablesState createState() => _ProfitablesState();
}

class _ProfitablesState extends State<Profitables> {
  String url;

  var data;
  String cropYear;
  String area;
  String stateName;
  String districtName;
  String cropName;
  String season;
  String rainfall;
  String profitableCropYeildProduction = 'loading';
  String profitableCrop;

  Future getdata(url) async {
    http.Response response = await http.get(url);
    return response.body;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text(getTranslated(context, 'title')),
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                area = value;
              },
              decoration: InputDecoration(
                hintText: getTranslated(context, 'area'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                stateName = value;
              },
              decoration: InputDecoration(
                hintText: getTranslated(context, 'state name'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                districtName = value;
              },
              decoration: InputDecoration(
                hintText: getTranslated(context, 'district name'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                season = value;
              },
              decoration: InputDecoration(
                hintText: getTranslated(context, 'season'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RaisedButton(
              onPressed: () async {
                url = 'http://192.168.0.$ip:3000/profitable_crop?' +
                    'area=' +
                    area.toString() +
                    '&state_name=' +
                    stateName.toString() +
                    '&district_name=' +
                    districtName.toString() +
                    '&season=' +
                    season.toString();

                print('URL : ' + url);

                data = await getdata(url);
                var decodedData = jsonDecode(data);
                var crop = decodedData[0]['profitable_crop'];

                var production =
                    decodedData[0]['profitable_crop_yeild_prediction'];

                print(crop.toString() + '==============');
                print(production.toString() + '==============');

                setState(() {
                  profitableCrop = crop.toString();
                  profitableCropYeildProduction = production.toString();
                });
              },
              child: Text(getTranslated(context, 'profitable crop')),
            ),
          ),
          Text('profitable crop : ' + profitableCrop),
          Text('Proitable crop yeild : ' + profitableCropYeildProduction),
          Container(
            height: 200,
          )
        ],
      ),
    );
  }
} */
 */
