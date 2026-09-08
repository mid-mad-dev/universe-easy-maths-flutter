import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ABOUT', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        const Text('ABOUT UNIVERSE EASY MATHS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppConstants.companyName, style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text(AppConstants.tagline), SizedBox(height: 15), Text(AppConstants.location), SizedBox(height: 15), Text('Founder: ${AppConstants.founder}'), Text('Co-Founder: ${AppConstants.coFounder}')]))
      ]),
    );
  }
}
