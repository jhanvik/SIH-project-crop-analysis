import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:sih/chartseries.dart';

class Graph extends StatefulWidget {
  final List<ChartSeries> data;
  Graph({this.data});

  @override
  _GraphState createState() => _GraphState();
}

class _GraphState extends State<Graph> {
  @override
  Widget build(BuildContext context) {
    List<charts.Series<ChartSeries, String>> series = [
      charts.Series(
        id: 'Production',
        data: widget.data,
        domainFn: (ChartSeries series, _) => series.year,
        measureFn: (ChartSeries series, _) => series.production,
        colorFn: (ChartSeries series, _) => series.barColor,
        fillPatternFn: (ChartSeries series, index) =>
            charts.FillPatternType.forwardHatch,
        labelAccessorFn: (ChartSeries series, _) => '${series.production}',
      )
    ];
    print(series[0].data[0].production.toString() + '==========');
    return Container(
      height: 400,
      padding: EdgeInsets.all(0),
      child: charts.BarChart(
        series,
        animate: true,
        barRendererDecorator: new charts.BarLabelDecorator<String>(
            insideLabelStyleSpec:
                charts.TextStyleSpec(color: charts.Color.black)),
        primaryMeasureAxis:
            new charts.NumericAxisSpec(renderSpec: new charts.NoneRenderSpec()),
        behaviors: [
          charts.ChartTitle('(Years)',
              behaviorPosition: charts.BehaviorPosition.bottom,
              titleOutsideJustification:
                  charts.OutsideJustification.middleDrawArea),
          charts.ChartTitle('(Production *in Tonnes*)',
              behaviorPosition: charts.BehaviorPosition.start,
              titleOutsideJustification:
                  charts.OutsideJustification.middleDrawArea),
        ],
      ),
    );
  }
}
