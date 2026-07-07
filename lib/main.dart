import 'dart:convert';
import 'dart:io' show File, Directory;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnd_player/mnd_player.dart';
import 'package:mnd_player/services/mnd_player_bootstrap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? setupError;
  try {
    await _setupQuestAssets();
  } catch (e) {
    setupError = e.toString();
  }

  try {
    MndPlayerBootstrap.initialize();
  } catch (_) {
    if (setupError == null) setupError = 'Failed to initialize player engine';
  }

  runApp(ProviderScope(child: TemplateQuestApp(bootstrapError: setupError)));
}

Future<void> _setupQuestAssets() async {
  final appDir = await getApplicationDocumentsDirectory();
  final targetDir = p.join(appDir.path, 'quests', 'embedded');
  final configPath = p.join(targetDir, 'config.json');

  final alreadyExtracted = await File(configPath).exists();
  if (alreadyExtracted && !kDebugMode) return;

  try {
    if (alreadyExtracted) {
      await Directory(targetDir).delete(recursive: true);
    }
  } catch (_) {}

  await Directory(targetDir).create(recursive: true);

  final data = await rootBundle.load('assets/quest.mnd');
  final rawBytes = data.buffer.asUint8List();

  final header = String.fromCharCodes(rawBytes.take(8));
  Uint8List zipBytes;
  if (header == 'MND_ZIP_') {
    zipBytes = Uint8List.sublistView(rawBytes, 8);
  } else {
    zipBytes = rawBytes;
  }

  final archive = ZipDecoder().decodeBytes(zipBytes);

  for (final file in archive) {
    final targetPath = p.join(targetDir, file.name);
    if (file.isFile) {
      final targetFile = File(targetPath);
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(file.content as List<int>);
    } else {
      await Directory(targetPath).create(recursive: true);
    }
  }
}

class TemplateQuestApp extends ConsumerStatefulWidget {
  final String? bootstrapError;
  const TemplateQuestApp({super.key, this.bootstrapError});

  @override
  ConsumerState<TemplateQuestApp> createState() => _TemplateQuestAppState();
}

class _TemplateQuestAppState extends ConsumerState<TemplateQuestApp> {
  String? _error;
  bool _loading = true;
  String? _questId;
  String? _startNodeId;

  @override
  void initState() {
    super.initState();
    final preExistingError = widget.bootstrapError;
    if (preExistingError != null) {
      setState(() {
        _error = preExistingError;
        _loading = false;
      });
      return;
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      final configPath =
          p.join(appDir.path, 'quests', 'embedded', 'config.json');
      final configFile = File(configPath);

      if (!await configFile.exists()) {
        throw Exception('config.json not found in embedded quest');
      }

      final content = await configFile.readAsString();
      final config = jsonDecode(content) as Map<String, dynamic>;
      final startNodeId = config['startNodeId'] as String? ?? '';

      if (mounted) {
        setState(() {
          _questId = 'embedded';
          _startNodeId = startNodeId;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null || _questId == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SelectableText(
                _error ?? 'Unknown error',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      ),
      home: GameScreen(
        questId: _questId!,
        startNodeId: _startNodeId,
        isTesting: false,
        isOnboarding: false,
      ),
    );
  }
}
