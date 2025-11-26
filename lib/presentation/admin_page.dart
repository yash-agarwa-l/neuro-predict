import 'package:flutter/material.dart';
import 'package:mlapp/presentation/homepage/homepagewidgets.dart';
import 'package:mlapp/presentation/report_page.dart';
import 'package:mlapp/presentation/theme.dart';
import 'package:mlapp/services/admin.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<dynamic>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = AdminApiService.getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: FutureBuilder<List<dynamic>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: kAccentColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final users = snapshot.data ?? [];

          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final user = users[index];
              final predictions = user['predictionLogs'] as List? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: kAccentColor,
                    child: Text(user['name']?[0].toUpperCase() ?? "U", 
                      style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(user['name'] ?? "Unknown"),
                  subtitle: Text(user['email'] ?? ""),
                  children: [
                    Container(
                      color: kSurfaceColor.withOpacity(0.3),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Predictions: ${predictions.length}", 
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (predictions.isEmpty)
                            const Text("No analysis history.", style: TextStyle(color: Colors.grey))
                          else
                            ...predictions.map((log) {
                              final date = DateTime.parse(log['created_at']).toLocal().toString().split(' ')[0];
                              return ListTile(
                                dense: true,
                                title: Text("Report Date: $date"),
                                subtitle: Text("High Risk: ${log['alzheimer_risk_score']}% (Alzheimer)"),
                                trailing: const Icon(Icons.visibility, size: 18),
                                onTap: () {

                                  final nestedPredictions = {
                                    "Alzheimer": {"Risk_Score": log['alzheimer_risk_score'], "Risk_Stage": log['alzheimer_risk_stage']},
                                    "Parkinson": {"Risk_Score": log['parkinson_risk_score'], "Risk_Stage": log['parkinson_risk_stage']},
                                    "Stress": {"Risk_Score": log['stress_risk_score'], "Risk_Stage": log['stress_risk_stage']},
                                  };
                                  _navigateToReport(context, log);
                                },
                              );
                            }),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  void _navigateToReport(BuildContext context, Map<String, dynamic> log) {
    // 1. Reconstruct the Predictions Map (Nested structure required by ReportPage)
    final Map<String, dynamic> predictionsMap = {
      "Alzheimer": {
        "Risk_Score": log['alzheimer_risk_score'],
        "Risk_Stage": log['alzheimer_risk_stage']
      },
      "Parkinson": {
        "Risk_Score": log['parkinson_risk_score'],
        "Risk_Stage": log['parkinson_risk_stage']
      },
      "Stress": {
        "Risk_Score": log['stress_risk_score'],
        "Risk_Stage": log['stress_risk_stage']
      }
    };

    // 2. Reconstruct the Feature Data Map (All 15 inputs required for PDF/Display)
    final Map<String, dynamic> featureDataMap = {
      "sleep_stage": log['sleep_stage'],
      "eeg_theta_power": log['eeg_theta_power'],
      "eeg_gamma_power": log['eeg_gamma_power'],
      "eeg_delta_power": log['eeg_delta_power'],
      "heart_rate_bpm": log['heart_rate_bpm'],
      "hrv_ms": log['hrv_ms'],
      "rem_bursts": log['rem_bursts'],
      "chin_emg": log['chin_emg'],
      "respiration_rate": log['respiration_rate'],
      "resp_irregularity": log['resp_irregularity'],
      "skin_conductance": log['skin_conductance'],
      "valence": log['valence'],
      "arousal": log['arousal'],
      "mood": log['mood'],
      "activity": log['activity']
    };

    // 3. Navigate
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