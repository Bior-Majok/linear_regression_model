import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ChildMortalityApp());
}

class ChildMortalityApp extends StatelessWidget {
  const ChildMortalityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Umoja Health Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E5631),
          primary: const Color(0xFF1E5631),
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      home: const PredictionScreen(),
    );
  }
}

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  // API Endpoint configuration: defaults to live Render API
  final TextEditingController _apiUrlController = TextEditingController(
    text: 'https://linear-regression-model-p51l.onrender.com/predict',
  );

  // Controllers for all 11 model features
  final TextEditingController _subregionController =
      TextEditingController(text: 'East Africa');
  final TextEditingController _incomeLevelController =
      TextEditingController(text: 'Low income');
  final TextEditingController _urbanPopController =
      TextEditingController(text: '25.5');
  final TextEditingController _urbanGrowthController =
      TextEditingController(text: '4.1');
  final TextEditingController _sanitationController =
      TextEditingController(text: '32.0');
  final TextEditingController _waterController =
      TextEditingController(text: '58.0');
  final TextEditingController _electricityController =
      TextEditingController(text: '45.0');
  final TextEditingController _healthExpController =
      TextEditingController(text: '42.5');
  final TextEditingController _dptController =
      TextEditingController(text: '82.0');
  final TextEditingController _gdpController =
      TextEditingController(text: '850.0');
  final TextEditingController _primaryCompletionController =
      TextEditingController(text: '68.0');

  // Display area state
  bool _isLoading = false;
  String? _predictionResult;
  String? _errorMessage;

  @override
  void dispose() {
    _apiUrlController.dispose();
    _subregionController.dispose();
    _incomeLevelController.dispose();
    _urbanPopController.dispose();
    _urbanGrowthController.dispose();
    _sanitationController.dispose();
    _waterController.dispose();
    _electricityController.dispose();
    _healthExpController.dispose();
    _dptController.dispose();
    _gdpController.dispose();
    _primaryCompletionController.dispose();
    super.dispose();
  }

  // Resets the inputs to clean sample values
  void _loadSampleData() {
    setState(() {
      _subregionController.text = 'East Africa';
      _incomeLevelController.text = 'Low income';
      _urbanPopController.text = '25.5';
      _urbanGrowthController.text = '4.1';
      _sanitationController.text = '32.0';
      _waterController.text = '58.0';
      _electricityController.text = '45.0';
      _healthExpController.text = '42.5';
      _dptController.text = '82.0';
      _gdpController.text = '850.0';
      _primaryCompletionController.text = '68.0';
      _predictionResult = null;
      _errorMessage = null;
    });
  }

  // Clears all form fields to test missing field errors
  void _clearForm() {
    setState(() {
      _subregionController.clear();
      _incomeLevelController.clear();
      _urbanPopController.clear();
      _urbanGrowthController.clear();
      _sanitationController.clear();
      _waterController.clear();
      _electricityController.clear();
      _healthExpController.clear();
      _dptController.clear();
      _gdpController.clear();
      _primaryCompletionController.clear();
      _predictionResult = null;
      _errorMessage = null;
    });
  }

  // Core API call method
  Future<void> _predictMortality() async {
    setState(() {
      _isLoading = true;
      _predictionResult = null;
      _errorMessage = null;
    });

    // Client-side check for empty fields
    final fields = [
      _subregionController.text.trim(),
      _incomeLevelController.text.trim(),
      _urbanPopController.text.trim(),
      _urbanGrowthController.text.trim(),
      _sanitationController.text.trim(),
      _waterController.text.trim(),
      _electricityController.text.trim(),
      _healthExpController.text.trim(),
      _dptController.text.trim(),
      _gdpController.text.trim(),
      _primaryCompletionController.text.trim(),
    ];

    if (fields.any((f) => f.isEmpty)) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Validation Error: All 11 feature fields are required. Please fill in all missing values.';
      });
      return;
    }

    // Build the JSON payload
    final Map<String, dynamic> requestPayload = {
      'subregion': _subregionController.text.trim(),
      'income_level': _incomeLevelController.text.trim(),
      'urban_pop_pct': double.tryParse(_urbanPopController.text.trim()) ??
          _urbanPopController.text.trim(),
      'urban_growth': double.tryParse(_urbanGrowthController.text.trim()) ??
          _urbanGrowthController.text.trim(),
      'sanitation_pct': double.tryParse(_sanitationController.text.trim()) ??
          _sanitationController.text.trim(),
      'water_pct': double.tryParse(_waterController.text.trim()) ??
          _waterController.text.trim(),
      'electricity_pct': double.tryParse(_electricityController.text.trim()) ??
          _electricityController.text.trim(),
      'health_exp_per_capita':
          double.tryParse(_healthExpController.text.trim()) ??
              _healthExpController.text.trim(),
      'dpt_immunization': double.tryParse(_dptController.text.trim()) ??
          _dptController.text.trim(),
      'gdp_per_capita': double.tryParse(_gdpController.text.trim()) ??
          _gdpController.text.trim(),
      'primary_completion':
          double.tryParse(_primaryCompletionController.text.trim()) ??
              _primaryCompletionController.text.trim(),
    };

    final uri = Uri.parse(_apiUrlController.text.trim());

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestPayload),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final prediction = data['predicted_u5_mortality'];
        final unit = data['unit'] ?? 'deaths per 1,000 live births';

        setState(() {
          _predictionResult =
              'Predicted Under-5 Mortality:\n$prediction $unit';
          _errorMessage = null;
        });
      } else if (response.statusCode == 422) {
        // FastAPI / Pydantic validation error (wrong type, out of range, missing)
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        final details = errorBody['detail'];

        String formattedError = 'API Validation Error (422):';
        if (details is List && details.isNotEmpty) {
          for (final err in details) {
            final loc = (err['loc'] as List).last;
            final msg = err['msg'] ?? 'Invalid value';
            formattedError += '\n- $loc: $msg';
          }
        } else {
          formattedError += '\n${response.body}';
        }

        setState(() {
          _errorMessage = formattedError;
          _predictionResult = null;
        });
      } else {
        setState(() {
          _errorMessage =
              'Server Error (${response.statusCode}): ${response.body}';
          _predictionResult = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Connection Error: Could not reach the API.\n${e.toString()}\n(Check your internet connection or API URL)';
        _predictionResult = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Umoja Health Connect'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E5631),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header title and use-case explanation
              const Text(
                'Under-5 Child Mortality Predictor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143D22),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter public health and socioeconomic indicators across 11 variables to predict under-5 mortality.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // API URL configuration card (for testing emulator vs Render)
              Card(
                elevation: 1,
                color: const Color(0xFFF5F5F5),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'API Endpoint URL:',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _apiUrlController,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'http://10.0.2.2:8000/predict or Render URL',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Use Render URL',
                                style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              setState(() {
                                _apiUrlController.text =
                                    'https://linear-regression-model-p51l.onrender.com/predict';
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('Use Localhost (127.0.0.1)',
                                style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              setState(() {
                                _apiUrlController.text =
                                    'http://127.0.0.1:8000/predict';
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text('Use Android Emulator (10.0.2.2)',
                                style: TextStyle(fontSize: 11)),
                            onPressed: () {
                              setState(() {
                                _apiUrlController.text =
                                    'http://10.0.2.2:8000/predict';
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick action buttons for video demo (Load Sample / Clear)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loadSampleData,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Load Sample Data'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearForm,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear Form'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section: The 11 Model Input Variables
              const Text(
                'Model Features (11 Input Variables):',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // 1. Subregion
              _buildLabeledField(
                label: '1. Subregion',
                hint: 'e.g. East Africa, West Africa, Central Africa',
                controller: _subregionController,
                keyboardType: TextInputType.text,
              ),

              // 2. Income Level
              _buildLabeledField(
                label: '2. Income Level',
                hint: 'e.g. Low income, Lower middle income',
                controller: _incomeLevelController,
                keyboardType: TextInputType.text,
              ),

              // 3. Urban Population %
              _buildLabeledField(
                label: '3. Urban Population (% of total population)',
                hint: 'Range: 0.0 - 100.0 (e.g. 25.5)',
                controller: _urbanPopController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              // 4. Urban Growth %
              _buildLabeledField(
                label: '4. Urban Population Growth (annual %)',
                hint: 'Range: -20.0 to 50.0 (e.g. 4.1)',
                controller: _urbanGrowthController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),

              // 5. Basic Sanitation %
              _buildLabeledField(
                label: '5. People using basic sanitation services (%)',
                hint: 'Range: 0.0 - 100.0 (e.g. 32.0)',
                controller: _sanitationController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              // 6. Basic Drinking Water %
              _buildLabeledField(
                label: '6. People using basic drinking water (%)',
                hint: 'Range: 0.0 - 100.0 (e.g. 58.0)',
                controller: _waterController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              // 7. Electricity Access %
              _buildLabeledField(
                label: '7. Access to electricity (% of population)',
                hint: 'Range: 0.0 - 100.0 (e.g. 45.0)',
                controller: _electricityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              // 8. Health Expenditure Per Capita
              _buildLabeledField(
                label: r'8. Health expenditure per capita (current US$)',
                hint: r'Range: >= 0.0 (e.g. 42.5)',
                controller: _healthExpController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              // 9. DPT Immunization %
              _buildLabeledField(
                label: '9. DPT Immunization (% children 12-23 months)',
                hint: 'Range: 0.0 - 100.0 (e.g. 82.0)',
                controller: _dptController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              // 10. GDP Per Capita
              _buildLabeledField(
                label: r'10. GDP per capita (constant 2015 US$)',
                hint: r'Range: >= 0.0 (e.g. 850.0)',
                controller: _gdpController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              // 11. Primary Completion %
              _buildLabeledField(
                label: '11. Primary school completion rate (%)',
                hint: 'Range: 0.0 - 200.0 (e.g. 68.0)',
                controller: _primaryCompletionController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 12),

              // Predict Button (Task 3 requires button text "Predict")
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _predictMortality,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5631),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Predict'),
                ),
              ),

              const SizedBox(height: 20),

              // Required Output Display Area
              // Shows predicted value upon success, or readable error upon failure
              _buildOutputDisplayArea(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to construct cleanly aligned and labelled input fields
  Widget _buildLabeledField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  // Output display area widget: satisfies requirements for single output/error zone
  Widget _buildOutputDisplayArea() {
    Color cardColor = const Color(0xFFF5F5F5);
    Color borderColor = Colors.grey.shade400;
    Widget content;

    if (_isLoading) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Text(
            'Contacting API and calculating prediction...',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      );
    } else if (_predictionResult != null) {
      cardColor = const Color(0xFFE8F5E9); // Light green
      borderColor = const Color(0xFF4CAF50);
      content = Text(
        _predictionResult!,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B5E20),
        ),
        textAlign: TextAlign.center,
      );
    } else if (_errorMessage != null) {
      cardColor = const Color(0xFFFFEBEE); // Light red
      borderColor = const Color(0xFFE53935);
      content = Text(
        _errorMessage!,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB71C1C),
        ),
        textAlign: TextAlign.center,
      );
    } else {
      content = const Text(
        'Ready. Tap "Predict" above to see the estimated mortality rate.',
        style: TextStyle(fontSize: 13, color: Colors.black54),
        textAlign: TextAlign.center,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'Prediction Output Area',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
