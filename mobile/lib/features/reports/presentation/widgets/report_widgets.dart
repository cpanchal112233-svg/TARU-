import 'package:flutter/material.dart';

import '../../domain/medical_report.dart';

IconData reportCategoryIcon(ReportCategory category) {
  return switch (category) {
    ReportCategory.lab => Icons.science_outlined,
    ReportCategory.imaging => Icons.image_outlined,
    ReportCategory.prescription => Icons.medication_outlined,
    ReportCategory.discharge => Icons.local_hospital_outlined,
    ReportCategory.other => Icons.description_outlined,
  };
}

String formatReportDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class ReportTypeChip extends StatelessWidget {
  const ReportTypeChip({super.key, required this.category});

  final ReportCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xffEAF1FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category.label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xff1D4ED8),
        ),
      ),
    );
  }
}
