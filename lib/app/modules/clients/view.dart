import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:legalsteward/app/modules/clients/controller.dart';

import '../../constants/ad_constant.dart';
import '../../data/models/client_model.dart';
import '../../utils/font_styles.dart';
import '../ads/banner_ad_implement.dart';
import 'add_client_view.dart';
import 'client_detail_view.dart';

class ClientsView extends StatelessWidget {
  const ClientsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClientsController());
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '👥 Clients',
          style: FontStyles.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          Obx(() => IconButton(
                icon: Icon(controller.showAdvancedFilters.value
                    ? Icons.filter_list_off
                    : Icons.filter_list),
                onPressed: controller.toggleAdvancedFilters,
              )),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: controller.updateSortBy,
            itemBuilder: (context) => controller.sortOptions.map((option) {
              return PopupMenuItem<String>(
                value: option,
                child: Obx(() => Row(
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
                    )),
              );
            }).toList(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              // if (value == 'export') {
              //   // _exportClients(controller);
              // } else 
              if (value == 'recent') {
                _showRecentClients(controller);
              }
            },
            itemBuilder: (context) => [
              // const PopupMenuItem(value: 'export', child: Text('Export CSV')),
              const PopupMenuItem(
                  value: 'recent', child: Text('Recent Clients')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          //adhere
          // RefreshableBannerAdWidget(adUnitId: 'ca-app-pub-3940256099942544/9214589741'),
          RefreshableBannerAdWidget(adUnitId: AdConstant.bannerAdUnitId),
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search clients, email, phone, company...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: controller.clearSearch,
                      )
                    : const SizedBox.shrink()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
          ),

          // Quick Stats
          Obx(() => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${controller.filteredCount} of ${controller.totalClients} clients',
                      style: FontStyles.poppins(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    if (controller.searchQuery.value.isNotEmpty ||
                        controller.selectedCity.value != 'All' ||
                        controller.selectedState.value != 'All')
                      TextButton(
                        onPressed: controller.clearFilters,
                        child: const Text('Clear Filters'),
                      ),
                  ],
                ),
              )),

          // Advanced Filters
          Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: controller.showAdvancedFilters.value ? null : 0,
                child: controller.showAdvancedFilters.value
                    ? _buildAdvancedFilters(controller, theme)
                    : const SizedBox.shrink(),
              )),

          // Clients List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<ClientModel>('clients').listenable(),
              builder: (context, Box<ClientModel> box, _) {
                return Obx(() {
                  final clients = controller.filteredClients.value;

                  if (controller.totalClients == 0) {
                    return _buildEmptyState(
                      'No clients added',
                      'Start by adding your first client',
                      Icons.person_add,
                    );
                  }

                  if (clients.isEmpty) {
                    return _buildEmptyState(
                      'No clients match your search',
                      'Try adjusting your filters or search terms',
                      Icons.search_off,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return _buildClientCard(client, theme, controller);
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed("/add-client"),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Client'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildAdvancedFilters(ClientsController controller, ThemeData theme) {
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

            // City Filter
            Row(
              children: [
                Expanded(
                  child: Obx(() => DropdownButtonFormField<String>(
                        value: controller.selectedCity.value,
                        decoration: const InputDecoration(
                          labelText: 'Filter by City',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        items: controller.cityOptions.map((city) {
                          final count = city == 'All'
                              ? controller.totalClients
                              : controller.clientsByCity[city] ?? 0;
                          return DropdownMenuItem(
                            value: city,
                            child: Text('$city ($count)'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.updateCityFilter(value);
                          }
                        },
                      )),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quick Filter Buttons
            Wrap(
              spacing: 8,
              children: controller.stateOptions.map((state) {
                if (state == 'All') return const SizedBox.shrink();
                return ActionChip(
                  label: Text(state),
                  onPressed: () => controller.updateStateFilter(state),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
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
            style: FontStyles.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(
      ClientModel client, ThemeData theme, ClientsController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => Get.to(() => ClientDetailView(client: client)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                radius: 24,
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Client Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: FontStyles.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            client.email,
                            style: FontStyles.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          client.contactNumber,
                          style: FontStyles.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                   
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'edit') {
                    Get.to(() => AddClientView(), arguments: client);
                  } else if (value == 'delete') {
                    await controller.deleteClient(client);
                  } 
                  // else if (value == 'call') {
                  //   // Implement call functionality
                  //   Get.snackbar('Call', 'Calling ${client.name}...');
                  // } else if (value == 'email') {
                  //   // Implement email functionality
                  //   Get.snackbar('Email', 'Emailing ${client.name}...');
                  // }
                },
                itemBuilder: (context) => [
                  // const PopupMenuItem(
                  //   value: 'call',
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.phone, size: 16),
                  //       SizedBox(width: 8),
                  //       Text('Call'),
                  //     ],
                  //   ),
                  // ),
                  // const PopupMenuItem(
                  //   value: 'email',
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.email, size: 16),
                  //       SizedBox(width: 8),
                  //       Text('Email'),
                  //     ],
                  //   ),
                  // ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
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

  // void _exportClients(ClientsController controller) {
  //   final csvData = controller.exportClientsToCSV();
  //   // You can implement file saving logic here
  //   Get.snackbar(
  //     'Export',
  //     'CSV data generated successfully',
  //     snackPosition: SnackPosition.BOTTOM,
  //   );
  // }

  void _showRecentClients(ClientsController controller) {
    final recentClients = controller.getRecentClients();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recent Clients',
              style: FontStyles.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...recentClients.take(5).map((client) => ListTile(
                  leading: CircleAvatar(
                    child: Text(client.name[0].toUpperCase()),
                  ),
                  title: Text(client.name),
                  subtitle: Text(client.email),
                  onTap: () {
                    Get.back();
                    Get.to(() => ClientDetailView(client: client));
                  },
                )),
          ],
        ),
      ),
    );
  }
}
