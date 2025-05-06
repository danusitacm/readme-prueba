import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String name;
  final String? email; // Used for storing username if needed
  final String? id;
  final String? role;
  final String? lastName;
  final DateTime? lastAccessDate;

  const User({
    required this.name,
    this.email,
    this.id,
    this.role,
    this.lastName,
    this.lastAccessDate,
  });

  // Constructor de fábrica para crear un objeto User desde un mapa JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      email: json['email'] ?? json['username'], // Handle both email or username
      id: json['id']?.toString(),
      role: json['role'],
      lastName: json['lastName'],
      lastAccessDate: json['lastAccessDate'] != null 
          ? DateTime.tryParse(json['lastAccessDate'])
          : null,
    );
  }

  // Método para convertir el objeto User a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'id': id,
      'role': role,
      'lastName': lastName,
      'lastAccessDate': lastAccessDate?.toIso8601String(),
    };
  }

  // Crea una copia de este User, pero con los campos actualizados
  User copyWith({
    String? name,
    String? email,
    String? id,
    String? role,
    String? lastName,
    DateTime? lastAccessDate,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      id: id ?? this.id,
      role: role ?? this.role,
      lastName: lastName ?? this.lastName,
      lastAccessDate: lastAccessDate ?? this.lastAccessDate,
    );
  }

  @override
  List<Object?> get props => [name, email, id, role, lastName, lastAccessDate];
}