import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:swiftcomp/generated/l10n.dart';
import 'package:swiftcomp/util/NumberPrecisionHelper.dart';
import 'package:swiftcomp/util/ads_manager.dart';

class ToolSettingPage extends StatefulWidget {
  const ToolSettingPage({Key? key}) : super(key: key);

  @override
  _ToolSettingPageState createState() => _ToolSettingPageState();
}

class _ToolSettingPageState extends State<ToolSettingPage> {
  BannerAd? _anchoredAdaptiveAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _loadAd();
  }

  Future<void> _loadAd() async {
    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate());

    if (size == null) {
      print('Unable to get height of anchored banner.');
      return;
    }

    _anchoredAdaptiveAd = BannerAd(
      // TODO: replace these test ad units with your own ad unit.
      adUnitId: AdsManager.bannerAdUnitId,
      size: size,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$ad loaded: ${ad.responseInfo}');
          setState(() {
            // When the ad is loaded, get the ad size and use it to set
            // the height of the ad container.
            _anchoredAdaptiveAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('Anchored adaptive banner failedToLoad: $error');
          ad.dispose();
        },
      ),
    );
    return _anchoredAdaptiveAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).Settings),
      ),
      body: Consumer<NumberPrecisionHelper>(
          builder: (context, value, child) => SafeArea(
                child: Stack(alignment: AlignmentDirectional.bottomCenter, children: [
                  ListView(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      ListTile(
                        title: Text(S.of(context).Result_Precision),
                        subtitle: Text(123456789.toStringAsExponential(value.precision)),
                        trailing: SizedBox(
                          width: 140,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () => setState(() {
                                  if (value.precision > 1) {
                                    value.set(value.precision - 1);
                                  }
                                }),
                              ),
                              Container(
                                  width: 40,
                                  child: Text(
                                    value.precision.toString(),
                                    textAlign: TextAlign.center,
                                  )),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () => setState(() {
                                  if (value.precision < 9) {
                                    value.set(value.precision + 1);
                                  }
                                }),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // if (_anchoredAdaptiveAd != null && _isLoaded)
                  //   Container(
                  //     color: Colors.green,
                  //     width: _anchoredAdaptiveAd!.size.width.toDouble(),
                  //     height: _anchoredAdaptiveAd!.size.height.toDouble(),
                  //     child: AdWidget(ad: _anchoredAdaptiveAd!),
                  //   )
                ]),
              )),
    );
  }
}
