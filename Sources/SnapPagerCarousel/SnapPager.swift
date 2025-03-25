import SwiftUI

public struct SnapPager<Content: View, T: Hashable>: View {
    
    // MARK: - Bound Variables
    @Binding var items: [T]
    @Binding var selection: T?
    @Binding var currentIndex: Int
    
    // MARK: - Layout Parameters
    /// The fixed width for each card/item.
    let itemWidth: CGFloat
    
    /// The fixed gap between cards.
    let itemSpacing: CGFloat
    
    /// Renders each item’s content.
    let content: (Int, T) -> Content
    
    // MARK: - Internal State
    @State private var scrollOffset: CGPoint = .zero
    @State private var isDragging: Bool = false
    
    // MARK: - Init
    public init(
        items: Binding<[T]>,
        selection: Binding<T?>,
        currentIndex: Binding<Int>,
        itemWidth: CGFloat,
        itemSpacing: CGFloat,
        @ViewBuilder content: @escaping (Int, T) -> Content
    ) {
        self._items = items
        self._selection = selection
        self._currentIndex = currentIndex
        self.itemWidth = itemWidth
        self.itemSpacing = itemSpacing
        self.content = content
    }
    
    // MARK: - Body
    public var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: itemSpacing) {
                        ForEach(Array(items.enumerated()), id: \.element) { index, item in
                            content(index, item)
                                .frame(width: itemWidth)
                                .id(index)
                        }
                    }
                    // Ensure the HStack takes at least the full width of the container.
                    .frame(minWidth: geometry.size.width)
                }
                // This modifier tells the system to snap the closest target to the center.
                .scrollTargetBehavior(.viewCentered)
                .onAppear {
                    // Scroll to the current index when the view appears.
                    DispatchQueue.main.async {
                        scrollProxy.scrollTo(currentIndex, anchor: .center)
                    }
                }
                .onChange(of: currentIndex) { newValue in
                    withAnimation {
                        scrollProxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Calculate Which Item Is Centered
    private func calculateCurrentIndex(containerWidth: CGFloat) -> Int {
        // The scroll offset is negative, so offsetX = -scrollOffset.x
        let offsetX = -scrollOffset.x
        
        // The center of the visible region
        let visibleCenterX = offsetX + (containerWidth / 2)
        
        // Each "slot" is itemWidth + itemSpacing
        let slotWidth = itemWidth + itemSpacing
        
        // Convert the center point to an item index
        let rawIndex = Int(visibleCenterX / slotWidth)
        
        return rawIndex
    }
}

// MARK: - Preference Key
/// Holds the offset of the entire scrollable content
struct SnapPagerOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}
