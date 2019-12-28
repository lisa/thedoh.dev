---
title: Writing the CKA Exam with ADD or ADHD
parentcategory: "kubernetes"
category: cka-add
description: |
  Some tips to effectively write the CKA Exam as a person with ADD or ADHD.
---

# Writing the CKA Exam with ADD or ADHD

In August 2019 I passed the CKA exam. To prepare for it I spent my Friday mornings going through the Linux Foundation's CKA training course. The coursework and labs largely prepared me for the exam, but it didn't prepare my ADD for the exam.

When writing the exam, your desk must be completely clear, aside from a clear glass with water for drinks, your keyboard, mouse, mouse pad, computer and monitor. No paper, pencil, fidget cube, water bottle, snacks, or anything else is permitted on the desk. You may not listen to music, talk to yourself (and certainly not to anyone else). If you're like me, this can be troublesome because fidgeting with a pencil or fidget cube helps me think. I read quietly to myself, which helps me understand the questions. I also use music to help me focus my mind on the task at hand.

Thus, the CKA test environment isn't quite ideal for me, or perhaps other folks with ADD or ADHD.

# Preparing for the Exam

## Timing

Schedule the exam for the time of day where you are most productive and capable. From long experience I know that if I go too long without a snack my blood sugar levels drop and that can impact my cognative abilities. That means for me the best time will be in the morning, after a good breakfast and after taking my Concerta. Remember, you're not allowed snacks, and only water.

I also wanted to be sure I didn't give myself time during the day to freak myself out after a long day of work. Scheduling my exam early meant I got it out of the way before any stress from work compounded the feeling of "Oh no, I have to write the three hour exam after work!"

## Environment

Ahead of time, make sure you've cleaned everything off your desk, and around your test area. You'll need to swing your camera around so the proctor knows you don't have a cheat sheet stuck to the wall in front of you. This gives an opportunity to clean off the months of papers that have accumulated, too!

Make sure you can move your camera around. If you have an external webcam, free the cables ahead of time. If you use your laptop, make sure you can swing it around.

Get your glass of water ahead of time and don't put it at the edge of your desk where you're likely to accidentally knock it off and into your gaming computer. :(

## The Computer

When the exam is booked, you are given a URL to test the browser plugin used by the exam. Be sure to use it, but also verify it by arriving fifteen minutes early to the scheduled test start so that issues can be worked out ahead of time.

You may not have a lot of programs running on your computer, so be prepared to close all but the web browser. This includes music apps, mail readers, the terminal, and others.

Ensure that the web browser/test extension have the permissions it needs ahead of time. MacOS users may need to grant permissions to the browser to share desktop, access the camera and microphone. This is hard to diagnose, so take it from me and do it ahead of time. While your browser may request permission, it won't have it unless it's _also_ granted in the security settings.

# During the Test

## References

As of August 2019, you may actually use resources outside the test material. Verify that this is still the case, as it could change at any time.

People writing the exam may use external notes from the entire [kubernetes github organization](https://github.com/kubernetes), everything under [https://kubernetes.io/docs](https://kubernetes.io/docs), and [https://kubernetes.io/blog/](https://kubernetes.io/blog/) (as well as `man` pages and `--help` output). However, the gotcha is, you may only have one additional browser tab opened, _and_ it is up to you to check that any links do not leave the approved websites prior to clicking them.

What are the implications? Every single issue, bug, API reference, and documentation page is fair game. Know in advance how to find specific things in the Kubernetes documentation _without_ using a search engine. Can you quickly find the persistent storage references from the kubernetes.io/docs page? Can you find the docs that explain what `.spec.externalTrafficPolicy` is for a `Service`? Can you find the API docs for the Kubernetes version that's the subject of the exam?

(Note: These are provided for illustrative purposes and are not an endorsement of their appearance on the exam.)

There's another "secret" reference available: `kubectl explain`. This is a valuable [quick reference](https://kubernetes.io/docs/reference/kubectl/overview/) that can give reminders about various Kubernetes objects. Try it out before the test.

## Shortcuts

The test is entirely within the browser, and you only get the one terminal window, as such, it's important to remember where one is during the course of answering questions. Check directories, check connections. It's no good to be in the wrong place to answer a question. It's a good habit to have a "reset" procedure for the start of every question to get to a known good state.

Customize your shell as the first thing. Do you use a `k` shell alias for `kubectl`? If so, set it up in the shell as the first thing you do.

While the contents of the exam are covered under a non-disclosure agreement, I think it's safe to assume that given the labs from the Linux Foundation's CKA training course, one will need to create some kind of Kubernetes objects. Thus, you might want to memorize how to do that ahead of time, or maybe `k get $object --export -o yaml > $object.yaml` early to have a "reference" manifest which can be editied.

## Priorities and Time Management

For me, time management is always a challenge. I can spend too much time reading a document, or not enough time reading a question clearly, and then end end up rushing later on.

Certain questions are worth more than others. Question 5 might be worth 5% and question 1 may only be worth 1%. With only three hours to complete the exam, it's not worth spending an hour on the 1% question since getting it wrong only costs 1%, and that 5% might take less time. Spent time at the start of the exam to read the percentage for each question (which are provided in the question text) and prioritize which will give the best use of time.

Keep track of the time remaining with the timer countdown and do not be afraid to stop working on a 1% question in order to double check a 5% question's answer.

## Reviewing Your Work

There's a notepad feature in the browser test environment which is valuable to use. Dump all notes in there, since that's the only place to take notes - remember, no paper or pencils. Keep track of the questions which have been answered, have had the answer double checked, certain answers, doubtful answers.

I know that I can't quite remember which ones I've answered and checked.

## Reading Comprehension

Read each question twice, and watch out for "gotchas words" that might change the understanding. Be sure answers end up in the right place.
