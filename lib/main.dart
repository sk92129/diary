import 'package:diary/bloc/diary_bloc.dart';
import 'package:diary/bloc/diary_event.dart';
import 'package:diary/bloc/diary_state.dart';
import 'package:diary/diary_entry.dart';
import 'package:diary/storage_mgr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageManager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DiaryBloc(),
      child: MaterialApp(
        title: 'My Diary',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'My Diary'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    context.read<DiaryBloc>().add(GetDiaryEvent());
  }

  void _addNewEntry() {
    final newEntry = DiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Entry',
      content:
          'This is a new diary entry. Tap to edit and add your thoughts here.',
      date: DateTime.now(),
      mood: 'Neutral',
    );
    context.read<DiaryBloc>().add(AddDiaryEvent(newEntry));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: BlocListener<DiaryBloc, DiaryState>(
        listener: (context, state) {
          if (state is DiaryFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<DiaryBloc, DiaryState>(
          builder: (context, state) {
            if (state is DiaryProgressing) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is DiaryLoadSuccess) {
              final entries = state.entries.values.toList();
              if (entries.isEmpty) {
                return const Center(
                  child: Text(
                    'No diary entries yet.\nTap the + button to add your first entry!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return DiaryEntryCard(entry: entry);
                },
              );
            } else if (state is DiaryFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading diary entries',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DiaryBloc>().add(GetDiaryEvent());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else {
              // DiaryInitial state
              return const Center(
                child: Text(
                  'Welcome to your diary!\nTap the + button to add your first entry!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewEntry,
        tooltip: 'Add New Entry',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryEntryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    entry.mood,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              entry.content,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8.0),
            Text(
              _formatDate(entry.date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    // generate a string with the date time with the local time zone DD/MM/YYYY HH:MM AM/PM
    final formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(date);

    if (difference == 0) {
      return 'Today $formattedDate';
    } else if (difference == 1) {
      return 'Yesterday $formattedDate';
    } else if (difference < 7) {
      return '$difference days ago $formattedDate';
    } else {
      return '${date.day}/${date.month}/${date.year} $formattedDate';
    }
  }
}
