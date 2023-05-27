import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:idp_notes/notifier.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'db.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);

  Hive.registerAdapter(NotateAdapter());
  await Hive.openBox<Notate>('notates');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NotateProvider())
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData.from(colorScheme: const ColorScheme.dark()).copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
            },
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const NoteListPage(),
      ),
    );
  }
}

class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key});

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Notes")),
        body: Consumer<NotateProvider>(
          builder: (context, noteProvider, child) =>
              noteProvider.notates.isNotEmpty
                  ? ListView.builder(
                      itemCount: noteProvider.notates.length,
                      itemBuilder: (context, index) => Slidable(
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            CustomSlidableAction(
                              backgroundColor: Colors.red,
                              onPressed: (context) => noteProvider.deleteNotate(
                                noteProvider.notates[index],
                              ),
                              child: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(noteProvider.notates[index].title),
                          subtitle: Text(
                            noteProvider.notates[index].content,
                            maxLines: 1,
                          ),
                          onTap: () => _toDetails(
                            noteProvider,
                            noteProvider.notates[index],
                          ),
                        ),
                      ),
                    )
                  : const Center(child: Text('Записів нема')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (context) => DetailScreen()),
          ),
          child: const Icon(Icons.add),
        ),
      );

  void _toDetails(NotateProvider provider, Notate? notate) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(notate: notate),
        ),
      );
}

class DetailScreen extends StatelessWidget {
  final Notate? notate;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final titleKey = GlobalKey<FormState>();

  DetailScreen({super.key, this.notate});

  @override
  Widget build(BuildContext context) {
    _titleController.text = notate?.title ?? '';
    _contentController.text = notate?.content ?? '';

    return Scaffold(
      appBar: AppBar(
        title: notate != null
            ? const Text('Edit Notate')
            : const Text('New Notate'),
        actions: [
          IconButton(
            onPressed: () => _onClick(context),
            icon: const Icon(Icons.check),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: titleKey,
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Title'),
                validator: (str) {
                  if (str == null || str.trim().isEmpty) {
                    return 'Title is empty';
                  } else {
                    return null;
                  }
                },
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Content',
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onClick(BuildContext context) {
    if (titleKey.currentState?.validate() ?? false) {
      if (notate != null) {
        _updateNotate(context, notate!);
      } else {
        _addNotate(context);
      }
      Navigator.pop(context);
    }
  }

  void _updateNotate(
    BuildContext context,
    Notate notate,
  ) =>
      context.read<NotateProvider>().updateNotate(
            notate.copyWith(
              title: _titleController.text,
              content: _contentController.text,
            ),
          );

  void _addNotate(BuildContext context) =>
      context.read<NotateProvider>().addNotate(
            title: _titleController.text,
            content: _contentController.text,
          );
}
