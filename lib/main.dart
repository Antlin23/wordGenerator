import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Antons random word generator',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var currentWord = WordPair.random();
  var history = <WordPair>[];

  GlobalKey? historyListKey;

  //Get next word
  void getNext() {
    history.insert(0, currentWord);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    currentWord = WordPair.random();
    notifyListeners();
  }

  //get previous word
  void getPrevious() {
    if (history.isNotEmpty) {
      var animatedList = historyListKey?.currentState as AnimatedListState?;
      if (animatedList != null && history.isNotEmpty) {
        currentWord = history.first;
        var removedItem = history.removeAt(0);
        animatedList.removeItem(
          0,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: Text(removedItem.asPascalCase),
            ),
          ),
        );
      }
      notifyListeners();
    }
  }

  var favorites = <WordPair>[];

  void toggleFavorite(WordPair? pair){
    if(favorites.contains(pair)){
      favorites.remove(pair);
    } else if (pair != null) {
      favorites.add(pair);
    }
    notifyListeners();
  }

  String capitalize(String text){
    return "${text[0].toUpperCase()}${text.substring(1)}";
  }

  void clearAllFavorites(){
    favorites.clear();
    notifyListeners();
  }
}

//Pages ------------

//Standard page
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritesPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Antons word generator"),
          ),
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 800,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

//Homepage
class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.currentWord;

    WordPair? prevoiusPair;

    if(appState.history.isNotEmpty){
      prevoiusPair = appState.history[0];
    }

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    IconData prevIcon;
    if (appState.favorites.contains(prevoiusPair)) {
      prevIcon = Icons.favorite;
    } else {
      prevIcon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView()
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PreviousButton(appState: appState),
                    SizedBox(width: 20),
                    BigCard(pair: pair),
                    SizedBox(width: 20),
                    NextButton(appState: appState),
                  ]
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //Like previous
                    ElevatedButton.icon(
                      onPressed: (){
                        appState.toggleFavorite(prevoiusPair);
                      },
                      label: Text("Like previous"),
                      icon: Icon(prevIcon),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        appState.toggleFavorite(pair);
                      },
                      icon: Icon(icon),
                      label: Text('Like'),
                    ),
                    SizedBox(width: 20),
                  ],
                ),
                SizedBox(height: 20,)
              ],
            )
          ),
        ],
      ),
    );
  }
}

//History list
class HistoryListView extends StatefulWidget {
  const HistoryListView({super.key});

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  final _key = GlobalKey();

  static const Gradient _maskingGradient = LinearGradient(
    colors: [Colors.transparent, Colors.black],
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  appState.toggleFavorite(pair);
                },
                icon: appState.favorites.contains(pair)
                    ? Icon(Icons.favorite, size: 12)
                    : SizedBox(),
                label: Text(
                  pair.asPascalCase,
                  semanticsLabel: pair.asPascalCase,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

//Favorite page 
class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //You have x favorites text
        Padding(
          padding: const EdgeInsets.all(30),
          child: ListTile(
            title: Text('You have ${appState.favorites.length} favorites'),
            titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
              decoration: TextDecoration.underline
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7
          ),
          child: GridView(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 420 / 90,
              ),
              children: [
                for (var wordPair in appState.favorites)
                  ListTile(
                    leading: IconButton(
                      icon: Icon(Icons.delete_outline,semanticLabel: "Delete"),
                      onPressed: () {
                        appState.toggleFavorite(wordPair);
                      },
                    ),
                    title: Text(wordPair.asPascalCase, semanticsLabel: wordPair.asPascalCase,),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(30),
            child: ElevatedButton.icon(
          onPressed: appState.clearAllFavorites,
          label: Text("Delete all"),
          ),
        ),
      ],
    );
  }
}

//Items -----------
//Next word button
class NextButton extends StatelessWidget {
  const NextButton({
    super.key,
    required this.appState,
  });

  final MyAppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displaySmall!.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.primary
    );
    return ElevatedButton(
      onPressed: () {
        appState.getNext();
      },
      child: Text(
        'Next',
        style: style,
      ),
    );
  }
}

//Previous button
class PreviousButton extends StatelessWidget {
  const PreviousButton({
    super.key,
    required this.appState,
  });

  final MyAppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displaySmall!.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.primary
    );
    return ElevatedButton(
      onPressed: () {
        appState.getPrevious();
      },
      child: Text(
        'Previous',
        style: style,
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontWeight: FontWeight.normal,
      decorationColor: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSize(
          duration: Duration(milliseconds: 200),
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(appState.capitalize(pair.first), style: style.copyWith(fontWeight: FontWeight.normal),),
                Text(appState.capitalize(pair.second), style: style.copyWith(fontWeight: FontWeight.bold),)
              ],
            ),
          ),          
        ),
      ),
    );
  }
}