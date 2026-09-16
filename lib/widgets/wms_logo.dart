import 'package:flutter/material.dart';

class WmsLogo extends StatelessWidget {
  const WmsLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Image.asset(
      'assets/images/wms_logo.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Logo Manajemen Logistik SMK Negeri 20 Jakarta',
    ),
  );
}
