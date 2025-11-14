import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../constants/ad_constant.dart';

class NativeAdExample extends StatefulWidget {
  const NativeAdExample({super.key});

  @override
  _NativeAdExampleState createState() => _NativeAdExampleState();
}

class _NativeAdExampleState extends State<NativeAdExample> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();

    _nativeAd = NativeAd(
      //adhere
      // adUnitId: 'ca-app-pub-3940256099942544/2247696110', // Test ID
      adUnitId: AdConstant.nativeAdUnitId, 
      factoryId: 'listTileMedium',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('Ad loaded.');
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Ad failed to load: $error');
          ad.dispose();
        },
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      return const SizedBox.shrink(); // nothing before ad loads
    }

    return Container(
      height: 300,
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(5),
     
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
