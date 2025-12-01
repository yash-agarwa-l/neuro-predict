
import 'package:flutter/material.dart';
import 'package:mlapp/presentation/report_page.dart';
import 'package:mlapp/presentation/theme.dart';

/// 1. The Header with the Icon and Title
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30.0),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: kAccentColor,
          ),
          const SizedBox(height: 20),
          Text(
            'Neural Health Insights',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Upload your encrypted sensor data to generate a new diagnostic report.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// 2. The Buttons or Loading Indicator
class ActionSection extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onUploadPressed;
  final VoidCallback onMockPressed;

  const ActionSection({
    super.key,
    required this.isLoading,
    required this.onUploadPressed,
    required this.onMockPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: kAccentColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: onUploadPressed,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(
            'Upload & Analyze CSV',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBackgroundColor,
          ),
          onPressed: onMockPressed,
          icon: const Icon(Icons.science_outlined),
          label: Text(
            'Run Mock Analysis',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

/// 3. The History List Section
class HistorySection extends StatelessWidget {
  final Future<List<dynamic>> historyFuture;
  final VoidCallback onRefresh;

  const HistorySection({
    super.key,
    required this.historyFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Reports',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
              tooltip: 'Refresh History',
            )
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<dynamic>>(
          future: historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: kAccentColor));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading history.',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No reports found.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            final reports = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                return HistoryItemBuilder(report: reports[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

class HistoryItemBuilder extends StatelessWidget {
  final Map<String, dynamic> report;

  const HistoryItemBuilder({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    // Parse Scores
    final scores = {
      'Alzheimer': (report['alzheimer_risk_score'] ?? 0.0) as num,
      'Parkinson': (report['parkinson_risk_score'] ?? 0.0) as num,
      'Stress': (report['stress_risk_score'] ?? 0.0) as num,
    };

    final highest = scores.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    final double scoreVal = highest.value.toDouble();
    final String subtitle = "${highest.key}: ${scoreVal.toStringAsFixed(1)}% Risk";
    
    final Color subtitleColor = (scoreVal > 70)
        ? kRiskHigh
        : (scoreVal > 40 ? kRiskMedium : kRiskLow);

    final String date = DateTime.parse(report['created_at'])
        .toLocal()
        .toString()
        .split(' ')[0];

    return ReportCard(
      title: 'Report - $date',
      subtitle: subtitle,
      subtitleColor: subtitleColor,
      onTap: () => _navigateToReport(context, report),
    );
  }

  void _navigateToReport(BuildContext context, Map<String, dynamic> report) {
    final predictionsMap = {
      "Alzheimer": {
        "Risk_Score": report['alzheimer_risk_score'],
        "Risk_Stage": report['alzheimer_risk_stage']
      },
      "Parkinson": {
        "Risk_Score": report['parkinson_risk_score'],
        "Risk_Stage": report['parkinson_risk_stage']
      },
      "Stress": {
        "Risk_Score": report['stress_risk_score'],
        "Risk_Stage": report['stress_risk_stage']
      },
      "carePlan": report['personalized_care_plan']
    };


    final featureDataMap = {
        "sleep_stage": report['sleep_stage'],
        "eeg_theta_power": report['eeg_theta_power'],
        "eeg_gamma_power": report['eeg_gamma_power'],
        "eeg_delta_power": report['eeg_delta_power'],
        "heart_rate_bpm": report['heart_rate_bpm'],
        "hrv_ms": report['hrv_ms'],
        "rem_bursts": report['rem_bursts'],
        "chin_emg": report['chin_emg'],
        "respiration_rate": report['respiration_rate'],
        "resp_irregularity": report['resp_irregularity'],
        "skin_conductance": report['skin_conductance'],
        "valence": report['valence'],
        "arousal": report['arousal'],
        "mood": report['mood'],
        "activity": report['activity'],

    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(
          predictions: predictionsMap,
          featureData: featureDataMap,
        ),
      ),
    );
  }
}

/// 5. The actual UI Card for a history item
class ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final VoidCallback onTap;

  const ReportCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: subtitleColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}