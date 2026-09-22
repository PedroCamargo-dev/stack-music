// Models Subsonic/Navidrome. IDs são SEMPRE strings (MD5/UUID) no Navidrome.

class SubsonicArtist {
  final String id;
  final String name;
  final int? albumCount;
  final String? coverArt;
  final String? artistImageUrl;

  SubsonicArtist({
    required this.id,
    required this.name,
    this.albumCount,
    this.coverArt,
    this.artistImageUrl,
  });

  factory SubsonicArtist.fromJson(Map<String, dynamic> j) => SubsonicArtist(
        id: j['id'].toString(),
        name: j['name'] ?? '',
        albumCount: j['albumCount'],
        coverArt: j['coverArt']?.toString(),
        artistImageUrl: j['artistImageUrl'],
      );
}

class SubsonicSong {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String album;
  final String albumId;
  final String? coverArt;
  final String? suffix;
  final String? contentType;
  final int? bitRate;
  final int duration; // segundos
  final int? track;
  final int? year;
  final String? genre;
  final int? playCount;
  bool starred;

  SubsonicSong({
    required this.id,
    required this.title,
    required this.artist,
    this.artistId = '',
    this.album = '',
    this.albumId = '',
    this.coverArt,
    this.suffix,
    this.contentType,
    this.bitRate,
    this.duration = 0,
    this.track,
    this.year,
    this.genre,
    this.playCount,
    this.starred = false,
  });

  factory SubsonicSong.fromJson(Map<String, dynamic> j) => SubsonicSong(
        id: j['id'].toString(),
        title: j['title'] ?? '',
        artist: j['artist'] ?? '',
        artistId: j['artistId']?.toString() ?? '',
        album: j['album'] ?? '',
        albumId: j['albumId']?.toString() ?? '',
        coverArt: j['coverArt']?.toString(),
        suffix: j['suffix']?.toString(),
        contentType: j['contentType']?.toString(),
        bitRate: j['bitRate'] as int?,
        duration: j['duration'] ?? 0,
        track: j['track'],
        year: j['year'],
        genre: j['genre'],
        playCount: j['playCount'],
        starred: j['starred'] != null,
      );

  String get durationLabel {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class SubsonicAlbum {
  final String id;
  final String name;
  final String artist;
  final String artistId;
  final String? coverArt;
  final int songCount;
  final int duration;
  final int? year;
  final String? genre;
  bool starred;

  SubsonicAlbum({
    required this.id,
    required this.name,
    required this.artist,
    this.artistId = '',
    this.coverArt,
    this.songCount = 0,
    this.duration = 0,
    this.year,
    this.genre,
    this.starred = false,
  });

  factory SubsonicAlbum.fromJson(Map<String, dynamic> j) => SubsonicAlbum(
        id: j['id'].toString(),
        name: j['name'] ?? j['title'] ?? '',
        artist: j['artist'] ?? '',
        artistId: j['artistId']?.toString() ?? '',
        coverArt: j['coverArt']?.toString(),
        songCount: j['songCount'] ?? 0,
        duration: j['duration'] ?? 0,
        year: j['year'],
        genre: j['genre'],
        starred: j['starred'] != null,
      );
}

class SubsonicPlaylist {
  final String id;
  final String name;
  final String? coverArt;
  final int songCount;
  final String? owner;
  final int? duration;
  bool starred;

  SubsonicPlaylist({
    required this.id,
    required this.name,
    this.coverArt,
    this.songCount = 0,
    this.owner,
    this.duration,
    this.starred = false,
  });

  factory SubsonicPlaylist.fromJson(Map<String, dynamic> j) =>
      SubsonicPlaylist(
        id: j['id'].toString(),
        name: j['name'] ?? '',
        coverArt: j['coverArt']?.toString(),
        songCount: j['songCount'] ?? 0,
        owner: j['owner'],
        duration: j['duration'],
        starred: j['starred'] != null,
      );
}

class SubsonicGenre {
  final String name;
  final int albumCount;
  final int songCount;

  SubsonicGenre({required this.name, this.albumCount = 0, this.songCount = 0});

  factory SubsonicGenre.fromJson(Map<String, dynamic> j) => SubsonicGenre(
        name: j['value'] ?? '',
        albumCount: j['albumCount'] ?? 0,
        songCount: j['songCount'] ?? 0,
      );
}

class SearchResult {
  final List<SubsonicArtist> artists;
  final List<SubsonicAlbum> albums;
  final List<SubsonicSong> songs;

  SearchResult({this.artists = const [], this.albums = const [], this.songs = const []});
}