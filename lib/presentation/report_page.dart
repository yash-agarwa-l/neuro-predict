import 'package:flutter/material.dart';
import 'package:mlapp/presentation/theme.dart';
import 'package:mlapp/services/preditct.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:io';

class ReportPage extends StatefulWidget {
  final Map<String, dynamic> predictions;
  final Map<String, dynamic> featureData;

  const ReportPage({
    super.key,
    required this.predictions,
    required this.featureData,
  });

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _isDownloading = false;

  List<MapEntry<String, dynamic>> _getDiseaseEntries() {
    return widget.predictions.entries
        .where((e) => e.value is Map<String, dynamic> || e.value is Map)
        .toList();
  }

  MapEntry<String, dynamic> _getHighestRisk() {
    final diseases = _getDiseaseEntries();

    if (diseases.isEmpty) {
      return const MapEntry("No Data", {"Risk_Score": 0.0, "Risk_Stage": 0});
    }

    return diseases.reduce((a, b) {
      final double scoreA = (a.value['Risk_Score'] ?? 0).toDouble();
      final double scoreB = (b.value['Risk_Score'] ?? 0).toDouble();
      return scoreA > scoreB ? a : b;
    });
  }

  Color _getColorForScore(double score) {
    if (score > 70) return kRiskHigh;
    if (score > 40) return kRiskMedium;
    return kRiskLow;
  }

  String _getRiskLevelText(double score) {
    if (score > 70) return 'High Risk Detected';
    if (score > 40) return 'Medium Risk Detected';
    return 'Low Risk Detected';
  }

  IconData _getRiskIcon(double score) {
    if (score > 70) return Icons.warning_amber_rounded;
    if (score > 40) return Icons.info_outline_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Future<void> _downloadReport() async {
    setState(() => _isDownloading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading PDF report...')),
    );

    try {
      final File pdfFile = await ApiService.getNeuroReport(widget.featureData);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to ${pdfFile.path}'),
          action: SnackBarAction(label: "Ok", onPressed: () {}),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final highestRisk = _getHighestRisk();
    final double highestScore = (highestRisk.value['Risk_Score'] ?? 0).toDouble();
    final String highestDisease = highestRisk.key;
    final int highestStage = (highestRisk.value['Risk_Stage'] ?? 0).toInt();
    final Color riskColor = _getColorForScore(highestScore);
    final String? carePlanText = widget.predictions["carePlan"] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Report'),
        actions: [
          _isDownloading
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kAccentColor,
                      )),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: _downloadReport, 
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          //Summary Card 
          Text('Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Card(
            color: kSurfaceColor,
            elevation: 4,
            shadowColor: riskColor.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: riskColor, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getRiskIcon(highestScore), color: riskColor, size: 40),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          _getRiskLevelText(highestScore),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: riskColor, fontSize: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$highestDisease: ${highestScore.toStringAsFixed(2)}% (Stage $highestStage)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),


          Text('Detailed Results', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          
          ..._getDiseaseEntries().map((entry) {
            final String disease = entry.key;
            final double score = (entry.value['Risk_Score'] ?? 0).toDouble();
            final int stage = (entry.value['Risk_Stage'] ?? 0).toInt();
            return _ResultCard(
              diseaseName: disease,
              riskScore: score,
              stage: stage,
              color: _getColorForScore(score),
            );
          }),

          const SizedBox(height: 30),

          //Personalized Care Plan
          if (carePlanText != null && carePlanText.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.auto_awesome, color: kAccentColor, size: 20),
                const SizedBox(width: 8),
                Text('AI Care Plan', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            _CarePlanViewer(carePlanText: carePlanText),
            const SizedBox(height: 20),
          ],

          Card(
            color: kSurfaceColor.withOpacity(0.5),
            margin: const EdgeInsets.only(top: 10, bottom: 30),
            child: ListTile(
              leading:  Icon(Icons.medical_information_outlined, color: kSecondaryTextColor),
              title:  Text('Disclaimer', style: TextStyle(color: kSecondaryTextColor, fontSize: 14)),
              subtitle: const Text(
                'This is an AI-generated insight and not a medical diagnosis. Please consult a qualified healthcare professional.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _ResultCard extends StatelessWidget {
  final String diseaseName;
  final double riskScore;
  final int stage;
  final Color color;

  const _ResultCard({
    required this.diseaseName,
    required this.riskScore,
    required this.stage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(diseaseName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Risk Stage: $stage', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            CircularPercentIndicator(
              radius: 28.0,
              lineWidth: 6.0,
              percent: (riskScore / 100.0).clamp(0.0, 1.0),
              center: Text(
                '${riskScore.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              progressColor: color,
              backgroundColor: kBackgroundColor,
              circularStrokeCap: CircularStrokeCap.round,
            ),
          ],
        ),
      ),
    );
  }
}

class _CarePlanViewer extends StatelessWidget {
  final String carePlanText;

  const _CarePlanViewer({required this.carePlanText});

  @override
  Widget build(BuildContext context) {
    final lines = carePlanText.split('\n');

    return Card(
      elevation: 0,
      color: kSurfaceColor.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kAccentColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) {
            String trimmed = line.trim();
            if (trimmed.isEmpty) return const SizedBox(height: 8);

            // 1. Headers
            if (trimmed.startsWith('**') && trimmed.endsWith('**')) {
              final text = trimmed.replaceAll('**', '');
              return Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Text(
                  text,
                  style: TextStyle(
                    color: kAccentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5
                  ),
                ),
              );
            }
            
            // 2. Bold starts
            if (trimmed.startsWith('**')) {
               return Padding(
                 padding: const EdgeInsets.only(bottom: 6.0),
                 child: RichText(
                   text: TextSpan(
                     children: _parseBoldLine(trimmed, context),
                   ),
                 ),
               );
            }

            // 3. Lists
            if (trimmed.startsWith('1.') || trimmed.startsWith('-') || trimmed.startsWith('•')) {
               return Padding(
                 padding: const EdgeInsets.only(bottom: 6.0, left: 8.0),
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text("•", style: TextStyle(color: kAccentColor, fontSize: 16)),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         _cleanListItem(trimmed),
                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                       ),
                     ),
                   ],
                 ),
               );
            }

            // 4. Body
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                trimmed,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: kSecondaryTextColor),
              ),
            );

          }).toList(),
        ),
      ),
    );
  }

  String _cleanListItem(String text) {
    return text.replaceAll(RegExp(r'^(\d+\.|- |• )\s*'), '');
  }

  List<InlineSpan> _parseBoldLine(String line, BuildContext context) {
    final parts = line.split('**');
    List<InlineSpan> spans = [];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      bool isBold = false;
      if (line.startsWith('**')) {
        isBold = (i % 2 != 0); 
      } else {
        isBold = (i % 2 != 0); 
      }

      spans.add(TextSpan(
        text: parts[i],
        style: isBold 
          ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
          : TextStyle(color: kSecondaryTextColor),
      ));
    }
    return spans;
  }
}