---
title:  Codable by Example
summary: Introduced in Swift 4, Codable is a versatile mechanism allowing the conversion to and from external data representations, such as JSON payloads or Property Lists.
date: 10-06-2019
---

Introduced in Swift 4, Codable is a versatile mechanism allowing the conversion to and from external data representations, such as JSON payloads or Property Lists.
If you look at the declaration of Codable you'll see it is a simple typealias for two protocols: Decodable and Encodable.

```swift
typealias Codable = Decodable & Encodable
```

In this article we'll be focusing specifically on the Decodable part. Decodable is meant to be used by types that, as the name suggests, can be decoded 😀. Here's what the declaration of Decodable looks like:

```swift
public protocol Decodable {
    init(from decoder: Decoder) throws
}
```

As you can see, the only requirement of Decodable is the implementation of an initializer which takes a `Decoder` as the only argument. Simple, right? Let's have a look at some examples.

## Simple Decodable example

Let's consider a simple JSON sample describing a board game entry:

```javascript
{
    "name": "Carcassonne",
    "minPlayers": 2,
    "maxPlayers": 5,
    "url": "https://boardgamegeek.com/boardgame/822/carcassonne"
}
```

Decoding this piece of JSON is straightforward, we just need to create a model object to hold the data, make it conform to Decodable, and decode it using the JSONDecoder class.

``` swift
struct BoardGame: Decodable {
    let name: String
    let minPlayers: Int
    let maxPlayers: Int
    let url: URL
}

let decoder = JSONDecoder()
let boardGame = try decoder.decode(BoardGame.self, from: jsonData)
```

## Coding Keys

Let's consider a small change now. When fetching data from an API, especially one we don't control, it's usual to come across with payloads that use different styles such as camel case, snake case, uppercase, etc. Taking the previous JSON payload as an example, what happens if we are presented with this instead?

```javascript
{
    "name": "Carcassonne",
    "min_players": 2,
    "max_players": 5,
    "url": "https://boardgamegeek.com/boardgame/822/carcassonne"
}
```

Notice how the properties `min_players` and `max_players` are written in snake case. Surely we could just update our struct to match the snake case style on the payload, however it doesn't really seem idiomatic Swift.

```swift
struct BoardGame: Decodable {
    let name: String
    let min_players: Int
    let max_players: Int
    let url: URL
}
```
    
Turns out we can make use of another protocol - CodingKey - to work around this while naming the properties using camel case. This approach will also require implementing *init(from decoder: Decoder)*.

```swift
struct BoardGame: Decodable {
    let name: String
    let minPlayers: Int
    let maxPlayers: Int
    let url: URL
    
    private enum CodingKeys: CodingKey {
        case name
        case min_players
        case max_players
        case url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        minPlayers = try container.decode(Int.self, forKey: .min_players)
        maxPlayers = try container.decode(Int.self, forKey: .max_players)
        url = try container.decode(URL.self, forKey: .url)
    }
}

let decoder = JSONDecoder()
let boardGame = try decoder.decode(BoardGame.self, from: jsonData)
```

In this example, we define a CodingKeys enum describing the properties we want to extract from the JSON payload. Then, on the initializer, we decode each of the properties using the respective key.

There is something worth mentioning regarding the two approaches described above: you can't have the best of both worlds - either you allow all properties to be synthesized automatically by the compiler or you use the coding keys approach and decode all properties manually.

**Note**: you may have noticed that, while the BoardGame struct is written using camel case, the CodingKeys enum isn't. The solution for this is simple, we just need to define its raw values to be of type String and redefine those values. This approach is also useful when we want to use a different name for the properties on our struct than the JSON properties.

```swift
struct BoardGame: Decodable {
    let boardGameName: String
    let minimumPlayers: Int
    let maximumPlayers: Int
    let externalUrl: URL
    
    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case minPlayers = "min_players"
        case maxPlayers = "max_players"
        case url = "url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        boardGameName = try container.decode(String.self, forKey: .name)
        minimumPlayers = try container.decode(Int.self, forKey: .minPlayers)
        maxPlayers = try container.decode(Int.self, forKey: .maxPlayers)
        externalUrl = try container.decode(URL.self, forKey: .url)
    }
}
```

## Nested objects

It would be great if all data we parse in our day-to-day was made of single-level objects, containing only a few properties, but generally that's not the case. Let's extend the JSON payload from the previous examples to include a new *otherDetails* property containing a nested object.

```javascript
{
    "name": "Carcassonne",
    "minPlayers": 2,
    "maxPlayers": 5,
    "url": "https://boardgamegeek.com/boardgame/822/carcassonne",
    "otherDetails": {
        "year": 2000,
        "categories": ["City Building", "Medieval", "Territory Building"],
        "mechanisms": ["Area Control / Area Influence", "Tile Placement"]
    }
}
```

Things certainly got more interesting, however Codable is still able to handle this. If the properties contained in our struct conform to Decodable, they too can be decoded along with the parent struct.

``` swift
struct BoardGameDetails: Decodable {
    let year: Int
    let categories: [String]
    let mechanisms: [String]
}

struct BoardGame: Decodable {
    let name: String
    let minPlayers: Int
    let maxPlayers: Int
    let url: URL
    let otherDetails: BoardGameDetails
}

let decoder = JSONDecoder()
let boardGame = try decoder.decode(BoardGame.self, from: jsonData)
```

Here we decided to create a new BoardGameDetails struct to hold the nested object containing the year, categories and mechanisms properties of a board game. In order to decode it as part of the BoardGame struct, the only thing we have to do is to make the new struct conform to Decodable.

Everything mentioned above related to coding keys still applies to the new struct, regardless of the implementation of the BoardGame struct. For instance, we may decide we want to make use of coding keys when decoding BoardGame, but keep the default implementation on BoardGameDetails.

### Does this mean I need to create a struct for every nested object?

The answer is no! Sometimes you may be interested in decoding some (or even all) nested properties, but don't really want to create yet another struct. Perhaps holding all data under a single struct is enough. This gets worse when the object you are trying to parse contains not just one, but multiple nested objects.

Again, let's see how we can work around this by extending the JSON payload from the previous examples:

```javascript
{
    "name": "Carcassonne",
    "minPlayers": 2,
    "maxPlayers": 5,
    "url": "https://boardgamegeek.com/boardgame/822/carcassonne",
    "otherDetails": {
        "year": 2000,
        "categories": ["City Building", "Medieval", "Territory Building"],
        "mechanisms": ["Area Control / Area Influence", "Tile Placement"]
    },
    "credits": {
        "designer": "Klaus-Jürgen Wrede",
        "artists": ["Doris Matthäus", "Anne Pätzke", "Chris Quilliams", "Klaus-Jürgen Wrede"]
    }
}
```

Let's assume in this case you are only interested in the name, year, categories and designer. Our struct would look like this:

```swift
struct BoardGame: Decodable {
    let name: String
    let year: Int
    let categories: [String]
    let designer: String
}
```

If you try to decode this struct from the JSON payload above soon you'll realize it is not possible, as the year, categories and designer properties are actually contained in nested objects. Fortunately, it's not that hard to achieve what we want. The solution again is to make use of coding keys and implement *init(from decoder: Decoder)*.

```swift
struct BoardGame: Decodable {
    let name: String
    let year: Int
    let categories: [String]
    let designer: String
    
    private enum CodingKeys: String, CodingKey {
        case name
        case otherDetails
        case credits
        
        enum OtherDetailsCodingKeys: String, CodingKey {
            case year
            case categories
        }
        
        enum Credits: String, CodingKey {
            case designer
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        let detailsContainer = try container.nestedContainer(keyedBy: CodingKeys.OtherDetailsCodingKeys.self, forKey: .otherDetails)
        year = try detailsContainer.decode(Int.self, forKey: .year)
        categories = try detailsContainer.decode([String].self, forKey: .categories)
        
        let creditsContainer = try container.nestedContainer(keyedBy: CodingKeys.Credits.self, forKey: .credits)
        designer = try creditsContainer.decode(String.self, forKey: .designer)
    }
}

let decoder = JSONDecoder()
let boardGame = try decoder.decode(BoardGame.self, from: data)
```

Things got a little more verbose now, but the idea is still simple, we define a "coding keys" enum for each object and proceed by decoding the properties manually. It is not mandatory to nest the enums, but I find it nice to follow the structure of the payload.

Notice how a new method was used in the previous example:

```swift
let detailsContainer = try container.nestedContainer(keyedBy: CodingKeys.OtherDetailsCodingKeys.self, forKey: .otherDetails)
```

We use *nestedContainer(keyedBy:forKey:)* to decode nested objects from the payload. The return type of this function is a new container holding the nested properties. From there we just need to decode its properties using the respective keys.

## Conclusion

It's really easy to use Codable (or Decodable to be more precise) to decode JSON data, and it provides great flexibility when it comes to dealing with nested objects/properties. We've also seen how simple it is to keep writing our model objects using idiomatic Swift, even if the JSON payload uses different styles such as snake case or others.

In the [second part](/posts/codable-by-example-part-2.html) of this series, we'll see how to decode more complex JSON payloads containing nested arrays.
