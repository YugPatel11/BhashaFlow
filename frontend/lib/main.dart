import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const BhashaFlowApp());
}

class BhashaFlowApp extends StatelessWidget {
  const BhashaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BhashaFlow',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BhashaFlow')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherScreen())),
              child: const Text('I am a Teacher'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentScreen())),
              child: const Text('I am a Student'),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});
  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  String _status = 'Select a lecture audio to upload';
  bool _isUploading = false;

  Future<void> _uploadAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        _status = 'Uploading and processing...';
        _isUploading = true;
      });
      try {
        var request = http.MultipartRequest('POST', Uri.parse('http://10.92.177.63:8000/api/lectures/upload/'));
        request.fields['title'] = result.files.single.name;
        request.files.add(await http.MultipartFile.fromPath('audio_file', result.files.single.path!));
        
        var response = await request.send();
        if (response.statusCode == 201) {
          setState(() => _status = 'Lecture uploaded and processed successfully!');
        } else {
          setState(() => _status = 'Upload failed with status: ${response.statusCode}');
        }
      } catch (e) {
        setState(() => _status = 'Error: $e');
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isUploading) const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadAudio, 
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Lecture Audio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});
  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  String selectedLang = 'en';
  List<dynamic> lectures = [];
  String transcript = '';
  bool _isLoading = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fetchLectures();
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Fixed: Resource leak
    super.dispose();
  }

  Future<void> _fetchLectures() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://10.92.177.63:8000/api/lectures/'));
      if (response.statusCode == 200) {
        setState(() => lectures = json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching lectures: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTranscript(int lectureId) async {
    setState(() {
      transcript = 'Loading transcript...';
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('http://10.92.177.63:8000/api/lectures/$lectureId/transcript/$selectedLang/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => transcript = data['text']);
        if (data['audio_url'] != null) {
          await _audioPlayer.play(UrlSource('http://10.92.177.63:8000${data['audio_url']}'));
        }
      } else {
        setState(() => transcript = 'Transcript not available for this language yet.');
      }
    } catch (e) {
      setState(() => transcript = 'Error loading transcript: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Select Language: '),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedLang,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                    DropdownMenuItem(value: 'gu', child: Text('Gujarati')),
                  ],
                  onChanged: (val) => setState(() { selectedLang = val!; transcript = ''; }),
                ),
              ],
            ),
          ),
          if (_isLoading && lectures.isEmpty) const Expanded(child: Center(child: CircularProgressIndicator())),
          Expanded(
            child: ListView.builder(
              itemCount: lectures.length,
              itemBuilder: (ctx, i) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.audio_file, color: Colors.blue),
                  title: Text(lectures[i]['title']),
                  subtitle: Text('Uploaded on: ${lectures[i]['created_at'].substring(0, 10)}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _loadTranscript(lectures[i]['id']),
                ),
              ),
            ),
          ),
          if (transcript.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              height: 250,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transcript (${selectedLang.toUpperCase()}):', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const Divider(),
                  Expanded(child: SingleChildScrollView(child: Text(transcript, style: const TextStyle(fontSize: 16)))),
                ],
              ),
            )
        ],
      ),
    );
  }
}
