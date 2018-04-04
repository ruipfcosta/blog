---
layout: post
title: "Migrating Yoyo Wallet to Swift 3"
author: "Rui Costa"
---

A few days ago I came across [this article](https://medium.com/@yammereng/yammer-ios-app-ported-to-swift-3-e3496525add1#.t1wrynq5k) by Yammer Engineering describing their process of migrating their codebase to Swift 3. I found it particularly interesting given we’ve been through the exact same process recently at Yoyo Wallet.

Our iOS codebase consists of two main projects: the Yoyo Wallet app containing mainly the UI side of things, and the Yoyo SDK which handles the requests to our platform, caching and persistence. Considering the two projects’ code, including unit tests and UI tests, we are roughly talking about 21K Swift LOC on the app project, plus 8k Swift LOC on the SDK project. Apart from a couple of customised Objective-C libraries, Swift code represents >92% of our entire codebase!

In terms of external dependencies, our dependency manager of choice is Carthage. Among others, our stack includes libraries like Realm, RxSwift, Alamofire and Moya.

## Reasons to migrate

It’s clear that if we didn’t migrate now, we would have to do it at some point in the future — in the meantime we would keep adding more and more features until we found a suitable time to migrate. The worst-case scenario would be watching most of our dependencies evolving in time, new Swift versions coming out, new Xcode versions being released, and we would still be stuck with Swift 2.2.

The other reason to migrate was opportunity: we had just completed some development related to our recent [partnership with the National Union of Students](https://www.nus.org.uk/en/lifestyle/what-has-nus-ever-done-for-students/) and were in the process of diving straight into another really important piece of work for us related to our [partnership with Caffè Nero](https://www.linkedin.com/pulse/caffè-nero-selects-yoyo-wallet-its-mobile-loyalty-payment-rolph) ☕. For us, it just felt logical to migrate to Swift 3 at this point in time otherwise there would be the risk of not having such a good opportunity to migrate any time soon. And again, the amount of technical debt accumulated until then was 😩.

## Swift 2.3 or Swift 3?

We felt this question was relatively straightforward, although it could be tempting to migrate to Swift 2.3, we felt the migration wouldn’t be complete — if we were going to spend time and effort migrating, why not go directly to Swift 3 instead? Another strong point in favour of Swift 3 is the fact that Xcode 8.2 will be the last version to support Swift 2.3. According to the release notes, *“Xcode 8.2 is the last release that will support Swift 2.3. Please migrate your projects to Swift 2.3…”*. The decision was to go for Swift 3.

## The process

After deciding to go ahead with the migration to Swift 3, we agreed that the best way to tackle it would be to stop all our iOS development work and pair for this migration task (Yoyo Wallet currently has two iOS developers). Because the migration would have to be done all at once (you can’t really have a mixed codebase with different Swift versions) we would always be blocking the other’s work, so the most logical thing to do was to work on it together and just get it done.

As I mentioned earlier, we have an SDK project where the requests to our platform and persistence are handled, which is a dependency of the main Yoyo Wallet app project. Because of this, we had to start the migration on the SDK project initially. This was also a good thing because it allowed us to start on a smaller section of the codebase and define a process that could be applied to the Yoyo Wallet app project.

The first thing we did after upgrading Xcode (and taking a long and deep breath) was to update our dependencies. Fortunately all of our Swift dependencies are well maintained and had already added support for Swift 3, so this process was surprisingly straightforward. The only problem here was that because some of the dependencies hadn’t been updated in a while, we also had to deal with some API changes and rework how certain parts of our code were using those dependencies.

After this (and taking another long and deep breath), we jumped directly to the migrator tool included in Xcode. Personally, having worked previously on another large Swift codebase, I’ve had my share of pain when it comes to migrations and I didn’t have good memories of previous migrator tools. This time however I was quite surprised with the quality of the suggestions provided, and we ended up accepting most of them. Even enums were properly lowercased and all missing leading dots were added – not bad at all! For the suggestions we weren’t sure about, or that we felt they could be improved or revised later, we decided to accept them while we were on the migrator tool previewer, but take note so we could get back to them. The typical suggestions falling into this category included things like casts between some Swift types and their NS counterparts (e.g. Data to NSData; Calendar to NSCalendar; IndexPath to NSIndexPath, etc) and new optional return types from existing methods that were being migrated as force unwrapped values. Given the fact that most of the files in the project suffered changes, this was a slow and boring process.

After previewing and migrating all the code, based on the suggestions from the migrator tool, it was time to go through our notes and adjust some of the things we identified earlier. A lot of these involved researching how some of the same operations were supposed to be done in Swift 3 in order to avoid unnecessary casts to NS classes or adding more guard statements to deal with new optional return types in a safer way. Although we can’t really say it was a hard task, it was definitely time consuming — and we still had the main Yoyo Wallet project waiting… 😞

The process used on the Yoyo Wallet project was pretty much the same: 1) start by updating its dependencies to support Swift 3; 2) Run the migrator tool previewer and go through every single suggestion, taking notes to revise it later if necessary; 3) go through our notes and make any necessary changes. Only this time we had almost 3x more lines of code to migrate!

## Conclusions

Overall, the whole process of migrating both projects to Swift 3 took around 2 weeks with two iOS developers working on it. Even though it was time consuming and stressful at times in the end it was quite rewarding: we are now up to date with the latest Swift version, we can use the latest version of Xcode and, most importantly, we can start developing new features without that awkward feeling that were just accumulating more and more code that would need to be migrated in the future. At least until Swift 4 arrives! 😂

<br>

##### Thanks to [@taxomania](https://twitter.com/taxomania) and [@TomGoesRAWRr](http://twitter.com/TomGoesRAWRr) for the feedback provided before the story was published.

<br>
<hr>
<br>

If you have any questions, comments or thoughts get in touch on Twitter [@ruipfcosta](https://twitter.com/ruipfcosta).

Thanks for reading! 💯