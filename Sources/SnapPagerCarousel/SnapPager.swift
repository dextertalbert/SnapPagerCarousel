// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public struct SnapPager<Content: View, T: Hashable>: View {
    
    // The data array and selection bindings
    @Binding var items: [T]
    @Binding var selection: T?
    @Binding var currentIndex: Int
    
    /// The fixed width of each item/card.
    let itemWidth: CGFloat
    
    /// The fixed space between items.
    let itemSpacing: CGFloat
    
    /// The content builder for each item.
    let content: (Int, T) -> Content
    
    /// Internal states
    @State private var realSelection: T?
    @State private var scrollPosition: CGPoint = .zero
    @State private var isVisible: Bool = false
    @State private var isScrolling: Bool = false
    @State private var isSelecting: Bool = false
    
    /// The coordinate-space name for reading the scroll offset
    private let prefKeyScroller: String
    
    // MARK: - Initializer
    public init(
        items: Binding<[T]>,
        selection: Binding<T?>,
        currentIndex: Binding<Int>,
        itemWidth: CGFloat,
        itemSpacing: CGFloat,
        @ViewBuilder content: @escaping (Int, T) -> Content,
        coordinateSpaceName: String = "snapPager"
    ) {
        self._items = items
        self._selection = selection
        self._currentIndex = currentIndex
        self.itemWidth = itemWidth
        self.itemSpacing = itemSpacing
        self.content = content
        self.prefKeyScroller = coordinateSpaceName
        
        if let selected = selection.wrappedValue {
            self.realSelection = selected
        }
    }
    
    // MARK: - Body
    public var body: some View {
        GeometryReader { proxy in
            let containerWidth = proxy.size.width
            
            VStack(alignment: .leading) {
                ScrollView(.horizontal, showsIndicators: false) {
                    // Use the fixed spacing between items
                    LazyHStack(spacing: itemSpacing) {
                        ForEach(Array(items.enumerated()), id: \.element) { index, item in
                            content(index, item)
                                .frame(width: itemWidth)
                                .id(item)
                        }
                    }
                    // Read offset via preference key
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: SnapPagerPreferenceKey.self,
                                            value: geometry.frame(in: .named(prefKeyScroller)).origin)
                        }
                    )
                    .onPreferenceChange(SnapPagerPreferenceKey.self) { value in
                        self.scrollPosition = value
                        self.updateCurrentIndex(containerWidth: containerWidth)
                    }
                }
                .coordinateSpace(name: prefKeyScroller)
                // SwiftUI 16 feature for snapping:
                // .scrollTargetBehavior(.viewAligned)
                // .scrollPosition(id: $realSelection)
            }
        }
        .onChange(of: selection) { _, newValue in
            // If something sets selection externally, scroll to it
            guard !isScrolling else { return }
            self.isSelecting = true
            withAnimation {
                self.realSelection = newValue
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isSelecting = false
            }
        }
        .onChange(of: currentIndex) { _, _ in
            // If something sets currentIndex externally, scroll to it
            guard !isSelecting, currentIndex < items.count else { return }
            withAnimation {
                self.selection = items[currentIndex]
            }
        }
        .onAppear {
            self.isVisible = true
            if currentIndex >= 0, currentIndex < items.count {
                self.selection = items[currentIndex]
            }
        }
        .onDisappear {
            self.isVisible = false
        }
    }
    
    // MARK: - Helpers
    
    /// Update currentIndex based on scroll offset
    private func updateCurrentIndex(containerWidth: CGFloat) {
        // The left edge of the scroll view is at negative scrollPosition.x
        let offsetX = -scrollPosition.x
        
        // The horizontal center of the viewport
        let visibleCenterX = offsetX + containerWidth / 2
        
        // Each item occupies `itemWidth + itemSpacing`
        let itemFullWidth = itemWidth + itemSpacing
        
        // Determine which item is centered
        let index = Int(visibleCenterX / itemFullWidth)
        
        guard isVisible, index >= 0, index < items.count else { return }
        
        // Throttle quick index changes
        DispatchQueue.main.async {
            self.isScrolling = true
            self.currentIndex = index
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isScrolling = false
            }
        }
    }
}

// MARK: - Preference Key
struct SnapPagerPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}
