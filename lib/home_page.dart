// ignore_for_file: camel_case_types, constant_identifier_names

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snake_game/blank_pixel.dart';
import 'package:snake_game/food_pixel.dart';
import 'package:snake_game/highscore_tile.dart';
import 'package:snake_game/snake_pixel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum snake_Direction { UP, DOWN, RIGHT, LEFT }

class _HomePageState extends State<HomePage> {
  //!grid dimenstions
  int rowSize = 10;
  int totalSquares = 100;

  //!GAME CONTROLS

  //!user score
  int currentScore = 0;

  //!Controllers
  final _nameController = TextEditingController();

  //!snake direction is intially to the right
  var currentDirection = snake_Direction.RIGHT;

  bool gameHasStarted = false;

  //!defeault snake positions
  List<int> snakePos = [0, 1, 2];

  //!default position of a food item
  int foodPosition = 55;

  //!high score list
  List<String> highscore_documentId = [];
  late final Future? getDocumentId;

  @override
  void initState() {
    getDocumentId = getDocId();
    super.initState();
  }

  //!get high score document ids of the top 10 players.

  Future getDocId() async {
    await FirebaseFirestore.instance
        .collection("highscores")
        .orderBy("score", descending: true)
        .limit(10)
        .get()
        // ignore: avoid_function_literals_in_foreach_calls
        .then((value) => value.docs.forEach((element) {
              highscore_documentId.add(element.reference.id);
            }));
  }

  //!start the game
  void startGame() {
    gameHasStarted = true;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        //!keep the snake to move around the grid
        moveSnake();

        //!check if the game is over
        if (gameOver()) {
          timer.cancel();
          //!display a message to the user
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Game Over"),
                  content: Column(
                    children: [
                      Text("Your score is $currentScore"),
                      TextField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(hintText: "Enter your name"),
                      )
                    ],
                  ),
                  actions: [
                    MaterialButton(
                      onPressed: () {
                        Navigator.pop(context);
                        submitScore();
                        startNewGame();
                      },
                      color: Colors.pink,
                      child: const Text("Submit Score"),
                    )
                  ],
                );
              });
        }
      });
    });
  }

  //!move the snake
  void moveSnake() {
    switch (currentDirection) {
      case snake_Direction.RIGHT:
        {
          //! add the head
          //!if snake is at the right wall then adjust
          if (snakePos.last % rowSize == 9) {
            snakePos.add(snakePos.last + 1 - rowSize);
          } else {
            snakePos.add(snakePos.last + 1);
          }

          break;
        }
      case snake_Direction.LEFT:
        {
          //!add the head
          if (snakePos.last % rowSize == 0) {
            snakePos.add(snakePos.last - 1 + rowSize);
          } else {
            snakePos.add(snakePos.last - 1);
          }

          break;
        }
      case snake_Direction.UP:
        {
          if (snakePos.last < rowSize) {
            snakePos.add(snakePos.last - rowSize + totalSquares);
          } else {
            snakePos.add(snakePos.last - rowSize);
          }

          break;
        }
      case snake_Direction.DOWN:
        {
          //!add the head
          if (snakePos.last + rowSize > totalSquares) {
            snakePos.add(snakePos.last + rowSize - totalSquares);
          } else {
            snakePos.add(snakePos.last + rowSize);
          }

          break;
        }

      default:
    }
    if (snakePos.last == foodPosition) {
      //!if snake is eating the food
      eatFood();
    } else {
      //!remove the tail
      snakePos.removeAt(0);
    }
  }

  //!snake eating the food
  void eatFood() {
    currentScore++;
    //!making sure the food is not where the snake already is
    while (snakePos.contains(foodPosition)) {
      foodPosition = Random().nextInt(totalSquares);
    }
  }

  bool gameOver() {
    //!the game is over when the snake runs into itself
    //!this occures when there is a duplicate pixel index in the snakePostion list of pixels

    //! this duplicate list helps to check
    List<int> bodySnake = snakePos.sublist(0, snakePos.length - 1);

    if (bodySnake.contains(snakePos.last)) {
      return true;
    }
    return false;
  }

  void submitScore() {
    //!get access to the firestore databse
    var database = FirebaseFirestore.instance;

    //!add values to the firestore database
    database
        .collection('highscores')
        .add({"name": _nameController.text, "score": currentScore});
  }

  Future startNewGame() async {
    highscore_documentId = [];
    await getDocId();
    setState(() {
      snakePos = [0, 1, 2];
      foodPosition = 55;
      currentDirection = snake_Direction.RIGHT;
      gameHasStarted = false;
      currentScore = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: screenWidth > 428 ? 428 : screenWidth,
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Current Score"),
                        Text(
                          currentScore.toString(),
                          style: const TextStyle(fontSize: 36),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: gameHasStarted
                        ? Container()
                        : FutureBuilder(
                            future: getDocumentId,
                            builder: (context, snapshot) {
                              return ListView.builder(
                                itemCount: highscore_documentId.length,
                                itemBuilder: (context, index) {
                                  return HighScoreTile(
                                      documentId: highscore_documentId[index]);
                                },
                              );
                            }),
                  )
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 0 &&
                      currentDirection != snake_Direction.UP) {
                    currentDirection = snake_Direction.DOWN;
                  }
                  if (details.delta.dy < 0 &&
                      currentDirection != snake_Direction.DOWN) {
                    currentDirection = snake_Direction.UP;
                  }
                },
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx > 0 &&
                      currentDirection != snake_Direction.LEFT) {
                    currentDirection = snake_Direction.RIGHT;
                  }
                  if (details.delta.dx < 0 &&
                      currentDirection != snake_Direction.RIGHT) {
                    currentDirection = snake_Direction.LEFT;
                  }
                },
                child: GridView.builder(
                    itemCount: totalSquares,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: rowSize),
                    itemBuilder: (context, index) {
                      if (snakePos.contains(index)) {
                        return const SnakePixel();
                      } else if (foodPosition == index) {
                        return const FoodPixel();
                      } else {
                        return const BlankPixel();
                      }
                    }),
              ),
            ),
            Expanded(
              child: Center(
                child: MaterialButton(
                  onPressed: gameHasStarted ? () {} : startGame,
                  color: gameHasStarted ? Colors.grey : Colors.pink,
                  child: const Text('PLAY'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
