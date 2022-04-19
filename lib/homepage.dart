import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sih/dropdownitems.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sih/language.dart';
import 'package:sih/main.dart';
import 'package:sih/persistent.dart';
import 'package:sih/profitables.dart';
import 'package:sih/yeildpredictor.dart';
import 'localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  final Locale locale;
  HomePage({this.locale});

  @override
  _HomePageState createState() => _HomePageState();
}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
    print(data);
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
    print(notification);
  }

  return null;
}

class _HomePageState extends State<HomePage> {
  DateTime date;
  List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  Position _currentPosition;
  String ip = '104';

  String cropYear;
  String area;
  String stateName;
  String districtName;
  String cropName;
  String season;
  String rainfall;

  var news;
  var weatherResponse;
  var currentTemp;
  var floodDecoded;
  bool isFloodLoading = false;
  String subDivision;
  String currentRain;
  String newsLinkSuffix;
  String newsFormat;
  bool showFloodData = false;
  bool feedbackEnable = true;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  Future getdata(url) async {
    print(url);
    http.Response response = await http.get(url);
    print('2 : ' + url);
    return response.body;
  }

  weatherInfo(var weatherResponse) {
    setState(() {
      currentRain = weatherResponse['Main_description']
          [days[date.weekday - 1].toString()];
      currentTemp = weatherResponse['current_weather']['current']['temp'];
    });
  }

  newsVar(locale) {
    if (locale == 'hi') {
      setState(() {
        newsLinkSuffix = 'hin';
        newsFormat = 'hindi';
      });
    } else if (locale == 'en') {
      newsLinkSuffix = 'eng';
      newsFormat = 'eng';
    }
  }

  newsShow(news) {
    var newsRes = jsonDecode(news);
    print(newsRes.toString());
    for (var item in newsRes['news_hindi']) {
      print(item['title']);
      print(item['description']);
    }
  }

  final FirebaseMessaging _messaging = FirebaseMessaging();

  @override
  void initState() {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        weatherInfo(weatherResponse);
      },
      onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        weatherInfo(weatherResponse);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        weatherInfo(weatherResponse);
      },
    );

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      setState(() {});
    });

    _messaging.getToken().then((token) => print(token));
    date = DateTime.now();

    newsVar(widget.locale.languageCode);
    print(date.weekday);
    print(days[date.weekday - 1].toString());
    _getCurrentLocation().then((_currentPosition) => {
          getdata('http://192.168.0.$ip:1500/?latitude=' +
                  _currentPosition.latitude.toString() +
                  '&longitude=' +
                  _currentPosition.longitude.toString())
              .then((response) => {
                    weatherResponse = jsonDecode(response),
                    weatherInfo(weatherResponse),
                    print(jsonDecode(response)['Main_description']
                        [days[date.weekday - 1].toString()])
                  })
        });
    getdata('http://192.168.0.$ip:5000/hin').then((res) => newsShow(res));

    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => checkDate(DateTime.now()));
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

  String unique;

  String outputYeild;

  saveonDB() async {
    DocumentSnapshot docus =
        await Firestore().collection('yield-prediction').document(unique).get();
    print(unique);
    print(docus['7']);
    var docuss = docus;
    docuss['7']['cropname'] = 'maize';
    print(docuss);
    /* Firestore.instance
        .collection('yield-prediction')
        .document(unique)
        .updateData(docuss); */
  }

  addData(v5) async {
    DocumentSnapshot docref = await Firestore.instance
        .collection('yield-prediction')
        .document(v5)
        .get();

    if (docref.data == null) {
      Firestore.instance.collection('yield-prediction').document(v5).setData({
        'output': [
          {
            'area': area,
            'statename': stateName,
            'districtname': districtName,
            'cropname': cropName,
            'season': season,
            'outputyield': outputYeild
          },
        ]
      });
    } else {
      print('upadte hua ??');
      Firestore.instance
          .collection('yield-prediction')
          .document(v5)
          .updateData({
        'output': FieldValue.arrayUnion([
          {
            'area': area,
            'statename': stateName,
            'districtname': districtName,
            'cropname': cropName,
            'season': season,
            'outputyield': outputYeild
          },
        ])
      });
      print('update khatam');
    }
  }

  matched(double predicted, double output) {
    if (predicted - 100.0 > output && output < predicted + 100.0) {
      print(predicted - 100);
      print(output);
      print(predicted + 100);
      print('Looks like perfect prediction !!');
    } else if (predicted - 200.0 > output && output < predicted + 200.0) {
      print(predicted - 200);
      print(output);
      print(predicted + 200);
      print('pretty close but we will improve !!');
    } else if (predicted - 300.0 > output && output < predicted + 300.0) {
      print(predicted - 300);
      print(output);
      print(predicted + 300);
      print('still needs improvements ');
    } else {
      print('we will try better next time !!');
    }
  }

  results() async {
    DocumentSnapshot docref = await Firestore.instance
        .collection('yield-prediction')
        .document(unique)
        .get();
    DocumentSnapshot docrefOutput = await Firestore.instance
        .collection('yield-prediction')
        .document(unique)
        .get();

    for (var item in docref['predicted']) {
      /* print('match hua??');
      print(docrefOutput['output']); */
      /* print(item.toString());
      docrefOutput['output'][0]['area'] == item['area']
          ? print('area matched')
          : print('area not matched');

      docrefOutput['output'][0]['statename'] == item['statname']
          ? print('statename matched')
          : print('state not matched');

      docrefOutput['output'][0]['districtname'] == item['districtname']
          ? print('district matched')
          : print('district not matched');

      docrefOutput['output'][0]['cropname'] == item['cropname']
          ? print('crop matched')
          : print('crop not matched'); */

      if (docrefOutput['output'][0]['area'] == item['area'] &&
          docrefOutput['output'][0]['districtname'] == item['districtname'] &&
          docrefOutput['output'][0]['cropname'] == item['cropname']) {
        showAlertDialog(context, num.parse(item['predicted yield']),
            num.parse(docrefOutput['output'][0]['outputyield']));
      } else {
        print('no matches found');
      }
    }
  }

  feedbackForm() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return AlertDialog(
                contentTextStyle: TextStyle(fontSize: 14, color: Colors.black),
                backgroundColor: Colors.white,
                title: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Text('Feedback Form '),
                ),
                content: Padding(
                    padding: EdgeInsets.all(8),
                    child: Expanded(
                      child: ListView(
                        children: <Widget>[
                          TextField(
                            onChanged: (value) {
                              area =
                                  (num.parse(value) * 0.404685642).toString();
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    style: BorderStyle.none,
                                    color: Colors.green),
                              ),
                              hintText: 'Area',
                            ),
                          ),
                          TextField(
                            onChanged: (value) {
                              stateName = value;
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    style: BorderStyle.none,
                                    color: Colors.green),
                              ),
                              hintText: 'state name',
                            ),
                          ),
                          TextField(
                            onChanged: (value) {
                              districtName = value;
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    style: BorderStyle.none,
                                    color: Colors.green),
                              ),
                              hintText: 'district name',
                            ),
                          ),
                          TextField(
                            onChanged: (value) {
                              season = value;
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    style: BorderStyle.none,
                                    color: Colors.green),
                              ),
                              hintText: 'season you grew',
                            ),
                          ),
                          TextField(
                            onChanged: (value) {
                              outputYeild = value;
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    style: BorderStyle.none,
                                    color: Colors.green),
                              ),
                              hintText: 'Output you got',
                            ),
                          ),
                        ],
                      ),
                    )),
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      color: Colors.green[400],
                      onPressed: () {
                        addData(unique);
                        Navigator.pop(context);
                        results();
                      },
                      child: Text(
                        'submit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: EdgeInsets.all(8),
              );
            },
          );
        },
        barrierDismissible: true);
  }

  moreWeatherInfoDialog(weatherResponse) {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, setState) {
              return AlertDialog(
                contentTextStyle: TextStyle(fontSize: 14, color: Colors.black),
                backgroundColor: Colors.white,
                title: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Text('Weather Info'),
                ),
                content: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(getTranslated(context, 'Today')),
                          Text(getTranslated(
                              context,
                              weatherResponse['Main_description']
                                  [days[date.weekday - 1]])),
                          Text(weatherResponse['Main_daily_rainfall_amt'][days[
                                      date.add(Duration(days: 0)).weekday - 1]]
                                  .toString() +
                              'mm')
                        ],
                      ),
                      Divider(
                        thickness: 1,
                      ),

                      // <=========== 1 day later =============>
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(getTranslated(context,
                              days[date.add(Duration(days: 1)).weekday - 1])),
                          Text(getTranslated(
                              context,
                              weatherResponse['Main_description'][days[
                                  date.add(Duration(days: 1)).weekday - 1]])),
                          Text(weatherResponse['Main_daily_rainfall_amt'][days[
                                      date.add(Duration(days: 1)).weekday - 1]]
                                  .toString() +
                              'mm')
                        ],
                      ),
                      Divider(
                        thickness: 1,
                      ),

                      // <============= 2 days later =============>
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(getTranslated(context,
                              days[date.add(Duration(days: 2)).weekday - 1])),
                          Text(getTranslated(
                              context,
                              weatherResponse['Main_description'][days[
                                  date.add(Duration(days: 2)).weekday - 1]])),
                          Text(weatherResponse['Main_daily_rainfall_amt'][days[
                                      date.add(Duration(days: 2)).weekday - 1]]
                                  .toString() +
                              'mm')
                        ],
                      ),
                      Divider(
                        thickness: 1,
                      ),

                      // <============= 3 days later =============>

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            getTranslated(context,
                                days[date.add(Duration(days: 3)).weekday - 1]),
                            style: TextStyle(color: Colors.black),
                          ),
                          Text(getTranslated(
                              context,
                              weatherResponse['Main_description'][days[
                                  date.add(Duration(days: 3)).weekday - 1]])),
                          Text(weatherResponse['Main_daily_rainfall_amt'][days[
                                      date.add(Duration(days: 3)).weekday - 1]]
                                  .toString() +
                              'mm')
                        ],
                      ),
                      Divider(
                        thickness: 1,
                      ),

                      // <============= 4 days later =============>
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(getTranslated(context,
                              days[date.add(Duration(days: 4)).weekday - 1])),
                          Text(getTranslated(
                              context,
                              weatherResponse['Main_description'][days[
                                  date.add(Duration(days: 4)).weekday - 1]])),
                          Text(weatherResponse['Main_daily_rainfall_amt'][days[
                                      date.add(Duration(days: 4)).weekday - 1]]
                                  .toString() +
                              'mm')
                        ],
                      ),
                      Divider(
                        thickness: 1,
                      ),
                      // <============= 5 days later =============>
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(getTranslated(context,
                              days[date.add(Duration(days: 5)).weekday - 1])),
                          Text(getTranslated(
                              context,
                              weatherResponse['Main_description'][days[
                                  date.add(Duration(days: 5)).weekday - 1]])),
                          Text(weatherResponse['Main_daily_rainfall_amt'][days[
                                      date.add(Duration(days: 5)).weekday - 1]]
                                  .toString() +
                              'mm')
                        ],
                      ),
                      Divider(
                        thickness: 1,
                      ),
                      // <============= 6 days later =============>
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(getTranslated(context,
                              days[date.add(Duration(days: 6)).weekday - 1])),
                          Text(getTranslated(
                              context,
                              weatherResponse['Main_description'][days[
                                  date.add(Duration(days: 6)).weekday - 1]])),
                          Text(weatherResponse['Main_daily_rainfall_amt'][days[
                                      date.add(Duration(days: 6)).weekday - 1]]
                                  .toString() +
                              'mm')
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, top: 15),
                        child: Divider(
                          color: Colors.black,
                          thickness: 1,
                          endIndent: 20,
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Column(
                          children: <Widget>[
                            Text(
                              getTranslated(context,
                                      'Probability of flood occuring') +
                                  ': ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              child: DropdownButton(
                                isExpanded: true,
                                hint: Text(
                                    getTranslated(context, 'Sub Division')),
                                value: subDivision == null ? null : subDivision,
                                items:
                                    DropDownItems().subDivisions().map((value) {
                                  return DropdownMenuItem(
                                    child:
                                        new Text(getTranslated(context, value)),
                                    value: value,
                                  );
                                }).toList(),
                                onChanged: (newValue) async {
                                  setState(() {
                                    isFloodLoading = true;
                                  });

                                  var flood = await getdata(
                                      'http://192.168.0.$ip:4000/floodtest?state=' +
                                          newValue +
                                          '&latitude=' +
                                          _currentPosition.latitude.toString() +
                                          '&longitude=' +
                                          _currentPosition.longitude
                                              .toString());
                                  floodDecoded = jsonDecode(flood);
                                  setState(() {
                                    subDivision = newValue;
                                    showFloodData = true;
                                    isFloodLoading = false;
                                    print(subDivision);
                                  });
                                },
                              ),
                            ),
                            showFloodData
                                ? isFloodLoading
                                    ? Center(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 25.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 10.0),
                                            child: Text(
                                              getTranslated(
                                                      context, '% change') +
                                                  ': ' +
                                                  (getNumberTranslated(
                                                      context,
                                                      floodDecoded['% change']
                                                          .round()
                                                          .toString())),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 10.0),
                                            child: Text(getTranslated(context,
                                                    'total rainfall expected in this week') +
                                                ' : ' +
                                                getNumberTranslated(
                                                    context,
                                                    floodDecoded[
                                                            'total rainfall expected in this week']
                                                        .toString()) +
                                                'mm'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 10.0),
                                            child: Text(getTranslated(context,
                                                    'Weekly average rainfall in last 5 years') +
                                                ' : ' +
                                                getNumberTranslated(
                                                    context,
                                                    floodDecoded[
                                                            'weekly average rainfall of last 5 years']
                                                        .toString()) +
                                                'mm'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 10.0),
                                            child: Text(floodDecoded[
                                                'final statement from us']),
                                          ),
                                        ],
                                      )
                                : Container()
                          ],
                        ),
                      ),
                    ],
                  )),
                ),
                actions: <Widget>[],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: EdgeInsets.all(8),
              );
            },
          );
        },
        barrierDismissible: true);
  }

  showAlertDialog(BuildContext context, predicted, output) {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () {},
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Results"),
      content: Text('predicted : ' +
          predicted.toString() +
          '&' +
          'real output : ' +
          output),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  checkDate(DateTime date) {
    DateTime futureDate = DateTime(2020, 8, 03);
    if (date.isAfter(futureDate)) {
      print('dialog box dikahao');
      feedbackForm();
    } else {
      print('dialog box mat dikahao');
    }
  }

  getcounterLocale() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    String sharedUnique = _prefs.getString('unique');
    unique = sharedUnique;
    print(unique);
  }

  @override
  Widget build(BuildContext context) {
    void _changeLanguage(Language language) async {
      Locale _temp = await setLocale(language.languageCode);
      newsVar(_temp.languageCode);
      MyApp.setLocale(context, _temp);
    }

    getcounterLocale();
    print(newsLinkSuffix + '' + '' + newsFormat);
    print(widget.locale.languageCode.toString() + '-----------');

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text(DemoLocalization.of(context).getTranslatedValue('title')),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
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
                            children: <Widget>[
                              Text(getTranslated(context, lang.name))
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        fit: StackFit.loose,
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height,
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.18,
            width: MediaQuery.of(context).size.width,
            color: Colors.green,
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  currentRain == null
                      ? Center(
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.white,
                          ),
                        )
                      : Text(
                          getTranslated(context, days[date.weekday - 1]) +
                              " : " +
                              getTranslated(context, currentRain),
                          style: TextStyle(color: Colors.white, fontSize: 19),
                        ),
                  currentTemp == null
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : Text(
                          getTranslated(context, 'Current Temperature') +
                              " : " +
                              currentTemp.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 19),
                        ),
                  GestureDetector(
                    onTap: () {
                      moreWeatherInfoDialog(weatherResponse);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        getTranslated(context, 'See more info') + ' >',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.16,
            left: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              height: MediaQuery.of(context).size.height * 0.715,
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(20.0),
                            ),
                          ),
                          child: FutureBuilder<dynamic>(
                            future: getdata('http://192.168.0.$ip:5000/' +
                                newsLinkSuffix), // a Future<String> or null
                            builder: (BuildContext context,
                                AsyncSnapshot<dynamic> snapshot) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.waiting:
                                  return new Center(
                                    child: CircularProgressIndicator(),
                                  );
                                default:
                                  if (snapshot.hasError)
                                    return new Text('Error: ${snapshot.error}');
                                  else {
                                    var data1 = jsonDecode(snapshot.data);
                                    var data2 = data1['news_' + newsFormat];
                                    print(data1['news_' + newsFormat][0]
                                            .toString() +
                                        '--------------');

                                    return ListView(
                                      children: <Widget>[
                                        Card(
                                          elevation: 20,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0, vertical: 2),
                                            child: Center(
                                              child: Text(
                                                getTranslated(
                                                    context, 'News Updates'),
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 25,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.7,
                                          child: ListView.builder(
                                            itemBuilder: (context, index) {
                                              return Card(
                                                elevation: 20,
                                                child: ListTile(
                                                  title: Text(
                                                    data2[index]['title'],
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  subtitle: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      data2[index]
                                                          ['description'],
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            itemCount: data2.length,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                              }
                            },
                          )),
                    ),
                  ),
                  Container(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0.0),
                          child: RaisedButton(
                              elevation: 10,
                              color: Colors.green[400],
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => YeildPredictor()),
                                );
                              },
                              child: Row(
                                children: <Widget>[
                                  Text(
                                    getTranslated(context, 'yield prediction'),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0.0),
                          child: RaisedButton(
                            elevation: 10,
                            color: Colors.green[400],
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Profitables()),
                              );
                            },
                            child: Text(
                              getTranslated(context, 'profitable crop'),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
          /* Positioned(
            top: 50,
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      child: ListView(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              elevation: 20,
                              child: ListTile(
                                title: Text(
                                  'Card 1 heading',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Card 1 contents -  It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              elevation: 20,
                              child: ListTile(
                                title: Text(
                                  'Card 2 heading',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Card 2 contents -  It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              elevation: 20,
                              child: ListTile(
                                title: Text(
                                  'Card 3 heading',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Card 3 contents -  It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: RaisedButton(
                          elevation: 10,
                          color: Colors.green[400],
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => YeildPredictor()),
                            );
                          },
                          child: Text(
                            getTranslated(context, 'yield prediction'),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: RaisedButton(
                          elevation: 10,
                          color: Colors.green[400],
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Profitables()),
                            );
                          },
                          child: Text(
                            getTranslated(context, 'profitable crop'),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ), */
        ],
      ),
    );
  }
}
