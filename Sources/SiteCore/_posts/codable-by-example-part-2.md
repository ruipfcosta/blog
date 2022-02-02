---
title:  Codable by Example - Part 2
summary: This is the second part of my previous article "Codable by Example". This time we'll be covering a few more scenarios when decoding JSON payloads into Swift types.
date: 13-06-2019
---

This article is the second part of my previous article [Codable by Example](/posts/codable-by-example.html). This time we'll be covering a few more scenarios when decoding JSON payloads into Swift types.

## Arrays

We've seen in the previous article how easy it is to decode an array of objects using Decodable. Let's start with a payload consisting of an object with a few properties, one of them being an array of strings:

```javascript
{
    "name": "Carcassonne",
    "minPlayers": 2,
    "maxPlayers": 5,
    "url": "https://boardgamegeek.com/boardgame/822/carcassonne",
    "categories": ["City Building", "Medieval", "Territory Building"]
}
```

Decoding this into a Swift object is simple, we just need to bring the Decodable-conforming struct `BoardGame` from the previous article and make sure if contains a property to hold the array of categories:

```swift
struct BoardGame: Decodable {
    let name: String
    let minPlayers: Int
    let maxPlayers: Int
    let url: URL
    let categories: [String]
}

let decoder = JSONDecoder()
let boardGame = try decoder.decode(BoardGame.self, from: data)
```

Simple, right? And this works smoothly for any custom types too, as long as they conform to Decodable.

What happens however if the root element of the payload is not an object itself, but an array?

```javascript
[{
    "name": "Carcassonne",
    "minPlayers": 2,
    "maxPlayers": 5,
    "url": "https://boardgamegeek.com/boardgame/822/carcassonne"
},
{
    "name": "Azul",
    "minPlayers": 2,
    "maxPlayers": 4,
    "url": "https://boardgamegeek.com/boardgame/230802/azul"
}
]
```

No problem at all! After defining the BoardGame struct and make it conform to Decodable, we just need to decode the payload directly as an array of BoardGame objects:

```swift
struct BoardGame: Decodable {
    let name: String
    let minPlayers: Int
    let maxPlayers: Int
    let url: URL
}

let decoder = JSONDecoder()
let boardGame = try decoder.decode([BoardGame].self, from: data)
```

## Nested arrays

So far we've seen very simple examples where simply conforming to Decodable is enough for our needs and no custom logic is necessary. To spice things up let's simulate that an API call responded with the following JSON payload:

```javascript
{
    "data": {
        "owned": [{
                "name": "Carcassonne",
                "minPlayers": 2,
                "maxPlayers": 5,
                "links": [{
                        "source": "BoardGameGeek",
                        "url": "https://boardgamegeek.com/boardgame/822/carcassonne"
                    },
                    {
                        "source": "Wikipedia",
                        "url": "https://en.wikipedia.org/wiki/Carcassonne_(board_game)"
                    }
                ]
            },
            {
                "name": "Azul",
                "minPlayers": 2,
                "maxPlayers": 4,
                "links": [{
                        "source": "BoardGameGeek",
                        "url": "https://boardgamegeek.com/boardgame/230802/azul"
                    },
                    {
                        "source": "Wikipedia",
                        "url": "https://en.wikipedia.org/wiki/Azul_(board_game)"
                    }
                ]

            }
        ]
    }
}
```

As you can see we now have a few nested objects and arrays of objects. For the sake of this example, let's suppose you are only interested in the names of the board games and their urls. As usual, we'll start by defining a couple of structs to hold this data, which can look like this:

```swift
struct BoardGame: Decodable {
    let name: String
    let urls: [URL]
}

struct OwnedBoardGamesResponse: Decodable {
    let boardGames: [BoardGame]

    init(from decoder: Decoder) throws {
        ...
    }
}
```

This time things aren't that simple. Although the OwnedBoardGamesResponse and BoardGame structs conform to Decodable, their properties don't directly map to the JSON structure, meaning we'll need to customise the decoding logic via *init(from decoder: Decoder)* and coding keys. Let's proceed to the complete implementation:

```swift
struct BoardGame: Decodable {
    let name: String
    let urls: [URL]
}

struct OwnedBoardGamesResponse: Decodable {
    let boardGames: [BoardGame]
    
    private enum CodingKeys: String, CodingKey {
        case data
        
        enum DataKeys: String, CodingKey {
            case owned
            
            enum OwnedKeys: String, CodingKey {
                case name
                case links
                
                enum LinksKeys: String, CodingKey {
                    case url
                }
            }
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dataContainer = try container.nestedContainer(keyedBy: CodingKeys.DataKeys.self, forKey: .data)
        var ownedContainer = try dataContainer.nestedUnkeyedContainer(forKey: .owned) // array of objects
        
        var decodedBoardGames: [BoardGame] = []
        
        // Iterate array of objects
        while !ownedContainer.isAtEnd {
            let ownedEntry = try ownedContainer.nestedContainer(keyedBy: CodingKeys.DataKeys.OwnedKeys.self)
            let name = try ownedEntry.decode(String.self, forKey: .name)
            var linksContainer = try ownedEntry.nestedUnkeyedContainer(forKey: .links) // nested array of objects
            
            var urls: [URL] = []
            
            // Iterate array of objects
            while !linksContainer.isAtEnd {
                let linkEntry = try linksContainer.nestedContainer(keyedBy: CodingKeys.DataKeys.OwnedKeys.LinksKeys.self)
                let url = try linkEntry.decode(URL.self, forKey: .url)
                urls.append(url)
            }
            
            let boardGame = BoardGame(name: name, urls: urls)
            decodedBoardGames.append(boardGame)
        }
        
        boardGames = decodedBoardGames
    }
}

let decoder = JSONDecoder()
let boardGame = try decoder.decode(OwnedBoardGamesResponse.self, from: data)
```

It doesn't look that simple anymore, right? Let's go step by step. First we defined a `CodingKeys` enum (with a few nested enums) representing the structure of the JSON. In total we will have to go four levels deep within the JSON to be able to retrieve all the data we want. We can see that the first level ("data") contains a nested object - we've learned in the previous article how to use `nestedContainer(keyedBy:)` to decode nested objects!

Nothing new until this point, however this time the "owned" property contains a nested array (of objects... 😅). At this point you can see we introduced a new method `nestedUnkeyedContainer(forKey:)`. This method is analogous to `nestedContainer(keyedBy:)` but allows us to decode an array instead of an object.

From there onwards we just need to iterate the array by repeatedly invoking `nestedContainer(keyedBy:)` to decode the objects it contains. Each of those objects contains the "name" property we want to extract and... another array of objects ("links")! This means we just need to repeat the same process again in order to decode those objects, until we get to the urls.

## Conclusion

Today we've seen how to leverage Decodable to have a very precise control over the data we want to extract from a JSON payload. Although in simple cases it is enough to create a struct and map it directly to the JSON, sometimes the JSON structure can be more intricate requiring custom logic to extract the data we're interested in.
