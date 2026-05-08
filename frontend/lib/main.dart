import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

// ══════════════════════════════════════════════════════════════
// ⚙️ CHANGE THIS to your backend server IP/port
// ══════════════════════════════════════════════════════════════
const String BASE_URL = 'http://10.92.177.63:8000';
// ══════════════════════════════════════════════════════════════

void main() {
  runApp(const BhashaFlowApp());
}

class BhashaFlowApp extends StatelessWidget {
  const BhashaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BhashaFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

// ── Role Selection ──────────────────────────────────────────

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BhashaFlow'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.translate, size: 80, color: Color(0xFF6750A4)),
            const SizedBox(height: 16),
            const Text('Welcome to BhashaFlow',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Post-Class AI Transcript System',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const TeacherScreen())),
              icon: const Icon(Icons.school),
              label: const Text('I am a Teacher'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(220, 50)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const StudentScreen())),
              icon: const Icon(Icons.person),
              label: const Text('I am a Student'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(220, 50)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Teacher Screen ──────────────────────────────────────────

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});
  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  String _status = 'Select a lecture audio to upload';
  bool _isUploading = false;
  String? _uploadedLectureStatus;
  int? _uploadedLectureId;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _uploadAudio() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null) return;

    setState(() {
      _status = 'Uploading...';
      _isUploading = true;
      _uploadedLectureStatus = null;
      _uploadedLectureId = null;
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$BASE_URL/api/lectures/upload/'));
      request.fields['title'] = result.files.single.name;
      request.files.add(await http.MultipartFile.fromPath(
          'audio_file', result.files.single.path!));

      var response = await request.send();
      var body = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        var data = json.decode(body);
        _uploadedLectureId = data['id'];
        setState(() {
          _status = 'Uploaded! Processing in background...';
          _uploadedLectureStatus = 'processing';
        });
        // Start polling for status
        _startPolling();
      } else {
        setState(() => _status = 'Upload failed (${response.statusCode})');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_uploadedLectureId == null) return;
      try {
        final resp = await http.get(
            Uri.parse('$BASE_URL/api/lectures/$_uploadedLectureId/status/'));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          final st = data['status'] as String;
          setState(() {
            _uploadedLectureStatus = st;
            if (st == 'completed') {
              _status = '✅ Processing complete! Transcripts ready.';
              _pollTimer?.cancel();
            } else if (st == 'failed') {
              _status = '❌ Processing failed: ${data['error_message']}';
              _pollTimer?.cancel();
            } else {
              _status = '⏳ Processing... ($st)';
            }
          });
        }
      } catch (_) {}
    });
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
              Icon(
                _uploadedLectureStatus == 'completed'
                    ? Icons.check_circle
                    : _uploadedLectureStatus == 'failed'
                        ? Icons.error
                        : Icons.cloud_upload_outlined,
                size: 64,
                color: _uploadedLectureStatus == 'completed'
                    ? Colors.green
                    : _uploadedLectureStatus == 'failed'
                        ? Colors.red
                        : const Color(0xFF6750A4),
              ),
              const SizedBox(height: 20),
              if (_isUploading || _uploadedLectureStatus == 'processing')
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(),
                ),
              Text(_status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 30),
              FilledButton.icon(
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

// ── Student Screen ──────────────────────────────────────────

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
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchLectures() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await http.get(Uri.parse('$BASE_URL/api/lectures/'));
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
      final response = await http.get(Uri.parse(
          '$BASE_URL/api/lectures/$lectureId/transcript/$selectedLang/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => transcript = data['text']);
        if (data['audio_url'] != null) {
          await _audioPlayer
              .play(UrlSource('$BASE_URL${data['audio_url']}'));
        }
      } else {
        setState(() =>
            transcript = 'Transcript not available for this language yet.');
      }
    } catch (e) {
      setState(() => transcript = 'Error loading transcript: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_top;
      case 'failed':
        return Icons.error;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLectures,
            tooltip: 'Refresh',
          )
        ],
      ),
      body: Column(
        children: [
          // Language selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Language: ',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedLang,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                    DropdownMenuItem(value: 'gu', child: Text('Gujarati')),
                  ],
                  onChanged: (val) =>
                      setState(() { selectedLang = val!; transcript = ''; }),
                ),
              ],
            ),
          ),
          // Lecture list
          if (_isLoading && lectures.isEmpty)
            const Expanded(
                child: Center(child: CircularProgressIndicator())),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchLectures,
              child: ListView.builder(
                itemCount: lectures.length,
                itemBuilder: (ctx, i) {
                  final lec = lectures[i];
                  final st = lec['status'] ?? 'pending';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Icon(_statusIcon(st),
                          color: _statusColor(st)),
                      title: Text(lec['title']),
                      subtitle: Text(
                          'Status: ${st.toUpperCase()}  •  ${lec['created_at'].substring(0, 10)}'),
                      trailing: st == 'completed'
                          ? const Icon(Icons.arrow_forward_ios, size: 16)
                          : null,
                      onTap: st == 'completed'
                          ? () => _loadTranscript(lec['id'])
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          // Transcript display
          if (transcript.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF6750A4).withOpacity(0.3)),
              ),
              height: 250,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transcript (${selectedLang.toUpperCase()}):',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6750A4))),
                  const Divider(),
                  Expanded(
                      child: SingleChildScrollView(
                          child: Text(transcript,
                              style: const TextStyle(fontSize: 16)))),
                ],
              ),
            )
        ],
      ),
    );
  }
}
