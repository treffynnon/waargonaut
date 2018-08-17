let
  initialNixpkgs = import <nixpkgs> {};

  sources = rec {
    digit-pinned = initialNixpkgs.pkgs.lib.importJSON ./digit.json;
    digit = initialNixpkgs.pkgs.fetchFromGitHub {
      owner = "qfpl";
      repo = "digit";
      inherit (digit-pinned) rev sha256;
    };
  };
in
  sources.digit
