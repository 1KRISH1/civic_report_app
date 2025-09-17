// lib/screens/report_submission_screen.dart
import 'dart:io';
import 'package:civic_report_app/models/report.dart';
import 'package:civic_report_app/services/firestore_service.dart';
import 'package:civic_report_app/services/image_service.dart';
import 'package:civic_report_app/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportSubmissionScreen extends StatefulWidget {
  final Report? report; // Optional report for editing

  const ReportSubmissionScreen({super.key, this.report});

  @override
  State<ReportSubmissionScreen> createState() => _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState extends State<ReportSubmissionScreen> {
  // Form and input management
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Pothole';

  // State variables
  XFile? _imageFile;
  bool _isSubmitting = false;
  late bool _isEditMode;
  bool _isLocating = false;
  bool _isProcessingImage = false; // For image stamping

  // Services
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.report != null;

    // If a report is passed, pre-fill the form for editing
    if (_isEditMode) {
      _selectedCategory = widget.report!.category;
      _locationController.text = widget.report!.location;
      _descriptionController.text = widget.report!.description;
    }
  }

  /// Shows a modal sheet to choose between Camera and Gallery.
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _captureAndGeotag(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _captureAndGeotag(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Calls the ImageService to capture, geotag, and return a processed image.
  Future<void> _captureAndGeotag(ImageSource source) async {
    setState(() => _isProcessingImage = true);
    try {
      final processedImage = await _imageService.captureAndGeotagImage(source: source);
      if (processedImage != null) {
        setState(() => _imageFile = processedImage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingImage = false);
    }
  }
  
  /// Gets the user's current location and fills the text field.
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final address = await _locationService.getCurrentAddress();
      _locationController.text = address;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  /// Handles both creating a new report and updating an existing one.
  Future<void> _submitOrUpdateReport() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);

      try {
        if (_isEditMode) {
          await _firestoreService.updateReport(
            reportId: widget.report!.id,
            category: _selectedCategory,
            description: _descriptionController.text,
            location: _locationController.text,
          );
          if (mounted) Navigator.of(context).pop();
        } else {
          await _firestoreService.submitReport(
            category: _selectedCategory,
            description: _descriptionController.text,
            location: _locationController.text,
            imageFile: _imageFile,
          );
          _resetForm();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode
                  ? 'Report updated successfully!'
                  : 'Report submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Operation failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _locationController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = 'Pothole';
      _imageFile = null;
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Update Report' : 'Submit a New Report'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Category Dropdown ---
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ['Pothole', 'Streetlight', 'Sanitation', 'Parks & Rec']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // --- Location Input ---
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter address or use GPS',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: _isLocating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    onPressed: _isLocating ? null : _getCurrentLocation,
                    tooltip: 'Get Current Location',
                  ),
                ),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 16),

              // --- Description Input ---
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) => (value?.isEmpty ?? true)
                    ? 'Please enter a description'
                    : null,
              ),

              // --- Image Picker ---
              if (!_isEditMode) ...[
                const SizedBox(height: 24),
                const Text('Attach an Image',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_isProcessingImage)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Processing Image...'),
                      ],
                    ),
                  )),
                if (!_isProcessingImage && _imageFile == null)
                  OutlinedButton.icon(
                    onPressed: _showImageSourceActionSheet,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Open Camera / Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                if (!_isProcessingImage && _imageFile != null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_imageFile!.path)),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _imageFile = null),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Remove Image',
                            style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
              ],
              const SizedBox(height: 24),

              // --- Submission Button ---
              if (_isSubmitting)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitOrUpdateReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                      _isEditMode ? 'Update Report' : 'Submit Report',
                      style: const TextStyle(fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}