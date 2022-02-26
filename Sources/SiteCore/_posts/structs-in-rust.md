---
title:  Structs in Rust
summary: Rust structs are user-defined types which combine an arbitrary number of values under a new type. They are the building blocks used to model an application's domain.
date: 26-02-2022
---

Rust structs are user-defined types which combine an arbitrary number of values under a new type. They are the building blocks used to model an application's domain. 

Rust has three kinds of structs, all created using the `struct` keyword:

- Structs with named fields
- Tuple structs
- Unit structs 

### Structs with named fields

A struct with named fields is created using the `struct` keyword, followed by the struct name and a list of fields tagged with their respective data types. A board game struct could be defined this way:

```rust
struct BoardGame {
    name: String,
    min_players: u8,
    max_players: u8,
    publisher: String
} 
```

This is how we can create an instance of the `BoardGame` struct and access its fields:

```rust
let mut board_game_1 = BoardGame {
    name: String::from("Agricola"),
    min_players: 1,
    max_players: 5,
    publisher: String::from("Mayfair Games")
};

board_game_1.publisher = String::from("New publisher name");
``` 

Note that in order to mutate the instance it is necessary to make it mutable explicitly with `let mut`. 

#### Field init shorthand syntax

When initialising a struct whose field names match the parameter values being used, Rust provides a shorthand syntax to make this more pleasant to write. Let's extend the previous example to see this scenario in action:

```rust
let min_players: u8 = 1;
let max_players: u8 = 5;

let board_game_1 = BoardGame {
    name: String::from("Agricola"),
    min_players: min_players,
    max_players: max_players,
    publisher: String::from("Mayfair Games")
};
```

This could be simplified using the field init shorthand syntax, which avoids having to repeat `min_players` and `max_players` for both the struct fields and their parameters.

```rust
let min_players: u8 = 1;
let max_players: u8 = 5;

let board_game_1 = BoardGame {
    name: String::from("Agricola"),
    min_players, // instead of min_players: min_players 
    max_players, // instead of max_players: max_players
    publisher: String::from("Mayfair Games")
};
```  

#### Struct update syntax

Another common scenario when dealing with structs is wanting to initialise an instance of a struct based on another instance. Again, let's extend the initial example, this time to create a second board game instance based on the original one:

```rust
let board_game_1 = BoardGame {
    name: String::from("Agricola"),
    min_players: min_players,
    max_players: max_players,
    publisher: String::from("Mayfair Games")
};

let board_game_2 = BoardGame {
    name: String::from("Agricola Revised Edition"),
    min_players: board_game_1.min_players,
    max_players: board_game_1.max_players,
    publisher: board_game_1.publisher
};
```

This can become quite tedious, especially when most fields remain the same. To help with this, we can use the struct update syntax:

```rust
let board_game_1 = BoardGame {
    name: String::from("Agricola"),
    min_players: min_players,
    max_players: max_players,
    publisher: String::from("Mayfair Games")
};

let board_game_2 = BoardGame {
    name: String::from("Agricola Revised Edition"),
    ..board_game_1
};
```

The only property that is different from the original instance was the name. The `..board_game_1` syntax ensures the remaining fields on `board_game_2` are initialised taking their values from `board_game_1`.

### Tuple structs

Tuple structs are very similar to tuples. Both are created the same way, however tuple structs must have a name:

```rust
struct Product(String, f64);

let product = Product(String::from("MacBook Pro"), 1499.99);
```

The values of a tuple struct can be accessed just like tuples:

```rust
let product = Product(String::from("MacBook Pro"), 1499.99);

let product_name = product.0;
let product_price = product.1; 
```  

### Unit structs 

The final struct type, unit structs, contain no fields:

```rust
struct EmptyResponse;

let response = EmptyResponse;
```

Unit structs resemble the unit type `()` and can be useful in some situations, for example with generics.

## Methods and traits

Structs can contain methods:

```rust
impl BoardGame {
    fn can_be_played_alone(&self) -> bool {
        self.min_players == 1
    }
}

let board_game_1 = BoardGame {
    name: String::from("Catan"),
    min_players: 3,
    max_players: 5,
    publisher: String::from("Publisher")
};

if board_game_1.can_be_played_alone() { // false
   println!("Can be played alone!");
} else {
   println!("Minimum of {} people!", board_game_1.min_players);
}
```

And can implement traits:

```rust
trait IdentifiableGame {
    fn game_identifier(&self) -> String;
}

impl IdentifiableGame for BoardGame {
    fn game_identifier(&self) -> String {
        format!("{} by {}", self.name, self.publisher)
    }
}

println!("{}", board_game_1.game_identifier());
```
