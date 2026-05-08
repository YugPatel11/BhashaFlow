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
        colorSchemeSeed: const Color(0xFFE0E5EC),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE0E5EC),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

// ── Neomorphic Helper ──────────────────────────────────────────

class NeomorphicContainer extends StatelessWidget {
  final Widget child;
  final double padding;
  final double borderRadius;
  final bool isPressed;

  const NeomorphicContainer({
    super.key,
    required this.child,
    this.padding = 16.0,
    this.borderRadius = 20.0,
    this.isPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? [
                BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: const Offset(-2, -2),
                    blurRadius: 2,
                    spreadRadius: 1),
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(2, 2),
                    blurRadius: 2,
                    spreadRadius: 1),
              ]
            : [
                BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    offset: const Offset(-6, -6),
                    blurRadius: 12),
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(6, 6),
                    blurRadius: 12),
              ],
      ),
      child: child,
    );
  }
}

// ── Role Selection ──────────────────────────────────────────

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NeomorphicContainer(
              padding: 24,
              child: Icon(Icons.translate, size: 60, color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 32),
            const Text('BhashaFlow',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2D3748))),
            const Text('AI Lecture Assistant',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey, letterSpacing: 1.2)),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherScreen())),
              child: const NeomorphicContainer(
                padding: 20,
                borderRadius: 15,
                child: SizedBox(
                  width: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, color: Color(0xFF2D3748)),
                      SizedBox(width: 12),
                      Text('I am a Teacher', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentScreen())),
              child: const NeomorphicContainer(
                padding: 20,
                borderRadius: 15,
                child: SizedBox(
                  width: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, color: Color(0xFF2D3748)),
                      SizedBox(width: 12),
                      Text('I am a Student', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                    ],
                  ),
                ),
              ),
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
  String _status = 'Upload audio to begin';
  bool _isUploading = false;
  String? _uploadedLectureStatus;
  int? _uploadedLectureId;
  Timer? _pollTimer;
  String _selectedSourceLang = 'gu'; // Default to Gujarati

  final Map<String, String> _languages = {
    'gu': 'Gujarati',
    'hi': 'Hindi',
    'en': 'English',
    'mr': 'Marathi',
    'ta': 'Tamil',
    'te': 'Telugu',
  };

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _uploadAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null) return;

    setState(() {
      _status = 'Uploading...';
      _isUploading = true;
      _uploadedLectureStatus = null;
      _uploadedLectureId = null;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$BASE_URL/api/lectures/upload/'));
      request.fields['title'] = result.files.single.name;
      request.fields['source_language'] = _selectedSourceLang;
      request.files.add(await http.MultipartFile.fromPath('audio_file', result.files.single.path!));
      var response = await request.send();
      var body = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        var data = json.decode(body);
        _uploadedLectureId = data['id'];
        setState(() {
          _status = 'Processing in background...';
          _uploadedLectureStatus = 'processing';
        });
        _startPolling();
      } else {
        setState(() => _status = 'Upload failed');
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
        final resp = await http.get(Uri.parse('$BASE_URL/api/lectures/$_uploadedLectureId/status/'));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          final st = data['status'] as String;
          setState(() {
            _uploadedLectureStatus = st;
            if (st == 'completed') {
              _status = '✅ Processing complete!';
              _pollTimer?.cancel();
            } else if (st == 'failed') {
              _status = '❌ Failed';
              _pollTimer?.cancel();
            }
          });
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard'), backgroundColor: Colors.transparent),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeomorphicContainer(
                padding: 40,
                child: Icon(
                  _uploadedLectureStatus == 'completed' ? Icons.check_circle : Icons.cloud_upload,
                  size: 80,
                  color: _uploadedLectureStatus == 'completed' ? Colors.green : const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 30),
              
              // Language Selection Dropdown
              const Text('Select Speaking Language:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              const SizedBox(height: 10),
              NeomorphicContainer(
                padding: 4,
                borderRadius: 12,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSourceLang,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(12),
                    items: _languages.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: _isUploading ? null : (val) => setState(() => _selectedSourceLang = val!),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              if (_isUploading || _uploadedLectureStatus == 'processing')
                const Padding(padding: EdgeInsets.only(bottom: 24), child: CircularProgressIndicator()),
              Text(_status, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _isUploading ? null : _uploadAudio,
                child: NeomorphicContainer(
                  borderRadius: 30,
                  padding: 20,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: const Color(0xFF2D3748)),
                      const SizedBox(width: 8),
                      const Text('Upload New Lecture', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                    ],
                  ),
                ),
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
      final response = await http.get(Uri.parse('$BASE_URL/api/lectures/'));
      if (response.statusCode == 200) {
        setState(() => lectures = json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTranscript(int lectureId) async {
    setState(() {
      transcript = 'Loading...';
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('$BASE_URL/api/lectures/$lectureId/transcript/$selectedLang/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => transcript = data['text']);
        if (data['audio_url'] != null) {
          await _audioPlayer.play(UrlSource('$BASE_URL${data['audio_url']}'));
        }
      } else {
        setState(() => transcript = 'Not available yet.');
      }
    } catch (e) {
      setState(() => transcript = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: NeomorphicContainer(
              padding: 8,
              borderRadius: 12,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _langBtn('en', 'English'),
                    const SizedBox(width: 8),
                    _langBtn('hi', 'Hindi'),
                    const SizedBox(width: 8),
                    _langBtn('gu', 'Gujarati'),
                    const SizedBox(width: 8),
                    _langBtn('mr', 'Marathi'),
                    const SizedBox(width: 8),
                    _langBtn('ta', 'Tamil'),
                    const SizedBox(width: 8),
                    _langBtn('te', 'Telugu'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: lectures.length,
              itemBuilder: (ctx, i) {
                final lec = lectures[i];
                final st = lec['status'] ?? 'pending';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: st == 'completed' ? () => _loadTranscript(lec['id']) : null,
                    child: NeomorphicContainer(
                      padding: 16,
                      borderRadius: 15,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(lec['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                        subtitle: Text(st.toUpperCase(), style: TextStyle(color: st == 'completed' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                        trailing: Icon(st == 'completed' ? Icons.play_circle_fill : Icons.hourglass_empty, color: const Color(0xFF2D3748)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (transcript.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: NeomorphicContainer(
                borderRadius: 20,
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: SingleChildScrollView(child: Text(transcript, style: const TextStyle(fontSize: 16, color: Color(0xFF2D3748)))),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _langBtn(String code, String label) {
    bool isSel = selectedLang == code;
    return GestureDetector(
      onTap: () => setState(() { selectedLang = code; transcript = ''; }),
      child: NeomorphicContainer(
        padding: 10,
        borderRadius: 10,
        isPressed: isSel,
        child: Text(label, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
