import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/mood_provider.dart';

class MoodAnalysisScreen extends StatefulWidget {
  const MoodAnalysisScreen({super.key});

  @override
  State<MoodAnalysisScreen> createState() => _MoodAnalysisScreenState();
}

class _MoodAnalysisScreenState extends State<MoodAnalysisScreen> {
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mood Analysis',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [],
      ),
      body: Consumer<MoodProvider>(
        builder: (context, moodProvider, child) {
          // Ensure provider is initialized
          if (!moodProvider.isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              moodProvider.initialize();
            });
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMoodOverviewCards(moodProvider),
                const SizedBox(height: 24),
                _buildMoodChart(moodProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodOverviewCards(MoodProvider moodProvider) {
    final now = DateTime.now();
    DateTime startDate;
    if (_selectedPeriod == 'Week') {
      startDate = now.subtract(const Duration(days: 7));
    } else if (_selectedPeriod == 'Month') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (_selectedPeriod == '3 Months') {
      startDate = DateTime(now.year, now.month - 2, 1);
    } else {
      startDate = DateTime(now.year - 1, now.month, 1);
    }

    final allMoods = moodProvider
        .getAllMoods()
        .where((m) => m.date.isAfter(startDate))
        .toList();

    double avgScore = 0;
    if (allMoods.isNotEmpty) {
      avgScore = allMoods.fold(0, (sum, m) => sum + m.score) / allMoods.length;
    }

    String rating = 'Unknown';
    Color ratingColor = Colors.grey;
    if (avgScore == 0 && allMoods.isEmpty) {
      rating = "No Data";
    } else if (avgScore < 6) {
      rating = 'Normal';
      ratingColor = Colors.orangeAccent;
    } else if (avgScore <= 10) {
      rating = 'Average';
      ratingColor = Colors.lightBlueAccent;
    } else {
      rating = 'Great';
      ratingColor = Colors.greenAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Mood Overview',
          icon: Icons.pie_chart,
          color: const Color(0xFF9B5DE5),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
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
                      value: avgScore / 16.0,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF9B5DE5)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        avgScore.toStringAsFixed(1),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Text(
                        '/16',
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
                      'Overall Status',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rating,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ratingColor,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSmallStat('Entries', '${allMoods.length}'),
                        const SizedBox(width: 24),
                        // Placeholder for another stat if needed
                        _buildSmallStat(
                            'Trend', allMoods.isNotEmpty ? 'Active' : '-'),
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

  Widget _buildMoodChart(MoodProvider moodProvider) {
    // Calculate width:
    // Week: Fit to screen (minus padding)
    // Month: 30 days * ~50px = 1500px
    double chartWidth = MediaQuery.of(context).size.width - 40; // Default fit
    if (_selectedPeriod != 'Week') {
      final days = _selectedPeriod == 'Month'
          ? 30
          : (_selectedPeriod == '3 Months' ? 90 : 12);
      // For Year view (12 months), fit to screen is fine usually, or maybe scrollable.
      // Let's assumes Month/3Months needs scrolling.
      // 7 days visible -> width / 7 per item.
      final itemWidth = (MediaQuery.of(context).size.width - 40) / 7;
      chartWidth = itemWidth * days;

      // Auto-scroll to end after build
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
              title: 'Mood History',
              icon: Icons.bar_chart,
              color: const Color(0xFF9B5DE5),
            ),
            PopupMenuButton<String>(
              initialValue: _selectedPeriod,
              position: PopupMenuPosition.under,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
          height: 320,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 20,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Theme.of(context).cardColor,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            rod.toY.round().toString(),
                            TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
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
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            final now = DateTime.now();
                            DateTime date;
                            if (_selectedPeriod == 'Week') {
                              date = now
                                  .subtract(Duration(days: 6 - value.toInt()));
                            } else {
                              date =
                                  DateTime(now.year, now.month, value.toInt());
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MMM d').format(date),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: _generateMoodBarGroups(moodProvider),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateMoodBarGroups(MoodProvider moodProvider) {
    final now = DateTime.now();
    List<BarChartGroupData> groups = [];

    if (_selectedPeriod == 'Week') {
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final mood = moodProvider.getMoodForDate(date);
        final score = mood?.score.toDouble() ?? 0.0;

        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: score,
                color: score > 0 ? const Color(0xFF9B5DE5) : Colors.transparent,
                width: 12,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 16,
                  color: const Color(0xFF9B5DE5).withOpacity(0.05),
                ),
              ),
            ],
            showingTooltipIndicators: score > 0 ? [0] : [],
          ),
        );
      }
    } else {
      // Month View (Default)
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(now.year, now.month, i);
        // Only show up to today? User said "creation start day ... from current day".
        // Let's show all month but empty for future.

        final mood = moodProvider.getMoodForDate(date);
        final score = mood?.score.toDouble() ?? 0.0;

        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: score,
                color: score > 0 ? const Color(0xFF9B5DE5) : Colors.transparent,
                width: 6,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 16,
                  color: const Color(0xFF9B5DE5).withOpacity(0.05),
                ),
              ),
            ],
            showingTooltipIndicators: score > 0 ? [0] : [],
          ),
        );
      }
    }
    return groups;
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
