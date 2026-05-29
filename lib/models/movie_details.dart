import 'package:json_annotation/json_annotation.dart';

part 'movie_details.g.dart';

@JsonSerializable()
class MovieDetails {
  @JsonKey(name: 'Title')
  final String title;

  @JsonKey(name: 'Year')
  final String year;

  @JsonKey(name: 'Rated')
  final String rated;

  @JsonKey(name: 'Released')
  final String released;

  @JsonKey(name: 'Runtime')
  final String runtime;

  @JsonKey(name: 'Genre')
  final String genre;

  @JsonKey(name: 'Director')
  final String director;

  @JsonKey(name: 'Writer')
  final String writer;

  @JsonKey(name: 'Actors')
  final String actors;

  @JsonKey(name: 'Plot')
  final String plot;

  @JsonKey(name: 'Language')
  final String language;

  @JsonKey(name: 'Country')
  final String country;

  @JsonKey(name: 'Awards')
  final String awards;

  @JsonKey(name: 'Poster')
  final String poster;

  @JsonKey(name: 'imdbRating')
  final String imdbRating;

  @JsonKey(name: 'imdbVotes')
  final String imdbVotes;

  @JsonKey(name: 'imdbID')
  final String imdbId;

  @JsonKey(name: 'Type')
  final String type;

  @JsonKey(name: 'Response')
  final String response;

  MovieDetails({
    required this.title,
    required this.year,
    required this.rated,
    required this.released,
    required this.runtime,
    required this.genre,
    required this.director,
    required this.writer,
    required this.actors,
    required this.plot,
    required this.language,
    required this.country,
    required this.awards,
    required this.poster,
    required this.imdbRating,
    required this.imdbVotes,
    required this.imdbId,
    required this.type,
    required this.response,
  });

  /// Crée une instance MovieDetails à partir d'un JSON
  factory MovieDetails.fromJson(Map<String, dynamic> json) =>
      _$MovieDetailsFromJson(json);

  /// Convertit une instance MovieDetails en JSON
  Map<String, dynamic> toJson() => _$MovieDetailsToJson(this);

  /// Vérifie si le poster est valide
  bool get hasPoster => poster != 'N/A';

  /// Récupère l'URL IMDB du film
  String get imdbUrl => 'https://www.imdb.com/title/$imdbId/';

  @override
  String toString() => 'MovieDetails(title: $title, imdbId: $imdbId)';
}
