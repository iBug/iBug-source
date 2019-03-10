---
title: Making a Reversi game with Python
tagline: And creating an AI with heuristic searching
description: The Reversi game is a Grand Assignment of the course "Program Design II". I'm giving it an attempt because the process of creating such a game would be interesting.
tags: development study-notes
redirect_from: /p/6
show_view: true
view_name: GitHub
view_url: "https://github.com/iBug/PyReversi"
---

As a casual attempt to accomplish a Grand Assignment, I created a Reversi game with Python. The project is open-source on GitHub and you can view it with the link above.

![Screenshot](https://user-images.githubusercontent.com/7273074/39672148-558d8104-5157-11e8-9a48-040459eb8d89.png)

The game implements the following functionality:

- Graphical User Interface (GUI), using PyQt5
- Built-in AI implemented as a heuristic searching (and evaluation) algorithm

The core functionality of the game is pretty simple, and should be easy for anyone familiar with the Reverso game. The code is in [`reversi.py`](https://github.com/iBug/PyReversi/blob/master/reversi.py).

It's the GUI and the AI part that differentiates implementations of the Reversi game. Since GUI isn't very hard to create with Qt, I'll focus on the AI algorithm here.

As a general (and relatively easy) way to create an AI for the game, heuristic searching well balances between coding complexity and the competence of the resulting algorithm. Heuristic searching is basically a complete searching tree at limited depth, equipped with a heuristic evaluation function that determines the situation of the game board.

# Heuristic Evaluation

From my previous experiences in playing Reversi with others, I've learnt that it's important to occupy side grids and corner grids, while avoiding the opponent to occupy them. With some research and calculation, this boils down to [a predefined weight table][1]:

```python
SCORE = [
    [  500, -150, 30, 10, 10, 30, -150,  500],
    [ -150, -250,  0,  0,  0,  0, -250, -150],
    [   30,    0,  1,  2,  2,  1,    0,   30],
    [   10,    0,  2, 16, 16,  2,    0,   30],
    [   10,    0,  2, 16, 16,  2,    0,   30],
    [   30,    0,  1,  2,  2,  1,    0,   30],
    [ -150, -250,  0,  0,  0,  0, -250, -150],
    [  500, -150, 30, 10, 10, 30, -150,  500]
]
```

This is a good start but may not be sufficient in complicated scenarios. While it's good to try to occupy sides and corners, it'd be of little value when they're easily captured by the opponent.

Given the idea above, I came up with this "chess liberty" solution. The score will be decreased if a chess is "too liberated".

```python
for dx in [-1, 0, 1]:
    for dy in [-1, 0, 1]:
        tx, ty = x + dx, y + dy
        if 0 <= tx < BS and 0 <= ty < BS and board[tx][ty] == EMPTY:
            liberty += 1
if chess == BLACK:
    c1 += 1
    s1 += SCORE[x][y] - liberty * LIBERTY
else:
    c2 += 1
    s2 += SCORE[x][y] - liberty * LIBERTY
```

where `s1` is the score for the black side, and `s2` is the score for the white side.

The final part is the side chess check ([code][2]). It checks if a corner may be occupied by the opponent (having own chess around), and if it's occupied, add additional score if there are more chesses of the same color.

# Searching tree

A plain searching algorithm would be really plain. The black side wants the score to be as high as possible, while the white side wants the exact opposite.

A pseudo-code of the algorithm is given below:

```javascript
MAX = 999999

function heuristicSearch(game, side, depth)
  if depth <= 0
    return null, heuristicScore(game)

  want_max = (side == BLACK)
  bestMove = null
  if want_max
    bestScore = -MAX - 1
  else
    bestScore = +MAX + 1

  for move in game.availableMoves
    game.perform move
    // Recurse
    subMove, subScore = heuristicSearch(game, side, depth - 1)
    game.undo

    if want_max
      if subScore > bestScore
        bestScore = subScore
        bestMove = move
    else
      if subScore < bestScore
        bestScore = subScore
        bestMove = move
  return bestMove, bestScore
```

That's the abstract of the searching procedure. There are a few things to do before it's fully working.

- Handle the case where the game has ended already
- Handle the case where the current player has no moves available

Both cases aren't too complex to be handled with a few lines of codes. And then, there's a performance concern: Why bother searching deeper when one move is bad enough that subsequent moves can't perform any better?

Fortunately, with the help of [the Alpha-Beta Pruning algorithm][3], this is a solvable problem, which ~~~I will describe in a later article~~~ I have written [here][4].


  [1]: https://github.com/iBug/PyReversi/blob/master/ai.py#L13
  [2]: https://github.com/iBug/PyReversi/blob/master/ai.py#L110
  [3]: https://en.wikipedia.org/wiki/Alpha–beta_pruning
  [4]: {{ site.url }}/p/7
