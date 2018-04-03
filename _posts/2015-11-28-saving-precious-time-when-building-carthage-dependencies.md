---
layout: post
title: "Saving precious time when building Carthage dependencies"
author: "Rui Costa"
---

If you do Cocoa development, it is likely you have come across with [Carthage](https://github.com/Carthage/Carthage) by now. Carthage is intended to be the simplest way to add frameworks to your Cocoa application. Contrary to its “competitor” [CocoaPods](https://cocoapods.org/), Carthage only builds the dependencies and provides you with binary frameworks, leaving you the responsibility to integrate them in your project. No extra nonsense added.

Although Carthage is a great tool to work with, one the most annoying things about it is that it [doesn’t have the ability to build a single dependency](https://github.com/Carthage/Carthage/issues/610): if you add a new entry to your Cartfile, or if you want to update a specific one, all dependencies will be rebuilt. This may not seem a huge problem at first, probably your Cartfile is left untouched for days or even weeks. However, recently at work we decided to extract part of our app into a framework in a separate project. Unfortunately, this requires us to run carthage update more often. Considering the number of dependencies on our Cartfile and the amount of time necessary to build them, this was becoming painful.

## So, how to workaround the problem?

What if you build a single dependency alone, and then integrate it with the rest of your frameworks? Well, that was my approach: I wrote a [shell script](https://github.com/ruipfcosta/carthage-workarounds#carthage-buildsh) that takes the dependency you want to add or update, builds it in a separate directory and integrates it back into your existing Carthage folder and Cartfile. And guess what, it does the job!

## Usage

Get **[carthage-build.sh](https://github.com/ruipfcosta/carthage-workarounds#carthage-buildsh)** and simply run it from the directory containing your Cartfile/Carthage directory:

{% highlight bash %}
./carthage-build.sh -d 'github "ruipfcosta/AutoLayoutPlus"'
{% endhighlight %}

<br>

![Demo](https://cdn-images-1.medium.com/max/1600/1*W_AasgtlLOAv1zP3ci9sAA.gif)_Demo_

<br>

For more information, check the repository [here](https://github.com/ruipfcosta/carthage-workarounds).

<br>
<hr>
<br>
If you have any questions, comments or thoughts get in touch on Twitter [@ruipfcosta](https://twitter.com/ruipfcosta).

Thanks for reading! 💯