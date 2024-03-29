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

## LISA19

On October 21st, 2019, I gave a talk at LISA19. Slides can be found on [Speakerdeck][lisa19-slides]. Image credits can be found on my [conferences repository](https://github.com/lisa/conferences). [Video recording is available at the LISA19 website][lisa19-video].

Reference material:

* Images built reside in [Docker Hub](https://hub.docker.com/r/thedoh/lisa19)
* Sample source code, including Makefiles, demo script and "pull" binary, in [lisa/lisa19-containers](https://github.com/lisa/lisa19-containers)

## DevConf.cz (2020)

On January 26, 2020, I co-presented at DevConf.cz 2020 in Brno, Czech Republic with Naveen Malik. Our talk is titled [Implementing Microservices as Kubernetes Operators](https://devconfcz2020a.sched.com/event/YOxf/implementing-microservices-as-kubernetes-operators). Slides are available on [Speakerdeck][devconfcz2020-slides] and sample code in [GitHub.com/jewzaam/pod-operator][devconfcz2020-code].

## Open Source SRE: Sharing how we Grow SRE Practices

On August 18th, 2022 I presented a talk at DevConf.us in Boston, New York titled Open Source SRE: Sharing how we Grow SRE Practices. The talk, based on work at Red Hat, discusses the progress of SIG-SRE (a special interes group inside Red Hat for SRE topics) has spent 2022 producing material to level up SRE practices inside Red Hat. These materials are shared at Operate First's [operate-first/sre][operate-first-sre-git] repository, and will have a landing page soon.

For more information about Operate First, refer to their [webpage][operate-first-web].

The slides for this talk are [available in Github][opensource-sre-slides] in PDF form. A recording will be available soon.

[exploretech]: https://www.meetup.com/ExploreTech-Toronto/ "ExploreTech Toronto Meetup"
[dod18-slides]: https://speakerdeck.com/thedoh/slos-and-you-or-how-we-learned-to-stop-worrying-and-love-the-queue-length
[dod18-recording]: https://www.youtube.com/watch?v=MB0u2-c-2zs
[exploretech18-slides]: https://speakerdeck.com/thedoh/slo-creation-and-you-or-how-we-learned-to-stop-worrying-and-love-the-queue-length
[lisa19-slides]: https://speakerdeck.com/thedoh/multi-architecture-container-images-why-bother-and-how-to
[lisa19-video]: https://www.usenix.org/conference/lisa19/presentation/seelye
[devconfcz2020-slides]: https://speakerdeck.com/jewzaam/implementing-microservices-as-kubernetes-operators
[devconfcz2020-code]: https://github.com/jewzaam/pod-operator
[operate-first-web]: https://operate-first.cloud
[operate-first-sre-git]: https://github.com/operate-first/sre
[opensource-sre-slides]: https://github.com/lisa/thedoh.dev/blob/master/pdfs/devconf%20us%202022%20-%20Open%20Source%20SRE.pdf
