import SwiftUI
import UIKit

/// Pages you turn with a real page curl (UIPageViewController), each page a
/// SwiftUI view. The page count is read live, so pages can be added while
/// the story is still being written.
struct PageCurlReader: UIViewControllerRepresentable {
    let pageCount: () -> Int
    let makePage: (Int) -> AnyView

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: NSNumber(value: UIPageViewController.SpineLocation.min.rawValue)]
        )
        controller.isDoubleSided = false
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        controller.view.backgroundColor = .clear
        controller.setViewControllers([context.coordinator.page(0)], direction: .forward, animated: false)
        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurlReader
        private var cache: [Int: PageHost] = [:]
        private let turn = UIImpactFeedbackGenerator(style: .soft)

        init(_ parent: PageCurlReader) {
            self.parent = parent
        }

        func page(_ index: Int) -> PageHost {
            if let cached = cache[index] { return cached }
            let host = PageHost(index: index, rootView: parent.makePage(index))
            cache[index] = host
            return host
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let host = viewController as? PageHost, host.index > 0 else { return nil }
            return page(host.index - 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let host = viewController as? PageHost, host.index + 1 < parent.pageCount() else { return nil }
            return page(host.index + 1)
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed { turn.impactOccurred(intensity: 0.6) }
        }
    }
}

/// Hosts one page. The page's paper colour shows through the curl.
final class PageHost: UIHostingController<AnyView> {
    let index: Int

    init(index: Int, rootView: AnyView) {
        self.index = index
        super.init(rootView: rootView)
        view.backgroundColor = UIColor(DS.Colors.surface)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("PageHost is created in code")
    }
}
