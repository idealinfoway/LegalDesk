import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/case_model.dart';
import '../../data/models/client_model.dart';
import '../clients/add_client_view.dart';

enum DocumentSourceType { files, scan, camera }

class DocumentPickerResult {
  final List<String> paths;
  final DocumentSourceType source;
  final String? error;

  DocumentPickerResult({
    required this.paths,
    required this.source,
    this.error,
  });

  bool get isSuccess => error == null && paths.isNotEmpty;
}

class AddCaseView extends StatefulWidget {
  final CaseModel? existingCase;

  const AddCaseView({super.key, this.existingCase});

  @override
  State<AddCaseView> createState() => _AddCaseViewState();
}

class _AddCaseViewState extends State<AddCaseView> {
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
  // final _registrationDateController = TextEditingController();

  String _status = 'Pending';
  DateTime? _vakalatDate;
  DateTime? _registrationDate;
  DateTime? _hearingDate;
  DateTime? _filingDate;
  List<String> _vakalatMembers = [];
  List<String> _attachedFiles = [];

  ClientModel? _selectedClient;
  List<ClientModel> _clients = [];

  @override
  void initState() {
    super.initState();
    _clients = Hive.box<ClientModel>('clients').values.toList();

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

      if (c.clientId != null) {
        _selectedClient = _clients.firstWhereOrNull(
          (cl) => cl.id == c.clientId,
        );
      }
    }
  }

  void _saveCase() async {
    if (_formKey.currentState!.validate() && _selectedClient != null) {
      if (_attachedFiles.isNotEmpty) {
        // Text('${_attachedFiles.length} files attached');}
        print("Attached");
      } else {
        print("Not Attached");
      }

      if (widget.existingCase != null) {
        widget.existingCase!
          ..title = _titleController.text.trim()
          ..clientName = _selectedClient!.name
          ..clientId = _selectedClient!.id
          ..court = _courtController.text.trim()
          ..caseNo = _caseNoController.text.trim()
          ..status = _status
          ..nextHearing = _hearingDate
          ..notes = _notesController.text.trim()
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
          ..registrationNo = _registrationNoController.text.trim();

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
        );

        await Hive.box<CaseModel>('cases').add(newCase);
        Get.back(result: 'updated');
        // Get.back(result: 'updated');

        Get.snackbar('Success', 'Case added successfully!');
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hearingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _hearingDate = picked);
  }

  Future<void> _pickFilingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _filingDate = picked);
  }

  Future<void> _pickRegistrationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _registrationDate = picked);
  }

  void _addNewClient() async {
    await Get.to(() => AddClientView());
    setState(() {
      _clients = Hive.box<ClientModel>('clients').values.toList();
    });
  }

  Future<void> _pickFiles() async {
  try {
    final sourceType = await _showDocumentSourcePicker();
    if (sourceType == null) return;

    // Show loading indicator
    _showLoadingDialog();

    final result = await _handleDocumentSelection(sourceType);
    
    // Hide loading indicator
    Navigator.of(context).pop();

    if (result.isSuccess) {
      await _processSelectedFiles(result.paths, result.source);
      _showSuccessMessage(result.paths.length, result.source);
    } else if (result.error != null) {
      _showErrorMessage(result.error!);
    }
  } catch (e) {
    // Hide loading indicator if still showing
    if (Navigator.canPop(context)) Navigator.of(context).pop();
    _showErrorMessage('An unexpected error occurred: ${e.toString()}');
  }
}

Future<DocumentSourceType?> _showDocumentSourcePicker() async {
  return await showModalBottomSheet<DocumentSourceType>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Document Source',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
            title: const Text('Pick from Files'),
            subtitle: const Text('Choose from device storage'),
            onTap: () => Navigator.pop(context, DocumentSourceType.files),
          ),
          ListTile(
            leading: const Icon(Icons.document_scanner, color: Colors.green),
            title: const Text('Scan Document'),
            subtitle: const Text('Scan with camera'),
            onTap: () => Navigator.pop(context, DocumentSourceType.scan),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.orange),
            title: const Text('Take Photo'),
            subtitle: const Text('Capture with camera'),
            onTap: () => Navigator.pop(context, DocumentSourceType.camera),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Future<DocumentPickerResult> _handleDocumentSelection(DocumentSourceType sourceType) async {
  switch (sourceType) {
    case DocumentSourceType.files:
      return await _pickFromFiles();
    case DocumentSourceType.scan:
      return await _scanDocuments();
    case DocumentSourceType.camera:
      return await _captureFromCamera();
  }
}

Future<DocumentPickerResult> _pickFromFiles() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
    );

    if (result == null) {
      return DocumentPickerResult(
        paths: [],
        source: DocumentSourceType.files,
      );
    }

    final files = result.paths.whereType<String>().toList();
    return DocumentPickerResult(
      paths: files,
      source: DocumentSourceType.files,
    );
  } catch (e) {
    return DocumentPickerResult(
      paths: [],
      source: DocumentSourceType.files,
      error: 'Failed to pick files: ${e.toString()}',
    );
  }
}

Future<DocumentPickerResult> _scanDocuments() async {
  try {
    final scannedFiles = await CunningDocumentScanner.getPictures();
    
    if (scannedFiles == null || scannedFiles.isEmpty) {
      return DocumentPickerResult(
        paths: [],
        source: DocumentSourceType.scan,
      );
    }

    return DocumentPickerResult(
      paths: scannedFiles,
      source: DocumentSourceType.scan,
    );
  } catch (e) {
    return DocumentPickerResult(
      paths: [],
      source: DocumentSourceType.scan,
      error: 'Failed to scan documents: ${e.toString()}',
    );
  }
}

Future<DocumentPickerResult> _captureFromCamera() async {
  try {
    // Assuming you have image_picker package
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image == null) {
      return DocumentPickerResult(
        paths: [],
        source: DocumentSourceType.camera,
      );
    }

    return DocumentPickerResult(
      paths: [image.path],
      source: DocumentSourceType.camera,
    );
  } catch (e) {
    return DocumentPickerResult(
      paths: [],
      source: DocumentSourceType.camera,
      error: 'Failed to capture image: ${e.toString()}',
    );
  }
}

Future<void> _processSelectedFiles(List<String> files, DocumentSourceType source) async {
  try {
    // Validate files before processing
    final validFiles = await _validateFiles(files);
    if (validFiles.isEmpty) {
      throw Exception('No valid files selected');
    }

    final localPaths = await saveFilesToLocalStorage(validFiles);
    
    setState(() {
      _attachedFiles.addAll(localPaths);
    });
  } catch (e) {
    throw Exception('Failed to process files: ${e.toString()}');
  }
}

Future<List<String>> _validateFiles(List<String> files) async {
  final validFiles = <String>[];
  const maxFileSize = 10 * 1024 * 1024; // 10MB limit
  
  for (final filePath in files) {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize <= maxFileSize) {
          validFiles.add(filePath);
        } else {
          print('File too large: ${file.path}');
        }
      }
    } catch (e) {
      print('Error validating file: $filePath, Error: $e');
    }
  }
  
  return validFiles;
}

void _showLoadingDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
}

void _showSuccessMessage(int fileCount, DocumentSourceType source) {
  final sourceText = source == DocumentSourceType.files 
      ? 'files selected' 
      : source == DocumentSourceType.scan 
        ? 'documents scanned'
        : 'photo captured';
        
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$fileCount $sourceText successfully'),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _showErrorMessage(String error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    ),
  );
}

  Future<List<String>> saveFilesToLocalStorage(List<String> paths) async {
    final List<String> copiedPaths = [];
    final appDir = await getApplicationDocumentsDirectory();

    for (final originalPath in paths) {
      final file = File(originalPath);
      if (await file.exists()) {
        final newPath = p.join(appDir.path, p.basename(originalPath));
        await file.copy(newPath);
        copiedPaths.add(newPath);
      }
    }
    return copiedPaths;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCase == null ? 'Add New Case' : 'Edit Case'),
        elevation: 0,
      ),
      body: Container(
        // decoration: BoxDecoration(
        //   ,
        //   gradient: LinearGradient(
        //     begin: Alignment.topCenter,
        //     end: Alignment.bottomCenter,
        //     colors: [
        //       colorScheme.primary.withOpacity(0.05),
        //       theme.scaffoldBackgroundColor,
        //     ],
        //     stops: const [0.0, 0.3],
        //   ),
        // ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.gavel,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Case Information',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // TextFormField(
                    //   controller: _caseNoController,
                    //   decoration: InputDecoration(
                    //     labelText: 'Case No',
                    //     prefixIcon: Icon(
                    //       Icons.numbers,
                    //       color: colorScheme.secondary,
                    //     ),
                    //     filled: true,
                    //     fillColor: colorScheme.surface,
                    //   ),
                    //   keyboardType: TextInputType.number,
                    // ),
                    // const SizedBox(height: 24),
                    TextFormField(
                      controller: _courtController,
                      decoration: InputDecoration(
                        labelText: 'Court',
                        prefixIcon: Icon(
                          Icons.location_city,
                          color: colorScheme.secondary,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Case Title *',
                        prefixIcon: Icon(
                          Icons.view_headline_rounded,
                          color: colorScheme.primary,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,

                        // border: OutlineInputBorder(
                        //   borderRadius: BorderRadius.circular(8),
                        //   borderSide: BorderSide(color: colorScheme.outline),
                        // ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Case title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _registrationNoController,
                      decoration: InputDecoration(
                        labelText: 'Case/Registration No',
                        prefixIcon: Icon(
                          Icons.numbers,
                          color: colorScheme.secondary,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                      
                    ),
                    const SizedBox(height: 20),
                    _buildDateTile(
                      context,
                      'Registration Date',
                      _registrationDate,
                      _pickRegistrationDate,
                      Icons.app_registration,
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ClientModel>(
                            value: _selectedClient,
                            items:
                                _clients
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c.name),
                                      ),
                                    )
                                    .toList()
                                  ..add(
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text('None'),
                                    ),
                                  ),

                            onChanged: (val) =>
                                setState(() => _selectedClient = val),
                            decoration: InputDecoration(
                              labelText: 'Client *',
                              prefixIcon: Icon(
                                Icons.person,
                                color: colorScheme.primary,
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.outline,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null) {
                                print("hmmm");
                                Get.snackbar(
                                  'Validation Error',
                                  'Client must not be empty',
                                  backgroundColor: Colors.red.withValues(
                                    alpha: 0.1,
                                  ),
                                  colorText: Colors.red,
                                  icon: const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                );
                                return 'Please select a client';
                                // Show a toast/snackbar if client is not selected
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, color: colorScheme.primary),
                            onPressed: _addNewClient,
                            tooltip: 'Add New Client',
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Court Details Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            color: colorScheme.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Court Details',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 12),
                    _buildDateTile(
                      context,
                      'Filing Date',
                      _filingDate,
                      _pickFilingDate,
                      Icons.file_upload,
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 16),

                    // const SizedBox(height: 24),

                    // Court Details Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _srNoController,
                            decoration: InputDecoration(
                              labelText: 'SR No',
                              // prefixIcon: Icon(Icons.confirmation_number,
                              // color: colorScheme.secondary),
                              filled: true,
                              fillColor: colorScheme.surface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _status,
                            
                            items:
                                [
                                      'Pending',
                                      'Un Numbered',
                                      'Disposed',
                                      'Closed',
                                    ]
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) =>
                                setState(() => _status = val!),
                              
                            decoration: InputDecoration(
                              labelText: 'Status',
                              
                              // prefixIcon: Icon(Icons.flag,
                              //     color: colorScheme.secondary),
                              filled: true,
                              fillColor: colorScheme.surface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // const SizedBox(height: 24),

                    // Dates Section
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Vakalat Details Section
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Vakalat Details',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  children: [
                    const Divider(),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Filed by:",
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._vakalatMembers.map(
                      (entry) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry)),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _vakalatMembers.remove(entry);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _vakalatNameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(
                                Icons.person_add,
                                color: colorScheme.primary,
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, color: colorScheme.primary),
                            onPressed: () {
                              final name = _vakalatNameController.text.trim();
                              if (name.isNotEmpty) {
                                setState(() {
                                  _vakalatMembers.add(name);
                                  _vakalatNameController.clear();
                                  _vakalatDate = null;
                                });
                              } else {
                                Get.snackbar(
                                  "Error",
                                  "Please enter name and date",
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _vakalatDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _vakalatDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date of Vakalat',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _vakalatDate != null
                                        ? "${_vakalatDate!.day}/${_vakalatDate!.month}/${_vakalatDate!.year}"
                                        : "Select Date",
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Parties Section
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Parties',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  children: [
                    const Divider(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _petitionerController,
                      decoration: InputDecoration(
                        labelText: 'Petitioner',
                        prefixIcon: Icon(Icons.person, color: Colors.green),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _petitionerAdvController,
                      decoration: InputDecoration(
                        labelText: 'Petitioner Advocate',
                        prefixIcon: Icon(Icons.work, color: Colors.green),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _respondentController,
                      decoration: InputDecoration(
                        labelText: 'Respondent',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: Colors.green,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _respondentAdvController,
                      decoration: InputDecoration(
                        labelText: 'Respondent Advocate',
                        prefixIcon: Icon(
                          Icons.work_outline,
                          color: Colors.green,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Files Section
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.attach_file,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Attached Files',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      
                    ],
                  ),
                  children: [
                    const Divider(),
                    Text(
                      "vakalat and other files can be attached here⬇",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._attachedFiles.map(
                      (file) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                file.split('/').last,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _attachedFiles.remove(file));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickFiles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          foregroundColor: Colors.blue,
                          elevation: 0,
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach Files'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Notes Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.note_alt,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Notes',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        // prefixIcon: Icon(Icons.notes, color: Colors.amber[700]),
                        filled: true,
                        fillColor: colorScheme.surface,
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.event,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Hearing Date',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    _buildDateTile(
                      context,
                      'Next Hearing Date',
                      _hearingDate,
                      _pickDate,
                      Icons.schedule,
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveCase,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: Text(
                        widget.existingCase == null
                            ? 'Save Case'
                            : 'Update Case',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile(
    BuildContext context,
    String title,
    DateTime? date,
    VoidCallback onTap,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted
              ? colorScheme.primary.withValues(alpha: 0.05)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          // border: Border.all(
          //   color: isHighlighted
          //       ? colorScheme.primary.withValues(alpha: 0.3)
          //       : colorScheme.outline.withValues(alpha: 0.2),
          // ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isHighlighted ? colorScheme.primary : Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isHighlighted
                          ? colorScheme.primary
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date == null
                        ? "Choose a date"
                        : '${date.day}/${date.month}/${date.year}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: date == null
                          ? colorScheme.onSurface.withValues(alpha: 0.6)
                          : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: isHighlighted ? colorScheme.primary : Colors.orange,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
