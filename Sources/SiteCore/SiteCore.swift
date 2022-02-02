import Foundation
import Stencil
import PathKit
import Ink

enum Page: String, CaseIterable {
    case index
    case blog
    case about
}

public class SiteCore{
    
    private let siteUrl: String
    private let environment: Environment
    private var posts: [Post] = []
    
    // Paths
    private let resourcesPath: Path
    private let partialsPath: Path
    private let postsPath: Path
    private let contentPath: Path
    private let outputPath: Path
    private let postsOutputPath: Path
    
    public init(siteUrl: String) {
        self.siteUrl = siteUrl
        
        guard let bundleResources = Bundle.module.resourcePath else {
            fatalError("Bundle resources not found")
        }
        
        self.resourcesPath = Path(bundleResources)
        self.partialsPath = resourcesPath + Path("_partials")
        self.postsPath = resourcesPath + Path("_posts")
        self.contentPath = resourcesPath + Path("Content")
        self.outputPath = Path.current + Path("Output")
        self.postsOutputPath = outputPath + Path("posts")
        self.environment = Environment(loader: FileSystemLoader(paths: [partialsPath, contentPath]), extensions: [])        
    }
    
    public func build() {

        // Step 1: Create output directories
        createOutputDirectories()
        
        // Step 2: Load and render posts
        loadAndRenderPosts()
                   
        // Step 3: Process remaining resources
        processResources()
    }
    
    private func createOutputDirectories() {
        do {
            // Delete Output directory if it already exists
            if outputPath.exists {
                try outputPath.delete()
            }
            
            try outputPath.mkdir()
            try postsOutputPath.mkdir()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func loadAndRenderPosts() {
        let parsedPosts = postsPath.iterateChildren().compactMap(Post.parse(path:))
        self.posts = parsedPosts.sorted(by: { $0.date > $1.date })
        
        for index in posts.indices {
            let post = posts[index]
            let postOutput = postsOutputPath + Path(post.slug + ".html")
            let previousPost = index == 0 ? posts.last : posts[index - 1]
            let nextPost = index == posts.indices.last ? posts.first : posts[index + 1]
            
            var context: [String: Any] = [
                "siteUrl": siteUrl
            ]
            
            if let previous = previousPost {
                context["previousPost"] = previous.slug
            }
            
            if let next = nextPost {
                context["nextPost"] = next.slug
            }
            
            do {
                context["post"] = post
                context["post"] = post
                
                let pageHtml = try environment.renderTemplate(
                    name: "post.html",
                    context: context
                )
                try postOutput.write(pageHtml)
            } catch {
                print("Failed to render post \(post.slug)")
            }
        }
    }
    
    private func processResources() {
        do {
            for path in try contentPath.recursiveChildren() {
                var location = path.string.replacingOccurrences(of: contentPath.string, with: "")
                
                if location.first == "/" {
                    location.removeFirst()
                }
                
                let destination = outputPath + Path(location)
                print("Processing:", location)
                
                if destination.extension == nil {
                    do {
                        try destination.mkpath()
                    } catch {
                        print("Ignoring")
                    }
                } else if destination.extension == "html" {
                    if let page = Page(rawValue: destination.lastComponentWithoutExtension) {
                        let pageHtml = try environment.renderTemplate(name: destination.lastComponent, context: context(for: page))
                        try destination.write(pageHtml)
                    }
                } else {
                    try path.copy(destination)
                }
            }
        } catch {
            print("Failed to process resources: ", error.localizedDescription)
        }
    }
    
    private func context(for page: Page) -> [String: Any] {
        var context: [String: Any] = [:]
        
        switch page {
        case .index:
            context["posts"] = Array(posts.prefix(5))
        case .blog:
            context["posts"] = posts
        default:
            break
        }
        
        context["currentPage"] = page.rawValue
        context["siteUrl"] = siteUrl
        
        return context
    }
}
