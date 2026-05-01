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

  Future<void> _uploadAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() => _status = 'Uploading...');
      var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/api/lectures/upload/'));
      request.fields['title'] = result.files.single.name;
      request.files.add(await http.MultipartFile.fromPath('audio_file', result.files.single.path!));
      
      var response = await request.send();
      if (response.statusCode == 201) {
        setState(() => _status = 'Upload successful!');
      } else {
        setState(() => _status = 'Upload failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _uploadAudio, child: const Text('Upload Audio')),
          ],
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
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fetchLectures();
  }

  Future<void> _fetchLectures() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/lectures/'));
    if (response.statusCode == 200) {
      setState(() => lectures = json.decode(response.body));
    }
  }

  Future<void> _loadTranscript(int lectureId) async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/lectures/$lectureId/transcript/$selectedLang/'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() => transcript = data['text']);
      if (data['audio_url'] != null) {
        await _audioPlayer.play(UrlSource('http://127.0.0.1:8000${data['audio_url']}'));
      }
    } else {
      setState(() => transcript = 'Transcript not available for this language yet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedLang,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'hi', child: Text('Hindi')),
              DropdownMenuItem(value: 'gu', child: Text('Gujarati')),
            ],
            onChanged: (val) => setState(() { selectedLang = val!; transcript = ''; }),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: lectures.length,
              itemBuilder: (ctx, i) => ListTile(
                title: Text(lectures[i]['title']),
                onTap: () => _loadTranscript(lectures[i]['id']),
              ),
            ),
          ),
          if (transcript.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              height: 200,
              child: SingleChildScrollView(child: Text(transcript)),
            )
        ],
      ),
    );
  }
}
