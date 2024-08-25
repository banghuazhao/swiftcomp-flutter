import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:linalg/matrix.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/home/model/mechanical_tensor_model.dart';
import 'package:swiftcomp/more/tool_setting_page.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';

class LaminateStressStrainResultPage extends StatefulWidget {
  final MechanicalTensor inputTensor;
  final MechanicalTensor resultTensor;
  final double thickness;
  final List<Matrix> Q;

  const LaminateStressStrainResultPage(
      {Key? key,
      required this.resultTensor,
      required this.inputTensor,
      required this.thickness,
      required this.Q})
      : super(key: key);

  @override
  _LaminateStressStrainResultPageState createState() => _LaminateStressStrainResultPageState();
}

class _LaminateStressStrainResultPageState extends State<LaminateStressStrainResultPage> {
  List<FlSpot> epsilon11_datas = [];
  List<FlSpot> epsilon22_datas = [];
  List<FlSpot> epsilon12_datas = [];
  List<FlSpot> sigma11_datas = [];
  List<FlSpot> sigma22_datas = [];
  List<FlSpot> sigma12_datas = [];

  initChartData() {
    Matrix epsilon = Matrix.fill(3, 1);
    Matrix kappa = Matrix.fill(3, 1);
    if (widget.inputTensor is LaminateStrain) {
      epsilon[0][0] = (widget.inputTensor as LaminateStrain).epsilon11!;
      epsilon[1][0] = (widget.inputTensor as LaminateStrain).epsilon22!;
      epsilon[2][0] = (widget.inputTensor as LaminateStrain).epsilon12!;
      kappa[0][0] = (widget.inputTensor as LaminateStrain).kappa11!;
      kappa[1][0] = (widget.inputTensor as LaminateStrain).kappa22!;
      kappa[2][0] = (widget.inputTensor as LaminateStrain).kappa12!;
    } else {
      epsilon[0][0] = (widget.resultTensor as LaminateStrain).epsilon11!;
      epsilon[1][0] = (widget.resultTensor as LaminateStrain).epsilon22!;
      epsilon[2][0] = (widget.resultTensor as LaminateStrain).epsilon12!;
      kappa[0][0] = (widget.resultTensor as LaminateStrain).kappa11!;
      kappa[1][0] = (widget.resultTensor as LaminateStrain).kappa22!;
      kappa[2][0] = (widget.resultTensor as LaminateStrain).kappa12!;
    }

    double totalThickness = widget.Q.length * widget.thickness;
    for (var i = 0; i < widget.Q.length; i++) {
      print(i);
      double x3Start = widget.thickness * i - totalThickness / 2;
      double x3End = widget.thickness * (i + 1) - totalThickness / 2;

      Matrix epsilon_e_Start = epsilon + kappa * x3Start;
      Matrix epsilon_e_End = epsilon + kappa * x3End;

      Matrix sigma_e_Start = widget.Q[i] * epsilon_e_Start;
      Matrix sigma_e_End = widget.Q[i] * epsilon_e_End;

      epsilon11_datas.add(FlSpot(x3Start, epsilon_e_Start[0][0]));
      epsilon11_datas.add(FlSpot(x3End, epsilon_e_End[0][0]));

      epsilon22_datas.add(FlSpot(x3Start, epsilon_e_Start[1][0]));
      epsilon22_datas.add(FlSpot(x3End, epsilon_e_End[1][0]));

      epsilon12_datas.add(FlSpot(x3Start, epsilon_e_Start[2][0]));
      epsilon12_datas.add(FlSpot(x3End, epsilon_e_End[2][0]));

      sigma11_datas.add(FlSpot(x3Start, sigma_e_Start[0][0]));
      sigma11_datas.add(FlSpot(x3End, sigma_e_End[0][0]));

      sigma22_datas.add(FlSpot(x3Start, sigma_e_Start[1][0]));
      sigma22_datas.add(FlSpot(x3End, sigma_e_End[1][0]));

      sigma12_datas.add(FlSpot(x3Start, sigma_e_Start[2][0]));
      sigma12_datas.add(FlSpot(x3End, sigma_e_End[2][0]));
    }
    print(epsilon11_datas);
  }

  @override
  void initState() {
    super.initState();
    initChartData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => const ToolSettingPage()));
              },
              icon: const Icon(Icons.settings_rounded),
            ),
          ],
          title: Text(S.of(context).Results),
        ),
        body: SafeArea(
          child: StaggeredGridView.countBuilder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              crossAxisCount: 8,
              itemCount: 7,
              staggeredTileBuilder: (int index) =>
                  StaggeredTile.fit(MediaQuery.of(context).size.width > 600 ? 4 : 8),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemBuilder: (BuildContext context, int index) {
                return [
                  ResultStressStrainWidget(
                    mechanicalTensor: widget.resultTensor,
                  ),
                  LaminarStressStrainLineChat(
                    title: "ε11 through the thickness",
                    data: epsilon11_datas,
                  ),
                  LaminarStressStrainLineChat(
                    title: "ε22 through the thickness",
                    data: epsilon22_datas,
                  ),
                  LaminarStressStrainLineChat(
                    title: "ε12 through the thickness",
                    data: epsilon12_datas,
                  ),
                  LaminarStressStrainLineChat(
                    title: "σ11 through the thickness",
                    data: sigma11_datas,
                  ),
                  LaminarStressStrainLineChat(
                    title: "σ22 through the thickness",
                    data: sigma22_datas,
                  ),
                  LaminarStressStrainLineChat(
                    title: "σ12 through the thickness",
                    data: sigma12_datas,
                  )
                ][index];
              }),
        ));
  }
}

class ResultStressStrainWidget extends StatelessWidget {
  final MechanicalTensor mechanicalTensor;
  const ResultStressStrainWidget({Key? key, required this.mechanicalTensor}) : super(key: key);

  _propertyRow(BuildContext context, String title, double? value) {
    return Consumer<NumberPrecisionHelper>(builder: (context, precs, child) {
      return SizedBox(
        height: 40,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            title,
            style: Theme.of(context).textTheme.subtitle1,
          ),
          Text(
            getValue(value, precs.precision),
            style: Theme.of(context).textTheme.bodyText1,
          )
        ]),
      );
    });
  }

  String getValue(double? value, int precision) {
    String valueString = "";
    if (value != null) {
      valueString = value == 0 ? "0" : value.toStringAsExponential(precision).toString();
    }
    return valueString;
  }

  @override
  Widget build(BuildContext context) {
    bool isStress = (mechanicalTensor is LaminateStress);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              "Result",
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            height: 240 + 20,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _propertyRow(
                    context,
                    isStress ? "N11" : "ϵ11",
                    isStress
                        ? (mechanicalTensor as LaminateStress).N11
                        : (mechanicalTensor as LaminateStrain).epsilon11),
                const Divider(height: 1),
                _propertyRow(
                    context,
                    isStress ? "N22" : "ϵ22",
                    isStress
                        ? (mechanicalTensor as LaminateStress).N22
                        : (mechanicalTensor as LaminateStrain).epsilon22),
                const Divider(height: 1),
                _propertyRow(
                    context,
                    isStress ? "N12" : "ϵ12",
                    isStress
                        ? (mechanicalTensor as LaminateStress).N12
                        : (mechanicalTensor as LaminateStrain).epsilon12),
                const Divider(height: 1),
                _propertyRow(
                    context,
                    isStress ? "M11" : "𝞳11",
                    isStress
                        ? (mechanicalTensor as LaminateStress).M11
                        : (mechanicalTensor as LaminateStrain).kappa11),
                const Divider(height: 1),
                _propertyRow(
                    context,
                    isStress ? "M22" : "𝞳22",
                    isStress
                        ? (mechanicalTensor as LaminateStress).M22
                        : (mechanicalTensor as LaminateStrain).kappa22),
                const Divider(height: 1),
                _propertyRow(
                    context,
                    isStress ? "M12" : "𝞳12",
                    isStress
                        ? (mechanicalTensor as LaminateStress).M12
                        : (mechanicalTensor as LaminateStrain).kappa12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LaminarStressStrainLineChat extends StatelessWidget {
  final String title;
  final List<FlSpot> data;
  const LaminarStressStrainLineChat({Key? key, required this.title, required this.data})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double minX = data[0].x;
    double maxX = data.last.x;
    double minY = (data.map((e) => e.y)).reduce(min);
    double maxY = (data.map((e) => e.y)).reduce(max);
    double horizontalInterval = (maxX - minX) / 4;
    double verticalInterval = (maxY - minY) / 4;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(children: [
        ListTile(
          title: Text(
            title,
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(5, 0, 25, 10),
          height: 200,
          child: LineChart(LineChartData(
            lineTouchData: LineTouchData(enabled: false),
            gridData: FlGridData(
              show: true,
              horizontalInterval: verticalInterval > 0 ? verticalInterval : null,
              verticalInterval: horizontalInterval > 0 ? horizontalInterval : null,
              drawHorizontalLine: true,
              drawVerticalLine: true,
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: SideTitles(showTitles: false),
              topTitles: SideTitles(showTitles: false),
              leftTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: verticalInterval > 0 ? verticalInterval : null,
                  getTextStyles: (context, value) => const TextStyle(
                        fontSize: 10,
                      ),
                  getTitles: (value) {
                    return value.toStringAsExponential(2);
                  }),
              bottomTitles: SideTitles(
                  showTitles: true,
                  interval: horizontalInterval > 0 ? horizontalInterval : null,
                  getTextStyles: (context, value) => const TextStyle(
                        fontSize: 10,
                      ),
                  getTitles: (value) {
                    return value.toStringAsExponential(2);
                  }),
            ),
            borderData: FlBorderData(
                show: true,
                border: const Border(
                    left: BorderSide(color: Colors.grey), bottom: BorderSide(color: Colors.grey))),
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                isCurved: false,
                colors: [Theme.of(context).colorScheme.primary],
                barWidth: 1,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
                spots: data,
              ),
            ],
          )),
        )
      ]),
    );
  }
}
