import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.yellowAccent,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 24,
            color: Colors.black,
          ),
        ),
      ),
      home: ChangeNotifierProvider(
        create: (_) => GameProvider(),
        child: const TicTacToePage(),
      ),
    );
  }
}

// Game Logic
class GameProvider extends ChangeNotifier {
  List<String> _board = List.generate(9, (index) => '');
  bool _isXTurn = true;
  String _message = 'Player X\'s Turn';
  List<int>? _winningPattern;
  bool _gameOver = false;
  bool _isSinglePlayer = false;

  List<String> get board => _board;
  bool get isXTurn => _isXTurn;
  String get message => _message;
  List<int>? get winningPattern => _winningPattern;
  bool get gameOver => _gameOver;
  bool get isSinglePlayer => _isSinglePlayer;

  void setSinglePlayer(bool value) {
    _isSinglePlayer = value;
    resetGame();
    notifyListeners();
  }

  void handleTap(int index) {
    if (_board[index] != '') return;
    if (_winningPattern != null) return; // Game over

    _board[index] = _isXTurn ? 'X' : 'O';
    _winningPattern = _checkWinner(_board[index]);

    if (_winningPattern != null) {
      _message = 'Player ${_board[index]} Wins!';
      _gameOver = true;
    } else if (!_board.contains('')) {
      _message = 'It\'s a Draw!';
      _gameOver = true;
    } else {
      _isXTurn = !_isXTurn;
      _message = 'Player ${_isXTurn ? 'X' : 'O'}\'s Turn';
      if (_isSinglePlayer && !_isXTurn && !_gameOver) {
        _makeAIMove();
      }
    }
    notifyListeners();
  }

  List<int>? _checkWinner(String player, [List<String>? board]) {
    board ??= _board;
    const winPatterns = [
      [0, 1, 2], // Row 1
      [3, 4, 5], // Row 2
      [6, 7, 8], // Row 3
      [0, 3, 6], // Column 1
      [1, 4, 7], // Column 2
      [2, 5, 8], // Column 3
      [0, 4, 8], // Diagonal 1
      [2, 4, 6], // Diagonal 2
    ];

    for (var pattern in winPatterns) {
      if (board[pattern[0]] == player &&
          board[pattern[1]] == player &&
          board[pattern[2]] == player) {
        return pattern;
      }
    }
    return null;
  }

  void resetGame() {
    _board = List.generate(9, (index) => '');
    _isXTurn = true;
    _message = 'Player X\'s Turn';
    _winningPattern = null;
    _gameOver = false;
    notifyListeners();
  }

  void _makeAIMove() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_gameOver) return;

      int bestScore = -1000;
      int bestMove = -1;

      for (int i = 0; i < _board.length; i++) {
        if (_board[i] == '') {
          _board[i] = 'O';
          int score = _minimax(_board, 0, false);
          _board[i] = '';
          if (score > bestScore) {
            bestScore = score;
            bestMove = i;
          }
        }
      }

      if (bestMove != -1) {
        handleTap(bestMove);
      }
    });
  }

  int _minimax(List<String> board, int depth, bool isMaximizing) {
    if (_checkWinner('O', board) != null) return 10 - depth;
    if (_checkWinner('X', board) != null) return depth - 10;
    if (!board.contains('')) return 0;

    if (isMaximizing) {
      int bestScore = -1000;
      for (int i = 0; i < board.length; i++) {
        if (board[i] == '') {
          board[i] = 'O';
          int score = _minimax(board, depth + 1, false);
          board[i] = '';
          bestScore = max(score, bestScore);
        }
      }
      return bestScore;
    } else {
      int bestScore = 1000;
      for (int i = 0; i < board.length; i++) {
        if (board[i] == '') {
          board[i] = 'X';
          int score = _minimax(board, depth + 1, true);
          board[i] = '';
          bestScore = min(score, bestScore);
        }
      }
      return bestScore;
    }
  }

  int max(int a, int b) => (a > b) ? a : b;
  int min(int a, int b) => (a < b) ? a : b;
}

// UI Components
class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key});

  @override
  TicTacToePageState createState() => TicTacToePageState();
}

class TicTacToePageState extends State<TicTacToePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.addListener(() {
      setState(() {});
    });

    gameProvider.addListener(() {
      if (gameProvider.winningPattern != null) {
        _animationController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildGridItem(int index) {
    return GestureDetector(
      onTap: () {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        if (!gameProvider.gameOver) {
          gameProvider.handleTap(index);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 4),
        ),
        child: Center(
          child: Consumer<GameProvider>(
            builder: (context, gameProvider, child) {
              String value = gameProvider.board[index];
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.elasticOut,
                    ),
                    child: child,
                  );
                },
                child: value != ''
                    ? Text(
                  value,
                  key: ValueKey(value + index.toString()),
                  style: const TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 64,
                    color: Colors.black,
                  ),
                  semanticsLabel: 'Cell $index: $value',
                )
                    : const SizedBox.shrink(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBoard() {
    final gameProvider = Provider.of<GameProvider>(context);
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          GridView.builder(
            itemCount: 9,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemBuilder: (context, index) => _buildGridItem(index),
          ),
          if (gameProvider.winningPattern != null)
            CustomPaint(
              size: Size.infinite,
              painter: WinningLinePainter(
                winningPattern: gameProvider.winningPattern!,
                progress: _animation.value,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        return Text(
          gameProvider.message,
          style: const TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 32,
            color: Colors.black,
          ),
        );
      },
    );
  }

  Widget _buildResetButton() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.yellowAccent,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'BebasNeue',
          fontSize: 24,
        ),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.black, width: 4),
        ),
      ),
      onPressed: () {
        gameProvider.resetGame();
        _animationController.reset();
      },
      child: const Text('Reset Game'),
    );
  }

  Widget _buildModeSwitch() {
    final gameProvider = Provider.of<GameProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Two Players',
          style: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        Switch(
          value: gameProvider.isSinglePlayer,
          onChanged: (value) {
            gameProvider.setSinglePlayer(value);
          },
          activeColor: Colors.black,
          inactiveThumbColor: Colors.black,
          inactiveTrackColor: Colors.black38,
        ),
        const Text(
          'AI Opponent',
          style: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 24,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: orientation == Orientation.portrait
                ? Column(
              children: [
                _buildMessage(),
                const SizedBox(height: 16),
                _buildBoard(),
                const SizedBox(height: 16),
                _buildResetButton(),
                const SizedBox(height: 16),
                _buildModeSwitch(),
              ],
            )
                : Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMessage(),
                      const SizedBox(height: 16),
                      _buildResetButton(),
                      const SizedBox(height: 16),
                      _buildModeSwitch(),
                    ],
                  ),
                ),
                Expanded(child: _buildBoard()),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.yellowAccent,
      elevation: 0,
      title: const Text(
        'Tic Tac Toe',
        style: TextStyle(
          fontFamily: 'BebasNeue',
          fontSize: 28,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      shape: const Border(
        bottom: BorderSide(color: Colors.black, width: 4),
      ),
    );
  }
}

class WinningLinePainter extends CustomPainter {
  final List<int> winningPattern;
  final double progress;

  WinningLinePainter({required this.winningPattern, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final start = _getCellCenter(winningPattern[0], size);
    final end = _getCellCenter(winningPattern[2], size);

    final currentEnd = Offset.lerp(start, end, progress)!;

    canvas.drawLine(start, currentEnd, paint);
  }

  Offset _getCellCenter(int index, Size size) {
    final row = index ~/ 3;
    final col = index % 3;
    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;

    final x = col * cellWidth + cellWidth / 2;
    final y = row * cellHeight + cellHeight / 2;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant WinningLinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.winningPattern != winningPattern;
  }
}
