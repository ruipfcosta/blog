---
title:  Enums in Rust
summary: Enums are one of the ways Rust allows creating user-defined types. An enum is useful to represent a set of related values known at compile time.
date: 25-01-2022
---

Enums are one of the ways Rust allows creating user-defined types. An enum is useful to represent a set of related values known at compile time, such as a list of possible t-shirt sizes (small, medium, large, extra large) or the available payment methods at a till (contactless, cash, loyalty card). The latter would be defined this way:

```rust
enum PaymentMethod {
    Contactless,
    Cash,
    LoyaltyCard
}

let payment_type = PaymentMethod::Cash;
```

It is worth pointing out that, under the hood, enums are stored as integers, starting with 0. If appropriate, the underlying integer value can even be set explicitly:

```rust
enum SquareSize {
    Small = 16,
    Medium = 48,
    Large = 96
}
```

Unlike enums in other languages, Rust's enums are quite powerful: not only can they be used to define a list of predefined values, but those values can also hold associated data. For example, when representing the delivery type of a meal, the user's address can be associated with the `Delivery` value, while `Collection` doesn't contain any additional data.

```rust
enum DeliveryType {
    Collection,
    Delivery(String)
}

let address = String::from("86A Fictional Street, London");
let delivery_type = DeliveryType::Delivery(address);
```

`Collection` is known as a unit variant since it takes no arguments. On the other hand, `Delivery` is known as a tuple variant because it takes one or more arguments. Enums can also have struct variants, with named fields:

```rust
enum Reward {
    None,
    Points(u32),
    Prize { description: String, code: String }
}

let reward = Reward::Prize {
    description: String::from("4 museum tickets"),
    code: String::from("XYZ987A")
};
```

As seen above, a single enum can contain multiple kinds of variants alongside each other. To get data out of an enum you use a match expression:

```rust
let reward = determine_user_reward();

let prize_description =
    match reward {
        Reward::None =>
            format!("Sorry, no prize :("),
        Reward::Points(points) =>
            format!("You won {} points to redeem on your next purchase", points),
        Reward::Prize { description: desc, code: code } =>
            format!("You won {}! Use the code {} to redeem", desc, code)
    };
```

Finally, just like [structs](/posts/structs-in-rust.html), enums can also contain methods and implement traits:

```rust
trait Freebie {
    fn has_freebie(self) -> bool;
}

impl Freebie for Reward {
    fn has_freebie(self) -> bool {
        let freebie_inside =
            match self {
                Reward::None => false,
                _ => true
            };

        return freebie_inside;
    }
}
```
