import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:legalsteward/app/modules/ads/native_ads.dart';
import 'package:legalsteward/app/modules/cases/controller.dart';

import '../../data/models/case_model.dart';
import '../../utils/font_styles.dart';
import 'case_detail_view.dart';

class CasesView extends StatelessWidget {
  const CasesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CasesController());
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          '📁 All Cases',
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
      body: Column(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        label: Text('$status ($count)'),
                        selected: isSelected,
                        onSelected: (_) =>
                            controller.updateStatusFilter(status),
                        selectedColor: colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: colorScheme.primary,
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
                        SizedBox(height: 150,)
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
                          SizedBox(height: 200,)
                        ],
                      )
                    ;
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
                            _buildCaseCard(c, theme, context),
                            SizedBox(height: 10),
                            // NativeAdExample(),
                          ],
                        );
                      }
                      final c = cases[index];
                      return _buildCaseCard(c, theme, context);
                    },
                  );
                });
              },
            ),
          ),
          SizedBox(height: 10),
        ],
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

  Widget _buildCaseCard(CaseModel c, ThemeData theme, BuildContext context) {
    return Card(
      elevation: 3,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Get.to(() => CaseDetailView(caseData: c));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    c.title,
                    style: TextStyle(
                      fontFamily: 'oswald',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge!.color,
                    ),
                  ),
                  // if(!c.nextHearing.isAfter(DateTime.now()) && c.status == 'Pending')
                  Spacer(),
                  if (c.nextHearing != null &&
                      !c.nextHearing!.isAfter(DateTime.now()) &&
                      c.status == 'Pending')
                    Icon(Icons.warning, size: 16, color: theme.iconTheme.color),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.numbers, size: 16, color: theme.iconTheme.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      c.registrationNo == "" ? "No Case.no " : c.registrationNo!,
                      style: FontStyles.poppins(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium!.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(
                    c.status,
                    theme.colorScheme,
                    theme.colorScheme.inversePrimary,
                    c,
                  ),
                  if (c.nextHearing != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: theme.iconTheme.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${c.nextHearing!.day}/${c.nextHearing!.month}/${c.nextHearing!.year}',
                          style: FontStyles.poppins(
                            fontSize: 13,
                            color: theme.textTheme.bodySmall!.color,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String status,
    ColorScheme scheme,
    Color color,
    CaseModel c,
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
        if (c.nextHearing != null && c.nextHearing!.isAfter(DateTime.now())) {
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
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      backgroundColor: chipColor,
    );
  }
}
