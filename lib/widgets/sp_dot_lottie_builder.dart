// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';

// class SpDotLottieBuilder extends StatelessWidget {
//   const SpDotLottieBuilder({
//     required this.asset,
//     super.key,
//   });

//   final String asset;

//   @override
//   Widget build(BuildContext context) {
//     return LottieBuilder.asset(
//       asset,
//       reverse: true,
//       decoder: customDecoder,
//     );
//   }

//   // https://pub.dev/packages/lottie#telegram-stickers-tgs-and-dotlottie-lottie
//   Future<LottieComposition?> customDecoder(List<int> bytes) {
//     return LottieComposition.decodeZip(bytes, filePicker: (files) {
//       return files.where((f) => f.name.startsWith('animations/') && f.name.endsWith('.json')).firstOrNull;
//     });
//   }
// }
