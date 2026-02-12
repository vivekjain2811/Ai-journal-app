import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // 0 = Weekly, 1 = Daily
  int _selectedIndex = 0;
  final JournalService _journalService = JournalService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(body: Center(child: Text("Please login to view analytics")));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weekly Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: _journalService.getJournals(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading data: ${snapshot.error}"));
          }

          final journals = snapshot.data ?? [];
          final weeklyData = _processWeeklyData(journals);
          final dailyData = _processDailyData(journals);
          final totalEntries = journals.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Toggle Segmented Control
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildToggleOption(
                        context,
                        title: 'Weekly',
                        index: 0,
                        isSelected: _selectedIndex == 0,
                      ),
                      _buildToggleOption(
                        context,
                        title: 'Daily',
                        index: 1,
                        isSelected: _selectedIndex == 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Chart Section
                Container(
                  height: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedIndex == 0 ? 'Journal Entries (Last 4 Weeks)' : 'Journal Entries (This Week)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: _selectedIndex == 0
                            ? _buildWeeklyChart(primaryColor, weeklyData)
                            : _buildDailyChart(primaryColor, dailyData),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stats / Insights Summary Card
                _buildSummaryCard(
                  context,
                  title: 'Total Entries',
                  value: totalEntries.toString(),
                  subtitle: 'Keep journaling!', 
                  icon: Icons.emoji_events_rounded,
                  color: Colors.amber,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Returns list of 4 doubles: [3 weeks ago, 2 weeks ago, 1 week ago, current week]
  List<double> _processWeeklyData(List<JournalEntry> journals) {
    List<double> data = [0, 0, 0, 0];
    final now = DateTime.now();
    // Normalize now to start of today to match basic week logic if needed, 
    // but simplified: strictly difference in days / 7
    
    for (var entry in journals) {
      final diff = now.difference(entry.createdAt).inDays;
      if (diff < 7) {
        data[3]++; // Current week (0-6 days ago)
      } else if (diff < 14) {
        data[2]++; // 1 week ago (7-13 days ago)
      } else if (diff < 21) {
        data[1]++; // 2 weeks ago (14-20 days ago)
      } else if (diff < 28) {
        data[0]++; // 3 weeks ago (21-27 days ago)
      }
    }
    return data;
  }

  // Returns list of 7 doubles for Mon-Sun counts
  // X axis 0=Mon, 6=Sun. Logic: Check entry.createdAt.weekday.
  // We only count entries from the current calendar week (Monday to Sunday)? 
  // OR last 7 days? 
  // User asked for "Daily Journal Graph".
  // Standard UI implies Mon-Sun fixed axis. Let's show counts for the CURRENT week (Mon-Sun).
  List<double> _processDailyData(List<JournalEntry> journals) {
    List<double> data = List.filled(7, 0);
    final now = DateTime.now();
    
    // Find start of current week (Monday) at 00:00:00
    // weekday: 1=Mon, 7=Sun
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)).copyWith(
      hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0
    );
    
    // End of week is startOfWeek + 7 days
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    for (var entry in journals) {
      if (entry.createdAt.isAfter(startOfWeek) && entry.createdAt.isBefore(endOfWeek)) {
        // map weekday 1..7 to index 0..6
        int index = entry.createdAt.weekday - 1;
        if (index >= 0 && index < 7) {
          data[index]++;
        }
      }
    }
    return data;
  }

  Widget _buildToggleOption(BuildContext context, {required String title, required int index, required bool isSelected}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(Color primaryColor, List<double> data) {
    // Find max Y for dynamic scaling, min 5
    double maxY = data.reduce((curr, next) => curr > next ? curr : next);
    maxY = (maxY < 5) ? 5 : maxY + 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.round().toString(),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                String text;
                switch (value.toInt()) {
                  case 0:
                    text = '3W Ago';
                    break;
                  case 1:
                    text = '2W Ago';
                    break;
                  case 2:
                    text = 'Last W';
                    break;
                  case 3:
                    text = 'This W';
                    break;
                  default:
                    text = '';
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(text, style: style),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
               showTitles: true,
               getTitlesWidget: (value, meta) {
                 if (value % 2 == 0) {
                   return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                 }
                 return const SizedBox.shrink();
               },
               reservedSize: 28,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1, // Draw line for every integer
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildBarGroup(0, data[0], primaryColor, maxY),
          _buildBarGroup(1, data[1], primaryColor, maxY),
          _buildBarGroup(2, data[2], primaryColor, maxY),
          _buildBarGroup(3, data[3], primaryColor, maxY),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY, 
            color: color.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChart(Color primaryColor, List<double> data) {
    // Find max Y for dynamic scaling
    double maxY = data.reduce((curr, next) => curr > next ? curr : next);
    maxY = (maxY < 5) ? 5 : maxY + 1;

    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
        spots.add(FlSpot(i.toDouble(), data[i]));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
           drawVerticalLine: false,
           horizontalInterval: 1,
           getDrawingHorizontalLine: (value) {
             return FlLine(
               color: Colors.grey.withOpacity(0.1),
               strokeWidth: 1,
             );
           },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                 String text;
                switch (value.toInt()) {
                  case 0: text = 'Mon'; break;
                  case 1: text = 'Tue'; break;
                  case 2: text = 'Wed'; break;
                  case 3: text = 'Thu'; break;
                  case 4: text = 'Fri'; break;
                  case 5: text = 'Sat'; break;
                  case 6: text = 'Sun'; break;
                  default: text = '';
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(text, style: style),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
             sideTitles: SideTitles(
               showTitles: true,
               getTitlesWidget: (value, meta) {
                 if (value % 2 == 0) {
                   return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                 }
                 return const SizedBox.shrink();
               },
               reservedSize: 28,
             ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {required String title, required String value, required String subtitle, required IconData icon, required Color color}) {
     final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                   Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
