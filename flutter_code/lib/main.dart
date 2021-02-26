import 'dart:convert' as convert;
import 'dart:html' hide Animation;
import 'dart:html' as html;
import 'dart:math' show sqrt, log;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps/google_maps.dart' hide Icon;
import 'package:gtag_analytics/gtag_analytics.dart';
import 'package:http/http.dart' as http;

import 'external_content.dart';
import 'popup.dart';
import 'popup_content.dart';
import 'timeseries_widget.dart';


//import 'package:google_maps/google_maps_LIBRARY1.dart';
//import 'package:google_maps/google_maps_LIBRARY2.dart';

void main() => runApp(MyApp());
final ga = new GoogleAnalytics(failSilently: true);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coronavirus Tracker',
      theme: ThemeData(
        // Define the default brightness and colors.
        brightness: Brightness.dark,
        primaryColor: Color(0xFFbf360c),
        accentColor: Colors.cyan[600],

        // Define the default font family.
        fontFamily: 'Helvetica',

        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: TextTheme(
          headline: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          title: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
          body1: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
        ),
      ),
      home: MyHomePage(title: 'Coronavirus Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool loaded = false;

  List<dynamic> provData = List<dynamic>();
  List<dynamic> allData = List<dynamic>();


  List<dynamic> dashData = List<dynamic>();
  List<dynamic> currentDash = List<dynamic>();
  List<dynamic> countryData = List<dynamic>();
  List<dynamic> currentCountry = List<dynamic>();
  List<dynamic> currentProv = List<dynamic>();

  var timeseries;
  List<String> countryName = List<String>();
  int numConfirmed = 0;
  int numDeath = 0;
  int numRecovered = 0;
  var country_flag_map;
  var firstGridData = [];

  List<dynamic> applyFilter(List<dynamic> data, String filter) {
    if (filter == null || filter == "") {
      return data;
    } else {
      var test = data
          .where((i) =>
              i["Country/Region"].toLowerCase().contains(filter.toLowerCase()))
          .toList();
      return test;
    }
  }


  List<dynamic> applyProv(List<dynamic> data, String filter) {
    if (filter == null || filter == "") {
      return data;
    } else {
      var test = data
          .where((i) =>
          i["Combined_Key"].toLowerCase().contains(filter.toLowerCase())
      )
          .toList();
      return test;
    }
  }
  List<dynamic> applyFilterStart(List<dynamic> data, String filter) {
    if (filter == null || filter == "") {
      return data;
    } else {
      var test = data
          .where((i) =>
          i["Country/Region"]
              .toLowerCase()
              .startsWith(filter.toLowerCase()))
          .toList();
      return test;
    }
  }

  List<dynamic> removeNotState(List<dynamic> data) {
    var test = data
        .where((i) =>
    i["Province/State"]
        .trim() != "")
        .toList();
    return test;
  }


  List<dynamic> applyDashFilter(List<dynamic> data, String filter) {
    if (filter == null || filter == "") {
      return data;
    } else {
      var test = data
          .where((i) =>
      i["title"].toLowerCase().contains(filter.toLowerCase()) ||
          i["description"].toLowerCase().contains(filter.toLowerCase())
      )
          .toList();
      return test;
    }

  }

  buildVariables() async {
    numConfirmed = int.parse(metadata["columns_meta"]["Confirmed"]["total"]);
    numDeath = int.parse(metadata["columns_meta"]["Deaths"]["total"]);
    numRecovered = int.parse(metadata["columns_meta"]["Recovered"]["total"]);
    country_flag_map = metadata["country_meta"];
    countryName = country_flag_map.keys.toList();
    countryName.sort();

    firstGridData = [
      {
        "header": "Total Cases",
        "description": '${combined["confirmed"]}',
        "footer": "Total Infection Reported",
        "color": Colors.yellow,
        "timeseries_path": ["confirmed", "!summary", "total"]
      },



      {
        "header": "Recovered",
        "description": "${getPercent(int.parse(combined["recovered"]),
            int.parse(combined["confirmed"]))} %",
        "footer": '${combined["recovered"]}',
        "color": Colors.greenAccent,
        "timeseries_path": ["recovered", "!summary", "total"]
      },
      {
        "header": "Deaths",
        "description": "${getPercent(int.parse(combined["deaths"]),
            int.parse(combined["confirmed"]))} %",
        "footer": '${combined["deaths"]}',
        "color": Colors.redAccent,
        "timeseries_path": ["death", "!summary", "total"]
      },
      {
        "header": "Active Cases",
        "description":
        "${getPercent(int.parse(combined["active_case"]),
            int.parse(combined["confirmed"]))} %",
        "footer": '${combined["active_case"]} are currently sick',
        "color": Colors.orange,

        "url": 'https://datastudio.google.com/embed/reporting/8b0b2857-1f24-4e1f-b4e9-df7082dafe72/page/WGiJB'
      },


      {
        "header": "Serious Cases",
        "description": "${getPercent(int.parse(combined["serious_case"]),
            int.parse(combined["confirmed"]))} %",
        "footer": '${combined["serious_case"]} people with serious condition',
        "color": Colors.brown[300],

        "url": 'https://datastudio.google.com/embed/reporting/8b0b2857-1f24-4e1f-b4e9-df7082dafe72/page/ykiJB'
      },

      {
        "header": "Countries Affected",
        "description": '${combined["country"]}',
        "footer": "Out of 197 Countries",
        "color": Colors.lightBlueAccent,

        "url": 'https://datastudio.google.com/embed/reporting/8b0b2857-1f24-4e1f-b4e9-df7082dafe72/page/YriJB'
      },

      {
        "header": "Happening Today",
        "description":
        'Added today',
        "footer": '${combined["new_deaths"]} death & ${combined["new_case"]} infection',
        "color": Colors.lightGreenAccent,

        "url": 'https://datastudio.google.com/embed/reporting/8b0b2857-1f24-4e1f-b4e9-df7082dafe72/page/SmiJB'
      },


      {
        "header": "Data Information",
        "description": "${combined["updated"]}",
        "footer": 'updated',
        "color": Colors.lightGreen,
        "url": 'https://datastudio.google.com/embed/reporting/8b0b2857-1f24-4e1f-b4e9-df7082dafe72/page/HsXIB'
      },
    ];
    setState(() {
      firstGridData;
    });
  }


  Widget getMap() {
    String htmlId = "7";

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(htmlId, (int viewId) {
      final myLatlng = LatLng(-25.363882, 131.044922);

      final mapOptions = new MapOptions()

        ..minZoom = 1
        ..maxZoom = 15
        ..mapTypeControl = true
        ..streetViewControl = false
        ..zoomControl = true
        ..zoomControlOptions = (ZoomControlOptions()
          ..style = ZoomControlStyle.DEFAULT
          ..position = ControlPosition.LEFT_TOP) // puts the zoom icons to the right
       // ..zoomControlOptions = type style zoomcontrolOptions
        ..zoom = 4
        ..clickableIcons = false


//        ..styles = <MapTypeStyle>[
//          MapTypeStyle()
//            ..stylers = <MapTypeStyler>[
//              MapTypeStyler()..hue = '#808080	',
//            ],
//          MapTypeStyle()
//            ..elementType = MapTypeStyleElementType.LABELS_TEXT_FILL
//            ..stylers = <MapTypeStyler>[
//              MapTypeStyler()..color = '#616161'
//            ],
//          MapTypeStyle()
//            ..elementType = MapTypeStyleElementType.LABELS_TEXT_STROKE
//            ..stylers = <MapTypeStyler>[
//              MapTypeStyler()..color = '#f5f5f5'
//            ],
//          MapTypeStyle()
//            ..elementType = MapTypeStyleElementType.GEOMETRY
//            ..stylers = <MapTypeStyler>[
//              MapTypeStyler()..color = '#f5f5f5'
//            ],
//          MapTypeStyle()
//            ..featureType = MapTypeStyleFeatureType.WATER
//            ..stylers = <MapTypeStyler>[
//              MapTypeStyler()..color = '#0084E1'
//            ]
//        ]
        ..center = LatLng(37.09024, -95.712891);

      final elem = DivElement()
        ..id = htmlId
        ..style.width = "100%"
        ..style.height = "100%"
        ..style.border = 'none';

      final map = new GMap(elem, mapOptions);

      // Prevents dragging infinitely North and South into grey area
      var lastValidCenter = map.center;
      var maxLat = 73;
      var minLat = -73;
      map.onCenterChanged.listen((e) {
        var center = map.center;
        var lat = map.center.lat;
        lastValidCenter = map.center;
        if(lat < minLat){
          map.panTo(LatLng(-70,center.lng));
          return;
        }
        else if(lat > maxLat){
          map.panTo(LatLng(70,center.lng));
          return;
        }
    }); // end of function that prevents dragging north and south


      for (final e in allData) {

        try{
          var conf = int.parse(e["Confirmed"]);
          if (conf < 1) {
            continue;
          }

          var location = "";
          if(e['Combined_Key'] != ""){
            location = "<b>${e['Combined_Key']} <\/b><br>";
          }
          else{
            location = '<b>${e['Country/Region']}<\/b><br>';
          }
          var contentString = ' $location Confirmed: ${e['Confirmed']}<br>Deaths: ${e['Deaths']}<br>Recovered: ${e['Recovered']}';


//        var radius =   (sqrt(int.parse(e["Confirmed"]) +1 as int) * 1000);
          var radius = log(conf + 1) * 18880 + conf;
          if (e['Country/Region'] == "US"){
            radius = 500+ log(conf + 1) * 1500 + conf;
          }

          var loc =
          LatLng(double.parse(e["Latitude"]), double.parse(e["Longitude"]));

          final populationOptions = CircleOptions()
            ..strokeColor = '#FF0000'
            ..strokeOpacity = 0.45
            ..strokeWeight = 2
            ..fillColor = '#FF0000'
            ..fillOpacity = 0.35
            ..map = map
            ..center = loc
            ..radius = radius;
          var circle = Circle(populationOptions);
          // allows clicking on a circle and opening the tooltip
          final infowindow = InfoWindow(InfoWindowOptions()
            ..content = contentString
            ..position = loc
          );
          circle.onClick.listen((e){
            infowindow.open(circle.map,circle);
          });


        } catch (err){
          print(e);
          print(err);


        }




      }

      return elem;
    });

    return HtmlElementView(viewType: htmlId);
  }

  cleanProv() async {
    var prov = removeNotState(provData);
    setState(() {
      provData = prov;
      currentProv = provData;
    });
  }

  buildCountry() {
    Map<String, dynamic> mapCountry = Map<String, dynamic>();


    for (final e in currentProv) {
      //
      var currentElement = e;
      var deaths = int.parse(currentElement["Deaths"]);
      var confirmed = int.parse(currentElement["Confirmed"]);
      var recovered = int.parse(currentElement["Recovered"]);
      var name = currentElement["Country/Region"];

      if (mapCountry.length > 0 && mapCountry.containsKey(name)) {
        deaths = mapCountry[name]["Deaths"] + deaths;
        confirmed = mapCountry[name]["Confirmed"] + confirmed;
        recovered = mapCountry[name]["Recovered"] + recovered;

        mapCountry[name] = {
          "Deaths": deaths,
          "Confirmed": confirmed,
          "Recovered": recovered,
          "Country/Region": name
        };
      } else {
        mapCountry.putIfAbsent(
            name,
                () =>
            {
              "Deaths": deaths,
              "Confirmed": confirmed,
              "Recovered": recovered,
              "Country/Region": name
            });
      }
    }
    currentCountry = List<dynamic>();


    var sortedKeys = mapCountry.keys.toList()
      ..sort();
    var keys = mapCountry.keys.toList();

    for (final e in keys) {
      countryData.add(mapCountry[e]);
    }
    setState(() {
      currentCountry = countryData;

    });
  }

  int getPercent(int num, int num2) {
    if (num2 == null) {
      num2 = numConfirmed;
    }
    if (num2 == 0) {
      return 0;
    }
    var ret = num / num2 * 100;
    return ret.toInt();
  }

  var metadata;
  var combined;

  gaSend(String e) async {
    ga.sendCustom(e);
  }

  getData() async {
    var URLs = {
      "confirmed":
      "https://raw.githubusercontent.com/zmsp/coronavirus-json-api/master/v2/time_series_covid19_confirmed_global.json",
      "death":
      "https://raw.githubusercontent.com/zmsp/coronavirus-json-api/master/v2/time_series_covid19_deaths_global.json",
      "recovered":
      "https://raw.githubusercontent.com/zmsp/coronavirus-json-api/master/v2/time_series_covid19_recovered_global.json"
    };
    var tmp_timeseries = {};

    for (final e in ["confirmed", "death", "recovered"]) {
      var response = await http.get(URLs[e]);

      if (response.statusCode == 200) {
        // var jsonResponse = convert.jsonDecode(response.body);

        var decoded = convert.json.decode(response.body);
        tmp_timeseries[e] = decoded;
      }
    }
    setState(() {
      timeseries = tmp_timeseries;
    });
  }

  getProductsApi() async {
    // print(response);
    var response;

    response = await http.get(
        "https://raw.githubusercontent.com/zmsp/coronavirus-json-api/master/v2/combine_summary.json");
    if (response.statusCode == 200) {
      // var jsonResponse = convert.jsonDecode(response.body);

      var decoded = convert.json.decode(response.body);

      setState(() {
        combined = decoded;
      });
      response = await http.get(
        "https://raw.githubusercontent.com/zmsp/coronavirus-json-api/master/v2/metadata.json");
    if (response.statusCode == 200) {
      // var jsonResponse = convert.jsonDecode(response.body);

      var decoded = convert.json.decode(response.body);

      setState(() {
        metadata = decoded;
      });

      setState(() {
        loaded = true;
      });
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }


      setState(() {
        loaded = true;
      });
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }


    response = await http.get(
        "https://raw.githubusercontent.com/zmsp/coronavirus-json-api/master/v2/latest_daily_report.json");
    if (response.statusCode == 200) {
      // var jsonResponse = convert.jsonDecode(response.body);
      var decodedCategories = convert.jsonDecode(response.body);
      provData = decodedCategories;
      currentProv = provData;
      allData = decodedCategories;

      buildCountry();

    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }
    cleanProv();
    buildVariables();


    response = await http.get(
        "https://raw.githubusercontent.com/zmsp/coronavirusdashboard/master/dashboards.json");
    if (response.statusCode == 200) {
      // var jsonResponse = convert.jsonDecode(response.body);
      var decodedCategories = convert.jsonDecode(response.body);
      dashData = decodedCategories;
      currentDash = dashData;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return null;
    }

    setState(() {

    });



  }

  @override
  void initState() {
    // TODO: implement initState

    getProductsApi().then((result) {
      setState(() {});
    });
    getData();
    super.initState();
  }

  ScrollController _controller = new ScrollController();
  TextEditingController searchController = new TextEditingController();
  var focusNode = new FocusNode();

  final countryKey = new GlobalKey();
  final provKey = new GlobalKey();
  final statsKey = new GlobalKey();

  final dashKey = new GlobalKey();
  filterByValue(value, bool start) async {
    if (value == null || value.trim() == "") {
      setState(() {
        currentCountry = countryData;
        currentProv = provData;
        currentDash = dashData;
      });
    } else {
      setState(() {
        currentCountry = start
            ? applyFilterStart(countryData, value)
            : applyFilter(countryData, value);
        currentProv = currentProv = applyProv(provData, value);
        currentDash = applyDashFilter(dashData, value);
      });
    }
  }

  void _goToElement(int index) {
    _controller.animateTo((100.0 * index),
        // 100 is the height of container and index of 6th element is 5
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut);
  }

  void goEnd(int index) {
    _controller.jumpTo(100.0);
  }


  void reloadData() {
    setState(() {
      currentCountry = countryData;

      currentProv = provData;
      currentDash = dashData;
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery
        .of(context)
        .size;

    /*24 is for notification bar on Android*/
    final column = 10;
    final double itemHeight = (size.height - kToolbarHeight - 24) / column;
    final double itemWidth = size.width / column;

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          title: TextField(
            onTap: () {
              Scrollable.ensureVisible(countryKey.currentContext);
            },
            focusNode: focusNode,
            controller: searchController,
            onChanged: (value) {
              filterByValue(value, false);
            },
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ),
              hintText: "Search Location here",
              hintStyle: TextStyle(color: Colors.white),
              suffixIcon: IconButton(
                onPressed: () {
                  reloadData();
                  searchController.clear();
//
                },
                icon: Icon(Icons.clear),
              ),
            ),
          )),
      drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text("Coronavirus Tracker",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18),
                      ),
                      Text("Made by Zobair, with love",
                        style: const TextStyle(
                            color: Colors.white),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),

                      ),
                      Row(
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.all(10),
                            child: Tooltip(
                              message: 'Share coronavirus dashboard on Facebook',
                              child: IconButton(
                                icon: FaIcon(FontAwesomeIcons.facebook,
                                    color: Colors.blueAccent),
                                highlightColor: Colors.blueAccent,
                                onPressed: () {
                                  String url =
                                      'https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fcoronavirusdashboard.live%2F';
                                  html.window.open(url, '_blank');
                                },
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.all(10),
                            child: Tooltip(
                              message: 'Share coronavirus dashboard on twitter',
                              child: IconButton(
                                icon: FaIcon(FontAwesomeIcons.twitter,
                                    color: Colors.lightBlueAccent),
                                highlightColor: Colors.lightBlueAccent,
                                onPressed: () {
                                  String url =
                                      'https://twitter.com/intent/tweet?url=https%3A%2F%2Fcoronavirusdashboard.live%2F&text=View%20coronavirus%20historical%20data';
                                  html.window.open(url, '_blank');
                                },
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.all(10),
                            child: Tooltip(
                              message: 'Share coronavirus dashboard on linkedin',
                              child: IconButton(
                                icon: FaIcon(FontAwesomeIcons.linkedin,
                                    color: Colors.blue),
                                highlightColor: Colors.blueAccent,
                                onPressed: () {
                                  String url =
                                      'https://www.linkedin.com/shareArticle?mini=true&url=http://coronavirusdashboard.live/&title=&summary=Track coronavirus with coronavirus.icu&source=';
                                  html.window.open(url, '_blank');
                                },
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.all(10),
                            child: Tooltip(
                              message: 'Feedback? ',
                              child: IconButton(
                                icon: FaIcon(FontAwesomeIcons.heart,
                                    color: Colors.redAccent),
                                highlightColor: Colors.greenAccent,
                                onPressed: () {
                                  String url =
                                      'https://gitreports.com/issue/zmsp/coronavirusdashboard';
                                  html.window.open(url, '_blank');
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


                decoration: BoxDecoration(
                  color: Colors.white12,
                ),
              ),
              ListTile(

                leading: FaIcon(FontAwesomeIcons.table),
                title: Text('Explore the data'),
                dense: true,
                onTap: () {
                  gaSend("pressed_explore");
                  Navigator.pop(context);
                  showExternalPopup(
                      context,
                      "About This Project",
                      'https://coronavirusdashboard.live/analysis/data.html'
                  );

                  gaSend("pressed_about");
                },
              ),

              ListTile(

                leading: FaIcon(FontAwesomeIcons.diagnoses),
                title: Text('Analyze the data'),
                dense: true,
                onTap: () {
                  gaSend("pressed_analyze");
                  Navigator.pop(context);
                  showExternalPopup(
                      context,
                      "About This Project",
                      'https://coronavirusdashboard.live/analysis/index.html'
                  );

                  gaSend("pressed_about");
                },
              ),



              ListTile(

                leading: FaIcon(FontAwesomeIcons.info),
                title: Text('About This Project'),
                dense: true,
                onTap: () {
                  gaSend("pressed_learn");
                  Navigator.pop(context);
                  showExternalPopup(
                      context,
                      "About This Project",
                      'https://www.zobairshahadat.com/datascience/i-see-u-coronavirus/'
                  );

                  gaSend("pressed_about");
                },
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.table),
                title: Text('About the data'),
                dense: true,
                onTap: () {
                  String url = 'https://github.com/zmsp/coronavirus-json-api';
                  html.window.open(url, '_blank');
                  Navigator.pop(context);
                  gaSend("pressed_api");
                },
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.map),
                title: Text('Map'),
                dense: true,
                onTap: () {
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                  _goToElement(0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.chartPie),
                title: Text('Dashboards'),
                dense: true,
                onTap: () {
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                  Scrollable.ensureVisible(dashKey.currentContext);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.listOl),
                title: Text('Statistics'),
                dense: true,
                onTap: () {
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                  Scrollable.ensureVisible(statsKey.currentContext);
                  Navigator.pop(context);
                  gaSend("pressed_stats");
                },
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.globe),
                title: Text('Countries'),
                dense: true,
                onTap: () {
                  setState(() {});
                  Scrollable.ensureVisible(countryKey.currentContext);
                  Navigator.pop(context);
                  gaSend("pressed_countries");
                },
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.flagUsa),
                title: Text('Provances'),
                dense: true,
                onTap: () {
                  // Update the state of the app
                  // ...
                  Scrollable.ensureVisible(provKey.currentContext);

                  Navigator.pop(context);
                  gaSend("pressed_provances");
                },
              ),
              GridView.count(
                  shrinkWrap: true,
                  // Create a grid with 2 columns. If you change the scrollDirection to
                  // horizontal, this produces 2 rows.
                  crossAxisCount: 1,
                  childAspectRatio: 6,
                  padding: const EdgeInsets.all(0.0),
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  physics: const NeverScrollableScrollPhysics(),
//                 shrinkWrap:false,

                  // Generate 100 widgets that display their index in the List.
                  children: List.generate(countryName.length, (index) {
                    var country = country_flag_map[countryName[index]];
                    return ListTile(
                      title: Text(countryName[index]),
                      dense: true,
                      leading: Image.asset(
                        'assets/flags/png/100/${country['alpha_2']}.png'
                            .toLowerCase(),
                        width: 20,
                        fit: BoxFit.fitHeight,
                        alignment: Alignment.centerLeft,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        var name = countryName[index];
                        searchController.text = name;
                        filterByValue(countryName[index], true);
                        _goToElement(10);
                        gaSend("click_country$name");
                      },
                    );
                  })),
            ],
          )),

      body: CustomScrollView(controller: _controller, slivers: <Widget>[
        SliverList(
            delegate: SliverChildListDelegate(
              [
                ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    Container(
                        child: provData.length > 1 ? getMap() : Text("loading"),
                        height: 600.0),
                  ],
                )
              ],
            )),

        SliverStickyHeader(
            key: statsKey,
            header: Container(
              height: 60,
              color: Colors.black45,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.topCenter,
              child: Text(
                "Statistics (Tap items for timeline)",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//              crossAxisCount: (size.width / 300).toInt(),
                maxCrossAxisExtent: 500.0,
                childAspectRatio: 2.5,
                mainAxisSpacing: 2.0,
                crossAxisSpacing: 2.0,
              ),
              delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                  var widgetContainer = Card(
                    color: Colors.black87,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: firstGridData[index]["color"], width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.all(20.0),
                    child: InkWell(
                      splashColor: Colors.blue.withAlpha(30),
                      onTap: () {
                        if (firstGridData[index].containsKey("url")) {
                          showExternalPopup(
                              context, firstGridData[index]["header"],
                              firstGridData[index]["url"]);
                        } else {
                          showPopup(
                              context,
                              SimpleTimeSeriesChart(
                                  firstGridData[index]["timeseries_path"],
                                  timeseries),
                              firstGridData[index]["header"]);
                        }


                        gaSend("pressed_${firstGridData[index]["header"]}");
                      },
                      child: Container(
                        child: Column(
                          children: <Widget>[
                            ListTile(
                              title: Text(
                                '${firstGridData[index]["header"]}',
                                style: TextStyle(
                                    color: firstGridData[index]["color"],
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              subtitle: Column(
                                children: <Widget>[
                                  FittedBox(
                                      fit: BoxFit.fitWidth,
                                      child: Text(
                                        '${firstGridData[index]["description"]}',
                                        style: TextStyle(
                                            fontSize: 30, color: Colors.white),
                                      )),
                                  Text(
                                    '${firstGridData[index]["footer"]}',
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  return widgetContainer;
                },
                childCount: firstGridData.length,
              ),
            )),

        SliverStickyHeader(
            key: dashKey,
            header: Container(
              height: 60,
              color: Colors.black45,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.topCenter,
              child: Text(
                "Dashboards (Click the tiles to see)",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//              crossAxisCount: (size.width / 300).toInt(),
              maxCrossAxisExtent: 500.0,
                childAspectRatio: 2.2,
              mainAxisSpacing: 2.0,
              crossAxisSpacing: 4.0,
              ),
              delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                  return Card(
                      color: Colors.black87,
                      elevation: 10,
                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(5.0),
                      child: InkWell(
                          splashColor: Colors.white,
                          onTap: () {
                            showExternalPopup(
                              context,
                              "${currentDash[index]['title']}",
                              "${currentDash[index]['url']}",
                            );

                            gaSend("pressed_${currentDash[index]['title']}");
                          },

                          child: Card(
                            color: Colors.black,
//                    alignment: Alignment.center,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[

                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      fit: BoxFit.fill,
                                      image: new ExactAssetImage( 'assets/images/dash.jpg'
                                          .toLowerCase()),
                                         ),
                                    ),
                                  ),
                                new Container(
                                  height: 20,
                                  child: Text(
                                    '${currentDash[index]["title"]}',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),




                                Container(
                                  height: 100,
                                  color: Colors.black,
                                  padding: new EdgeInsets.symmetric(
                                      horizontal: 5.0,),
                                  alignment: Alignment.centerLeft,

                                    child: Text(
                                      '${currentDash[index]["description"]}',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal),

                                    )


                                ),
                              ],
                            ),
                          ))
                  );
                },
                childCount: currentDash.length,
              ),
            )),
        SliverStickyHeader(
          key: countryKey,
          header: Container(
            height: 60,
            color: Colors.black45,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            alignment: Alignment.topCenter,
            child: Text(
              "     Countries :${currentCountry
                  .length} (Tap items for timeline)",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//              crossAxisCount: (size.width / 300).toInt(),
              maxCrossAxisExtent: 500.0,
              childAspectRatio: 2.5,
              mainAxisSpacing: 2.0,
              crossAxisSpacing: 4.0,
            ),
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                var country =
                country_flag_map[currentCountry[index]["Country/Region"]];

                var widgetContainer = InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      showPopup(
                          context,
                          SimpleTimeSeriesChart([
                            "*",
                            currentCountry[index]["Country/Region"],
                            "total"
                          ], timeseries),
                          "Timeline of ${currentCountry[index]["Country/Region"]}");
                      gaSend(
                          "pressed_${ currentCountry[index]["Country/Region"]}");
                    },
                    child: Card(
                      color: Colors.black,
//                    alignment: Alignment.center,
                      child: Column(
                        children: <Widget>[
                          new Container(
                              height: 50,
                              color: Color(0xFF212121),
                              padding:
                              new EdgeInsets.symmetric(horizontal: 12.0),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Image.asset(
                                      'assets/flags/png/100/${country["alpha_2"]}.png'
                                          .toLowerCase(),
                                      width: 30),
                                  Text(
                                    '${currentCountry[index]["Country/Region"]}',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )),
                          Container(
                            color: Colors.black,
                            padding: new EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 12),
                            alignment: Alignment.centerLeft,
                            child: new Text(
                              'Confirmed: ${currentCountry[index]['Confirmed']} \nDeath: ${currentCountry[index]['Deaths']}  \nRecovered: ${currentCountry[index]['Recovered']}',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal),
                            ),
                          ),
                        ],
                      ),
                    ));

                return widgetContainer;
              },
              childCount: currentCountry.length,
            ),
          ),
        ),
        SliverStickyHeader(
          key: provKey,

          header: Container(
            height: 60,
            color: Colors.black45,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            alignment: Alignment.topCenter,
            child: Text(
              "Provances/States (${currentProv
                  .length})  (Tap items for timeline)",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//              crossAxisCount: (size.width / 300).toInt(),
              maxCrossAxisExtent: 500.0,
              childAspectRatio: 2.5,
              mainAxisSpacing: 2.0,
              crossAxisSpacing: 4.0,
            ),
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                var country =
                country_flag_map[currentProv[index]["Country/Region"]];
                return InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      showPopup(
                          context,
                          SimpleTimeSeriesChart([
                            "*",
                            currentProv[index]["Country/Region"],
                            "province",
                            currentProv[index]["Province/State"]
                          ], timeseries),
                          "Timeline of ${currentProv[index]["Country/Region"]} - ${currentProv[index]["Province/State"]}");

                      gaSend(
                          "pressed_timeline_${currentProv[index]["Country/Region"]}");
                    },
                    child: Card(
                      color: Colors.black87,
                      child: Column(
                        children: <Widget>[
                          new Container(
                              height: 50,
                              color: Color(0xFF212121),
                              padding:
                              new EdgeInsets.symmetric(horizontal: 12.0),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Image.asset(
                                      'assets/flags/png/100/${country['alpha_2']}.png'
                                          .toLowerCase(),
                                      width: 30),
                                  Text(
                                    '${currentProv[index]["Combined_Key"]}',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )),
                          Container(
                            padding: new EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 12),
                            alignment: Alignment.centerLeft,
                            child: new Text(
                              'Confirmed: ${currentProv[index]['Confirmed']} \nDeath: ${currentProv[index]['Deaths']}  \nRecovered: ${currentProv[index]['Recovered']}',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal),
                            ),
                          ),
                        ],
                      ),
                    ));
              },
              childCount: currentProv.length,
            ),
          ),
        ),
      ]),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _goToElement(61);
          FocusScope.of(context).requestFocus(focusNode);
          gaSend("press_search");
        },
        tooltip: 'Go to search',
        child: Icon(Icons.search),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  showExternalPopup(BuildContext context, String title, String url,
      {BuildContext popupContext}) {
    Navigator.push(
      context,
      PopupLayout(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        bgColor: Colors.white70,
        child: PopupContent(
          content: Scaffold(
            appBar: AppBar(
              actions: <Widget>[
                FlatButton.icon(
                    onPressed: () {
                      html.window.open(url, '_blank');
                    },
                    icon: FaIcon(FontAwesomeIcons.externalLinkAlt),
                    label: Text("Visit Site")
                ),
                IconButton(
                  tooltip: 'Having issues with this site?',
                  icon: FaIcon(FontAwesomeIcons.exclamationCircle),
                  onPressed: () {
                    html.window.open(
                        "https://gitreports.com/issue/zmsp/coronavirusdashboard",
                        '_blank');
                  },
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: FaIcon(FontAwesomeIcons.times),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
              primary: false,

              title: Text(title),

              leading: new Builder(builder: (context) {
                return IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    try {
                      Navigator.pop(context); //close the popup
                    } catch (e) {}
                  },
                );
              },

              ),
              brightness: Brightness.dark,

            ),
            resizeToAvoidBottomPadding: true,
            body: ExternalContent(url),
          ),
        ),
      ),
    );
  }
  showPopup(BuildContext context, Widget widget, String title,
      {BuildContext popupContext}) {
    Navigator.push(
      context,
      PopupLayout(
        top: 5,
        left: 5,
        right: 5,
        bottom: 5,
        child: PopupContent(
          content: Scaffold(
            appBar: AppBar(
              title: Text(title),
              leading: new Builder(builder: (context) {
                return IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    try {
                      Navigator.pop(context); //close the popup
                    } catch (e) {}
                  },
                );
              }),
              brightness: Brightness.light,
            ),
            resizeToAvoidBottomPadding: false,
            body: widget,
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                try {
                  Navigator.pop(context); //close the popup
                } catch (e) {
                }
              },
              tooltip: 'Close Timeline',
              child: Icon(Icons.close),
            ),
          ),
        ),
      ),
    );
  }
}
