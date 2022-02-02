---
title:  Swift, MVVM and Combine
summary: The Combine framework provides a declarative Swift API for processing values over time, similar to other frameworks such as RxSwift, which means FRP now becomes a first-party paradigm in the iOS world!
date: 30-06-2019
---

One of the most exciting announcements coming from this year's WWDC is the new Combine framework. Combine provides a declarative Swift API for processing values over time, similar to other frameworks such as RxSwift, which means
[Functional Reactive Programming](https://en.wikipedia.org/wiki/Functional_reactive_programming) now becomes a first-party paradigm in the iOS world!

Although some types have different names in RxSwift and Combine, the main principles behind them are the same and should be very easy to transfer knowledge between both frameworks. At my company, Yoyo Wallet, we started using RxSwift/FRP mainly to allow different parts of the app to observe and react to data updates, but with time, and after adopting MVVM as our architectural pattern, we also started using RxSwift to set up bindings between view models and view controllers, control state changes and trigger actions.

In this article I'll be showing a technique to structure view models and control the flow of data using Combine. This approach is essentially the same we use at Yoyo, with the difference that we use RxSwift instead of Combine. For simplicity I'll be focusing on UIKit (sorry...😀)! I know Combine + UIKit might be an unlikely combination since SwiftUI is also available starting from iOS 13, so in reality this is an exercise to replace RxSwift with Combine in order to get familiar with it.

## View model

A view model is a pure Swift representation of a view, holding all its business logic. By "view" I mean not just subclasses of UIView but also, and most importantly, UIViewController subclasses.
To demonstrate this, let's pretend we are building a new screen for our app to display the details of a product and allow the user to purchase it. The screen will have a couple of labels for the product's title and description, and a button which, when tapped, triggers and API call to the backend to make that purchase. If something goes wrong with that request, a third label will show the error message to the user.

At this point we already have enough information to start building our view model:

```swift
class ViewModel {
    let title           = CurrentValueSubject<String?, Never>(nil)
    let description     = CurrentValueSubject<String?, Never>(nil)
    let buttonEnabled   = CurrentValueSubject<Bool, Never>(false)
    let errorText       = CurrentValueSubject<String?, Never>(nil)
    let errorTextHidden = CurrentValueSubject<Bool, Never>(true)

    let product: Product

    init(product: Product) {
        self.product = product
    }
}
```

As you can see, this was almost a direct translation from English to Swift! For each property we want to control on the view there is an associated property on the view model. Each view model property is defined as `CurrentValueSubject`, one of the Subject types included in Combine. But why use `CurrentValueSubject` and not plain Swift types such as String and Bool? The answer is simple, one of the key aspects of MVVM is the usage of data bindings to connect the view model to the view. `CurrentValueSubject` will allow us to set and observe its value over time, ensuring the view controller's IBOutlets are always updated accordingly.


### State

I also mentioned that the error label is only visible when the API call fails. We can immediately identify two states for our screen: an initial state in which the user is presented with the details of a product, and an error state for when things go wrong when making the purchase. An enum feels appropriate to represent these two cases:

```swift
enum State {
    case initial
    case error(message: String)
}
```

Now let's define a function to process the state. The different view model properties will be set accordingly depending on the current state:

```swift
func processState(_ state: State) {
    switch state {
    case .initial:
        title.value = product.title
        description.value = product.description
        buttonEnabled.value = true
        errorText.value = nil
        errorTextHidden.value = true
    case .error(let message):
        errorText.value = message
        errorTextHidden.value = false
    }
}
```

In order to glue everything together we just need to define a `state` property on the view model (again using `CurrentValueSubject`) and observe any changes to its value. Every time the value changes, all we need to do is to call the `processState` function created above which will then set the properties based on the current state.

```swift
let state = CurrentValueSubject<State, Never>(.initial)

init(product: Product) {
    ...

    _ = state.sink(receiveValue: { [weak self] state in
        self?.processState(state)
    })
}

```

Later on we'll see how the view model properties will be connected to the view controller's IBOutlets.

### Actions

It makes sense for the view model to be the one who handles the purchase of the product. This means the view will need a way to communicate that intention to the view model. We can start by defining an `Action` enum containing the possible actions supported by the view model, similar to the `State` enum we created earlier:

```swift
enum Action {
    case purchase
}
```

And we can use the same approach as above to handle the actions:

```swift
let action = PassthroughSubject<Action, Never>()

init(product: Product) {
    ...

    _ = action.sink(receiveValue: { [weak self] action in
        self?.processAction(action)
    })
}

func processAction(_ action: Action) {
    switch action {
    case .purchase:
        do {
            try backend.purchaseProduct(id: product.id)
        } catch {
            state.value = .error(message: error.localizedDescription)
        }
    }
}
```

This time however we're using another type of Subject, a `PassthroughSubject`. The difference to the `CurrentValueSubject` used for the state is that, as the name suggests, its current value is not stored, it can only be observed. This is fine, because we just need to be informed every time an action is triggered and react to that. However, for the state we may need to access its current value at some point, so I prefer to use a `CurrentValueSubject` for it, although a `PassthroughSubject` would also be valid.


## View

After all the progress we've made so far, the view will be incredibly simple to implement! Let's start by defining the IBOutlets we need and create the view model:

```swift
class ViewController: UIViewController {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var purchaseButton: UIButton!
    @IBOutlet var errorLabel: UILabel!

    let viewModel = ViewModel(product: product) // assume we have a product object already
}
```

For the sake of this example let's just assume the view model is created inside the view controller. In practice there are better ways to do this (I quite like the [coordinator pattern](https://benoitpasquier.com/coordinator-pattern-swift/)).

Nothing exciting so far, but that's about to change! We already know our view model contains all the relevant properties for this view, and contains all the logic to determine how those properties should be set on each state. This means we just need to connect those properties to the view's IBOutlets using the `assign` function:

```swift
var cancelables: [AnyCancellable] = []

override func viewDidLoad() {
    super.viewDidLoad()

    self.cancelables = [
        viewModel.title.assign(to: \.text, on: titleLabel),
        viewModel.description.assign(to: \.text, on: descriptionLabel),
        viewModel.buttonEnabled.assign(to: \.isEnabled, on: purchaseButton),
        viewModel.errorText.assign(to: \.text, on: errorLabel),
        viewModel.errorTextHidden.assign(to: \.isHidden, on: errorLabel)
    ]
}
```

We'll need to hold a reference to the `Cancelable` objects returned by `assign`, otherwise the subscription will get terminated. The easiest way to do it is to just put all of them inside an array, but we could have also kept individual references to each `Cancelable` if we wanted.

Finally, we just need to connect the tap gesture on the purchase button to the respective action on the view model:

```swift
@IBAction func purchaseButtonTouchUpInside(_ sender: UIButton) {
    viewModel.action.send(.purchase)
}
```

## Conclusion

It’s easy to design an MVVM architecture for our apps based on the new Combine framework. Here's a quick summary of what we've implemented:

- Every property we want to control on the view is matched by a property on the view model;
- The view model defines enums and properties for both state and actions;
- The view model observes state changes and sets its properties accordingly;
- The view model reacts to any actions triggered by the view;
- The view controller connects the view model properties to its IBOutlets.

And finally, it's great to see Apple coming up with their own FRP framework avoiding the need to link other third-party dependencies to our apps!

---

You can find a sample project [here](https://github.com/ruipfcosta/MVVM-Combine-Example/tree/master).
