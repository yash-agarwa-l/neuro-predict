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

  MapEntry<String, dynamic> _getHighestRisk() {
    // 1. Safety check: If predictions is empty, return a dummy entry to prevent crash
    if (widget.predictions.isEmpty) {
      return const MapEntry("No Data", {"Risk_Score": 0.0, "Risk_Stage": 0});
    }

    return widget.predictions.entries.reduce((a, b) {
      // 2. Safe access: Use '?? 0' to default to 0 if Risk_Score is missing/null
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
    setState(() {
      _isDownloading = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading PDF report...')),
    );

    try {
      final File pdfFile = await ApiService.getNeuroReport(widget.featureData);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to ${pdfFile.path}'),
          action: SnackBarAction(
            label: "Open",
            onPressed: () {
            },
          ),
        ),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unknown error occurred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final highestRisk = _getHighestRisk();
    final double highestScore = highestRisk.value['Risk_Score']??0;
    final String highestDisease = highestRisk.key;
    final int highestStage = highestRisk.value['Risk_Stage']??0;
    final Color riskColor = _getColorForScore(highestScore);

    return Scaffold(
      appBar: AppBar(
        title: Text('Analysis Report'),
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
                  icon: Icon(Icons.picture_as_pdf_outlined),
                  onPressed: _downloadReport, 
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // --- Summary Card ---
          Text(
            'Summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 10),
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
                  Icon(
                    _getRiskIcon(highestScore),
                    color: riskColor,
                    size: 40,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _getRiskLevelText(highestScore),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: riskColor, fontSize: 22),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '$highestDisease: ${highestScore.toStringAsFixed(2)}% (Stage $highestStage)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 30),

          // --- Detailed Results ---
          Text(
            'Detailed Results',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 10),
          ...widget.predictions.entries.map((entry) {
            final String disease = entry.key;
            final double score = entry.value['Risk_Score']??0;
            final int stage = entry.value['Risk_Stage']??0;
            return _ResultCard(
              diseaseName: disease,
              riskScore: score,
              stage: stage,
              color: _getColorForScore(score),
            );
          }),

          SizedBox(height: 20),

          // --- Disclaimer ---
          Card(
            color: kSurfaceColor.withOpacity(0.5),
            child: ListTile(
              leading: Icon(Icons.medical_information_outlined,
                  color: kSecondaryTextColor),
              title: Text(
                'Disclaimer',
                style: TextStyle(color: kSecondaryTextColor),
              ),
              subtitle: Text(
                'This is an AI-generated insight and not a medical diagnosis. Please consult a qualified healthcare professional.',
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
    super.key,
    required this.diseaseName,
    required this.riskScore,
    required this.stage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diseaseName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 4),
                Text(
                  'Risk Stage: $stage',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 8.0,
              percent: riskScore / 100.0,
              center: Text(
                '${riskScore.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: kPrimaryTextColor),
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