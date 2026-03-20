import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/pdf_editor_service.dart';

class PdfPageManagerSheet extends StatefulWidget {
  final String pdfPath;
  final VoidCallback onSaved;

  const PdfPageManagerSheet({
    super.key,
    required this.pdfPath,
    required this.onSaved,
  });

  @override
  State<PdfPageManagerSheet> createState() => _PdfPageManagerSheetState();
}

class _PdfPageManagerSheetState extends State<PdfPageManagerSheet> {
  List<Uint8List> _pages = [];
  List<int> _order = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnails();
  }

  Future<void> _loadThumbnails() async {
    setState(() => _loading = true);
    try {
      final thumbs = await PdfEditorService.renderThumbnails(widget.pdfPath);
      if (mounted) {
        setState(() {
          _pages = thumbs;
          _order = List.generate(thumbs.length, (i) => i);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load PDF pages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Reorder ──────────────────────────────────────────────
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final page = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, page);
      final idx = _order.removeAt(oldIndex);
      _order.insert(newIndex, idx);
    });
  }

  // ─── Delete ───────────────────────────────────────────────
  Future<void> _deletePage(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Page'),
        content: Text(
          'Delete page ${index + 1}? This cannot be undone after saving.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      _pages.removeAt(index);
      _order.removeAt(index);
    });
  }

  // ─── Append files ─────────────────────────────────────────
  Future<void> _appendFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.paths.isEmpty) return;

    setState(() => _loading = true);
    try {
      await PdfEditorService.appendFiles(
        widget.pdfPath,
        result.paths.whereType<String>().toList(),
      );
      await _loadThumbnails();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to append files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Camera scan ──────────────────────────────────────────
  Future<void> _appendFromCamera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      await PdfEditorService.appendFiles(widget.pdfPath, [picked.path]);
      await _loadThumbnails();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to append photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Save reorder / deletions ─────────────────────────────
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await PdfEditorService.reorderAndSave(widget.pdfPath, _order);
      widget.onSaved();
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF saved successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.withValues(alpha: 0.08),
                      Colors.indigo.withValues(alpha: 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.indigo.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.indigo,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pdfPath.split('/').last.split('\\').last,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (_loading)
                            Text(
                              'Loading...',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            )
                          else
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_pages.length} page${_pages.length == 1 ? '' : 's'}',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.swipe_vertical_rounded,
                                  size: 13,
                                  color: colorScheme.outline,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    'Hold & drag to reorder',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.outline,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_saving)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      FilledButton.icon(
                        onPressed: _pages.isEmpty ? null : _save,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Save'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.note_add_rounded,
                        label: 'Append Files',
                        color: Colors.indigo,
                        onTap: _loading ? null : _appendFiles,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionChip(
                        icon: Icons.camera_alt_rounded,
                        label: 'Scan Page',
                        color: Colors.teal,
                        onTap: _loading ? null : _appendFromCamera,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Thumbnail list (reorderable)
              Expanded(
                child: _loading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.indigo.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Rendering pages...',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _pages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.insert_drive_file_outlined,
                                  size: 48,
                                  color: colorScheme.outlineVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No pages',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ReorderableListView.builder(
                            scrollController: scrollController,
                            onReorder: _onReorder,
                            itemCount: _pages.length,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            proxyDecorator: (child, index, animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) => Material(
                                  color: Colors.transparent,
                                  elevation: 6,
                                  shadowColor:
                                      Colors.indigo.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(14),
                                  child: child,
                                ),
                                child: child,
                              );
                            },
                            itemBuilder: (context, index) => _PageTile(
                              key: ValueKey('page_${_order[index]}'),
                              imageBytes: _pages[index],
                              pageNumber: index + 1,
                              totalPages: _pages.length,
                              onDelete: () => _deletePage(index),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Page Tile Widget ──────────────────────────────────────────────────────────

class _PageTile extends StatelessWidget {
  final Uint8List imageBytes;
  final int pageNumber;
  final int totalPages;
  final VoidCallback onDelete;

  const _PageTile({
    super.key,
    required this.imageBytes,
    required this.pageNumber,
    required this.totalPages,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Drag handle
          Icon(
            Icons.drag_indicator_rounded,
            color: colorScheme.outlineVariant,
            size: 22,
          ),
          const SizedBox(width: 10),

          // Page thumbnail with number badge
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    imageBytes,
                    width: 60,
                    height: 78,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$pageNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Page info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Page $pageNumber',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'of $totalPages',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

          // Delete button
          Material(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Chip Button ────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Material(
      color: isEnabled ? color.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isEnabled ? color : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isEnabled ? color : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
