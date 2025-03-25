import SwiftUI

public struct SnapPager<Content: View, T: Hashable>: View {
    
    @Binding var items: [T]
    @Binding var selection: T?
    @Binding var currentIndex: Int
    
    var edgesOverlap: CGFloat = 0
    /// We’ll store the “gap” in `itemSpacing` internally
    var itemSpacing: CGFloat = 0
    
    var content: (Int, T) -> Content
    
    @State private var realSelection: T?
    @State private var scrollPosition: CGPoint = .zero
    @State private var isVisible: Bool = false
    @State private var contentSize: CGSize = .zero
    @State private var prefKeyScroller: String = "snapPager"
    @State private var isScrolling: Bool = false
    @State private var isSelecting: Bool = false
    
    public init(
        items: Binding<[T]>,
        selection: Binding<T?>,
        currentIndex: Binding<Int>,
        edgesOverlap: CGFloat = 0,
        itemsMargin: CGFloat = 0,
        content: @escaping (Int, T) -> Content,
        prefKeyScroller: String? = nil
    ) {
        self._items = items
        self._selection = selection
        self._currentIndex = currentIndex
        self.edgesOverlap = abs(edgesOverlap)
        // We’ll store the gap as `itemSpacing`
        self.itemSpacing = abs(itemsMargin)
        self.content = content
        self.prefKeyScroller = prefKeyScroller ?? "snapPager"
        
        if let selected = selection.wrappedValue {
            self.realSelection = selected
        }
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let _ = updateContentSize(proxy.size)
            
            VStack(alignment: .leading) {
                ScrollView(.horizontal, showsIndicators: false) {
                    // 1) Use `itemSpacing` here instead of fixed 0
                    LazyHStack(spacing: itemSpacing) {
                        ForEach(Array(items.enumerated()), id: \.element) { index, item in
                            ZStack {
                                // 2) Remove `.padding(.horizontal, itemSpacing)`
                                content(index, item)
                                    .frame(maxWidth: proxy.size.width - edgesOverlap * 2)
                                    .containerRelativeFrame(.horizontal)
                            }
                            .id(item)
                            .clipped()
                            .frame(width: proxy.size.width - edgesOverlap * 2, alignment: .center)
                        }
                    }
                    .scrollTargetLayout()
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: SnapPagerPreferenceKey.self,
                                            value: geometry.frame(in: .named(prefKeyScroller)).origin)
                        }
                    )
                    .onPreferenceChange(SnapPagerPreferenceKey.self) { value in
                        self.scrollPosition = value
                        self.readPositionScrollView()
                    }
                }
                .safeAreaPadding(.horizontal, edgesOverlap)
                .coordinateSpace(name: prefKeyScroller)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $realSelection)
            }
        }
        // The rest is unchanged from your original code
        .onChange(of: selection) { _, newValue in
            if !isScrolling {
                self.isSelecting = true
                withAnimation {
                    self.realSelection = newValue
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.isSelecting = false
                }
            }
        }
        .onChange(of: currentIndex) { _, newValue in
            if currentIndex < items.count, !isSelecting {
                withAnimation {
                    self.selection = items[currentIndex]
                }
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
    
    func updateContentSize(_ proxySize: CGSize) {
        DispatchQueue.main.async {
            self.contentSize = proxySize
        }
    }
    
    /// 3) Incorporate `itemSpacing` in the “slot width”
    func readPositionScrollView() {
        let offsetX = -scrollPosition.x
        let margins = edgesOverlap * 2
        let screenContentWidth = self.contentSize.width
        
        if isVisible, screenContentWidth > 0 {
            // The center of the visible area
            let visibleCenterX = offsetX + screenContentWidth / 2.0
            
            // Each “slot” is the item’s width plus the gap
            let slotWidth = (screenContentWidth - margins) + itemSpacing
            
            // Convert center X to an item index
            let index = Int(visibleCenterX / slotWidth)
            
            DispatchQueue.main.async {
                self.isScrolling = true
                self.currentIndex = index
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.isScrolling = false
                }
            }
        }
    }
}

// Same preference key as original
struct SnapPagerPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}
