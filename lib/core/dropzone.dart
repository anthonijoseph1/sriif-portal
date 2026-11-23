import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../config.dart';
import 'ui.dart';

// Drag-and-drop + click-to-browse uploading.
// Needs:  flutter pub add file_picker:^8.1.2 desktop_drop:^0.8.1

class PickedFile {
  final String name;
  final int size;
  final Uint8List? bytes;
  PickedFile(this.name, this.size, this.bytes);
  String get ext =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';
  bool get isImage => ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext);
}

const docExts = ['pdf', 'jpg', 'jpeg', 'png', 'docx', 'pptx'];
const imgExts = ['jpg', 'jpeg', 'png', 'webp'];

/// Opens the system file picker. Returns [] if cancelled.
Future<List<PickedFile>> browseFiles({
  List<String> allowed = docExts,
  bool multiple = false,
}) async {
  final List<PlatformFile> files;
  if (multiple) {
    files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowed,
    );
  } else {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: allowed,
    );
    files = file == null ? <PlatformFile>[] : <PlatformFile>[file];
  }

  final picked = <PickedFile>[];
  for (final file in files) {
    final size = file.lengthSync() ?? await file.length() ?? 0;
    final bytes = await file.readAsBytes();
    picked.add(PickedFile(file.name, size, bytes));
  }
  return picked;
}

/// Validates type and size. Returns an error text or null.
String? checkFile(PickedFile f, List<String> allowed, double maxMb) {
  if (!allowed.contains(f.ext))
    return '${f.name}: type not allowed (${allowed.join(', ').toUpperCase()})';
  if (f.size > maxMb * 1048576)
    return '${f.name}: larger than ${maxMb.toStringAsFixed(0)} MB';
  return null;
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      );
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 7), p);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter o) => o.color != color;
}

/// Big dashed drop area. Drag files onto it or click to browse.
class FileDropZone extends StatefulWidget {
  final void Function(List<PickedFile> files) onFiles;
  final List<String> allowed;
  final double maxMb;
  final bool multiple, compact;
  final String title, hint;
  final IconData icon;
  const FileDropZone({
    super.key,
    required this.onFiles,
    this.allowed = docExts,
    this.maxMb = 10,
    this.multiple = true,
    this.compact = false,
    this.title = 'Drag & drop files here',
    this.hint = '',
    this.icon = Icons.cloud_upload_outlined,
  });
  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool drag = false;
  String? error;

  void _handle(List<PickedFile> list) {
    final ok = <PickedFile>[];
    String? err;
    for (final f in list) {
      final e = checkFile(f, widget.allowed, widget.maxMb);
      if (e == null) {
        ok.add(f);
      } else {
        err ??= e;
      }
    }
    setState(() => error = err);
    if (ok.isNotEmpty) widget.onFiles(widget.multiple ? ok : [ok.first]);
  }

  Future<void> _browse() async => _handle(
    await browseFiles(allowed: widget.allowed, multiple: widget.multiple),
  );

  @override
  Widget build(BuildContext context) {
    final hint = widget.hint.isNotEmpty
        ? widget.hint
        : '${widget.allowed.join(', ').toUpperCase()} · up to ${widget.maxMb.toStringAsFixed(0)} MB';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropTarget(
          onDragEntered: (_) => setState(() => drag = true),
          onDragExited: (_) => setState(() => drag = false),
          onDragDone: (d) async {
            setState(() => drag = false);
            final out = <PickedFile>[];
            for (final f in d.files) {
              out.add(
                PickedFile(f.name, await f.length(), await f.readAsBytes()),
              );
            }
            _handle(out);
          },
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _browse,
            child: CustomPaint(
              painter: _DashPainter(
                drag ? Brand.accent : Brand.primary.withOpacity(.35),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: widget.compact ? 16 : 30,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: drag
                      ? Brand.accent.withOpacity(.1)
                      : Brand.primary.withOpacity(.03),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: widget.compact
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.icon, color: Brand.primary),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              drag
                                  ? 'Drop to upload'
                                  : 'Drop files or click to browse',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Brand.primary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Brand.primary.withOpacity(.1),
                            child: Icon(
                              widget.icon,
                              size: 28,
                              color: Brand.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            drag ? 'Drop to upload' : widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.black54),
                              children: [
                                TextSpan(text: 'or '),
                                TextSpan(
                                  text: 'browse your computer',
                                  style: TextStyle(
                                    color: Brand.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hint,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Round photo / logo picker. Click or drop an image on it.
class PhotoPicker extends StatefulWidget {
  final Uint8List? bytes;
  final String name;
  final double size;
  final bool square;
  final ValueChanged<Uint8List> onPicked;
  const PhotoPicker({
    super.key,
    required this.bytes,
    required this.name,
    required this.onPicked,
    this.size = 110,
    this.square = false,
  });
  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  bool drag = false;
  String? error;

  void _take(PickedFile f) {
    final e = checkFile(f, imgExts, 3);
    if (e != null || f.bytes == null) {
      setState(() => error = e ?? 'Could not read the image');
      return;
    }
    setState(() => error = null);
    widget.onPicked(f.bytes!);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.square ? 22.0 : 999.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropTarget(
          onDragEntered: (_) => setState(() => drag = true),
          onDragExited: (_) => setState(() => drag = false),
          onDragDone: (d) async {
            setState(() => drag = false);
            if (d.files.isEmpty) return;
            final f = d.files.first;
            _take(PickedFile(f.name, await f.length(), await f.readAsBytes()));
          },
          child: InkWell(
            customBorder: widget.square
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  )
                : const CircleBorder(),
            onTap: () async {
              final l = await browseFiles(allowed: imgExts);
              if (l.isNotEmpty) _take(l.first);
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      r == 999 ? widget.size : r,
                    ),
                    border: Border.all(
                      color: drag ? Brand.accent : Colors.white,
                      width: 4,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12),
                    ],
                  ),
                  child: Avatar(
                    bytes: widget.bytes,
                    name: widget.name,
                    size: widget.size,
                    radius: r,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Brand.accent,
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              width: widget.size + 40,
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }
}
