import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:idp_notes/db/rep.dart';
import 'package:idp_notes/notifier.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'db/db.dart';

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
        ChangeNotifierProvider(
          create: (context) => NotateProvider(RepositoryImpl()),
        )
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData.from(colorScheme: const ColorScheme.dark()).copyWith(
          useMaterial3: true,
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

class _NoteListPageState extends State<NoteListPage>
    with TickerProviderStateMixin {
  late AnimationController tileAnimationController;
  late Animation<Offset> tileAnimation;

  late AnimationController btnAnimationController;
  late Animation<Offset> btnSlideAnimation;
  late Animation<double> btnRotateAnimation;

  @override
  void initState() {
    super.initState();

    tileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    btnAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    btnSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 2),
    ).animate(CurvedAnimation(
      parent: btnAnimationController,
      curve: Curves.easeInBack,
    ));
    btnRotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: btnAnimationController,
      curve: Curves.easeInBack,
    ));
    tileAnimationController.forward();
  }

  @override
  void dispose() {
    tileAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Notes"),
          actions: [
            IconButton(
                onPressed: () {
                  if (tileAnimationController.isCompleted) {
                    tileAnimationController.reverse();
                  } else {
                    tileAnimationController.forward();
                  }
                },
                icon: const Icon(Icons.animation)),
          ],
        ),
        body: Consumer<NotateProvider>(
          builder: (context, noteProvider, child) => noteProvider
                  .notates.isNotEmpty
              ? ListView.builder(
                  itemCount: noteProvider.notates.length,
                  itemBuilder: (context, index) {
                    final delay = index * 700 / noteProvider.notates.length;
                    tileAnimation = Tween<Offset>(
                      begin: const Offset(0, 10),
                      end: const Offset(0, 0),
                    ).animate(
                      CurvedAnimation(
                        parent: tileAnimationController,
                        curve: Interval(
                            delay /
                                tileAnimationController
                                    .duration!.inMilliseconds,
                            1,
                            curve: Curves.easeInOut),
                      ),
                    );
                    return SlideTransition(
                      position: tileAnimation,
                      child: Slidable(
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
                    );
                  },
                )
              : const Center(child: Text('Записів нема')),
        ),
        floatingActionButton: AnimatedBuilder(
            animation: btnAnimationController,
            builder: (context, child) => Transform.rotate(
                  angle: btnRotateAnimation.value,
                  child: SlideTransition(
                    position: btnSlideAnimation,
                    child: FloatingActionButton(
                      onPressed: () {
                        btnAnimationController.forward().then((value) async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => const DetailScreen(),
                            ),
                          );

                          btnAnimationController.reverse();
                        });
                      },
                      child: const Icon(Icons.add),
                    ),
                  ),
                )),
      );

  void _toDetails(NotateProvider provider, Notate? notate) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(notate: notate),
        ),
      );
}

class DetailScreen extends StatefulWidget {
  final Notate? notate;

  const DetailScreen({super.key, this.notate});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _contentController = TextEditingController();

  final titleKey = GlobalKey<FormState>();

  late final AnimationController animController;

  late final Animation<double> anim;

  bool isActionDone = false;

  @override
  void initState() {
    super.initState();
    animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    anim = Tween<double>(
      begin: 0,
      end: 2,
    ).animate(
      CurvedAnimation(parent: animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _titleController.text = widget.notate?.title ?? '';
    _contentController.text = widget.notate?.content ?? '';

    return Scaffold(
      appBar: AppBar(
        title: widget.notate != null
            ? const Text('Edit Notate')
            : const Text('New Notate'),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(microseconds: 500),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: anim,
              child: child,
            ),
            child: IconButton(
              onPressed: () => _onClick(context),
              icon: isActionDone
                  ? SvgPicture.asset(
                      'images/success.svg',
                      color: Colors.white,
                      width: 30,
                    )
                  : const Icon(Icons.check),
            ),
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
      if (widget.notate != null) {
        _updateNotate(context, widget.notate!);
      } else {
        _addNotate(context);
      }
      setState(() {
        isActionDone = !isActionDone;
        animController.forward().then((value) => Navigator.pop(context));
      });
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
