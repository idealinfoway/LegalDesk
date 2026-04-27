import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:legalsteward/app/modules/billing/add_time_entry_view.dart';
import 'package:legalsteward/app/modules/billing/expense/add_expense_view.dart';
import 'package:legalsteward/app/modules/billing/invoice/addInvoiceView.dart';
import 'package:legalsteward/app/modules/cases/add_cases_view.dart';
import 'package:legalsteward/app/modules/tasks/add_task_view.dart';
import 'package:legalsteward/app/services/storage_service.dart';
import 'package:legalsteward/app/utils/font_styles.dart';
import 'package:open_file/open_file.dart';

import '../../data/models/case_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/hearing_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/time_entry_model.dart';
import '../../widgets/pdf_page_manager_sheet.dart';
import 'History/hearing_view.dart';

class CaseDetailView extends StatelessWidget {
  final CaseModel caseData;
  static final StorageService _storage = StorageService.instance;
  static const String _migratedSummaryText = 'Migrated from case details';

  const CaseDetailView({super.key, required this.caseData});

  // ── Logic (unchanged) ────────────────────────────────────────────────────

  void _deleteCase(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: cs.error, size: 22),
            const SizedBox(width: 10),
            Text(
              'Delete Case',
              style: FontStyles.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this case? This action cannot be undone.',
          style: FontStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: FontStyles.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Get.back(result: true),
            child: Text('Delete', style: FontStyles.button),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final hearingBox = await _storage.getBox<hearingModel>('hearings');
      final taskBox = await _storage.getBox<TaskModel>('tasks');
      final timeEntryBox = await _storage.getBox<TimeEntryModel>(
        'time_entries',
      );
      final expenseBox = await _storage.getBox<ExpenseModel>('expenses');
      final invoiceBox = await _storage.getBox<InvoiceModel>('invoices');

      final hearingsToDelete = hearingBox.values
          .where((h) => h.caseId == caseData.id)
          .toList();
      final tasksToDelete = taskBox.values
          .where((t) => t.linkedCaseId == caseData.id)
          .toList();
      final timeEntriesToDelete = timeEntryBox.values
          .where((t) => t.caseId == caseData.id)
          .toList();
      final expensesToDelete = expenseBox.values
          .where((e) => e.caseId == caseData.id)
          .toList();
      final invoicesToDelete = invoiceBox.values
          .where((i) => i.caseId == caseData.id)
          .toList();

      await Future.wait(hearingsToDelete.map((h) => h.delete()));
      await Future.wait(tasksToDelete.map((t) => t.delete()));
      await Future.wait(timeEntriesToDelete.map((t) => t.delete()));
      await Future.wait(expensesToDelete.map((e) => e.delete()));
      await Future.wait(invoicesToDelete.map((i) => i.delete()));

      await caseData.delete();
      Get.back();
      Get.snackbar('Deleted', 'Case removed successfully');
    }
  }

  void _editCase() {
    Get.to(() => AddCaseView(existingCase: caseData))!.then((_) {});
  }

  hearingModel? _findLatestHearing(Iterable<hearingModel> hearings) {
    final filtered = hearings.where((h) => h.caseId == caseData.id).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) {
      final c = b.createdAt.compareTo(a.createdAt);
      return c != 0 ? c : b.hearingDate.compareTo(a.hearingDate);
    });
    return filtered.first;
  }

  String? _latestNotes(hearingModel? h) {
    if (h == null) return null;
    final n = h.nextHearingNotes?.trim() ?? '';
    if (n.isNotEmpty) return n;
    final o = h.orderNotes?.trim() ?? '';
    if (o.isNotEmpty) return o;
    final s = h.summary.trim();
    if (s.isNotEmpty && s != _migratedSummaryText) return s;
    return null;
  }

  DateTime? _latestNextHearingDate(hearingModel? h) => h?.nextHearingDate;

  static String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<Box<hearingModel>>(
        future: _storage.getBox<hearingModel>('hearings'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }
          final hearingBox = snapshot.data!;
          return ValueListenableBuilder(
            valueListenable: hearingBox.listenable(),
            builder: (context, Box<hearingModel> box, _) {
              final latestHearing = _findLatestHearing(box.values);
              final latestNotes = _latestNotes(latestHearing);
              final nextDate = _latestNextHearingDate(latestHearing);

              return CustomScrollView(
                slivers: [
                  // ── Collapsing App Bar ────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 196,
                    pinned: true,
                    backgroundColor:
                        theme.appBarTheme.backgroundColor ?? cs.primary,
                    foregroundColor:
                        theme.appBarTheme.foregroundColor ?? Colors.white,
                    elevation: 0,
                    actions: [
                      IconButton(
                        onPressed: _editCase,
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Case',
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: _HeroHeader(caseData: caseData),
                    ),
                  ),

                  // ── Body ─────────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Next Hearing Banner

                        // Case Information
                        _LegalCard(
                          title: 'Case Information',
                          icon: Icons.info_outline_rounded,
                          accentColor: cs.primary,
                          trailing: _ChipButton(
                            label: 'Hearing History',
                            icon: Icons.history_rounded,
                            color: cs.primary,
                            onTap: () => Get.to(
                              () => HearingHistoryView(caseData: caseData),
                            ),
                          ),
                          children: [
                            _InfoRow(
                              label: 'Client',
                              value: caseData.clientName,
                              icon: Icons.person_outline,
                            ),
                            _InfoRow(
                              label: 'Court',
                              value: caseData.court,
                              icon: Icons.account_balance_outlined,
                            ),
                            _InfoRow(
                              label: 'SR No',
                              value: caseData.srNo ?? '—',
                              icon: Icons.confirmation_number_outlined,
                            ),
                            _InfoRow(
                              label: 'Reg. No',
                              value: caseData.registrationNo ?? '—',
                              icon: Icons.numbers_rounded,
                            ),
                            _InfoRow(
                              label: 'Registration',
                              value: _fmt(caseData.registrationDate),
                              icon: Icons.app_registration_outlined,
                            ),
                            _InfoRow(
                              label: 'Filing Date',
                              value: _fmt(caseData.filingDate),
                              icon: Icons.upload_file_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Vakalat
                        if ((caseData.vakalatMembers?.isNotEmpty ?? false) ||
                            caseData.vakalatDate != null) ...[
                          _ExpandableCard(
                            title: 'Vakalat Details',
                            icon: Icons.description_outlined,
                            accentColor: const Color.fromARGB(
                              255,
                              58,
                              120,
                              255,
                            ),
                            children: [
                              if (caseData.vakalatDate != null)
                                _InfoRow(
                                  label: 'Date',
                                  value: _fmt(caseData.vakalatDate),
                                  icon: Icons.event_outlined,
                                ),
                              if (caseData.vakalatMembers?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(height: 10),
                                _SectionLabel(text: 'Filed by'),
                                const SizedBox(height: 8),
                                ...caseData.vakalatMembers!.map(
                                  (m) => _MemberChip(name: m),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Parties
                        _ExpandableCard(
                          title: 'Parties',
                          icon: Icons.people_alt_outlined,
                          accentColor: const Color(0xFF059669),
                          children: [
                            if (caseData.petitioner?.isNotEmpty ?? false)
                              _InfoRow(
                                label: 'Petitioner',
                                value: caseData.petitioner!,
                                icon: Icons.person,
                              ),
                            if (caseData.petitionerAdv?.isNotEmpty ?? false)
                              _InfoRow(
                                label: 'Pet. Advocate',
                                value: caseData.petitionerAdv!,
                                icon: Icons.work_outline,
                              ),
                            if (caseData.respondent?.isNotEmpty ?? false)
                              _InfoRow(
                                label: 'Respondent',
                                value: caseData.respondent!,
                                icon: Icons.person_outline,
                              ),
                            if (caseData.respondentAdv?.isNotEmpty ?? false)
                              _InfoRow(
                                label: 'Res. Advocate',
                                value: caseData.respondentAdv!,
                                icon: Icons.work_history_outlined,
                              ),
                            if ((caseData.petitioner?.isEmpty ?? true) &&
                                (caseData.petitionerAdv?.isEmpty ?? true) &&
                                (caseData.respondent?.isEmpty ?? true) &&
                                (caseData.respondentAdv?.isEmpty ?? true))
                              Text(
                                'No party information available',
                                style: FontStyles.bodySmall.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.45),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Attachments
                        if (caseData.attachedFiles?.isNotEmpty ?? false) ...[
                          _ExpandableCard(
                            title:
                                'Attachments (${caseData.attachedFiles!.length})',
                            icon: Icons.attach_file_rounded,
                            accentColor: cs.secondary,
                            children: caseData.attachedFiles!
                                .map((p) => _AttachmentTile(path: p))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Notes
                        if (latestNotes != null) ...[
                          _NotesCard(notes: latestNotes),
                          const SizedBox(height: 12),
                        ],

                        const SizedBox(height: 4),
                        _NextHearingBanner(date: nextDate),
                        const SizedBox(height: 12),
                        _CaseActionRail(
                          onAddTask: () => Get.to(
                            () => AddTaskView(initialCaseId: caseData.id),
                          ),
                          onAddTimeEntry: () => Get.to(
                            () => AddTimeEntryView(initialCaseId: caseData.id),
                          ),
                          onAddExpense: () => Get.to(
                            () => AddExpenseView(initialCaseId: caseData.id),
                          ),
                          onAddInvoice: () => Get.to(
                            () => AddInvoiceView(initialCaseId: caseData.id),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _editCase,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: Text(
                                  'Edit Case',
                                  style: FontStyles.button,
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _deleteCase(context),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                                label: Text('Delete', style: FontStyles.button),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.error,
                                  foregroundColor: cs.onError,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final CaseModel caseData;
  const _HeroHeader({required this.caseData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final appBarColor = theme.appBarTheme.backgroundColor ?? cs.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            appBarColor,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.28), appBarColor),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.gavel_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  caseData.title,
                  style: FontStyles.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatusBadge(status: caseData.status),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        caseData.court,
                        style: FontStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        status,
        style: FontStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Next Hearing Banner ───────────────────────────────────────────────────────

class _NextHearingBanner extends StatelessWidget {
  final DateTime? date;
  const _NextHearingBanner({this.date});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDate = date != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: isDark ? 0.2 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_rounded, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT HEARING',
                  style: FontStyles.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasDate
                      ? '${date!.day.toString().padLeft(2, '0')} / ${date!.month.toString().padLeft(2, '0')} / ${date!.year}'
                      : 'No hearing scheduled',
                  style: FontStyles.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Case Action Rail ─────────────────────────────────────────────────────────

class _CaseActionRail extends StatelessWidget {
  final VoidCallback onAddTask;
  final VoidCallback onAddTimeEntry;
  final VoidCallback onAddExpense;
  final VoidCallback onAddInvoice;

  const _CaseActionRail({
    required this.onAddTask,
    required this.onAddTimeEntry,
    required this.onAddExpense,
    required this.onAddInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _cardShell(
      theme: theme,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'CASE ACTIONS',
                  style: FontStyles.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Create linked records in one tap',
              style: FontStyles.caption.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CaseActionButton(
                    label: 'Task',
                    icon: Icons.task_alt_rounded,
                    color: cs.primary,
                    onTap: onAddTask,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CaseActionButton(
                    label: 'Time',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFF0EA5E9),
                    onTap: onAddTimeEntry,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CaseActionButton(
                    label: 'Expense',
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFFDC2626),
                    onTap: onAddExpense,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CaseActionButton(
                    label: 'Invoice',
                    icon: Icons.request_quote_outlined,
                    color: const Color(0xFF059669),
                    onTap: onAddInvoice,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CaseActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.26)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: FontStyles.caption.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Legal Card (non-expandable) ───────────────────────────────────────────────

class _LegalCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;
  final Widget? trailing;

  const _LegalCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _cardShell(
      theme: theme,
      child: Column(
        children: [
          _CardHeader(
            title: title,
            icon: icon,
            accentColor: accentColor,
            trailing: trailing,
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ── Expandable Card ───────────────────────────────────────────────────────────

class _ExpandableCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const _ExpandableCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _cardShell(
      theme: theme,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            title: _CardHeader(
              title: title,
              icon: icon,
              accentColor: accentColor,
            ),
            children: [
              Divider(
                height: 1,
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

Widget _cardShell({required ThemeData theme, required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.28 : 0.05,
          ),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

// ── Card Header ───────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget? trailing;
  const _CardHeader({
    required this.title,
    required this.icon,
    required this.accentColor,
    this.trailing,
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
          Expanded(
            child: Text(
              title,
              style: FontStyles.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.35)),
          const SizedBox(width: 10),
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: FontStyles.caption.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: FontStyles.caption.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notes Card ────────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const amber = Color(0xFFD97706);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? amber.withValues(alpha: 0.08) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sticky_note_2_outlined, color: amber, size: 15),
              const SizedBox(width: 7),
              Text(
                'NOTES',
                style: FontStyles.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: amber,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: FontStyles.bodySmall.copyWith(
              color: cs.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: FontStyles.caption.copyWith(
        color: cs.onSurface.withValues(alpha: 0.4),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontSize: 10,
      ),
    );
  }
}

// ── Member Chip ───────────────────────────────────────────────────────────────

class _MemberChip extends StatelessWidget {
  final String name;
  const _MemberChip({required this.name});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 14,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: FontStyles.bodySmall.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attachment Tile ───────────────────────────────────────────────────────────

class _AttachmentTile extends StatelessWidget {
  final String path;
  const _AttachmentTile({required this.path});
  bool get _isPdf => path.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fileName = path.split(RegExp(r'[\\/]+')).last;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            _isPdf
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined,
            color: cs.secondary,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              style: FontStyles.caption.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isPdf)
            _TileIcon(
              icon: Icons.edit_note_outlined,
              color: cs.primary,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) =>
                    PdfPageManagerSheet(pdfPath: path, onSaved: () {}),
              ),
            ),
          _TileIcon(
            icon: Icons.open_in_new_rounded,
            color: cs.secondary,
            onTap: () async {
              final result = await OpenFile.open(path);
              if (result.type != ResultType.done) {
                Get.snackbar('Error', 'Could not open file');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TileIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}

// ── Chip Button ───────────────────────────────────────────────────────────────

class _ChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _ChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: FontStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}
