import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/client_model.dart';
import '../../services/contact_import_service.dart';
import '../../services/storage_service.dart';

class AddClientView extends StatefulWidget {
  final ClientModel? existingClient;

  AddClientView({super.key}) : existingClient = Get.arguments;

  @override
  State<AddClientView> createState() => _AddClientViewState();
}

class _AddClientViewState extends State<AddClientView> {
  final StorageService _storage = StorageService.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

 Future<void> _importFromContacts() async {
  final imported = await ContactImportService.pickClientFromContacts(context);
  if (imported == null) return;

  setState(() {
    if ((imported.name ?? '').trim().isNotEmpty) {
      _nameController.text = imported.name!.trim(); // ← trim here
    }
    if ((imported.phone ?? '').trim().isNotEmpty) {
      _contactController.text = imported.phone!.trim();
    }
    if ((imported.email ?? '').trim().isNotEmpty) {
      _emailController.text = imported.email!.trim();
    }
    if ((imported.city ?? '').trim().isNotEmpty) {
      _cityController.text = imported.city!.trim();
    }
    if ((imported.state ?? '').trim().isNotEmpty) {
      _stateController.text = imported.state!.trim();
    }
  });

  // Force the form to revalidate after import
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _formKey.currentState?.validate();
  });

  Get.snackbar('Imported', 'Client details imported from Contacts');
}

  @override
  void initState() {
    super.initState();
    if (widget.existingClient != null) {
      _nameController.text = widget.existingClient!.name;
      _contactController.text = widget.existingClient!.contactNumber;
      _emailController.text = widget.existingClient!.email;
      _cityController.text = widget.existingClient!.city;
      _stateController.text = widget.existingClient!.state;
    }
  }

  void _saveClient() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    if (widget.existingClient != null) {
      widget.existingClient!
        ..name = _nameController.text.trim()
        ..contactNumber = _contactController.text.trim()
        ..email = _emailController.text.trim()
        ..city = _cityController.text.trim()
        ..state = _stateController.text.trim();
      await widget.existingClient!.save();
    } else {
      final newClient = ClientModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
      );
      final box = await _storage.getBox<ClientModel>('clients');
      await box.add(newClient);
    }

    if (context.mounted) {
      Navigator.of(context).pop();
      Get.snackbar(
        widget.existingClient != null ? 'Updated' : 'Success',
        widget.existingClient != null
            ? 'Client updated successfully'
            : 'Client added successfully',
        backgroundColor:  Colors.green ,
      );
    }
  } catch (e, stack) {
    // This will tell us exactly what's failing
    print('SAVE ERROR: $e');
    print('STACK: $stack');
    if (context.mounted) {
      Get.snackbar('Error', 'Failed to save: $e', backgroundColor: Colors.red);
    }
  }
}
  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    // required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Text(
                      //   subtitle,
                      //   style: theme.textTheme.bodySmall?.copyWith(
                      //     color: colorScheme.onSurfaceVariant,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingClient != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(isEditing ? 'Edit Client' : 'Add Client')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: colorScheme.surfaceContainerHighest.withValues(
              //       alpha: 0.45,
              //     ),
              //     borderRadius: BorderRadius.circular(16),
              //     border: Border.all(
              //       color: colorScheme.outlineVariant.withValues(alpha: 0.75),
              //     ),
              //   ),
              //   child: Row(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Container(
              //         padding: const EdgeInsets.all(10),
              //         decoration: BoxDecoration(
              //           color: colorScheme.primaryContainer.withValues(
              //             alpha: 0.6,
              //           ),
              //           shape: BoxShape.circle,
              //         ),
              //         child: Icon(
              //           isEditing
              //               ? Icons.person_outline
              //               : Icons.person_add_alt_1,
              //           color: colorScheme.primary,
              //         ),
              //       ),
              //       const SizedBox(width: 12),
              //       // Expanded(
              //       //   child: Column(
              //       //     crossAxisAlignment: CrossAxisAlignment.start,
              //       //     children: [
              //       //       Text(
              //       //         isEditing
              //       //             ? 'Update client profile'
              //       //             : 'Create client profile',
              //       //         style: textTheme.titleMedium?.copyWith(
              //       //           fontWeight: FontWeight.w700,
              //       //         ),
              //       //       ),
              //       //       const SizedBox(height: 4),
              //       //       Text(
              //       //         'Add essential contact details for communication and case tracking.',
              //       //         style: textTheme.bodyMedium?.copyWith(
              //       //           color: colorScheme.onSurfaceVariant,
              //       //         ),
              //       //       ),
              //       //     ],
              //       //   ),
              //       // ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _importFromContacts,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: colorScheme.outlineVariant),
                    foregroundColor: colorScheme.primary,
                  ),
                  icon: const Icon(Icons.contact_page_outlined),
                  label: Text(
                    'Import from Contacts',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                context: context,
                title: 'Primary Information',
                // subtitle: 'Basic identity and communication details',
                icon: Icons.badge_outlined,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      context,
                      label: 'Name',
                      icon: Icons.person_outline,
                      hint: 'Client full name',
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contactController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      context,
                      label: 'Contact Number',
                      icon: Icons.phone_outlined,
                      hint: 'Phone number',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      context,
                      label: 'Email',
                      icon: Icons.alternate_email,
                      hint: 'name@example.com',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                context: context,
                title: 'Location',
                // subtitle: 'Region details for records and communication',
                icon: Icons.location_on_outlined,
                children: [
                  TextFormField(
                    controller: _cityController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      context,
                      label: 'City',
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _stateController,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      context,
                      label: 'State',
                      icon: Icons.map_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveClient,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: Icon(
                    Icons.save_outlined,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  label: Text(isEditing ? 'Update Client' : 'Save Client'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
