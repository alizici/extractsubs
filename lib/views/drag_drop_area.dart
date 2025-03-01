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
    this.height = 200.0,
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: widget.height,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: _isDragging
                  ? theme.primaryColor.withAlpha(38)
                  : _isHovering
                      ? (isDarkMode
                          ? const Color(0xFF2C2C2E).withAlpha(204)
                          : Colors.white.withAlpha(204))
                      : (isDarkMode
                          ? const Color(0xFF2C2C2E).withAlpha(128)
                          : Colors.white.withAlpha(128)),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: _isDragging
                    ? theme.primaryColor
                    : _isHovering
                        ? theme.primaryColor.withAlpha(128)
                        : Colors.transparent,
                width: 1.0,
              ),
              boxShadow: _isHovering || _isDragging
                  ? [
                      BoxShadow(
                        color: theme.shadowColor.withAlpha(26),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: widget.isProcessing
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 48.0,
                        color: _isDragging || _isHovering
                            ? theme.primaryColor
                            : theme.iconTheme.color?.withAlpha(178),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        _isDragging
                            ? 'Dosyaları bırakın'
                            : 'Video dosyalarını buraya sürükleyin',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'veya dosya seçmek için tıklayın',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12.0),
                      if (_isHovering && !_isDragging)
                        Container(
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.file_upload,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Video Dosyalarını Seç',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
