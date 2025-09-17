// lib/services/image_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:civic_report_app/services/location_service.dart';
import 'package:image/image.dart' as img; // The 'image' package is now the only font source
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();

  Future<XFile?> captureAndGeotagImage({required ImageSource source}) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile == null) return null;

    String address = "Location not available";
    try {
      address = await _locationService.getCurrentAddress();
    } catch (e) {
      // Ignore location errors
    }
    
    // Using the current date for the timestamp
    final String timestamp = DateFormat("d MMM yyyy, hh:mm:ss a").format(DateTime.now());
    final String geotagText = "$address\n$timestamp";

    final Uint8List imageBytes = await pickedFile.readAsBytes();
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return null;

    // --- FONT LOGIC SIMPLIFIED ---
    // No more loading files. We just use the built-in arial24 font.
    img.drawString(
      originalImage,
      geotagText,
      font: img.arial24, // Use the built-in font
      x: 10,
      y: originalImage.height - 60, // Adjusted for the font size
      color: img.ColorRgb8(255, 255, 255),
    );
    // --- FONT LOGIC SIMPLIFIED ---

    final Uint8List geotaggedImageBytes = Uint8List.fromList(img.encodeJpg(originalImage, quality: 95));
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File newFile = await File(path).writeAsBytes(geotaggedImageBytes);

    return XFile(newFile.path);
  }
}