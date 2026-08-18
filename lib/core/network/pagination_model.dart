class PaginationMetadata {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  PaginationMetadata({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMetadata.fromJson(Map<String, dynamic> json) {
    return PaginationMetadata(
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'page': page, 'page_size': pageSize, 'total': total, 'total_pages': totalPages};
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMetadata pagination;

  PaginatedResponse({required this.items, required this.pagination});

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList.map((item) => fromJsonT(item as Map<String, dynamic>)).toList();

    final paginationData = json['pagination'] as Map<String, dynamic>? ?? {};
    final pagination = PaginationMetadata.fromJson(paginationData);

    return PaginatedResponse(items: items, pagination: pagination);
  }
}
