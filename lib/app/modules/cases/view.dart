import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:legalsteward/app/modules/ads/native_ads.dart';
import 'package:legalsteward/app/modules/cases/controller.dart';
import 'package:legalsteward/app/services/storage_service.dart';

import '../../data/models/case_model.dart';
import '../../data/models/hearing_model.dart';
import '../../utils/font_styles.dart';
import 'History/hearing_view.dart';
import 'case_detail_view.dart';

class CasesView extends StatelessWidget {
  const CasesView({super.key});

  Future<void> _ensureCoreBoxesOpen() async {
    await StorageService.instance.ensureCoreBoxesOpen();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CasesController());
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final coreBoxesReady = StorageService.coreBoxNames.every(Hive.isBoxOpen);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'All Cases',
          style: FontStyles.poppins(fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withAlpha((0.9 * 255).toInt()),
                colorScheme.secondary.withAlpha((0.9 * 255).toInt()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.showAdvancedFilters.value
                    ? Icons.filter_list_off
                    : Icons.filter_list,
              ),
              onPressed: controller.toggleAdvancedFilters,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: controller.updateSortBy,
            itemBuilder: (context) => controller.sortOptions.map((option) {
              return PopupMenuItem<String>(
                value: option,
                child: Obx(
                  () => Row(
                    children: [
                      Text(option),
                      const Spacer(),
                      if (controller.sortBy.value == option) ...[
                        Icon(
                          controller.sortAscending.value
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: coreBoxesReady ? Future<void>.value() : _ensureCoreBoxesOpen(),
        builder: (context, snapshot) {
          if (!coreBoxesReady &&
              snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    hintText: 'Search cases, clients, courts...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Obx(
                      () => controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: controller.clearSearch,
                            )
                          : const SizedBox.shrink(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                ),
              ),

              // Quick Stats
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${controller.filteredCount} of ${controller.totalCases} cases',
                        style: FontStyles.poppins(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      if (controller.searchQuery.value.isNotEmpty ||
                          controller.selectedStatus.value != 'All' ||
                          controller.dateRange.value != null)
                        TextButton(
                          onPressed: controller.clearFilters,
                          child: const Text('Clear Filters'),
                        ),
                    ],
                  ),
                ),
              ),

              // Advanced Filters
              Obx(
                () => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: controller.showAdvancedFilters.value ? null : 0,
                  child: controller.showAdvancedFilters.value
                      ? _buildAdvancedFilters(controller, theme)
                      : const SizedBox.shrink(),
                ),
              ),

              // Status Filter Chips
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.statusOptions.length,
                    itemBuilder: (context, index) {
                      final status = controller.statusOptions[index];

                      // Move the isSelected check inside the Obx scope
                      return Obx(() {
                        final isSelected =
                            controller.selectedStatus.value == status;
                        final count = status == 'All'
                            ? controller.totalCases
                            : controller.casesByStatus[status] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              '$status ($count)',
                              style: FontStyles.poppins(
                                fontWeight: FontWeight.w900,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) =>
                                controller.updateStatusFilter(status),
                            selectedColor: colorScheme.primary,
                            checkmarkColor: colorScheme.onPrimary,
                          ),
                        );
                      });
                    },
                  ),
                ),
              ),
              // Cases List
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box<CaseModel>('cases').listenable(),
                  builder: (context, Box<CaseModel> box, _) {
                    return ValueListenableBuilder(
                      valueListenable: Hive.box<hearingModel>(
                        'hearings',
                      ).listenable(),
                      builder: (context, Box<hearingModel> hearingBox, __) {
                        final latestNextHearingByCaseId =
                            _buildLatestNextHearingMap(hearingBox.values);

                        return Obx(() {
                          final cases = controller.filteredCases;

                          if (controller.totalCases == 0) {
                            return ListView(
                              children: [
                                _buildEmptyState(
                                  'No cases found.',
                                  'Start by adding your first case',
                                ),
                                // NativeAdExample(),
                                SizedBox(height: 150),
                              ],
                            );
                          }

                          if (cases.isEmpty) {
                            return ListView(
                              children: [
                                _buildEmptyState(
                                  'No cases match your search',
                                  'Try adjusting your filters or search terms',
                                ),
                                // NativeAdExample(),
                                SizedBox(height: 200),
                              ],
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            itemCount: cases.length,
                            itemBuilder: (context, index) {
                              if (index == cases.length - 1) {
                                final c = cases[index];
                                return Column(
                                  children: [
                                    _buildCaseCard(
                                      c,
                                      theme,
                                      context,
                                      latestNextHearingByCaseId,
                                    ),
                                    SizedBox(
                                      height: index == cases.length - 1
                                          ? 100
                                          : 10,
                                    ),
                                    // NativeAdExample(),
                                  ],
                                );
                              }

                              final c = cases[index];
                              return _buildCaseCard(
                                c,
                                theme,
                                context,
                                latestNextHearingByCaseId,
                              );
                            },
                          );
                        });
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 10),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/add-case'),
        icon: const Icon(Icons.add),
        label: const Text('Add Case'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildAdvancedFilters(CasesController controller, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Filters',
              style: FontStyles.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Date Range Filter
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => OutlinedButton.icon(
                      onPressed: () => _showDateRangePicker(controller),
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        controller.dateRange.value == null
                            ? 'Select Date Range'
                            : '${controller.dateRange.value!.start.day}/${controller.dateRange.value!.start.month} - ${controller.dateRange.value!.end.day}/${controller.dateRange.value!.end.month}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => controller.dateRange.value != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => controller.updateDateRange(null),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quick Filter Buttons
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Upcoming Hearings'),
                  onPressed: controller.filterUpcomingHearings,
                  avatar: const Icon(Icons.schedule, size: 16),
                ),
                ActionChip(
                  label: const Text('Overdue Hearings'),
                  onPressed: controller.filterOverdueHearings,
                  avatar: const Icon(Icons.warning, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(CasesController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: controller.dateRange.value,
    );

    if (picked != null) {
      controller.updateDateRange(picked);
    }
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: FontStyles.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: FontStyles.poppins(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard(
    CaseModel c,
    ThemeData theme,
    BuildContext context,
    Map<String, DateTime> latestNextHearingByCaseId,
  ) {
    final latestNextHearing = _latestNextHearingForCase(
      c,
      latestNextHearingByCaseId,
    );
    final isOverdue =
        latestNextHearing != null &&
        !latestNextHearing.isAfter(DateTime.now()) &&
        c.status == 'Pending';

    return Card(
      elevation: 2,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => Get.to(() => CaseDetailView(caseData: c)),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: TextStyle(
                            fontFamily: 'oswald',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge!.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.numbers,
                              size: 16,
                              color: theme.iconTheme.color,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c.registrationNo?.isEmpty ?? true
                                    ? "No Case No."
                                    : c.registrationNo!,
                                style: FontStyles.poppins(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium!.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Court
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance,
                              size: 16,
                              color: theme.iconTheme.color,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c.court,
                                style: FontStyles.poppins(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium!.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      _buildStatusChip(
                        c.status,
                        theme.colorScheme,
                        theme.colorScheme.secondaryContainer,
                        latestNextHearing,
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Footer row ──
              Row(
                children: [
                  
                  TextButton.icon(
                    onPressed: () =>
                        Get.to(() => HearingHistoryView(caseData: c)),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFE6F1FB),
                      foregroundColor: const Color(0xFF185FA5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.history, size: 14),
                    label: Text(
                      'Hearing History',
                      style: FontStyles.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (latestNextHearing != null) ...[
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 14,
                      color: theme.iconTheme.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${latestNextHearing.day}/${latestNextHearing.month}/${latestNextHearing.year}',
                      style: FontStyles.poppins(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall!.color,
                      ),
                    ),
                  ] else
                    Text(
                      'No upcoming hearing',
                      style: FontStyles.poppins(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall!.color,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isNewerHearing(hearingModel candidate, hearingModel current) {
    final createdAtComparison = candidate.createdAt.compareTo(
      current.createdAt,
    );
    if (createdAtComparison != 0) {
      return createdAtComparison > 0;
    }
    return candidate.hearingDate.isAfter(current.hearingDate);
  }

  Map<String, DateTime> _buildLatestNextHearingMap(
    Iterable<hearingModel> hearings,
  ) {
    final Map<String, hearingModel> latestHearingByCaseId = {};
    for (final hearing in hearings) {
      final existing = latestHearingByCaseId[hearing.caseId];
      if (existing == null || _isNewerHearing(hearing, existing)) {
        latestHearingByCaseId[hearing.caseId] = hearing;
      }
    }

    final Map<String, DateTime> latestNextHearingByCaseId = {};
    for (final entry in latestHearingByCaseId.entries) {
      final nextDate = entry.value.nextHearingDate;
      if (nextDate != null) {
        latestNextHearingByCaseId[entry.key] = nextDate;
      }
    }
    return latestNextHearingByCaseId;
  }

  DateTime? _latestNextHearingForCase(
    CaseModel caseModel,
    Map<String, DateTime> latestNextHearingByCaseId,
  ) {
    return latestNextHearingByCaseId[caseModel.id];
  }

  Widget _buildStatusChip(
    String status,
    ColorScheme scheme,
    Color color,
    DateTime? nextHearingDate,
  ) {
    Color chipColor;
    switch (status) {
      case 'Closed':
        chipColor = Colors.greenAccent;
        break;
      case 'Disposed':
        chipColor = Colors.orangeAccent;
        break;
      case 'Un Numbered':
        chipColor = Colors.orange;
        break;
      case 'Pending':
        if (nextHearingDate != null &&
            nextHearingDate.isAfter(DateTime.now())) {
          chipColor = Colors.blueAccent;
        } else {
          chipColor = Colors.redAccent;
        }
        break;
      default:
        chipColor = scheme.primary;
        break;
    }

    return Chip(
      label: Text(
        status,
        style: FontStyles.poppins().copyWith(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      backgroundColor: chipColor,
    );
  }
}
