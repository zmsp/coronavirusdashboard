import 'dart:math';

import 'package:charts_flutter/flutter.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:charts_flutter/src/text_element.dart' as te;
import 'package:charts_flutter/src/text_style.dart' as style;
import 'package:flutter/material.dart';

class SimpleTimeSeriesChart extends StatelessWidget {
  final bool animate;

  final timeseries_path;
  final timeseries;
  final title;
  static String pointerValue;

  SimpleTimeSeriesChart(this.timeseries_path, this.timeseries,
      {this.animate = true, this.title = "Timeseries chart"});

  /// Creates a [TimeSeriesChart] with sample data and no transition.
//  factory CustomMeasureTickCount.withSampleData() {
//    return new CustomMeasureTickCount(
//      _createSampleData(timeseriesPath, timeseries, title),
//      // Disable animations for image tests.
//      animate: false,
//    );
//  }

  @override
  Widget build(BuildContext context) {
    var data = _createSampleData(timeseries_path, timeseries, title);
    print(data);

    return  ( data == null)
        ? Center(
            child: Text(
                "Not enough data. We will update this section later. Thank you!"))
        : Container(
            padding: EdgeInsets.all(30),
        color: Colors.white70,
            child: charts.TimeSeriesChart(
                data,
                animate: animate,
                behaviors: [
                  LinePointHighlighter(
                      symbolRenderer: CustomCircleSymbolRenderer())
                ],
                selectionModels: [
                  SelectionModelConfig(changedListener: (SelectionModel model) {
                    if (model.hasDatumSelection) {
//              pointerValue = model.selectedSeries[0]
//                  .measureFn(model.selectedDatum[0].index).toString();
                      pointerValue = model.selectedSeries[0]
                          .measureFn(model.selectedSeries[0].data[0].number)
                          .toString();
                    }
                  })
                ],

                /// Customize the measure axis to have 10 ticks
                primaryMeasureAxis: new charts.NumericAxisSpec(
                    tickProviderSpec: new charts.BasicNumericTickProviderSpec(
                        desiredTickCount: 10))));
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<TimeSeriesCOVID, DateTime>> _createSampleData(
      timeseriesPath, timeseries, title) {
    List<TimeSeriesCOVID> data = List<TimeSeriesCOVID>();
    var tmp = timeseries;
    try {
      for (final e in timeseriesPath) {
        if (e == "*") {
          tmp = tmp["confirmed"];
        } else {
          tmp = tmp[e];
        }
      }

      var ignoredCol = [
        "Country/Region",
        "Province/State",
        "Lat",
        "Long",
        "Latitude",
        "Longitude"
      ];

      for (final e in tmp.keys) {
        if (ignoredCol.contains(e)) {
          continue;
        }
        if (tmp[e] == 0) {
          continue;
        }

        var arr = e.split("/");

        data.add(new TimeSeriesCOVID(
            new DateTime(
                int.parse(arr[2]) + 2000, int.parse(arr[0]), int.parse(arr[1])),
            tmp[e]));
      }

      return [
        new charts.Series<TimeSeriesCOVID, DateTime>(
          id: title,
          colorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.blue),
          areaColorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.red),
          patternColorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.green),
          fillColorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.blue),
          domainFn: (TimeSeriesCOVID sales, _) => sales.time,
          measureFn: (TimeSeriesCOVID sales, _) => sales.number,
          data: data,
        )
      ];
    }
    on NoSuchMethodError {
      return null;
    } catch(e) {
     return null;
    }






  }
//  static List<charts.Series<MyRow, DateTime>> _createSampleData() {
//    final data = [
//      new MyRow(new DateTime(2017, 9, 25), 6),
//      new MyRow(new DateTime(2017, 9, 26), 8),
//      new MyRow(new DateTime(2017, 9, 27), 6),
//      new MyRow(new DateTime(2017, 9, 28), 9),
//      new MyRow(new DateTime(2017, 9, 29), 11),
//      new MyRow(new DateTime(2017, 9, 30), 15),
//      new MyRow(new DateTime(2017, 10, 01), 25),
//      new MyRow(new DateTime(2017, 10, 02), 33),
//      new MyRow(new DateTime(2017, 10, 03), 27),
//      new MyRow(new DateTime(2017, 10, 04), 31),
//      new MyRow(new DateTime(2017, 10, 05), 23),
//    ];
//
//    return [
//      new charts.Series<MyRow, DateTime>(
//        id: 'Cost',
//        domainFn: (MyRow row, _) => row.timeStamp,
//        measureFn: (MyRow row, _) => row.cost,
//        data: data,
//        colorFn: (_, __) => charts.MaterialPalette.indigo.shadeDefault,
//      )
//    ];
//  }
}

/// Sample time series data type.
class MyRow {
  final DateTime timeStamp;
  final int cost;

  MyRow(this.timeStamp, this.cost);
}

class CustomCircleSymbolRenderer extends CircleSymbolRenderer {
  @override
  void paint(ChartCanvas canvas, Rectangle<num> bounds,
      {List<int> dashPattern,
      Color fillColor,
      FillPatternType fillPattern,
      Color strokeColor,
      double strokeWidthPx}) {
    super.paint(canvas, bounds,
        dashPattern: dashPattern,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidthPx: strokeWidthPx);
    canvas.drawRect(
        Rectangle(bounds.left - 5, bounds.top - 30, bounds.width + 80,
            bounds.height + 10),
        fill: Color.white);
    var textStyle = style.TextStyle();
    textStyle.color = Color.black;
    textStyle.fontSize = 15;
    canvas.drawText(
        te.TextElement(SimpleTimeSeriesChart.pointerValue, style: textStyle),
        (bounds.left).round(),
        (bounds.top - 28).round());
  }
}

class SimpleTimeSeriesChart2 extends StatelessWidget {
//  final List<charts.Series> seriesList;
  final bool animate;

  final timeseries_path;
  final timeseries;
  final title;

  SimpleTimeSeriesChart2(this.timeseries_path, this.timeseries,
      {this.animate = true, this.title = "Timeseries chart"});

  /// Creates a [TimeSeriesChart] with sample data and no transition.
//  factory SimpleTimeSeriesChart.withSampleData() {
//    return new SimpleTimeSeriesChart(
//      _createSampleData(timeseries_path, timeseries),
//      // Disable animations for image tests.
//      animate: false,
//    );
//  }

  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(
      _createSampleData(timeseries_path, timeseries, title),
      animate: animate,
      // Optionally pass in a [DateTimeFactory] used by the chart. The factory
      // should create the same type of [DateTime] as the data provided. If none
      // specified, the default creates local date time.
      dateTimeFactory: const charts.LocalDateTimeFactory(),
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<TimeSeriesCOVID, DateTime>> _createSampleData(
      timeseriesPath, timeseries, title) {
    List<TimeSeriesCOVID> data = List<TimeSeriesCOVID>();
    var tmp = timeseries;
    var ignoredCol = ["Province/State", "Lat", "Long", "Latitude", "Longitude"];
    for (final e in timeseriesPath) {
      if (e == "") {
        tmp = tmp["*"];

        continue;
      }

      tmp = tmp[e];
    }
    for (final e in tmp.keys) {
      if (ignoredCol.contains(e)) {
        continue;
      }
      var arr = e.split("/");

      data.add(new TimeSeriesCOVID(
          new DateTime(
              int.parse(arr[2]) + 2000, int.parse(arr[0]), int.parse(arr[1])),
          tmp[e]));
    }

    return [
      new charts.Series<TimeSeriesCOVID, DateTime>(
        id: title,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesCOVID sales, _) => sales.time,
        measureFn: (TimeSeriesCOVID sales, _) => sales.number,
        data: data,
      )
    ];
  }
}

/// Sample time series data type.
class TimeSeriesCOVID {
  final DateTime time;
  final int number;

  TimeSeriesCOVID(this.time, this.number);
}

//Widget popupBody(timeseries_path, timeseries) {
//  var tmp = timeseries;
//  for (final e in timeseries_path){
//    tmp = tmp [e];
//  }
//
//  var title = "Timeseries of ${timeseries_path[0]}";
//  factory SimpleTimeSeriesChart.withSampleData() {
//    return new SimpleTimeSeriesChart(
//      _createSampleData(),
//      // Disable animations for image tests.
//      animate: false,
//    );
//  }
//
//  return new charts.TimeSeriesChart(
//    seriesList,
//    animate: animate,
//    // Optionally pass in a [DateTimeFactory] used by the chart. The factory
//    // should create the same type of [DateTime] as the data provided. If none
//    // specified, the default creates local date time.
//    dateTimeFactory: const charts.LocalDateTimeFactory(),
//  );
//
//
//}
