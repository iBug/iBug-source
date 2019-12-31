---
title: "High-performance mass web crawling on AWS"
tags: web-scraping aws
redirect_from: /p/31

published: false
---

The 3rd-and-last experiment of course *Web Information Processing and Application* required us to create a recommendation engine, and "predict" the rating (1-5 stars) for 4M user-item pairs based on the training data of 9M user-item pairs and a social network.

The interesting part is, all user and rating data are real, i.e. unmasked. This makes it possible to, instead of playing nicely by doing data analysis, crawl the target data directly, bypassing the aim of the experiment to learn about recommendation systems, which is exactly the way I chose and I'm going to describe in this article.

To make things challenging, the target website, [Douban][douban], has a moderate level of anti-spider techniques in place. This makes it impossible to just submit a truckload of requests hoping to retrieve all data desired, but more advanced technologies and cleverer tactics are mandatory before pulling it off.

## Part 1: Scrapy and ScrapingHub

Previously I've done crawlers using [requests][requests] + [Beautiful Soup][bs4], but this time under suggestions from my roommate, I decided to try it out with [Scrapy][scrapy], a said-to-be-great web crawling framework.

Scrapy is a framework extremely easy to start with. I followed the guide on Scrapy's website and wrote less than 30 lines of Python ([commit][r1]), and the first version of my spider was ready to go.

It didn't take too long before I picked up on Douban's anti-spider techniques. My server's IP was banned (fortunately, only temporarily) and all requests to Douban were getting 403 responses.

I fortuitously recalled that GitHub Student Pack provides an offer from [ScrapingHub][scrapinghub], the company behind Scrapy, containing one scraper unit, for free forever. Following their guide on deployment, I asked my teammate to modify my spider to adopt Scrapy's project layout ([commit][r2]), redeemed the Student Pack offer, and deployed my first scraper project onto ScrapingHub cloud.

<figure>
<img src="/image/scrapinghub.png" alt="ScrapingHub results" />
<figcaption>
My job history on ScrapingHub, all of which are for this experiment
</figcaption>
</figure>

## Part 2: Expansion onto AWS, distributed crawling with centralized management

## Part 3: Redesigned management architecture, fine-grained control, more robust and faster


  [requests]: https://2.python-requests.org/
  [bs4]: https://www.crummy.com/software/BeautifulSoup/
  [scrapy]: https://scrapy.org/
  [scrapinghub]: https://scrapinghub.com/
  [douban]: https://www.douban.com/
  [r1]: https://github.com/iBug/douban-spider/commit/8aead82
  [r2]: https://github.com/iBug/douban-spider/compare/cecbcfb..8eb1ff1
