class AppTable {
  final String name;

  AppTable({required this.name});

  Map<String, dynamic> toJson() => {
        'name': name,
      };

  factory AppTable.fromJson(Map<String, dynamic> json) {
    return AppTable(
      name: json['name'],
    );
  }
}
