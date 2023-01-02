---
title: "Overengineering Advent of Code 2022"
tags: development
redirect_from: /p/56
---

*Advent of Code* ([Wikipedia](https://en.wikipedia.org/wiki/Advent_of_Code), [link](https://adventofcode.com/)) is an annual event that releases a programming puzzle every day from December 1 to December 25. It's a great chance to learn a new language or practice your skills.

Considering that all the puzzles are designed to be lightweight, meaning that if implemented correctly, they're solvable in no more than a few seconds with a reasonably small memory footprint, I picked Go as my language of choice. Go has been my preference over Python for a while, for being compiled into machine code and thus more performant, and a decent set of standard libraries.

## Notes on puzzles

The first 10 puzzles are very easy and doesn't even require special knowledge. They're practically just text processing and simulation, so there aren't many comments to be made.

- Day 2: While it's straightforward to implement a rock-paper-scissors game using `switch`es or lookup tables, noticing that shape `i+1` beats shape `i` allows us to simplify the code in an obscure way.

    For example, I implemented the "shape score" as `int(s[2] - 'W')`, and the "outcome score" as `(4 + int(s[2]-'X') - int(s[0]-'A')) % 3 * 3` for the first part. For the second part, the "shape score" is now `1 + (int(s[0]-'A')+int(s[2]-'X')+2)%3`, and the "outcome score" is `int(s[2]-'X') * 3`.

    This is certainly not the most readable code, but it's a good example of how to use math to simplify code. Less code = less bugs, and if you're really crazy about that, you can always add unit tests to ensure that the code doesn't break unexpectedly. That's not my style, though.

Starting from Day 11, the puzzles become more interesting. Some math or data structures are required to solve them.

- Day 11: The first part is plain simulation, but the second part can easily run the numbers out of range if you don't manage them properly. Actually, modulo by the [least common multiple](https://en.wikipedia.org/wiki/Least_common_multiple) of the divisors is a good way to keep them down.
- Day 14, 15 and 23: With a large coordinate space but limited elements, it's a better idea to use a map or set instead of contiguous memory.
- Day 17 part 2: Running a simulation for 1000000000000 rounds is certainly not feasible, but it's possible to find a pattern from the first 10000 or so rounds, and calculate the result from there.
- Day 18 part 2: Finding internal holes would be difficult, but [flood filling](https://en.wikipedia.org/wiki/Flood_fill) from the outside is an alternative approach.
- Day 19 part 2: Even if searching for the "next robot to make" can't keep the search space small, pruning near the leaves (i.e. stop searching in the last few minutes) can still cut it down by a large factor. This is the only way that I managed to bring the run time below 1 second.
- Day 20 part 2: Again simulating for so many 811589153 steps is not feasible, so like Day 11 part 2, it's important to find a correct modulo.
- Day 21 part 2: At first this seems like tremendous work, but I made a bold assumption that the equation is linear (degree = 1), which turned out to be true. This enabled me to use very simple math to solve it.
- Day 22 is my favorite puzzle. Finding an algorithm to fold a flat layout into a cube is far from easy, so I hard-coded it for my input. (It seems like everyone is getting the same layout.) Such a two-layer `switch` statement is prone to bugs and took me the longest time to debug.
- Day 25: To my surprise, the puzzle is missing a part 2. Maybe the author is getting on a vacation?

Finally, a magic trick that I discovered from Reddit for Day 15 part 2: Observing that the only uncovered space must be adjacent to multiple covered areas, examining the intersections of the edges of the beacons' coverage areas produces a tiny search space. While it's intuitive to build upon part 1's solution, this discovery leads to a lightspeed solution.

## Engineering the project

In fact, rushing to the puzzles was not even the first thing. I did not come across the event until my friend [taoky](https://www.taoky.moe/) recommended it to me. He was already halfway through the puzzles ([his <i class="fab fa-fw fa-github"></i> repository](https://github.com/taoky/adventofcode)) and had set himself a set of rules, including one where "*all solutions should take reasonable time and memory usage*". We discussed various methods to measure the time and memory usage, when he set it forth that it was not easy to add measurements to every single program.
