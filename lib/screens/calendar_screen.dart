import 'package:flutter/material.dart';

import '../models/task_entry.dart';

class CalendarScreen extends StatefulWidget {
  final List<TaskEntry> tasks;
  final Color accentColor;
  final String title;

  const CalendarScreen({
    super.key,
    required this.tasks,
    required this.accentColor,
    required this.title,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks =
        widget.tasks
            .where((task) => _isSameDay(task.dateTime, _selectedDate))
            .toList()
          ..sort((a, b) => a.dateTime!.compareTo(b.dateTime!));

    return Container(
      color: const Color(0xFFF7F2F4),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xFF151515),
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left, color: Color(0xFF151515)),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right, color: Color(0xFF151515)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _monthTitle(_visibleMonth),
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _CalendarGrid(
            visibleMonth: _visibleMonth,
            selectedDate: _selectedDate,
            tasks: widget.tasks,
            accentColor: widget.accentColor,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
            },
          ),
          const SizedBox(height: 24),
          Text(
            "Tasks on ${_dateTitle(_selectedDate)}",
            style: const TextStyle(
              color: Color(0xFF151515),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (selectedTasks.isEmpty)
            const _EmptyDayCard()
          else
            ...selectedTasks.map(
              (task) =>
                  _TaskDayCard(task: task, accentColor: widget.accentColor),
            ),
        ],
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
      _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
      _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    });
  }

  static bool _isSameDay(DateTime? a, DateTime b) {
    return a != null &&
        a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  static String _monthTitle(DateTime date) {
    return "${_monthName(date.month)} ${date.year}";
  }

  static String _dateTitle(DateTime date) {
    return "${date.day} ${_monthName(date.month)}";
  }

  static String _monthName(int month) {
    const names = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return names[month - 1];
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<TaskEntry> tasks;
  final Color accentColor;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarGrid({
    required this.visibleMonth,
    required this.selectedDate,
    required this.tasks,
    required this.accentColor,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    final leadingEmptyDays = firstDay.weekday - 1;
    final itemCount = leadingEmptyDays + daysInMonth;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              _WeekdayLabel("M"),
              _WeekdayLabel("T"),
              _WeekdayLabel("W"),
              _WeekdayLabel("T"),
              _WeekdayLabel("F"),
              _WeekdayLabel("S"),
              _WeekdayLabel("S"),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyDays) {
                return const SizedBox.shrink();
              }

              final day = index - leadingEmptyDays + 1;
              final date = DateTime(visibleMonth.year, visibleMonth.month, day);
              final isSelected = _isSameDay(date, selectedDate);
              final hasTasks = tasks.any(
                (task) => _isSameDay(task.dateTime, date),
              );

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onDateSelected(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : const Color(0xFFF7F2F4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        "$day",
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF151515),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (hasTasks)
                        Positioned(
                          bottom: 7,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static bool _isSameDay(DateTime? a, DateTime b) {
    return a != null &&
        a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TaskDayCard extends StatelessWidget {
  final TaskEntry task;
  final Color accentColor;

  const _TaskDayCard({required this.task, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.event_note_outlined, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Color(0xFF151515),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.dateLabel,
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  const _EmptyDayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        "No tasks assigned for this date.",
        style: TextStyle(color: Colors.black54, fontSize: 15),
      ),
    );
  }
}
