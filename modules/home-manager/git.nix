{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;

    options = {
      hunk-header-style = "file syntax";
      line-numbers = true;
      syntax-theme = "ansi";
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      alias = {
        a = "add";
        c = "commit";
        cp = "cherry-pick";
        d = "diff";
        l = "log";
        s = "status";
        sh = "show";
        sw = "switch";
      };

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
