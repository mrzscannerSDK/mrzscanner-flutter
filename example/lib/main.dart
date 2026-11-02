import 'package:flutter/material.dart';
import 'package:mrzscanner/mrzscanner.dart';

void main() => runApp(const MaterialApp(home: ExamplePage()));

/// Scans with the camera and shows the reads.
class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final _lines = <String>[];

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Your licence key: without it some fields come back masked.
    final licence = await MRZScanner.registerLicense('MRZ2...');
    _log('core ${await MRZScanner.version()} · licence ${licence.accepted ? "accepted" : licence.status}');
  }

  Future<void> _scan({bool continuous = false}) async {
    final result = await MRZScanner.scan(ScanSettings(
      continuous: continuous,
      timeout: continuous ? const Duration(seconds: 20) : null,
    ));
    _log('${result.status.name} after ${result.elapsed.inMilliseconds} ms');
    for (final read in result.reads) {
      _log('${read.kind}: ${read.field("surnames")}, ${read.field("given_names")} · '
          '${read.field("document_number")} · check digits ${read.checkDigitsValid ? "ok" : "bad"}\n${read.text}');
    }
  }

  void _log(String line) => setState(() => _lines.add(line));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('MRZ scanner')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Wrap(spacing: 12, children: [
            FilledButton(onPressed: _scan, child: const Text('Scan')),
            OutlinedButton(onPressed: () => _scan(continuous: true), child: const Text('Scan continuous')),
          ]),
          const SizedBox(height: 16),
          for (final line in _lines)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: SelectableText(line, style: const TextStyle(fontFamily: 'monospace'))),
        ]),
      );
}
