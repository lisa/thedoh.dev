---
title: Conference Talks
parentcategory: ""
category: "conftalks"
order: 2
description: |
  All of the conference talks Lisa has given, with links to recordings and slides.
---

# Conference Talks

All of the talks I've given live the [lisa/conferences](https://github.com/lisa/conferences) repository. Within that repository I have links to slides and any recordings. That repository will be the authoratative source for links and details; on this blog I'll expand or give some background, where available.

## Talk: Starting Over (2016)

In late 2015 I was invited by a coworker (@ahalliop) to give a talk at a [local meetup][exploretech] she helps organize. At the time, we were creating a new server environment for [PCI compliance](https://www.pcisecuritystandards.org/pci_security/). The previous, non-PCI environment, had grown very organically over time and had proven to have a number of pain points.

## SLO Creation And You: Or, How We Learned To Stop Worrying And Love The Queue Length (2018)

This talk originated from wanting to share some lessons from my team at FreshBooks coming up with the first SLOs. It wasn't an easy process because they were put into an existing monitoring ecosystem. We were trying to get buy-in for service ownership (the idea that people who wrote the software would be responsible for it, instead of "ops team" *de facto* being responsible). While that push never panned out while I was working there, the ops team did pilot a project to come up with some SLOs for MySQL and RabbitMQ.

The talk focuses on RabbitMQ because there are some more lessons there. One of those lessons is that the customer may think your service is the best source of truth for an objective, and that might be incorrect. Talking with the customers to understand the goals and best source of data is important, as is iterating on the SLO-creation process.

To date, this talk has been given twice.

### DevOpsDays Silicon Valley (2018)

I had mentioned to Jennifer Davis, co-author of [Effective DevOps: Building a Culture of Collaboration, Affinity, and Tooling at Scale](http://shop.oreilly.com/product/0636920039846.do), my talk topic and she expressed interest. To fill a speaker slot at the last minute, she graciously invited me to present at the [two-day conference](https://devopsdays.org/events/2018-silicon-valley/welcome/). 


The talk was [recorded][dod18-recording]. [Slides for the event are available][dod18-slides].

### ExploreTech (2018)

In October 2018 I was invited back to [ExploreTech][exploretech] to give the SLO talk. There is no recording, but the slightly [modified/updated slides are available][exploretech18-slides].


[exploretech]: https://www.meetup.com/ExploreTech-Toronto/ "ExploreTech Toronto Meetup"
[dod18-slides]: https://speakerdeck.com/thedoh/slos-and-you-or-how-we-learned-to-stop-worrying-and-love-the-queue-length
[dod18-recording]: https://www.youtube.com/watch?v=MB0u2-c-2zs
[exploretech18-slides]: https://speakerdeck.com/thedoh/slo-creation-and-you-or-how-we-learned-to-stop-worrying-and-love-the-queue-length
