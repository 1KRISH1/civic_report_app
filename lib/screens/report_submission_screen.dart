// lib/screens/report_submission_screen.dart
import 'dart:io';
import 'package:civic_report_app/models/report.dart';
import 'package:civic_report_app/services/firestore_service.dart';
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

  // Image and submission state
  XFile? _imageFile;
  bool _isSubmitting = false;
  late bool _isEditMode;

  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

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

  // Method to handle picking an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  // Handles both creating a new report and updating an existing one
  Future<void> _submitOrUpdateReport() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);

      try {
        if (_isEditMode) {
          // If editing, call the update service method
          await _firestoreService.updateReport(
            reportId: widget.report!.id,
            category: _selectedCategory,
            description: _descriptionController.text,
            location: _locationController.text,
          );
          // Go back to the previous screen after updating
          if (mounted) Navigator.of(context).pop();
        } else {
          // If creating, call the submit service method
          await _firestoreService.submitReport(
            category: _selectedCategory,
            description: _descriptionController.text,
            location: _locationController.text,
            imageFile: _imageFile,
          );
          _resetForm(); // Reset the form only on new submissions
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
                value: _selectedCategory,
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
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter address or cross-streets',
                  border: OutlineInputBorder(),
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

              // --- Image Picker (only shown when creating a new report) ---
              if (!_isEditMode) ...[
                const SizedBox(height: 24),
                const Text('Attach an Image (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _imageFile == null
                    ? OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select Image'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      )
                    : Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imageFile!.path),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
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

              // --- Submission Button and Progress ---
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