---
title: Alpha-Beta Pruning
description: The boosting algorithm behind the heuristic searching in my Reversi game
tags: algorithm study-notes
redirect_from: /p/7

mathjax: true
---

[As described in a previous article][1], *Alpha-Beta pruning* can be used to speed up minimax heuristic searching by pruning branches that will never be reached.

A quick glance from [Wikipedia][wk]:

> It is an adversarial search algorithm used commonly for machine playing of two-player games (Tic-tac-toe, Chess, Go, etc.).
> It stops completely evaluating a move when at least one possibility has been found that proves the move to be worse than a previously examined move.

# Alpha-Beta pruning

The alpha-beta pruning algorithm is based on the fact that one side wants to maximize the evaluated score, while the other wants to minimize it. Both sides are later referred to as Max and Min.

The algorithm maintains two values, alpha and beta, which represent the minimum score Max is assured of, and the maximum score Min is assured of, respectively. The values start at the "worst state", i.e., $$\alpha=-\infty$$ and $$\beta=+\infty$$. Whenever it goes to a point where $$\alpha\gt\beta$$, we know that this branch need not be examined as it will never be reached, given that both sides have found out that it's no better (or worse) than a known, assured branch.

This image from Wikipedia demonstrates it well:

![Image sourced from Wikipedia][2]

Let's call the above tree "Levels 0 to 4", where Level 0 contains only one node, the root node, and it's where the searching starts.
Levels 1 to 4 contains 3, 5, 7, 9 white nodes each. Greyed-out nodes are pruned by the alpha-beta algorithm. The numbers on the nodes are the best (maximum or minimum) score assured at this branch.

The tree is searched from left to right. It first completes the leftmost two nodes at level 4 and backtracks to the first node at level 2. At this time at the level 2 node, both sides know that this branch can assure Max of a minimum score of 5. The searching then goes to the second node at level 3, and it finds that this node can assure Min of a score of 4, which is lower than the minimum that Max has been assured of. This means that Max will not choose this branch if the game has reached the first node at level 2, and we can safely cut off the searching here (prune this branch).

Then we goes to the second node at level 2, and for Min it's a better branch, so Min will choose this path. No pruning is happening here.

After completing the first two branches at level 1, the search goes to the last branch at level 1. It finds that this branch can assure Min of 5, which is, to Max, worse than what it has been assured of (6 from the 2nd branch), so the rest of this branch is cut off. The final result is that Max will pick the 2nd branch at level 1.

# Heuristic searching with alpha-beta pruning

Here's the pseudo-code in the previous post that demonstrates a plain heuristic searching algorithm.

```javascript
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

To add alpha-beta pruning, as described above, we need to maintain two values, &alpha; and &beta;, and cut off searching when &alpha;&gt;&beta;.

```javascript
function heuristicSearch(game, side, depth, alpha, beta)
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
    subMove, subScore = heuristicSearch(game, side, depth - 1, alpha, beta)
    game.undo

    if want_max
      if subScore > bestScore
        bestScore = subScore
        bestMove = move
      alpha = max(alpha, bestScore)
      if alpha >= beta
        break  // alpha cut
    else
      if subScore < bestScore
        bestScore = subScore
        bestMove = move
      beta = min(beta, bestScore)
      if alpha >= beta
        break  // beta cut
  return bestMove, bestScore
```

Since &alpha; and &beta; are passed down to deeper recursive searches, they need initial values. The modified function should be called like

```javascript
heuristicSearch(game, side, depth, -INF, INF)
```

# Optimization

As seen in the image from Wikipedia:

![Image from Wikipedia][2]

We can see that if the 2nd node at level 2 is examined earlier, the 1st node would have been pruned. We want to find a way to make pruning occur more often, further improving the performance of the algorithm.

In most typical games, a partially good move often leads to better subsequences, and vice versa. This fact implies that we can sort the current steps we're going deep into, and search better moves first. Worse moves will likely be pruned more often. This leads to a small change in the code:

```javascript
function heuristicSearch(game, side, depth, alpha, beta)
  if depth <= 0
    return null, heuristicScore(game)

  want_max = (side == BLACK)
  bestMove = null
  if want_max
    bestScore = -MAX - 1
  else
    bestScore = +MAX + 1

  moves = game.availableMoves
  // ↓↓↓
  sort moves by heuristicScore(after move)
  // ↑↑↑

  for move in sorted_moves
    game.perform move
    // Recurse
    subMove, subScore = heuristicSearch(game, side, depth - 1, alpha, beta)
    game.undo

    if want_max
      if subScore > bestScore
        bestScore = subScore
        bestMove = move
      alpha = max(alpha, bestScore)
      if alpha >= beta
        break  // alpha cut
    else
      if subScore < bestScore
        bestScore = subScore
        bestMove = move
      beta = min(beta, bestScore)
      if alpha >= beta
        break  // beta cut
  return bestMove, bestScore
```

# Code

The whole project of the Python Reversi is [open-source at GitHub][3]. The AI algorithm is written in [file `ai.py`][4].


  [wk]: https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning
  [1]: /p/6
  [2]: /image/ab-pruning-wikipedia.png
  [3]: https://github.com/iBug/PyReversi
  [4]: https://github.com/iBug/PyReversi/tree/e340e9609dfa3f61419f4e8cb9e03248be52e3bc/ai.py#L145
