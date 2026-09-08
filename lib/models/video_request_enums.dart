/// Enum representing the video request workflow status.
enum VideoRequestStatus { pending, assigned, inProgress, completed, cancelled, unknown }

extension VideoRequestStatusParser on String? {
  VideoRequestStatus get asVideoRequestStatus {
    switch (this?.toLowerCase().trim()) {
      case 'pending':
        return VideoRequestStatus.pending;
      case 'assigned':
        return VideoRequestStatus.assigned;
      case 'in_progress':
      case 'inprogress':
        return VideoRequestStatus.inProgress;
      case 'completed':
        return VideoRequestStatus.completed;
      case 'cancelled':
      case 'canceled':
        return VideoRequestStatus.cancelled;
      default:
        return VideoRequestStatus.unknown;
    }
  }
}

extension VideoRequestStatusExtensions on VideoRequestStatus {
  bool get isPending => this == VideoRequestStatus.pending;

  bool get isAssigned => this == VideoRequestStatus.assigned;

  bool get isInProgress => this == VideoRequestStatus.inProgress;

  bool get isCompleted => this == VideoRequestStatus.completed;

  bool get isCancelled => this == VideoRequestStatus.cancelled;

  String get displayName {
    switch (this) {
      case VideoRequestStatus.pending:
        return 'Pending';
      case VideoRequestStatus.assigned:
        return 'Assigned';
      case VideoRequestStatus.inProgress:
        return 'In Progress';
      case VideoRequestStatus.completed:
        return 'Completed';
      case VideoRequestStatus.cancelled:
        return 'Cancelled';
      case VideoRequestStatus.unknown:
        return 'Unknown';
    }
  }

  String get apiValue {
    switch (this) {
      case VideoRequestStatus.pending:
        return 'pending';
      case VideoRequestStatus.assigned:
        return 'assigned';
      case VideoRequestStatus.inProgress:
        return 'in_progress';
      case VideoRequestStatus.completed:
        return 'completed';
      case VideoRequestStatus.cancelled:
        return 'cancelled';
      case VideoRequestStatus.unknown:
        return 'unknown';
    }
  }
}

/// Enum representing the super admin approval state of a video request.
enum VideoRequestApprovalStatus { pending, approved, rejected, unknown }

extension VideoRequestApprovalStatusParser on String? {
  VideoRequestApprovalStatus get asVideoRequestApprovalStatus {
    switch (this?.toLowerCase().trim()) {
      case 'pending':
        return VideoRequestApprovalStatus.pending;
      case 'approved':
        return VideoRequestApprovalStatus.approved;
      case 'rejected':
        return VideoRequestApprovalStatus.rejected;
      default:
        return VideoRequestApprovalStatus.unknown;
    }
  }
}

extension VideoRequestApprovalStatusExtensions on VideoRequestApprovalStatus {
  bool get isPending => this == VideoRequestApprovalStatus.pending;

  bool get isApproved => this == VideoRequestApprovalStatus.approved;

  bool get isRejected => this == VideoRequestApprovalStatus.rejected;

  String get displayName {
    switch (this) {
      case VideoRequestApprovalStatus.pending:
        return 'Pending';
      case VideoRequestApprovalStatus.approved:
        return 'Approved';
      case VideoRequestApprovalStatus.rejected:
        return 'Rejected';
      case VideoRequestApprovalStatus.unknown:
        return 'Unknown';
    }
  }

  String get apiValue {
    switch (this) {
      case VideoRequestApprovalStatus.pending:
        return 'pending';
      case VideoRequestApprovalStatus.approved:
        return 'approved';
      case VideoRequestApprovalStatus.rejected:
        return 'rejected';
      case VideoRequestApprovalStatus.unknown:
        return 'unknown';
    }
  }
}
