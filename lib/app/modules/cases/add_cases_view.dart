import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/case_model.dart';
import '../../data/models/client_model.dart';
import '../../data/models/hearing_model.dart';
import '../../services/storage_service.dart';
import '../../utils/font_styles.dart';
import '../../widgets/pdf_page_manager_sheet.dart';
import '../clients/add_client_view.dart';
import 'History/hearing_view.dart';

enum DocumentSourceType { files, scan, camera }

class DocumentPickerResult {
  final List<String> paths;
  final DocumentSourceType source;
  final String? error;
  DocumentPickerResult({required this.paths, required this.source, this.error});
  bool get isSuccess => error == null && paths.isNotEmpty;
}

class AddCaseView extends StatefulWidget {
  final CaseModel? existingCase;
  const AddCaseView({super.key, this.existingCase});

  @override
  State<AddCaseView> createState() => _AddCaseViewState();
}

class _AddCaseViewState extends State<AddCaseView> {
  final StorageService _storage = StorageService.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _courtController = TextEditingController();
  final _caseNoController = TextEditingController();
  final _notesController = TextEditingController();
  final _petitionerController = TextEditingController();
  final _petitionerAdvController = TextEditingController();
  final _respondentController = TextEditingController();
  final _respondentAdvController = TextEditingController();
  final _vakalatNameController = TextEditingController();
  final _srNoController = TextEditingController();
  final _registrationNoController = TextEditingController();

  String _status = 'Pending';
  DateTime? _vakalatDate;
  DateTime? _registrationDate;
  DateTime? _hearingDate;
  DateTime? _filingDate;
  List<String> _vakalatMembers = [];
  List<String> _attachedFiles = [];
  List<DateTime>? _hearingDates = [];
  ClientModel? _selectedClient;
  List<ClientModel> _clients = [];

  // ── Init (unchanged) ─────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeForm();
    if (widget.existingCase != null) {
      final c = widget.existingCase!;
      _titleController.text = c.title;
      _courtController.text = c.court;
      _caseNoController.text = c.caseNo;
      _notesController.text = c.notes;
      _status = c.status;
      _hearingDate = c.nextHearing;
      _petitionerController.text = c.petitioner ?? '';
      _petitionerAdvController.text = c.petitionerAdv ?? '';
      _respondentController.text = c.respondent ?? '';
      _respondentAdvController.text = c.respondentAdv ?? '';
      _attachedFiles = List<String>.from(c.attachedFiles ?? []);
      _vakalatMembers = c.vakalatMembers ?? [];
      _srNoController.text = c.srNo ?? '';
      _registrationDate = c.registrationDate;
      _filingDate = c.filingDate;
      _vakalatDate = c.vakalatDate;
      _registrationNoController.text = c.registrationNo ?? '';
      _hearingDates = c.hearingDates;
    }
  }

  Future<void> _initializeForm() async {
    final clientsBox = await _storage.getBox<ClientModel>('clients');
    if (!mounted) return;
    setState(() {
      _clients = clientsBox.values.toList();
      if (widget.existingCase?.clientId != null) {
        _selectedClient = _clients.firstWhereOrNull(
          (cl) => cl.id == widget.existingCase!.clientId,
        );
      }
    });
  }

  // ── Save (unchanged) ─────────────────────────────────────────────────────

  void _saveCase() async {
    if (_formKey.currentState!.validate() && _selectedClient != null) {
      if (widget.existingCase != null) {
        widget.existingCase!
          ..title = _titleController.text.trim()
          ..clientName = _selectedClient!.name
          ..clientId = _selectedClient!.id
          ..court = _courtController.text.trim()
          ..caseNo = _caseNoController.text.trim()
          ..status = _status
          ..petitioner = _petitionerController.text.trim()
          ..petitionerAdv = _petitionerAdvController.text.trim()
          ..respondent = _respondentController.text.trim()
          ..respondentAdv = _respondentAdvController.text.trim()
          ..attachedFiles = _attachedFiles
          ..vakalatMembers = _vakalatMembers
          ..srNo = _srNoController.text.trim()
          ..registrationDate = _registrationDate
          ..filingDate = _filingDate
          ..vakalatDate = _vakalatDate
          ..registrationNo = _registrationNoController.text.trim()
          ..hearingDates = _hearingDates;
        await widget.existingCase!.save();
        Get.back(result: 'updated');
        Get.snackbar('Updated', 'Case updated successfully!');
      } else {
        final newCase = CaseModel(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          clientName: _selectedClient!.name,
          clientId: _selectedClient!.id,
          court: _courtController.text.trim(),
          caseNo: _caseNoController.text.trim(),
          status: _status,
          nextHearing: _hearingDate,
          notes: _notesController.text.trim(),
          petitioner: _petitionerController.text.trim(),
          petitionerAdv: _petitionerAdvController.text.trim(),
          respondent: _respondentController.text.trim(),
          respondentAdv: _respondentAdvController.text.trim(),
          attachedFiles: _attachedFiles,
          vakalatMembers: _vakalatMembers,
          srNo: _srNoController.text.trim(),
          registrationDate: _registrationDate,
          filingDate: _filingDate,
          vakalatDate: _vakalatDate,
          registrationNo: _registrationNoController.text.trim(),
          hearingDates: _hearingDates,
        );
        final casesBox = await _storage.getBox<CaseModel>('cases');
        await casesBox.add(newCase);
        await _createInitialHearingEntryIfNeeded(newCase);
        Get.back(result: 'updated');
        Get.snackbar('Success', 'Case added successfully!');
      }
    }
  }

  Future<void> _createInitialHearingEntryIfNeeded(CaseModel newCase) async {
    final notes = _notesController.text.trim();
    if (_hearingDate == null && notes.isEmpty) return;
    final hearingsBox = await _storage.getBox<hearingModel>('hearings');
    final initialHearing = hearingModel(
      id: const Uuid().v4(),
      caseId: newCase.id,
      hearingDate: _hearingDate ?? DateTime.now(),
      summary: 'Initial entry from case creation',
      orderNotes: null,
      nextHearingDate: _hearingDate,
      nextHearingPurpose: null,
      nextHearingNotes: notes.isEmpty ? null : notes,
      attachedFiles: const <String>[],
      extraFields: const <String, dynamic>{'source': 'case_create'},
      createdAt: DateTime.now(),
    );
    await hearingsBox.add(initialHearing);
  }

  // ── Date Pickers (unchanged) ──────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hearingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _hearingDate = picked);
  }

  Future<void> _pickFilingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _filingDate = picked);
  }

  Future<void> _pickRegistrationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _registrationDate = picked);
  }

  void _addNewClient() async {
    await Get.toNamed('/add-client');
    await _initializeForm();
  }

  // ── File Picking (unchanged) ──────────────────────────────────────────────

  Future<void> _pickFiles() async {
    try {
      final sourceType = await _showDocumentSourcePicker();
      if (sourceType == null) return;
      _showLoadingDialog();
      final result = await _handleDocumentSelection(sourceType);
      if (mounted && Navigator.of(context).canPop()){
        Navigator.of(context).pop();
      }
      if (result.isSuccess) {
        await _processSelectedFiles(result.paths, result.source);
        _showSuccessMessage(result.paths.length, result.source);
      } else if (result.error != null) {
        _showErrorMessage(result.error!);
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()){
        Navigator.of(context).pop();
      }
      _showErrorMessage('Failed to pick files: ${e.toString()}');

    }
  }

  Future<DocumentSourceType?> _showDocumentSourcePicker() {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return showModalBottomSheet<DocumentSourceType>(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attach Document',
                style: FontStyles.subheading.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 16),
              _SourceTile(
                icon: Icons.folder_open_rounded,
                label: 'Pick from Files',
                onTap: () => Navigator.pop(context, DocumentSourceType.files),
              ),
              _SourceTile(
                icon: Icons.document_scanner_outlined,
                label: 'Scan Document',
                onTap: () => Navigator.pop(context, DocumentSourceType.scan),
              ),
              _SourceTile(
                icon: Icons.camera_alt_outlined,
                label: 'Use Camera',
                onTap: () => Navigator.pop(context, DocumentSourceType.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<DocumentPickerResult> _handleDocumentSelection(DocumentSourceType t) {
    switch (t) {
      case DocumentSourceType.files:
        return _pickFromFiles();
      case DocumentSourceType.scan:
        return _scanDocuments();
      case DocumentSourceType.camera:
        return _captureFromCamera();
    }
  }

  Future<DocumentPickerResult> _pickFromFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      );
      if (result == null){
        return DocumentPickerResult(
          paths: [],
          source: DocumentSourceType.files,
        );
      }
      return DocumentPickerResult(
        paths: result.paths.whereType<String>().toList(),
        source: DocumentSourceType.files,
      );
    } catch (e) {
      return DocumentPickerResult(
        paths: [],
        source: DocumentSourceType.files,
        error: e.toString(),
      );
    }
  }

  Future<DocumentPickerResult> _scanDocuments() async {
    try {
      final scanned = await CunningDocumentScanner.getPictures();
      if (scanned == null || scanned.isEmpty)
        {return DocumentPickerResult(paths: [], source: DocumentSourceType.scan);}
      return DocumentPickerResult(
        paths: scanned,
        source: DocumentSourceType.scan,
      );
    } catch (e) {
      return DocumentPickerResult(
        paths: [],
        source: DocumentSourceType.scan,
        error: e.toString(),
      );
    }
  }

  Future<DocumentPickerResult> _captureFromCamera() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null)
        {return DocumentPickerResult(
          paths: [],
          source: DocumentSourceType.camera,
        );}
      return DocumentPickerResult(
        paths: [image.path],
        source: DocumentSourceType.camera,
      );
    } catch (e) {
      return DocumentPickerResult(
        paths: [],
        source: DocumentSourceType.camera,
        error: e.toString(),
      );
    }
  }

  Future<void> _processSelectedFiles(
    List<String> files,
    DocumentSourceType source,
  ) async {
    final valid = await _validateFiles(files);
    if (valid.isEmpty) throw Exception('No valid files selected');
    final local = await saveFilesToLocalStorage(valid);
    setState(() => _attachedFiles.addAll(local));
  }

  Future<List<String>> _validateFiles(List<String> files) async {
    final valid = <String>[];
    const maxSize = 10 * 1024 * 1024;
    for (final f in files) {
      try {
        final file = File(f);
        if (await file.exists() && await file.length() <= maxSize) valid.add(f);
      } catch (_) {}
    }
    return valid;
  }

  void _showLoadingDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: cs.primary)),
    );
  }

  void _showSuccessMessage(int count, DocumentSourceType source) {
    final label = source == DocumentSourceType.files
        ? 'files selected'
        : source == DocumentSourceType.scan
        ? 'documents scanned'
        : 'photo captured';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$count $label successfully',
          style: FontStyles.bodySmall,
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String error) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error, style: FontStyles.bodySmall),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        // action: SnackBarAction(
        //   label: 'Dismiss',
        //   textColor: Colors.white,
        //   onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        // ),
      ),
    );

  }

  Future<List<String>> saveFilesToLocalStorage(List<String> paths) async {
    final List<String> copied = [];
    final appDir = await getApplicationDocumentsDirectory();
    for (final orig in paths) {
      final file = File(orig);
      if (await file.exists()) {
        final baseName = p.basenameWithoutExtension(orig);
        final ext = p.extension(orig);
        final stem = baseName.isEmpty ? 'attachment' : baseName;
        final now = DateTime.now().microsecondsSinceEpoch;

        var fileName = '${stem}_$now$ext';
        var newPath = p.join(appDir.path, fileName);
        var sequence = 1;

        while (await File(newPath).exists()) {
          fileName = '${stem}_${now}_$sequence$ext';
          newPath = p.join(appDir.path, fileName);
          sequence++;
        }

        await file.copy(newPath);
        copied.add(newPath);
      }
    }
    return copied;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEditing = widget.existingCase != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? cs.primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Case' : 'New Case',
                  style: FontStyles.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.appBarTheme.foregroundColor ?? Colors.white,
                  ),
                ),
                if (isEditing)
                  Text(
                    widget.existingCase!.title,
                    style: FontStyles.caption.copyWith(
                      color: (theme.appBarTheme.foregroundColor ?? Colors.white)
                          .withValues(alpha: 0.55),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                
              ],
            ),
            Spacer(),
                if (isEditing)
                  ElevatedButton(
                    onPressed: () {
                      Get.to(
                        () =>
                            HearingHistoryView(caseData: widget.existingCase!),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.secondaryFixedDim,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(0, 0),
                    ),
                    child: Text(
                      'Edit Hearing',
                      style: FontStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Case Details ─────────────────────────────────────────────
            _FormSection(
              title: 'Case Details',
              icon: Icons.gavel_rounded,
              accentColor: cs.primary,
              children: [
                _StyledField(
                  controller: _titleController,
                  label: 'Case Title *',
                  icon: Icons.title_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Case title is required'
                      : null,
                ),
                const SizedBox(height: 14),
                _StyledField(
                  controller: _courtController,
                  label: 'Court',
                  icon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: 14),
                _StyledField(
                  controller: _registrationNoController,
                  label: 'Case / Registration No',
                  icon: Icons.numbers_rounded,
                ),
                const SizedBox(height: 14),
                _DatePickerTile(
                  label: 'Registration Date',
                  date: _registrationDate,
                  icon: Icons.app_registration_outlined,
                  onTap: _pickRegistrationDate,
                ),
                const SizedBox(height: 14),
                // Client row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ClientModel>(
                        initialValue: _selectedClient,
                        isExpanded: true,
                        dropdownColor: theme.cardColor,
                        style: FontStyles.bodySmall.copyWith(
                          color: cs.onSurface,
                        ),
                        decoration: _dec(
                          context,
                          'Client *',
                          Icons.person_outline,
                        ),
                        items: [
                          ..._clients.map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                                style: FontStyles.bodySmall.copyWith(
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'None',
                              style: FontStyles.bodySmall.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedClient = val),
                        validator: (val) {
                          if (val == null) {
                            Get.snackbar(
                              'Error',
                              'Please select a client',
                              backgroundColor: cs.error.withValues(alpha: 0.1),
                              colorText: cs.error,
                            );
                            return 'Please select a client';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _CircleBtn(
                      icon: Icons.person_add_alt_1_outlined,
                      color: cs.primary,
                      onTap: _addNewClient,
                      tooltip: 'Add New Client',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Administrative ────────────────────────────────────────────
            _FormSection(
              title: 'Administrative',
              icon: Icons.admin_panel_settings_outlined,
              accentColor: cs.secondary,
              children: [
                _StyledField(
                  controller: _srNoController,
                  label: 'SR No',
                  icon: Icons.confirmation_number_outlined,
                ),
                const SizedBox(height: 14),
                _DatePickerTile(
                  label: 'Filing Date',
                  date: _filingDate,
                  icon: Icons.upload_file_outlined,
                  onTap: _pickFilingDate,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  dropdownColor: theme.cardColor,
                  style: FontStyles.bodySmall.copyWith(color: cs.onSurface),
                  items: ['Pending', 'Un Numbered', 'Disposed', 'Closed']
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            style: FontStyles.bodySmall.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _status = val!),
                  decoration: _dec(context, 'Status', Icons.flag_outlined),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Vakalat Details ───────────────────────────────────────────
            _ExpandableFormSection(
              title: 'Vakalat Details',
              icon: Icons.description_outlined,
              accentColor: const Color.fromARGB(255, 58, 120, 255),
              children: [
                ..._vakalatMembers.map(
                  (member) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            member,
                            style: FontStyles.bodySmall.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _vakalatMembers.remove(member)),
                          child: Icon(Icons.close, size: 15, color: cs.error),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StyledField(
                        controller: _vakalatNameController,
                        label: 'Add Member',
                        icon: Icons.person_add_alt_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _CircleBtn(
                      icon: Icons.add,
                      color: const Color(0xFF7C3AED),
                      onTap: () {
                        final name = _vakalatNameController.text.trim();
                        if (name.isNotEmpty) {
                          setState(() {
                            _vakalatMembers.add(name);
                            _vakalatNameController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _DatePickerTile(
                  label: 'Date of Vakalat',
                  date: _vakalatDate,
                  icon: Icons.event_outlined,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _vakalatDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _vakalatDate = picked);
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Parties ───────────────────────────────────────────────────
            _ExpandableFormSection(
              title: 'Parties',
              icon: Icons.people_alt_outlined,
              accentColor: const Color(0xFF059669),
              children: [
                _StyledField(
                  controller: _petitionerController,
                  label: 'Petitioner',
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                _StyledField(
                  controller: _petitionerAdvController,
                  label: 'Petitioner Advocate',
                  icon: Icons.work_outline,
                ),
                const SizedBox(height: 12),
                _StyledField(
                  controller: _respondentController,
                  label: 'Respondent',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _StyledField(
                  controller: _respondentAdvController,
                  label: 'Respondent Advocate',
                  icon: Icons.work_history_outlined,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Attachments ───────────────────────────────────────────────
            _ExpandableFormSection(
              title:
                  'Attachments${_attachedFiles.isNotEmpty ? ' (${_attachedFiles.length})' : ''}',
              icon: Icons.attach_file_rounded,
              accentColor: cs.secondary,
              children: [
                if (_attachedFiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Vakalat and other case files can be attached here.',
                      style: FontStyles.caption.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ..._attachedFiles.map(
                  (file) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          file.toLowerCase().endsWith('.pdf')
                              ? Icons.picture_as_pdf_outlined
                              : Icons.insert_drive_file_outlined,
                          color: cs.secondary,
                          size: 15,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            file.split('/').last,
                            style: FontStyles.caption.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (file.toLowerCase().endsWith('.pdf'))
                          GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => PdfPageManagerSheet(
                                pdfPath: file,
                                onSaved: () => setState(() {}),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit_note_outlined,
                                size: 17,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _attachedFiles.remove(file)),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 15, color: cs.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickFiles,
                  icon: Icon(
                    Icons.attach_file_rounded,
                    size: 18,
                    color: cs.secondary,
                  ),
                  label: Text(
                    'Attach Files',
                    style: FontStyles.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.secondary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.secondary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Notes + Hearing (new case only) ───────────────────────────
            // if (!isEditing) ...[
            //   _FormSection(
            //     title: 'Notes',
            //     icon: Icons.sticky_note_2_outlined,
            //     accentColor: const Color(0xFFD97706),
            //     children: [
            //       TextFormField(
            //         controller: _notesController,
            //         maxLines: 4,
            //         style: FontStyles.bodySmall.copyWith(color: cs.onSurface),
            //         decoration: _dec(
            //           context,
            //           'Add case notes here…',
            //           Icons.notes_rounded,
            //         ).copyWith(alignLabelWithHint: true),
            //       ),
            //     ],
            //   ),
            //   const SizedBox(height: 14),
            //   _FormSection(
            //     title: 'First Hearing Date',
            //     icon: Icons.event_rounded,
            //     accentColor: const Color(0xFFD97706),
            //     children: [
            //       _DatePickerTile(
            //         label: 'Next Hearing Date',
            //         date: _hearingDate,
            //         icon: Icons.schedule_rounded,
            //         onTap: _pickDate,
            //         highlighted: true,
            //       ),
            //     ],
            //   ),
            //   const SizedBox(height: 14),
            // ],

            // ── Save Button ───────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _saveCase,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text(
                isEditing ? 'Update Case' : 'Save Case',
                style: FontStyles.button,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Input decoration helper ───────────────────────────────────────────────

  static InputDecoration _dec(BuildContext ctx, String label, IconData icon) {
    final cs = Theme.of(ctx).colorScheme;
    final theme = Theme.of(ctx);
    return InputDecoration(
      labelText: label,
      labelStyle: FontStyles.caption.copyWith(
        color: cs.onSurface.withValues(alpha: 0.5),
      ),  
      prefixIcon: Icon(icon, color: cs.onSurface.withValues(alpha: 0.4), size: 19),
      filled: true,
      fillColor: theme.brightness == Brightness.dark ? cs.surface : cs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
    );
  }
}

// ── Styled Field ──────────────────────────────────────────────────────────────

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      style: FontStyles.bodySmall.copyWith(
        color: cs.onSurface,
        fontWeight: FontWeight.w500,
      ),
      decoration: _AddCaseViewState._dec(context, label, icon),
      validator: validator,
    );
  }
}

// ── Date Picker Tile ──────────────────────────────────────────────────────────

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDate = date != null;
    final activeColor = highlighted
        ? cs.primary
        : cs.onSurface.withValues(alpha: 0.45);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlighted && hasDate
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: activeColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: FontStyles.caption.copyWith(
                      color: activeColor, 
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDate
                        ? '${date!.day.toString().padLeft(2, '0')} / ${date!.month.toString().padLeft(2, '0')} / ${date!.year}'
                        : 'Tap to select',
                    style: FontStyles.bodySmall.copyWith(
                      color: hasDate
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.4),
                      fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 16, color: activeColor),
          ],
        ),
      ),
    );
  }
}

// ── Form Section ──────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.28 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _SectionHeader(title: title, icon: icon, accentColor: accentColor),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha:  0.4)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expandable Form Section ───────────────────────────────────────────────────

class _ExpandableFormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const _ExpandableFormSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.28 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: _SectionHeader(
              title: title,
              icon: icon,
              accentColor: accentColor,
            ),
            children: [
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 17),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: FontStyles.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Circle Button ─────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;
  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: color.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── Source Tile ───────────────────────────────────────────────────────────────

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: cs.primary, size: 20),
      ),
      title: Text(
        label,
        style: FontStyles.bodySmall.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
