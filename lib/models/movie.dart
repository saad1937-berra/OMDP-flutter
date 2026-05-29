import 'package:json_annotation/json_annotation.dart';

part 'movie.g.dart';

/// Modèle représentant un film/série dans les résultats de recherche
@JsonSerializable()
class Movie {
  @JsonKey(name: 'Title')
  final String title;

  @JsonKey(name: 'Year')
  final String year;

  @JsonKey(name: 'imdbID')
  final String imdbId;

  @JsonKey(name: 'Type')
  final String type;

  @JsonKey(name: 'Poster')
  final String poster;

  Movie({
    required this.title,
    required this.year,
    required this.imdbId,
    required this.type,
    required this.poster,
  });

  /// Crée une instance Movie à partir d'un JSON
  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);

  /// Convertit une instance Movie en JSON
  Map<String, dynamic> toJson() => _$MovieToJson(this);

  /// Vérifie si le poster est valide (pas "N/A")
  bool get hasPoster => poster != 'N/A';

  @override
  String toString() => 'Movie(title: $title, year: $year, imdbId: $imdbId)';
}
