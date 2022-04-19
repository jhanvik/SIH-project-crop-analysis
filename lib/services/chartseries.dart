import 'package:charts_flutter/flutter.dart' as charts;

class ChartSeries {
  final String year;
  final double production;
  final charts.Color barColor;

  ChartSeries({this.barColor, this.production, this.year});
}
