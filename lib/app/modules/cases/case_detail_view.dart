import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:legalsteward/app/modules/cases/History/add_hearing.dart';
import 'package:legalsteward/app/modules/cases/add_cases_view.dart';
import 'package:open_file/open_file.dart';

import '../../data/models/case_model.dart';
import '../../data/models/hearing_model.dart';
import 'History/hearing_view.dart';

class CaseDetailView extends StatelessWidget {
  final CaseModel caseData;




  const CaseDetailView({super.key, required this.caseData});

  void _deleteCase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Case'),
        content: const Text('Are you sure you want to delete this case?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      final box = Hive.box<hearingModel>('hearings');
      final toDelete = box.values.where((h) => h.caseId == caseData.id).toList();
      for (final h in toDelete) {
        await h.delete();
      }

      await caseData.delete();
      Get.back(); // back to list
      Get.snackbar('Deleted', 'Case removed successfully');
    }
  }

  void _editCase() {
    Get.to(() => AddCaseView(existingCase: caseData))!.then((result) {
      if (result == 'updated') {
        // print("should go back to tab");
        // Get.back(); // Now this pops CaseDetailView
      }
    });
  }
  // void _addHearing() {
  //   Get.off(() => AddHearingView(caseData: caseData))!.then((result) {
  //     if (result == 'hearing_added') {
  //       // print("should go back to tab");
  //       // Get.back(); // Now this pops CaseDetailView
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Details'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _editCase,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Case',
          ),
          // IconButton(
          //   onPressed: _addHearing,
          //   icon: const Icon(Icons.add),
          //   tooltip: 'Add Hearing',
          // ),

        ],
      ),
      body: Container(
        // decoration: BoxDecoration(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            spacing: 16,
            children: [
              // Header Section with Case Title
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.gavel,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      caseData.title,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        // color: Colo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            // color: _getStatusColor(caseData.status).withOpacity(0.3),
                            ),
                      ),
                      child: Text(
                        caseData.status,
                        style: textTheme.labelLarge?.copyWith(
                          // color: _getStatusColor(caseData.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // const SizedBox(height: 24),

              // ElevatedButton(onPressed: (){Get.to(() => HearingHistoryView(caseData: caseData));}, child: const Text("See History")),

              // Basic Information Section
              _buildInfoSection(
                context,
                'Information',
                Icons.info_outline,
                Colors.blue,
                [
                  _buildEnhancedDetailRow(
                      context, Icons.person, 'Client', caseData.clientName),
                  _buildEnhancedDetailRow(
                      context, Icons.account_balance, 'Court', caseData.court),
                  _buildEnhancedDetailRow(context, Icons.confirmation_number,
                      'SR No', caseData.srNo ?? 'Not specified'),
                  _buildEnhancedDetailRow(
                      context, Icons.numbers, 'Case/Registration No', caseData.registrationNo!),
                  _buildDateRow(context, Icons.app_registration,
                      'Registration Date', caseData.registrationDate),
                  _buildDateRow(context, Icons.file_upload, 'Filing Date',
                      caseData.filingDate),
                ],
              ),

              // const SizedBox(height: 20),

              // Vakalat Details Section
              if (caseData.vakalatMembers != null &&
                      caseData.vakalatMembers!.isNotEmpty ||
                  caseData.vakalatDate != null)
                _buildExpandableSection(
                  context,
                  'Vakalat Details',
                  Icons.description,
                  Colors.purple,
                  [
                    if (caseData.vakalatDate != null)
                      _buildEnhancedDetailRow(
                        context,
                        Icons.event,
                        'Date of Vakalat',
                        '${caseData.vakalatDate!.day}/${caseData.vakalatDate!.month}/${caseData.vakalatDate!.year}',
                      ),
                    const SizedBox(height: 12),
                    if (caseData.vakalatMembers != null &&
                        caseData.vakalatMembers!.isNotEmpty) ...[
                      Text(
                        'Filed by:',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...caseData.vakalatMembers!.map((member) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.purple.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.person,
                                      size: 16, color: Colors.purple),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(member)),
                              ],
                            ),
                          )),
                    ] else
                      Text(
                        'No Vakalat Members Present',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),

              // const SizedBox(height: 20),

              // Parties Section
              _buildExpandableSection(
                context,
                'Parties',
                Icons.people,
                Colors.green,
                [
                  if (caseData.petitioner != null &&
                      caseData.petitioner!.isNotEmpty)
                    _buildEnhancedDetailRow(context, Icons.person, 'Petitioner',
                        caseData.petitioner!),
                  if (caseData.petitionerAdv != null &&
                      caseData.petitionerAdv!.isNotEmpty)
                    _buildEnhancedDetailRow(context, Icons.work,
                        'Petitioner Advocate', caseData.petitionerAdv!),
                  if (caseData.respondent != null &&
                      caseData.respondent!.isNotEmpty)
                    _buildEnhancedDetailRow(context, Icons.person_outline,
                        'Respondent', caseData.respondent!),
                  if (caseData.respondentAdv != null &&
                      caseData.respondentAdv!.isNotEmpty)
                    _buildEnhancedDetailRow(context, Icons.work_outline,
                        'Respondent Advocate', caseData.respondentAdv!),
                  if ((caseData.petitioner?.isEmpty ?? true) &&
                      (caseData.petitionerAdv?.isEmpty ?? true) &&
                      (caseData.respondent?.isEmpty ?? true) &&
                      (caseData.respondentAdv?.isEmpty ?? true))
                    Text(
                      'No party information available',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),

              // const SizedBox(height: 20),

              // Attachments Section
              if (caseData.attachedFiles != null &&
                  caseData.attachedFiles!.isNotEmpty)
                _buildExpandableSection(
                  context,
                  'Attachments',
                  Icons.attach_file,
                  Colors.blue,
                  [
                    ...caseData.attachedFiles!.map((path) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.indigo.withOpacity(0.2)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.insert_drive_file,
                                  color: Colors.indigo, size: 20),
                            ),
                            title: Text(
                              path.split('/').last,
                              style: textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            trailing: Icon(Icons.open_in_new,
                                color: Colors.indigo.withOpacity(0.7)),
                            onTap: () async {
                              final result = await OpenFile.open(path);
                              if (result.type != ResultType.done) {
                                Get.snackbar(
                                  "Error",
                                  "Could not open file",
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  colorText: Colors.red,
                                  icon: const Icon(Icons.error,
                                      color: Colors.red),
                                );
                              }
                            },
                          ),
                        )),
                  ],
                ),

              // const SizedBox(height: 20),

              // Notes Section
              if (caseData.notes.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.note_alt,
                                color: Colors.amber, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Notes',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.amber.withOpacity(0.2)),
                        ),
                        child: Text(
                          caseData.notes,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),

              // const SizedBox(height: 20),

              // Important Dates Section
              _buildHistoryInfoSection(
                context,
                'Hearing Date',
                Icons.event,
                Colors.orange,
                [
                  _buildDateRow(context, Icons.schedule, 'Next Hearing',
                      caseData.nextHearing,
                      isHighlighted: true),
                ],
              ),
              // const SizedBox(height: 32),
              // if(caseData.hearingDates != null && caseData.hearingDates!.isNotEmpty)  
              // _buildInfoSection(context, 'Previous Hearings', Icons.history, Colors.blue, [
              //   ...caseData.hearingDates!.map((date) => _buildDateRow(
              //         context,
              //         Icons.check_circle,
              //         'Hearing Date',
              //         date,
              //       )),
              // ]),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _editCase,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text(
                        'Edit Case',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteCase(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text(
                        'Delete Case',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
  Widget _buildHistoryInfoSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Spacer() ,
              GestureDetector(
                onTap: (){Get.to(() => HearingHistoryView(caseData: caseData));},
                child: Text(
                  "See History",
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        children: [
          const Divider(),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? "-" : value,
              style: textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(
      BuildContext context, IconData icon, String label, DateTime? date,
      {bool isHighlighted = false}) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    String dateText = 'Not specified';
    if (date != null) {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.primary.withOpacity(0.05)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? colorScheme.primary.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isHighlighted ? colorScheme.primary : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isHighlighted ? colorScheme.primary : Colors.orange,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              dateText,
              style: textTheme.bodyMedium?.copyWith(
                color: date == null
                    ? colorScheme.onSurface.withOpacity(0.6)
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return Colors.orange;
//       case 'not filed':
//         return Colors.blue;
//       case 'disposed':
//         return Colors.green;
//       case 'closed':
//         return Colors.grey;
//       default:
//         return Colors.grey;
//     }
//   }
// }
}
