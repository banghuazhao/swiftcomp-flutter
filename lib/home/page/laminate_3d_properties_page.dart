import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:linalg/linalg.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/home/model/layer_thickness.dart';
import 'package:swiftcomp/home/model/layup_sequence_model.dart';
import 'package:swiftcomp/home/model/material_model.dart';
import 'package:swiftcomp/home/tools/DescriptionModels.dart';
import 'package:swiftcomp/home/widget/description.dart';
import 'package:swiftcomp/home/widget/lamina_constants_row.dart';
import 'package:swiftcomp/home/widget/layer_thickness_row.dart';
import 'package:swiftcomp/home/widget/layup_sequence_row.dart';

import 'laminate_3d_properties_result_page.dart';

class Laminate3DPropertiesPage extends StatefulWidget {
  const Laminate3DPropertiesPage({Key? key}) : super(key: key);

  @override
  _Laminate3DPropertiesPageState createState() => _Laminate3DPropertiesPageState();
}

class _Laminate3DPropertiesPageState extends State<Laminate3DPropertiesPage> {
  TransverselyIsotropicMaterial transverselyIsotropicMaterial = TransverselyIsotropicMaterial();
  LayupSequence layupSequence = LayupSequence();
  LayerThickness layerThickness = LayerThickness();
  bool validate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(S.of(context).Laminate_3D_properties),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              validate = true;
            });
            _calculate();
          },
          label: Text(S.of(context).Calculate),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (_) {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: SafeArea(
              child: StaggeredGridView.countBuilder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  crossAxisCount: 8,
                  itemCount: 4,
                  staggeredTileBuilder: (int index) =>
                      StaggeredTile.fit(MediaQuery.of(context).size.width > 600 ? 4 : 8),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemBuilder: (BuildContext context, int index) {
                    return [
                      LaminaContantsRow(
                        material: transverselyIsotropicMaterial,
                        validate: validate,
                        isPlaneStress: false,
                      ),
                      LayupSequenceRow(layupSequence: layupSequence, validate: validate),
                      LayerThicknessPage(layerThickness: layerThickness, validate: validate),
                      DescriptionItem(
                          content: DescriptionModels.getDescription(
                              DescriptionType.laminate_3d_properties, context))
                    ][index];
                  })),
        ));
  }

  void _calculate() {
    if (!transverselyIsotropicMaterial.isValid() ||
        !layupSequence.isValid() ||
        !layerThickness.isValid()) {
      return;
    }

    double thickness = layerThickness.value!;
    int nPly = layupSequence.layups!.length;

    List<double> bzi = [];
    for (int i = 1; i <= nPly; i++) {
      double bz = (-(nPly + 1) * thickness) / 2 + i * thickness;
      bzi.add(bz);
    }

    Matrix C = Matrix.fill(6, 6);

    for (int i = 0; i < nPly; i++) {
      double layup = layupSequence.layups![i];
      double e1 = transverselyIsotropicMaterial.e1!;
      double e2 = transverselyIsotropicMaterial.e2!;
      double g12 = transverselyIsotropicMaterial.g12!;
      double nu12 = transverselyIsotropicMaterial.nu12!;
      double nu23 = transverselyIsotropicMaterial.nu23!;
      double e3 = e2;
      double g13 = g12;
      double g23 = e2 / (2 * (1 + nu23));
      double nu13 = nu12;
      double angleRadian = layup * pi / 180;
      double s = sin(angleRadian);
      double c = cos(angleRadian);
      Matrix Sp = Matrix([
        [1 / e1, -nu12 / e1, -nu13 / e1, 0, 0, 0],
        [-nu12 / e1, 1 / e2, -nu23 / e2, 0, 0, 0],
        [-nu13 / e1, -nu23 / e2, 1 / e3, 0, 0, 0],
        [0, 0, 0, 1 / g23, 0, 0],
        [0, 0, 0, 0, 1 / g13, 0],
        [0, 0, 0, 0, 0, 1 / g12]
      ]);

      Matrix Cp = Sp.inverse();

      Matrix Rsigma = Matrix([
        [c * c, s * s, 0, 0, 0, -2 * s * c],
        [s * s, c * c, 0, 0, 0, 2 * s * c],
        [0, 0, 1, 0, 0, 0],
        [0, 0, 0, c, s, 0],
        [0, 0, 0, -s, c, 0],
        [s * c, -s * c, 0, 0, 0, c * c - s * s]
      ]);
      C += Rsigma * Cp * Rsigma.transpose();
    }

    C = C * (1 / nPly);

    Matrix S = C.inverse();

    OrthotropicMaterial orthotropicMaterial = OrthotropicMaterial();
    orthotropicMaterial.e1 = 1 / S[0][0];
    orthotropicMaterial.e2 = 1 / S[1][1];
    orthotropicMaterial.e3 = 1 / S[2][2];
    orthotropicMaterial.g12 = 1 / S[5][5];
    orthotropicMaterial.g13 = 1 / S[4][4];
    orthotropicMaterial.g23 = 1 / S[3][3];
    orthotropicMaterial.nu12 = -1 / S[0][0] * S[0][1];
    orthotropicMaterial.nu13 = -1 / S[0][0] * S[0][2];
    orthotropicMaterial.nu23 = -1 / S[1][1] * S[1][2];

    print(C);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Laminate3DPropertiesResultPage(
                  C: C,
                  S: S,
                  orthotropicMaterial: orthotropicMaterial,
                )));
  }
}
