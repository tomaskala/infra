{
  programs.beets = {
    enable = true;

    settings = {
      directory = "~/music";
      library = "~/musiclibrary.db";
      original_date = true;

      import.copy = true;
      match.strong_rec_thresh = 0.02;

      plugins = [
        "fetchart"
        "lastgenre"
        "edit"
        "permissions"
        "musicbrainz"
      ];

      paths = {
        default = "$albumartist/$year - $album%aunique{}/$track - $title";
        singleton = "Non-Album/$artist/$title";
        comp = "Compilations/$album%aunique{}/$track $title";
        "albumtype:soundtrack" = "Soundtracks/$album/$track - $title";
      };

      fetchart = {
        minwidth = 800;
        maxwidth = 800;
        enforce_ratio = true;
        sources = "coverart itunes amazon albumart fanarttv filesystem";
        lastfm_key = "c90786d2c221bf2a1e978d69b2812f83";
      };

      lastgenre = {
        auto = true;
        source = "album";
      };

      edit = {
        itemfields = [
          "album"
          "albumartist"
          "artist"
          "track"
          "title"
          "year"
        ];

        albumfields = [
          "albumartist"
          "album"
          "year"
          "albumtype"
        ];
      };
    };
  };
}
