---
title: "High-performance mass web crawling on AWS"
tags: web-scraping aws
redirect_from: /p/31

hidden: true
---

The 3rd-and-last experiment of course *Web Information Processing* and Application required us to create a recommendation engine, and "predict" the rating (1-5 stars) for 4M user-item pairs based on the training data of 9M user-item pairs and a social network.

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

ScrapingHub has forced AutoThrottle enabled for all jobs, so my first SH job survived for longer before it started receiving 403 responses. Looking at the stats, the job maintained its position for about 40 minutes, before signals of having its IP banned emerged. I updated the scraper a few times to include detections for more variations of indications of an IP ban, but never made it over an hour. And because I only attempted to avoid the IP ban by throttling and detecting, the actual "targets" contained in the code remained the same, which accounted for high duplication in crawled results in the first few runs, which in turn led to a quick drop in the increase of the submitted result (of this course experiment).

Recalling that I had spare promotional credits from AWS Educate, I came up with the idea of utilizing the large IP pool of AWS, which has another advantage of the ease to swap out a banned one.

## Part 2: Expansion onto AWS, distributed crawling with centralized management

The high duplication rate of results from the first few runs on ScrapingHub was alarming: I knew that I wouldn't make any real success if I didn't build a centralized job dispatcher and data collector, so the first thing before moving onto AWS is to create a control center.

I picked my favorite quickstarter framework Flask, implemented three simple interfaces `get job`, `update job` and `add result`. To make things absolutely simple yet reliable, I picked SQLite as database backend because it's easy to setup and query (`sqlite3` CLI is ready for use). I designed a "job pool" architecture, where each job record is a to-be-crawled URL, and is deleted from the pool once it's requested. The spider then crawls the page, send results back to the control center, as well as the "Next Page" link in the page back into the job pool if there is one. It didn't even take a lot of effort to work this out ([code][r3]).

Deployment is just as easy. I wrapped the server up in a Docker container, put it on my primary server on Amazon Lightsail (2 GB instance), configured Nginx and added a DNS record on Cloudflare.

## Part 3: Redesigned management architecture, fine-grained control, more robust and faster


  [requests]: https://2.python-requests.org/
  [bs4]: https://www.crummy.com/software/BeautifulSoup/
  [scrapy]: https://scrapy.org/
  [scrapinghub]: https://scrapinghub.com/
  [douban]: https://www.douban.com/
  [r1]: https://github.com/iBug/douban-spider/commit/8aead82
  [r2]: https://github.com/iBug/douban-spider/compare/cecbcfb..8eb1ff1
  [r3]: https://github.com/iBug/douban-spider/blob/5da2c80441aee5dd1ba0ee38f28d5edde393635b/server.py
