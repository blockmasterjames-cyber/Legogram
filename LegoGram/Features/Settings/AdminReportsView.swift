import SwiftUI

/// Admin-only reports queue. Reachable only from the Settings "Admin" row,
/// which is itself gated on `UserSession.isAdmin`. Lists open reports and lets
/// an admin Remove Content, Ban the reported user, or Dismiss — each of which
/// marks the report resolved and writes a `moderation_logs` audit entry.
struct AdminReportsView: View {

    @ObservedObject private var userSession = UserSession.shared

    @State private var reports: [AdminReport] = []
    @State private var isLoading   = true
    @State private var showResolved = false
    @State private var loadError: String?

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.legoYellow).scaleEffect(1.4)
            } else if let loadError {
                errorState(loadError)
            } else if reports.isEmpty {
                emptyState
            } else {
                reportList
            }
        }
        .navigationTitle(showResolved ? "All Reports" : "Open Reports")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showResolved.toggle()
                    Task { await load() }
                } label: {
                    Image(systemName: showResolved ? "tray.full.fill" : "tray.fill")
                        .foregroundColor(.legoYellow)
                }
            }
        }
        .task { await load() }
    }

    // MARK: - List

    private var reportList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(reports) { report in
                    NavigationLink {
                        AdminReportDetailView(report: report) { resolvedId in
                            // Remove the handled report from the open list.
                            reports.removeAll { $0.id == resolvedId }
                        }
                    } label: {
                        reportRow(report)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }

    private func reportRow(_ report: AdminReport) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(report.contentTypeLabel.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.darkBackground)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.legoYellow)
                    .cornerRadius(5)
                Spacer()
                if report.isResolved {
                    Text("RESOLVED")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.successGreen)
                }
                Text(report.timeAgo)
                    .font(.legoCaption).foregroundColor(.secondaryText)
            }

            Text(report.reason)
                .font(.legoCardTitle).foregroundColor(.lightText)
                .lineLimit(2)

            Text("Target: @\(report.reportedUsername.isEmpty ? "unknown" : report.reportedUsername)")
                .font(.legoCaption).foregroundColor(.secondaryText)
            Text("Reporter: @\(report.reportedByUsername.isEmpty ? "unknown" : report.reportedByUsername)")
                .font(.legoCaption).foregroundColor(.secondaryText)

            if !report.contextText.isEmpty {
                Text("\u{201C}\(report.contextText)\u{201D}")
                    .font(.legoCaption).foregroundColor(.secondaryText)
                    .italic().lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Empty / Error

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 54)).foregroundColor(.successGreen)
            Text(showResolved ? "No reports" : "No open reports")
                .font(.legoScreenTitle).foregroundColor(.lightText)
            Text("Reports created by users will appear here for review.")
                .font(.legoBody).foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44)).foregroundColor(.legoRed)
            Text("Couldn't load reports")
                .font(.legoCardTitle).foregroundColor(.lightText)
            Text(message)
                .font(.legoCaption).foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await load() } }
                .font(.legoBody).foregroundColor(.legoYellow)
        }
        .padding(40)
    }

    // MARK: - Load

    private func load() async {
        isLoading = true
        loadError = nil
        do {
            reports = try await FirebaseService.shared.fetchReports(includeResolved: showResolved)
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Report Detail + Actions

/// Detail screen for a single report with the moderation actions.
struct AdminReportDetailView: View {

    let report: AdminReport
    /// Called with the report id after it has been resolved (any action).
    let onResolved: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userSession = UserSession.shared

    @State private var isWorking = false
    @State private var actionError: String?
    @State private var showBanConfirm = false
    @State private var showRemoveConfirm = false

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    detailCard
                    if let actionError {
                        Text(actionError)
                            .font(.legoCaption).foregroundColor(.legoRed)
                    }
                    actionButtons
                }
                .padding()
            }

            if isWorking {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView().tint(.legoYellow).scaleEffect(1.4)
            }
        }
        .navigationTitle("Review Report")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Detail card

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            detailRow("Type", report.contentTypeLabel)
            detailRow("Reason", report.reason)
            detailRow("Reported user", "@\(report.reportedUsername) (\(report.reportedUserId))")
            detailRow("Reported by", "@\(report.reportedByUsername)")
            detailRow("Content id", report.contentId.isEmpty ? "—" : report.contentId)
            if !report.contextText.isEmpty {
                detailRow("Context", report.contextText)
            }
            detailRow("Reported", report.timeAgo)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.secondaryText)
            Text(value)
                .font(.legoBody).foregroundColor(.lightText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if report.canRemoveContent {
                actionButton("Remove Content", icon: "trash.fill", color: .legoRed) {
                    showRemoveConfirm = true
                }
            }

            if !report.reportedUserId.isEmpty {
                actionButton("Ban User", icon: "nosign", color: .legoRed) {
                    showBanConfirm = true
                }
            }

            actionButton("Dismiss (mark resolved)", icon: "checkmark.circle.fill",
                         color: .successGreen) {
                Task { await dismissReport() }
            }
        }
        .disabled(isWorking)
        .alert("Remove this content?", isPresented: $showRemoveConfirm) {
            Button("Remove", role: .destructive) { Task { await removeContent() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the reported \(report.contentTypeLabel.lowercased()).")
        }
        .alert("Ban @\(report.reportedUsername)?", isPresented: $showBanConfirm) {
            Button("Ban", role: .destructive) { Task { await banUser() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They will be signed out and blocked from using the app.")
        }
    }

    private func actionButton(_ title: String, icon: String, color: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title).font(.legoCardTitle)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 14).padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(12)
        }
    }

    // MARK: Action handlers

    private var adminUid: String { userSession.uid }

    private func removeContent() async {
        isWorking = true
        defer { isWorking = false }
        do {
            switch report.contentType {
            case "post":
                // deletePost decrements the OWNER's post_count, so pass the
                // reported (owner) uid — NOT the admin's.
                try await FirebaseService.shared.deletePost(
                    report.contentId, userId: report.reportedUserId)
            case "comment":
                try await FirebaseService.shared.deleteComment(commentId: report.contentId)
            default:
                break
            }
            await FirebaseService.shared.logModerationAction(
                action: "remove_content", adminUid: adminUid,
                targetUserId: report.reportedUserId,
                contentType: report.contentType, contentId: report.contentId)
            try await finishResolved()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func banUser() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await FirebaseService.shared.banUser(uid: report.reportedUserId)
            await FirebaseService.shared.logModerationAction(
                action: "ban_user", adminUid: adminUid,
                targetUserId: report.reportedUserId,
                contentType: report.contentType, contentId: report.contentId)
            try await finishResolved()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func dismissReport() async {
        isWorking = true
        defer { isWorking = false }
        do {
            await FirebaseService.shared.logModerationAction(
                action: "dismiss", adminUid: adminUid,
                targetUserId: report.reportedUserId,
                contentType: report.contentType, contentId: report.contentId)
            try await finishResolved()
        } catch {
            actionError = error.localizedDescription
        }
    }

    /// Marks the report resolved, notifies the list, and pops back.
    private func finishResolved() async throws {
        try await FirebaseService.shared.resolveReport(reportId: report.id, adminUid: adminUid)
        onResolved(report.id)
        dismiss()
    }
}
