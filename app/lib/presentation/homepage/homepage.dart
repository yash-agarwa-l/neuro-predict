import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mlapp/presentation/admin_page.dart';
import 'package:mlapp/presentation/login_page.dart';
import 'package:mlapp/presentation/report_page.dart';
import 'package:mlapp/presentation/homepage/homepagewidgets.dart';
import 'package:mlapp/services/auth.dart';
import 'package:mlapp/services/preditct.dart';
import 'package:mlapp/services/token.dart';
import '../theme.dart';

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
  late Future<List<dynamic>> _historyFuture;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
    _loadHistory();
  }

  Future<void> _checkRole() async {
    final role = await AuthLocalDataSource.instance.getRole();
    if (mounted) {
      setState(() {
        _isAdmin = (role == 'admin');
      });
    }
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

  Future<void> _pickAndProcessCsv() async {
    setState(() => _isLoadingAnalysis = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null) {
        setState(() => _isLoadingAnalysis = false);
        return;
      }

      final file = result.files.first;
      String csvString;
      
      if (file.bytes != null) {
        csvString = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        csvString = await File(file.path!).readAsString();
      } else {
        throw Exception("Unable to read CSV.");
      }

      if (csvString.trim().isEmpty) throw Exception("CSV is empty.");

      final lines = csvString.trim().split(RegExp(r'\r\n|\r|\n'));
      if (lines.length < 2) throw Exception("Invalid CSV format.");

      final headers = lines[0].split(',');
      final values = lines[1].split(',');

      if (values.length < headers.length) throw Exception("Column mismatch.");

      final Map<String, dynamic> featureData = {};
      for (int i = 0; i < headers.length; i++) {
        final key = headers[i].trim();
        final value = values[i].trim();
        featureData[key] = num.tryParse(value) ?? value;
      }

      await _runAnalysis(featureData);
    } catch (e) {
      setState(() => _isLoadingAnalysis = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _runAnalysis(Map<String, dynamic> featureData) async {
    if (!_isLoadingAnalysis) setState(() => _isLoadingAnalysis = true);

    try {
      final predictions = await ApiService.getNeuroPredictions(featureData);
      
      if (!mounted) return;
      setState(() => _isLoadingAnalysis = false);
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAnalysis = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _isAdmin ? Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: kAccentColor),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
                   SizedBox(height: 10),
                   Text('Admin Console', style: TextStyle(color: Colors.white, fontSize: 24)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Users & Models'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const AdminPage())
                );
              },
            ),
          ],
        ),
      ) : null,
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
          const HomeHeader(),
          const SizedBox(height: 20),
          
          ActionSection(
            isLoading: _isLoadingAnalysis,
            onUploadPressed: _pickAndProcessCsv,
            onMockPressed: () => _runAnalysis(_mockFeatureData),
          ),
          
          const SizedBox(height: 40),
          
          HistorySection(
            historyFuture: _historyFuture,
            onRefresh: _loadHistory,
          ),
        ],
      ),
    );
  }
}

