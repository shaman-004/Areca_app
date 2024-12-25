import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  /// Pick an image from the gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      } else {
        print('No image selected.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  /// Upload the selected image to the server
  Future<void> _uploadImage() async {
  if (_image == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No image selected. Please select an image to upload.')),
    );
    return;
  }

  setState(() {
    _isUploading = true;
  });

  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/run-detection/'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

    print('Sending request to backend...');
    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await http.Response.fromStream(response);
      print('Backend raw response: ${responseBody.body}');

      if (responseBody.body.isNotEmpty && responseBody.body != 'null') {
        Map<String, dynamic> result = jsonDecode(responseBody.body);

        // Navigate to Notification Page
        Navigator.pushNamed(context, '/notifications', arguments: result);
      } else {
        print('Empty or null response from backend');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid data received from backend.')),
        );
      }
    } else {
      print('Upload failed with status: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed with status: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Upload error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error during upload: $e')),
    );
  } finally {
    setState(() {
      _isUploading = false;
    });
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Image')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image == null
                  ? const Text('No image selected.')
                  : Image.file(_image!, height: 200),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: const Text('Select Image from Gallery'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                child: const Text('Take a Photo'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadImage,
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Upload Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
