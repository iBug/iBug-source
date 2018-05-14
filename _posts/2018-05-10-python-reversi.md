---
title: Making a Reversi game with Python
description: ""
tags: development
redirect_from: /p/6
show_view: true
view_name: GitHub
view_url: "https://github.com/iBug/PyReversi"
hidden: true
---

As a casual attempt to accomplish a Grand Assignment, I created a Reversi game with Python. The project is open-source on GitHub and you can view it with the link above.

![Screenshot](https://user-images.githubusercontent.com/7273074/39672148-558d8104-5157-11e8-9a48-040459eb8d89.png)

The game implements the following functionality:

- Graphical User Interface (GUI), using PyQt5
- Built-in AI implemented as a heuristic searching (and evaluation) algorithm

The core functionality of the game is pretty simple, and should be easy for anyone familiar with the Reverso game. The code is in [`reversi.py`](https://github.com/iBug/PyReversi/blob/master/reversi.py).

It's the GUI and the AI part that differentiates implementations of the Reversi game.

As a general (and relatively easy) way to create an AI for the game, heuristic searching well balances between coding complexity and the competence of the resulting algorithm. Heuristic searching is basically a complete searching tree at limited depth, equipped with a heuristic evaluation function that determines the situation of the game board.
