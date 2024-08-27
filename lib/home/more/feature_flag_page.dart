import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/home/more/feature_flag_provider.dart';

class FeatureFlagPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feature Flags'),
      ),
      body: Consumer<FeatureFlagProvider>(
        builder: (context, featureFlagProvider, _) {
          return ListView(
            children: featureFlagProvider.allFeatureFlags().keys.map((feature) {
              return SwitchListTile(
                title: Text(feature),
                value: featureFlagProvider.getFeatureFlag(feature),
                onChanged: (bool value) {
                  featureFlagProvider.toggleFeatureFlag(feature);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}