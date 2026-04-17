// schedules_screen.dart - Scaffold + liste des planifications
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/schedule_provider.dart';
import '../widgets/schedule_card.dart';
import 'create_schedule_screen.dart';

class SchedulesScreen extends ConsumerWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleProvider = ref.watch(scheduleProviderRef);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Filter schedules
            },
          ),
        ],
      ),
      body: scheduleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : scheduleProvider.schedules.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune planification\nCréez votre première planification',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: scheduleProvider.schedules.length,
              itemBuilder: (context, index) {
                final schedule = scheduleProvider.schedules[index];
                return ScheduleCard(schedule: schedule);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateSchedule(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle'),
      ),
    );
  }

  void _navigateToCreateSchedule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateScheduleScreen()),
    );
  }
}
