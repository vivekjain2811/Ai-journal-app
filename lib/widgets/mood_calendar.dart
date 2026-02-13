import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';

class MoodCalendar extends StatefulWidget {
  const MoodCalendar({super.key});

  @override
  State<MoodCalendar> createState() => _MoodCalendarState();
}

class _MoodCalendarState extends State<MoodCalendar> {
  final JournalService _journalService = JournalService();
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

    return StreamBuilder<List<JournalEntry>>(
      stream: _journalService.getJournals(_user.uid),
      builder: (context, snapshot) {
        final journals = snapshot.data ?? [];
        Map<DateTime, List<JournalEntry>> events = {};
        
        for (var entry in journals) {
           // Normalize date to remove time part for accurate matching
          final date = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
          if (events[date] == null) {
            events[date] = [];
          }
          events[date]!.add(entry);
        }

        return Column(
          children: [
            TableCalendar<JournalEntry>(
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
                // Custom builder for days with journals
                defaultBuilder: (context, day, focusedDay) {
                  final date = DateTime(day.year, day.month, day.day);
                  if (events[date]?.isNotEmpty ?? false) {
                     return Container(
                      margin: const EdgeInsets.all(6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.green[800], // Dark green for journaled days
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return null; // Use default for others
                },
                // Also override today builder if it has an event to ensure color consistency
                todayBuilder: (context, day, focusedDay) {
                  final date = DateTime(day.year, day.month, day.day);
                  final hasJournal = events[date]?.isNotEmpty ?? false;
                  
                  return Container(
                    margin: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      // If journal exists, use dark green, else use simple outline/indicator for "Today"
                      color: hasJournal ? Colors.green[800] : Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: hasJournal ? null : Border.all(color: Theme.of(context).primaryColor),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: hasJournal ? Colors.white : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
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
