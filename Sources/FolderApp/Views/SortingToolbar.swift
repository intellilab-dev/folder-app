import SwiftUI

/// Toolbar with icon buttons for sorting files (Windows-style)
struct SortingToolbar: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var body: some View {
        HStack(spacing: 4) {
            Spacer()

            sortButton(
                title: "Name",
                icon: "textformat",
                option: .name
            )

            sortButton(
                title: "Date",
                icon: "calendar",
                option: .dateModified
            )

            sortButton(
                title: "Size",
                icon: "archivebox",
                option: .size
            )

            sortButton(
                title: "Type",
                icon: "doc",
                option: .type
            )

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func sortButton(title: String, icon: String, option: ViewMode.SortOption) -> some View {
        Button(action: {
            if viewModel.viewMode.sortBy == option {
                // Same option clicked - toggle sort order
                viewModel.toggleSortOrder()
            } else {
                // Different option clicked - change sort option
                viewModel.setSortOption(option)
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))

                Text(title)
                    .font(.system(size: 12))

                // Show sort direction indicator if this is the active sort option
                if viewModel.viewMode.sortBy == option {
                    Image(systemName: viewModel.viewMode.sortOrder == .ascending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(viewModel.viewMode.sortBy == option ? Color.folderAccent.opacity(0.15) : Color.clear)
        )
        .buttonStyle(.plain)
        .focusable(false)
        .help("Sort by \(title)")
    }
}
