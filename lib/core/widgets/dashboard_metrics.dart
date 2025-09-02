import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/material.dart';

/// Dashboard metrics or overview card [DashboardMetrics]
class DashboardMetrics extends StatelessWidget {
  final Map<String, int> metrics;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  const DashboardMetrics({
    super.key,
    required this.metrics,
    required this.title,
    required this.subtitle,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.01,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      color: kTransparentColor, // context.secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _buildCard(context),
    );
  }

  Padding _buildCard(BuildContext context) {
    final metricEntries = metrics.entries.toList();
    // calculate the width of the card based on the number of metrics
    double cardWidth = (context.screenWidth * 0.9) / (metrics.length);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: metricEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final metric = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _MetricItem(
                    label: metric.key,
                    value: metric.value,
                    width: cardWidth,
                    index: index,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Row _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildListTile(context, title: title, subtitle: subtitle),
        ),
        IconButton(
          tooltip: 'Pin Metrics',
          onPressed: onPressed,
          icon: Icon(Icons.push_pin, color: kBrightPrimaryColor),
          hoverColor: kLightBlueColor.toAlpha(0.3),
        ),
      ],
    );
  }

  ListTile _buildListTile(
    BuildContext context, {
    String title = '',
    String subtitle = '',
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      titleAlignment: ListTileTitleAlignment.center,
      title: Text(
        title,
        style: context.textTheme.bodySmall?.copyWith(
          color: kWhiteColor,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
        ),
        textScaler: TextScaler.linear(context.textScaleFactor),
      ),
      subtitle: Text(
        subtitle.toTitle,
        style: context.textTheme.bodyLarge?.copyWith(
          color: kWhiteColor,
          fontWeight: FontWeight.normal,
          overflow: TextOverflow.ellipsis,
        ),
        // textScaler: TextScaler.linear(context.textScaleFactor),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final int value;
  final double width;
  final int index;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.width,
    required this.index,
  });

  get randomColor => randomBgColors[index];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.isMobile ? 140 : width,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor.toAlpha(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: randomColor, width: 10)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              color: randomColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toTitle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/*

INVENTORY::
workspaces/{workspaceId}/stats/inventory

Future<Map<String, int>> fetchInventoryMetrics(String workspaceId) async {
  final doc = await FirebaseFirestore.instance
      .collection('workspaces')
      .doc(workspaceId)
      .collection('stats')
      .doc('inventory')
      .get();

  if (!doc.exists) return {};

  final data = doc.data()!;
  return {
    "Pending Orders": data['pendingOrders'] ?? 0,
    "To Be Shipped": data['toBeShipped'] ?? 0,
    "Delivered": data['delivered'] ?? 0,
    "Current Stock": data['currentStock'] ?? 0,
    "Completed": data['completed'] ?? 0,
    "Cancelled": data['cancelled'] ?? 0,
  };
}
{
  "pendingOrders": 3,
  "toBeShipped": 2,
  "delivered": 8,
  "currentStock": 150,
  "completed": 10,
  "cancelled": 1
}

POS::
workspaces/{workspaceId}/stats/pos

Future<Map<String, dynamic>> fetchPOSMetrics(String workspaceId) async {
  final doc = await FirebaseFirestore.instance
      .collection('workspaces')
      .doc(workspaceId)
      .collection('stats')
      .doc('pos')
      .get();

  if (!doc.exists) return {};

  final data = doc.data()!;
  return {
    "Total Sales": data['totalSales'] ?? 0,
    "Daily Sales": data['dailySales'] ?? 0,
    "Monthly Revenue": data['monthlyRevenue'] ?? 0,
    "Refunds": data['refunds'] ?? 0,
    "Top Product ID": data['topProductId'] ?? '',
    "Customers Today": data['customersToday'] ?? 0,
  };
}
{
  "totalSales": 120,
  "dailySales": 15,
  "monthlyRevenue": 53000,
  "refunds": 2,
  "topProductId": "abc123",
  "customersToday": 9
}


CRM::
workspaces/{workspaceId}/stats/crm

Future<Map<String, dynamic>> fetchCRMMetrics(String workspaceId) async {
  final doc = await FirebaseFirestore.instance
      .collection('workspaces')
      .doc(workspaceId)
      .collection('stats')
      .doc('crm')
      .get();

      if (!doc.exists) return {};

  final data = doc.data()!;
  return {
    "Total Leads": data['totalLeads'] ?? 0,
    "Active Leads": data['activeLeads'] ?? 0,
    "Converted Leads": data['convertedLeads'] ?? 0,
    "Total Customers": data['totalCustomers'] ?? 0,
    "New Customers": data['newCustomers'] ?? 0,
    "Open Tickets": data['openTickets'] ?? 0,
    "Closed Tickets": data['closedTickets'] ?? 0,
  };
}
{
  "totalLeads": 34,
  "activeLeads": 34,
  "convertedLeads": 34,
  "totalCustomers": 210,
  "newCustomers": 5,
  "openTickets": 34,
  "closedTickets": 18
}

WAREHOUSE::
workspaces/{workspaceId}/stats/warehouse

Future<Map<String, dynamic>> fetchWarehouseMetrics(String workspaceId) async {
  final doc = await FirebaseFirestore.instance
      .collection('workspaces')
      .doc(workspaceId)
      .collection('stats')
      .doc('warehouse')
      .get();

      if (!doc.exists) return {};

      final data = doc.data()!;
      return {
        "Total Items": data['totalItems'] ?? 0,
        "Out of Stock": data['outOfStock'] ?? 0,
        "Low Stock": data['lowStock'] ?? 0,
        "Bins Used": data['binsUsed'] ?? 0,
        "Utilization (%)": data['spaceUtilization']?.toStringAsFixed(1) ?? '0.0',
      };
}
{
  "totalItems": 1200,
  "outOfStock": 4,
  "lowStock": 12,
  "binsUsed": 20,
  "spaceUtilization": 75.3 // percentage
}




class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, int>> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = fetchInventoryMetrics("your-workspace-id");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Failed to load inventory data"));
        }

        final metrics = snapshot.data ?? {};
        return InventoryOverviewCard(metrics: metrics);
      },
    );
  }
}


📌 How to Keep Stats Updated?

🔄 Option 1: Cloud Functions (Trigger-Based)
Use Firestore or Realtime Database triggers to update stats when relevant data changes.

Example:

On new sale -> increment totalSales
On inventory change -> recalculate currentStock
🔁 Option 2: App-Level Updates
Whenever a transaction happens in your app (e.g., a sale, order, customer support update), immediately update the stats document.

FirebaseFirestore.instance
    .collection('workspaces')
    .doc(workspaceId)
    .collection('stats')
    .doc('pos')
    .update({'totalSales': FieldValue.increment(1)});
*/

/*
class InventoryOverviewCard2 extends StatelessWidget {
  final Map<String, int> metrics;

  const InventoryOverviewCard2({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final bgColor = context.isDarkMode ? kBgLightColor : kLightColor;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Inventory Overview",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: metrics.entries.map((entry) {
                return _MetricItem(label: entry.key, value: entry.value);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem2 extends StatelessWidget {
  final String label;
  final int value;

  const _MetricItem2({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[700] : Colors.grey[200];

    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
*/
