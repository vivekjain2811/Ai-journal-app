import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_mood.dart';
import '../services/mood_service.dart';

class MoodCalendar extends StatefulWidget {
  const MoodCalendar({super.key});

  @override
  State<MoodCalendar> createState() => _MoodCalendarState();
}

class _MoodCalendarState extends State<MoodCalendar> {
  final MoodService _moodService = MoodService();
  final User? _user = FirebaseAuth.instance.currentUser;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<DailyMood>>(
      stream: _moodService.getMoodsForMonth(_user.uid, _focusedDay),
      builder: (context, snapshot) {
        final moods = snapshot.data ?? [];
        Map<DateTime, List<DailyMood>> events = {};
        
        for (var mood in moods) {
           // Normalize date to remove time part for accurate matching
          final date = DateTime(mood.date.year, mood.date.month, mood.date.day);
          if (events[date] == null) {
            events[date] = [];
          }
          events[date]!.add(mood);
        }

        return Column(
          children: [
            TableCalendar<DailyMood>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.week, // Minimal by default
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.week: 'Week',
              },
              eventLoader: (day) {
                final date = DateTime(day.year, day.month, day.day);
                return events[date] ?? [];
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: EdgeInsets.all(4),
                todayDecoration: BoxDecoration(
                  color: Colors.transparent, 
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue, 
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.transparent, // Minimal selection
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(BorderSide(color: Colors.blue, width: 2))
                ),
                selectedTextStyle: TextStyle(color: Colors.blue),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                leftChevronIcon: Icon(Icons.chevron_left, size: 28),
                rightChevronIcon: Icon(Icons.chevron_right, size: 28),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: -2,
                      child: Text(
                        events.first.mood,
                        style: const TextStyle(fontSize: 20), // Larger emoji
                      ),
                    );
                  }
                  return null;
                },
                defaultBuilder: (context, date, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.topCenter,
                     decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.day}',
                         style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
                todayBuilder: (context, date, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.topCenter,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.day}',
                         style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
