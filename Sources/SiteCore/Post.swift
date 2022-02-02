import Foundation
import Ink
import PathKit

struct Post {
    static let markdownParser = MarkdownParser()
    
    static var markdownDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        
        return formatter
    }()
    
    static var publishDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        
        return formatter
    }()
    
    let title: String
    let summary: String
    let date: Date
    let html: String
    let slug: String
    let publishDate: String
    
    static func parse(path: Path) -> Post? {
        guard let markdown: String = try? path.read() else {
            return nil
        }
        
        let parsed = Self.markdownParser.parse(markdown)
        let slug = path.lastComponentWithoutExtension
        
        guard
            let title = parsed.metadata["title"],
            let summary = parsed.metadata["summary"],
            let dateString = parsed.metadata["date"],
            let date = Self.markdownDateFormatter.date(from: dateString)
        else {
            return nil
        }
        
        return Post(
            title: title,
            summary: summary,
            date: date,
            html: parsed.html,
            slug: slug,
            publishDate: Self.publishDateFormatter.string(from: date)
        )
    }
}
