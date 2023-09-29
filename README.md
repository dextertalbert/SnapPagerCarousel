# SnapPager

SnapPager is a SwiftUI 5 library for iOS 17 (and newer) that simplifies the implementation of a horizontal paging scroll view with snapping behavior. It's perfect for creating carousels, image galleries, or any other horizontal scrolling view where you want items to snap neatly into place as the user scrolls. It is also highly performant, with lazy loading of the view making it ideal for displaying a large number of pages efficiently.

## Features

- **Easy Integration:** SnapPager can be easily integrated into your SwiftUI project, allowing you to create horizontal pagers with just a few lines of code.

- **Customizable:** You can customize the spacing between items and the amount of overlap between adjacent items.

- **Snap Behavior:** SnapPager automatically snaps items to the center, creating a smooth and intuitive scrolling experience.


## Installation

**Swift Package Manager:** XCode > File > Add package Dependencies... > copy/paste this repo in the search
```html
https://github.com/MaximeFILIPPI/SnapPagerCarousel
```


## Usage

Here's a basic example of how to integrate and use SnapPager in your SwiftUI views:

```swift
import SwiftUI
import SnapPagerCarousel // <- Import

struct ContentView: View {
    
    @State var carouselItems: [YourModel] = []  // <- Your items (can be anything Hashable)
    @State var carouselSelection: YourModel?    // <- Should match your items type
    @State var carouselIndex: Int = 0           // <- This keeps track of the page index
    
    var body: some View {
        
        SnapPager(items: $carouselItems,
                  selection: $carouselSelection,
                  currentIndex: $carouselIndex) { item in
            
            YourCustomView(item) // <- Content display for each page here (can be replace by any of your views)
            
        }
        
    }
    
    // Load your items into carouselItems
    
}
```

In this example, `carouselItems` is an array of String that you want to display in the pager. 
The `SnapPager` view automatically handles the horizontal paging and snapping behavior for you. 
You can customize the appearance of each page by providing a content closure.


## Customization

You can customize the appearance of your pager by adjusting the `edgesOverlap` property that controls how much adjacent your pages should overlap when snapping.

```swift
SnapPager(items: $carouselItems,
          selection: $carouselSelection,
          currentIndex: $carouselIndex,
          edgesOverlap: 60 // Customize the overlap
          ) { item in
    // Your content for each page here
    CustomView(item)
}
```


## License

SnapPager is available under the MIT license. See the [LICENSE](https://github.com/MaximeFILIPPI/SnapPagerCarousel/blob/main/LICENSE) file for more details.


## Credits

SnapPager is developed and maintained by [Maxime FILIPPI].

If you encounter any issues or have suggestions for improvements, please [open an issue](https://github.com/MaximeFILIPPI/SnapPagerCarousel/issues).
