import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/home/model/material_model.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';

class OrthotropicPropertiesWidget extends StatelessWidget {
  final String title;
  final OrthotropicMaterial orthotropicMaterial;
  const OrthotropicPropertiesWidget(
      {Key? key, required this.title, required this.orthotropicMaterial})
      : super(key: key);

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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            height: 40 * 9 + 20,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _propertyRow(context, "E1", orthotropicMaterial.e1),
                const Divider(height: 1),
                _propertyRow(context, "E2", orthotropicMaterial.e2),
                const Divider(height: 1),
                _propertyRow(context, "E3", orthotropicMaterial.e3),
                const Divider(height: 1),
                _propertyRow(context, "G12", orthotropicMaterial.g12),
                const Divider(height: 1),
                _propertyRow(context, "G13", orthotropicMaterial.g13),
                const Divider(height: 1),
                _propertyRow(context, "G23", orthotropicMaterial.g23),
                const Divider(height: 1),
                _propertyRow(context, "ν12", orthotropicMaterial.nu12),
                const Divider(height: 1),
                _propertyRow(context, "ν13", orthotropicMaterial.nu13),
                const Divider(height: 1),
                _propertyRow(context, "ν23", orthotropicMaterial.nu23),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
