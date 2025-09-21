/// موديل بسيط لتمثيل الماركة
class CarMake {
  final int id;
  final String name;
  final String logoUrl;

  CarMake({required this.id, required this.name, required this.logoUrl});

  factory CarMake.fromJson(Map<String, dynamic> j) {
    return CarMake(
      id: int.tryParse(j['id'].toString()) ?? 0,
      name: (j['name'] ?? '').toString().trim(),
      logoUrl: (j['logoUrl'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'logoUrl': logoUrl};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarMake && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CarMake(id: $id, name: $name)';
}
