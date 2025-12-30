import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/habit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/habit.dart';
import '../../screens/subscription/subscription_plans_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'profile_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String _selectedPeriod = 'Week';
  final List<String> _periods = ['Week', 'Month'];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium =
        context.watch<AuthProvider>().currentUser?.premium ?? false;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Analysis',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPlansScreen(),
                ),
              );
            },
            icon: const Icon(Icons.workspace_premium),
            color: const Color(0xFFFFD700),
            iconSize: 28,
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          final shouldLockScreen = !isPremium;

          return Stack(
            children: [
              SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                physics: shouldLockScreen
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(habitProvider),
                    const SizedBox(height: 24),
                    _buildCompletionChart(habitProvider),
                    const SizedBox(height: 24),
                    _buildStreakCalendar(habitProvider),
                    const SizedBox(height: 24),
                    _buildHabitBreakdown(habitProvider),
                    const SizedBox(height: 24),
                    _buildStreakAnalysis(habitProvider),
                  ],
                ),
              ),
              if (shouldLockScreen)
                Positioned.fill(
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: theme.scaffoldBackgroundColor.withOpacity(0.3),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.lock,
                                      size: 48,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Unlock Full Analysis',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Detailed analysis is a Premium feature.\nUpgrade to unlock full habit insights.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SubscriptionPlansScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Go Premium'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards(HabitProvider habitProvider) {
    final totalHabits = habitProvider.activeHabits.length;
    final completedToday = habitProvider.completedTodayCount;
    final totalStreaks = habitProvider.totalStreaks;
    final avgCompletion =
        totalHabits > 0 ? (completedToday / totalHabits * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Overview',
          icon: Icons.pie_chart,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
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
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: avgCompletion / 100,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${avgCompletion.toInt()}%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Text(
                        'Done',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Goals',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedToday / $totalHabits',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSmallStat('Active', '$totalHabits'),
                        const SizedBox(width: 24),
                        _buildSmallStat('Streaks', '$totalStreaks'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  Widget _buildCompletionChart(HabitProvider habitProvider) {
    double chartWidth = MediaQuery.of(context).size.width - 40;
    if (_selectedPeriod == 'Month') {
      final itemWidth = (MediaQuery.of(context).size.width - 40) / 7;
      chartWidth = itemWidth * 30;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              context,
              title: 'Habit Progress',
              icon: Icons.show_chart,
              color: Theme.of(context).colorScheme.primary,
            ),
            PopupMenuButton<String>(
              initialValue: _selectedPeriod,
              position: PopupMenuPosition.under,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                setState(() {
                  _selectedPeriod = value;
                });
              },
              itemBuilder: (context) => _periods.map((period) {
                return PopupMenuItem(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedPeriod,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          height: 350,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  // Fixed Y-Axis Labels
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('100', style: Theme.of(context).textTheme.bodySmall),
                      Text('80', style: Theme.of(context).textTheme.bodySmall),
                      Text('60', style: Theme.of(context).textTheme.bodySmall),
                      Text('40', style: Theme.of(context).textTheme.bodySmall),
                      Text('20', style: Theme.of(context).textTheme.bodySmall),
                      Text('0', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(
                          height: 24), // Bottom Titles padding approximation
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Scrollable Chart
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth -
                            50, // Adjust width to account for fixed axis
                        child: BarChart(
                          BarChartData(
                            maxY: 100,
                            alignment: BarChartAlignment.spaceAround,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Theme.of(context).cardColor,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${rod.toY.toInt()}%',
                                    TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 20,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.1),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: false), // Hidden in scroll view
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    final now = DateTime.now();
                                    DateTime date;
                                    if (_selectedPeriod == 'Week') {
                                      date = now.subtract(
                                          Duration(days: 6 - value.toInt()));
                                    } else {
                                      date = now.subtract(
                                          Duration(days: 29 - value.toInt()));
                                    }

                                    if (_selectedPeriod == 'Week') {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          DateFormat('E').format(date),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      );
                                    } else {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          DateFormat('MMM d').format(date),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: _generateBarGroups(habitProvider),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Removed the local blur overlay logic
            ],
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateBarGroups(HabitProvider habitProvider) {
    final groups = <BarChartGroupData>[];
    final totalHabits = habitProvider.activeHabits.length;
    final now = DateTime.now();

    if (totalHabits == 0) {
      // Return empty spots if needed, or 0 values
      int count =
          _selectedPeriod == 'Week' ? 7 : 30; // Just week/month support for now
      for (int i = 0; i < count; i++) {
        groups.add(BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: 0,
            color: Theme.of(context).colorScheme.primary,
            width: 12,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
            ),
          )
        ]));
      }
      return groups;
    }

    if (_selectedPeriod == 'Week') {
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        int completedCount = 0;
        for (final habit in habitProvider.activeHabits) {
          final isCompleted = habit.completedDates.any((d) =>
              d.year == date.year &&
              d.month == date.month &&
              d.day == date.day);
          if (isCompleted) completedCount++;
        }
        final completionRate = (completedCount / totalHabits * 100);
        groups.add(BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: completionRate,
            color: Theme.of(context).colorScheme.primary,
            width: 12,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
            ),
          )
        ]));
      }
    } else {
      // Month
      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: 29 - i));
        int completedCount = 0;
        for (final habit in habitProvider.activeHabits) {
          final isCompleted = habit.completedDates.any((d) =>
              d.year == date.year &&
              d.month == date.month &&
              d.day == date.day);
          if (isCompleted) completedCount++;
        }
        final completionRate = (completedCount / totalHabits * 100);
        groups.add(BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: completionRate,
            color: Theme.of(context).colorScheme.primary,
            width: 12,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
            ),
          )
        ]));
      }
    }
    return groups;
  }

  Widget _buildStreakCalendar(HabitProvider habitProvider) {
    // Identify days with at least one completion
    final events = <DateTime, List<String>>{};
    for (final habit in habitProvider.activeHabits) {
      for (final date in habit.completedDates) {
        final dayKey = DateTime(date.year, date.month, date.day);
        if (events[dayKey] == null) {
          events[dayKey] = [];
        }
        events[dayKey]!.add(habit.id);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Activity Log',
          icon: Icons.calendar_month,
          color: const Color(0xFF9B5DE5),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          ),
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now(),
            focusedDay: DateTime.now(),
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              leftChevronIcon: Icon(Icons.chevron_left,
                  color: Theme.of(context).colorScheme.onSurface),
              rightChevronIcon: Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle:
                  TextStyle(color: Theme.of(context).colorScheme.primary),
              markerDecoration: const BoxDecoration(
                color: Color(0xFF9B5DE5),
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) {
              final dayKey = DateTime(day.year, day.month, day.day);
              return events[dayKey] ?? [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: const Color(0xFF9B5DE5)
                            .withOpacity(0.2), // Light purple background
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF9B5DE5),
                          width: 1.5,
                        )),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return null;
              },
              defaultBuilder: (context, day, focusedDay) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitBreakdown(HabitProvider habitProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Habit Performance',
          icon: Icons.insights_outlined,
          color: Colors.tealAccent,
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: habitProvider.activeHabits.length,
            separatorBuilder: (context, index) => Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final habit = habitProvider.activeHabits[index];
              return _buildHabitPerformanceItem(habit);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHabitPerformanceItem(Habit habit) {
    final completionRate = habit.completionRate;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: habit.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(habit.icon, color: habit.color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(habit.color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(completionRate * 100).toInt()}% completion rate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF9B5DE5).withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${habit.currentStreak}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Color(0xFF9B5DE5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'streak',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakAnalysis(HabitProvider habitProvider) {
    final habits = [...habitProvider.activeHabits]
      ..sort((a, b) => b.longestStreak.compareTo(a.longestStreak));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Best Streaks',
          icon: Icons.local_fire_department_outlined,
          color: Color(0xFF9B5DE5),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: habits.take(5).length,
            separatorBuilder: (context, index) => Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: habit.color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: habit.color,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Longest streak',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Color(0xFF9B5DE5), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${habit.longestStreak} days',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
