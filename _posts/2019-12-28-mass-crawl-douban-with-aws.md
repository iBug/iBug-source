---
title: "High-performance mass web crawling on AWS"
tags: web-scraping aws
redirect_from: /p/31

published: false
---

The 3rd-and-last experiment of course *Web Information Processing and Application* required us to create a recommendation engine, and "predict" the rating (1-5 stars) for 4M user-item pairs based on the training data of 9M user-item pairs and a social network.

The interesting part is, all user and rating data are real, i.e. unmasked. This makes it possible to, instead of playing nicely by doing data analysis, crawl the target data directly, bypassing the aim of the experiment to learn about recommendation systems, which is exactly the way I chose and I'm going to describe in this article.

# Part 1: Trying Scrapy and ScrapingHub

Previously I've done crawlers using [requests][requests] + [Beautiful Soup][bs4], but this time under suggestions from my roommate, I decided to try it out with [Scrapy][scrapy], a said-to-be-great web crawling framework.

Scrapy is a framework that's extremely easy to start with.

# Part 2: Expanding onto AWS, distributed crawling with central management

# Part 3: Redesigning management architecture, more robust and faster


  [requests]: https://2.python-requests.org/
  [bs4]: https://www.crummy.com/software/BeautifulSoup/
  [scrapy]: https://scrapy.org/
