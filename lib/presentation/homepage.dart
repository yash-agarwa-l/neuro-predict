import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mlapp/presentation/login_page.dart';
import 'package:mlapp/presentation/report_page.dart';
import 'package:mlapp/services/auth.dart';
import 'package:mlapp/services/preditct.dart';
import 'theme.dart';

final Map<String, dynamic> _mockFeatureData = {
  "sleep_stage": 2,
  "eeg_theta_power": 45.5,
  "eeg_gamma_power": 12.3,
  "eeg_delta_power": 78.9,
  "heart_rate_bpm": 72,
  "hrv_ms": 45,
  "rem_bursts": 8,
  "chin_emg": 15.2,
  "respiration_rate": 16,
  "resp_irregularity": 2.1,
  "skin_conductance": 3.5,
  "valence": 0.6,
  "arousal": 0.4,
  "mood": 1,
  "activity": 0
};

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoadingAnalysis = false;
  String? fileName;
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = ApiService.getPredictionHistory();
    });
  }

  Future<void> _logout() async {
    await AuthApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  /// Pick CSV, parse it into a feature map, then run analysis
  Future<void> _pickAndProcessCsv() async {
    setState(() {
      _isLoadingAnalysis = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null) {
        // user actually cancelled
        setState(() => _isLoadingAnalysis = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File picking canceled.')),
          );
        }
        return;
      }

      final file = result.files.first;
      fileName = file.name;

      String csvString;
      if (file.bytes != null) {
        csvString = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        csvString = await File(file.path!).readAsString();
      } else {
        throw Exception("Unable to read the selected CSV file.");
      }

      print('Raw CSV content:\n$csvString');

      if (csvString.trim().isEmpty) {
        throw Exception("CSV file is empty or could not be read.");
      }

      // Robust line splitting for any platform
      final lines = csvString.trim().split(RegExp(r'\r\n|\r|\n'));
      print('Line count: ${lines.length}');
      if (lines.length < 2) {
        throw Exception(
            "CSV must have a header row and at least one data row. Lines: ${lines.length}");
      }

      // header row & first data row
      final headers = lines[0].split(',');
      final values = lines[1].split(',');

      print('Headers: $headers');
      print('Values: $values');

      if (values.length < headers.length) {
        throw Exception(
            "Data row has fewer columns than header row. Headers: ${headers.length}, Values: ${values.length}");
      }

      final Map<String, dynamic> featureData = {};
      for (int i = 0; i < headers.length; i++) {
        final key = headers[i].trim();
        final value = values[i].trim();
        final num? numericValue = num.tryParse(value);
        featureData[key] = numericValue ?? value;
      }

      print('Final featureData: $featureData');

      // 🔥 Use the same flow as mock analysis
      await _runAnalysis(featureData);
    } catch (e) {
      setState(() {
        _isLoadingAnalysis = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing CSV: $e')),
        );
      }
      print('Error in _pickAndProcessCsv: $e');
    }
  }

  Future<void> _runAnalysis(Map<String, dynamic> featureData) async {
    if (!_isLoadingAnalysis) {
      setState(() {
        _isLoadingAnalysis = true;
      });
    }

    try {
      final predictions = await ApiService.getNeuroPredictions(featureData);

      if (!mounted) return;

      setState(() {
        _isLoadingAnalysis = false;
      });

      _loadHistory();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportPage(
            predictions: predictions,
            featureData: featureData,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAnalysis = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAnalysis = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unknown error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NeuroPredict'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Padding(
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
          ),
          const SizedBox(height: 20),
          _isLoadingAnalysis
              ? Center(
                  child: CircularProgressIndicator(
                    color: kAccentColor,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickAndProcessCsv,
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
                      onPressed: () => _runAnalysis(_mockFeatureData),
                      icon: const Icon(Icons.science_outlined),
                      label: Text(
                        'Run Mock Analysis',
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Reports',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadHistory,
                tooltip: 'Refresh History',
              )
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<dynamic>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child:
                        CircularProgressIndicator(color: kAccentColor));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading history: ${snapshot.error}',
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
                  final report = reports[index] as Map<String, dynamic>;

                  final scores = {
                    'Alzheimer': report['alzheimer_risk_score'] ?? 0.0,
                    'Parkinson': report['parkinson_risk_score'] ?? 0.0,
                    'Stress': report['stress_risk_score'] ?? 0.0,
                  };

                  final highest = scores.entries
                      .reduce((a, b) => a.value > b.value ? a : b);
                  final String subtitle =
                      "${highest.key}: ${highest.value.toStringAsFixed(1)}% Risk";
                  final Color subtitleColor = (highest.value > 70)
                      ? kRiskHigh
                      : (highest.value > 40 ? kRiskMedium : kRiskLow);

                  final String date = DateTime.parse(report['created_at'])
                      .toLocal()
                      .toString()
                      .split(' ')[0];

                  return _buildRecentReportCard(
                    title: 'Report - $date',
                    subtitle: subtitle,
                    subtitleColor: subtitleColor,
                    onTap: () {
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
                        }
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
                        "activity": report['activity']
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
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportCard({
    required String title,
    required String subtitle,
    Color? subtitleColor,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: subtitleColor ?? kSecondaryTextColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
