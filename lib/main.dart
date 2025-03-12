import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Matching Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      navigatorKey: navigatorKey, // Ensure navigatorKey is set
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameState>(context, listen: false).initializeGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Matching Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              gameState.restartGame();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time: ${gameState.seconds}s', style: const TextStyle(fontSize: 18)),
                Text('Score: ${gameState.score}', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: gameState.cards.length,
              itemBuilder: (context, index) {
                return CardWidget(index: index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CardWidget extends StatelessWidget {
  final int index;
  const CardWidget({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final card = gameState.cards[index];

    return GestureDetector(
      onTap: () {
        gameState.flipCard(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isMatched ? Colors.green : Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: card.isFaceUp || card.isMatched
              ? Text(card.value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
              : const Text('?', style: TextStyle(fontSize: 32, color: Colors.white)),
        ),
      ),
    );
  }
}

class CardModel {
  final String value;
  bool isFaceUp;
  bool isMatched;

  CardModel({required this.value, this.isFaceUp = false, this.isMatched = false});
}

class GameState extends ChangeNotifier {
  List<CardModel> cards = [];
  CardModel? firstCard;
  CardModel? secondCard;
  int score = 0;
  int seconds = 0;
  Timer? _timer;

  void initializeGame() {
    List<String> values = ['🍎', '🍌', '🍒', '🍇', '🥝', '🍉', '🍓', '🍍'];
    values = [...values, ...values]..shuffle();
    cards = values.map((value) => CardModel(value: value)).toList();
    score = 0;
    seconds = 0;
    startTimer();
    notifyListeners();
  }

  void flipCard(int index) {
    if (cards[index].isFaceUp || cards[index].isMatched) return;

    cards[index].isFaceUp = true;

    if (firstCard == null) {
      firstCard = cards[index];
    } else if (secondCard == null) {
      secondCard = cards[index];
      Future.delayed(const Duration(milliseconds: 500), () {
        checkMatch();
      });
    }

    notifyListeners();
  }

  void checkMatch() {
    if (firstCard != null && secondCard != null) {
      if (firstCard!.value == secondCard!.value) {
        firstCard!.isMatched = true;
        secondCard!.isMatched = true;
        score += 10;
      } else {
        firstCard!.isFaceUp = false;
        secondCard!.isFaceUp = false;
        score -= 5;
      }
      firstCard = null;
      secondCard = null;
    }
    notifyListeners();
    checkWinCondition();
  }

  void checkWinCondition() {
    if (cards.every((card) => card.isMatched)) {
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 500), () {
        showWinDialog();
      });
    }
  }

  void showWinDialog() {
    if (navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Congratulations!'),
            content: Text('You matched all pairs in $seconds seconds! Your score: $score'),
            actions: [
              TextButton(
                child: const Text('Restart'),
                onPressed: () {
                  Navigator.of(context).pop();
                  restartGame();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds++;
      notifyListeners();
    });
  }

  void restartGame() {
    initializeGame();
    notifyListeners();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
