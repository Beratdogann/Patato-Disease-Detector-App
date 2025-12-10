// =============================================================================
// Potato Disease Detector - Flutter Frontend
// =============================================================================
// 
// A clean, Google-inspired Flutter app that detects potato leaf diseases
// using a FastAPI backend with machine learning.
//
// USAGE:
//   1. Run the FastAPI backend first (ensure it's running on http://127.0.0.1:8000)
//   2. Run this app with: flutter run
//
// TODO: CONFIGURATION
// - To change the backend URL, modify the `_backendUrl` constant below.
// - For production, replace with your actual server URL (e.g., "https://api.yourserver.com")
//
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const PotatoDiseaseDetectorApp());
}

/// Main application widget
class PotatoDiseaseDetectorApp extends StatelessWidget {
  const PotatoDiseaseDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Potato Disease Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Clean, light theme inspired by Google's design
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Green theme for agriculture
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Google's default font
      ),
      home: const PotatoHomePage(),
    );
  }
}

/// Main home page with all the disease detection functionality
class PotatoHomePage extends StatefulWidget {
  const PotatoHomePage({super.key});

  @override
  State<PotatoHomePage> createState() => _PotatoHomePageState();
}

class _PotatoHomePageState extends State<PotatoHomePage> {
  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  /// Backend API URL
  /// TODO: Change this URL when deploying to production
  /// For local development: "http://127.0.0.1:8000"
  /// For Android emulator: "http://10.0.2.2:8000" (localhost alias)
  /// For production: "https://your-production-server.com"
  static const String _backendUrl = 'http://10.0.2.2:9000';
  
  /// The predict endpoint path
  static const String _predictEndpoint = '/predict';

  // ===========================================================================
  // STATE VARIABLES
  // ===========================================================================
  
  /// The selected image file (null if no image selected)
  File? _selectedImage;
  
  /// Loading state while the API request is in progress
  bool _isLoading = false;
  
  /// Prediction result from the backend
  PredictionResult? _predictionResult;
  
  /// Error message to display to the user
  String? _errorMessage;
  
  /// Image picker instance
  final ImagePicker _imagePicker = ImagePicker();

  // ===========================================================================
  // IMAGE PICKING METHODS
  // ===========================================================================

  /// Pick an image from the device gallery
  /// 
  /// This method uses the image_picker package to open the gallery
  /// and let the user select an image.
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Limit image size for faster uploads
        maxHeight: 1024,
        imageQuality: 85, // Slight compression for better performance
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _predictionResult = null; // Clear previous result
          _errorMessage = null; // Clear previous error
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  /// Take a photo using the device camera
  /// 
  /// TODO: To enable camera support:
  /// 1. This method is already implemented using ImageSource.camera
  /// 2. Ensure camera permissions are configured:
  ///    - Android: Add to AndroidManifest.xml:
  ///      <uses-permission android:name="android.permission.CAMERA"/>
  ///    - iOS: Add to Info.plist:
  ///      <key>NSCameraUsageDescription</key>
  ///      <string>We need camera access to take photos of potato leaves</string>
  /// 3. Test on a physical device (camera doesn't work on emulators)
  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _predictionResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to take photo: ${e.toString()}';
      });
    }
  }

  // ===========================================================================
  // API CALL METHODS
  // ===========================================================================

  /// Send the selected image to the backend for disease prediction
  /// 
  /// This method:
  /// 1. Validates that an image is selected
  /// 2. Creates a multipart/form-data request
  /// 3. Sends the image to the backend
  /// 4. Parses the JSON response
  /// 5. Updates the UI with the result
  Future<void> _analyzeImage() async {
    // Validate: Check if an image is selected
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    // Start loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _predictionResult = null;
    });

    try {
      // Build the multipart request
      // The backend expects:
      // - Method: POST
      // - Content-Type: multipart/form-data
      // - Field name: "file"
      final uri = Uri.parse('$_backendUrl$_predictEndpoint');
      
      final request = http.MultipartRequest('POST', uri);
      
      // Add the image file to the request
      // The field name "file" must match what the backend expects
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Field name expected by the FastAPI backend
          _selectedImage!.path,
        ),
      );

      // Send the request and wait for response
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30), // Timeout after 30 seconds
        onTimeout: () {
          throw Exception('Request timed out. Please check if the backend is running.');
        },
      );
      
      // Convert streamed response to regular response
      final response = await http.Response.fromStream(streamedResponse);

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response
        // Expected format: {"class": "Early_blight", "confidence": 0.87}
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        setState(() {
          _predictionResult = PredictionResult.fromJson(jsonResponse);
          _isLoading = false;
        });
      } else {
        // Handle non-200 responses
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}\n${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle network errors, timeouts, JSON parsing errors, etc.
      setState(() {
        _isLoading = false;
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          _errorMessage = 'Cannot connect to server.\n\n'
              'Please ensure:\n'
              '1. The FastAPI backend is running\n'
              '2. It\'s accessible at $_backendUrl\n'
              '3. Check firewall settings';
        } else {
          _errorMessage = 'Error: ${e.toString()}';
        }
      });
    }
  }

  // ===========================================================================
  // UI BUILD METHODS
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Icon/Logo
                  _buildLogo(),
                  
                  const SizedBox(height: 24),
                  
                  // App Title
                  _buildTitle(),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  _buildSubtitle(),
                  
                  const SizedBox(height: 40),
                  
                  // Image Preview
                  _buildImagePreview(),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  _buildActionButtons(),
                  
                  const SizedBox(height: 32),
                  
                  // Result Section (Loading, Error, or Result Card)
                  _buildResultSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the app logo/icon
  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.eco, // Leaf icon representing agriculture
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Build the main title
  Widget _buildTitle() {
    return Text(
      'Potato Disease Detector',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build the subtitle description
  Widget _buildSubtitle() {
    return Text(
      'Upload a potato leaf and let the AI detect\nEarly / Late Blight or Healthy',
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Colors.grey[600],
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build the image preview container
  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedImage != null 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _selectedImage != null
          ? Image.file(
              _selectedImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No image selected',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
    );
  }

  /// Build the action buttons (Select Image, Take Photo, Analyze)
  Widget _buildActionButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        // Select Image Button
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _pickImageFromGallery,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Select Image'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        
        // Take Photo Button
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _takePhoto,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Take Photo'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        
        // Analyze Button
        ElevatedButton.icon(
          onPressed: (_isLoading || _selectedImage == null) ? null : _analyzeImage,
          icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.search),
          label: Text(_isLoading ? 'Analyzing...' : 'Analyze'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
      ],
    );
  }

  /// Build the result section (loading indicator, error message, or result card)
  Widget _buildResultSection() {
    // Show loading indicator
    if (_isLoading) {
      return _buildLoadingIndicator();
    }
    
    // Show error message if there is one
    if (_errorMessage != null) {
      return _buildErrorCard();
    }
    
    // Show prediction result if available
    if (_predictionResult != null) {
      return _buildResultCard();
    }
    
    // Nothing to show yet
    return const SizedBox.shrink();
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Analyzing your potato leaf...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error message card
  Widget _buildErrorCard() {
    return Card(
      elevation: 0,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[700],
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
              icon: Icon(
                Icons.close,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the prediction result card
  Widget _buildResultCard() {
    final result = _predictionResult!;
    
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: result.displayColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result Header with Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: result.displayColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    result.icon,
                    color: result.displayColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detection Result',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.displayName,
                        style: TextStyle(
                          color: result.displayColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Confidence Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Confidence',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      result.confidencePercentage,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: result.confidence,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(result.displayColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: result.displayColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: result.displayColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

/// Model class for prediction results from the backend
class PredictionResult {
  /// The predicted disease class: "Early_blight", "Late_blight", or "Healthy"
  final String diseaseClass;
  
  /// Confidence score from 0.0 to 1.0
  final double confidence;

  PredictionResult({
    required this.diseaseClass,
    required this.confidence,
  });

  /// Factory constructor to create from JSON response
  /// Expected format: {"class": "Early_blight", "confidence": 0.87}
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      diseaseClass: json['prediction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  /// Get human-readable display name for the disease class
  String get displayName {
    switch (diseaseClass) {
      case 'Early_blight':
        return 'Early Blight';
      case 'Late_blight':
        return 'Late Blight';
      case 'Healthy':
        return 'Healthy';
      default:
        return diseaseClass;
    }
  }

  /// Get confidence as a percentage string
  String get confidencePercentage {
    return '${(confidence * 100).toStringAsFixed(1)}%';
  }

  /// Get color associated with the disease class for UI display
  Color get displayColor {
    switch (diseaseClass) {
      case 'Early_blight':
        return const Color(0xFFFF9800); // Orange - warning
      case 'Late_blight':
        return const Color(0xFFF44336); // Red - danger
      case 'Healthy':
        return const Color(0xFF4CAF50); // Green - healthy
      default:
        return const Color(0xFF9E9E9E); // Grey - unknown
    }
  }

  /// Get icon associated with the disease class
  IconData get icon {
    switch (diseaseClass) {
      case 'Early_blight':
        return Icons.warning_amber_rounded;
      case 'Late_blight':
        return Icons.dangerous_outlined;
      case 'Healthy':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  /// Get description/recommendation based on the disease class
  String get description {
    switch (diseaseClass) {
      case 'Early_blight':
        return 'Early blight detected. Remove infected leaves and apply appropriate fungicide.';
      case 'Late_blight':
        return 'Late blight detected. This is serious – isolate the plant and consider professional advice.';
      case 'Healthy':
        return 'Leaf looks healthy. Keep monitoring regularly.';
      default:
        return 'Unknown disease class. Please consult an expert.';
    }
  }
}
