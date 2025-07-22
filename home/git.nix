{
  programs.git = {
    enable = true;
    lfs.enable = true;

    delta = {
      enable = true;
      options = {
        hunk-header-style = "file syntax";
        line-numbers = true;
        syntax-theme = "ansi";
      };
    };

    aliases = {
      a = "add";
      c = "commit";
      cp = "cherry-pick";
      d = "diff";
      l = "log";
      s = "status";
      sh = "show";
      sw = "switch";
    };

    extraConfig = {
      user = {
        name = "Tomas Kala";
        email = "me@tomaskala.com";
      };

      init.defaultBranch = "main";
      commit.verbose = true;
      fetch.prune = true;
      pull.ff = "only";

      push = {
        autoSetupRemote = true;
        followTags = true;
      };

      rebase = {
        autoSquash = true;
        autoStash = true;
      };

      merge = {
        ff = "only";
        conflictStyle = "zdiff3";
      };

      diff.algorithm = "histogram";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
    };
  };
}
