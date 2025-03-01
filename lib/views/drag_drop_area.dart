// lib/views/drag_drop_area.dart
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

typedef OnFilesDropped = Function(List<String> filePaths);
typedef OnAreaTapped = Function();

class DragDropArea extends StatefulWidget {
  final OnFilesDropped onFilesDropped;
  final OnAreaTapped onTap;
  final double height;
  final bool isProcessing;

  const DragDropArea({
    Key? key,
    required this.onFilesDropped,
    required this.onTap,
    this.height = 160.0,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  State<DragDropArea> createState() => _DragDropAreaState();
}

class _DragDropAreaState extends State<DragDropArea> {
  bool _isDragging = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        if (widget.isProcessing) return;

        final filePaths = detail.files
            .map((file) => file.path)
            .where((path) => File(path).existsSync())
            .toList();

        if (filePaths.isNotEmpty) {
          widget.onFilesDropped(filePaths);
        }
      },
      onDragEntered: (detail) {
        if (!widget.isProcessing) {
          setState(() {
            _isDragging = true;
          });
        }
      },
      onDragExited: (detail) {
        setState(() {
          _isDragging = false;
        });
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: widget.isProcessing ? null : widget.onTap,
          child: Container(
            height: widget.height,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: _isDragging
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : _isHovering
                      ? Theme.of(context).hoverColor
                      : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: _isDragging
                    ? Theme.of(context).primaryColor
                    : _isHovering
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).dividerColor,
                width: (_isDragging || _isHovering) ? 2.0 : 1.0,
              ),
            ),
            child: widget.isProcessing
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 48.0,
                        color: _isDragging || _isHovering
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        _isDragging
                            ? 'Dosyaları bırakın'
                            : 'Video dosyalarını buraya sürükleyin',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'veya dosya seçmek için tıklayın',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4.0),
                      if (_isHovering && !_isDragging)
                        ElevatedButton.icon(
                          onPressed: widget.onTap,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Video Dosyalarını Seç'),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
