{
  lib ? inputs.nixpkgs.lib,
  nixosOptionsDoc ? pkgs.nixosOptionsDoc,
  runCommand ? pkgs.runCommand,
  fetchurl ? pkgs.fetchurl,
  pandoc ? pkgs.pandoc,
  modules ? [
    {
      imports = [ flake.nixosModules.default ];
      nixpkgs = {
        inherit pkgs;
      };
    }
  ],
  filterPrefix ? "lollypops",
  title ? "Lollypops options",
  pkgs,
  pname,
  flake,
  inputs,
  ...
}:

let
  eval = lib.nixosSystem {
    inherit modules;
  };
  options = nixosOptionsDoc {

    # If the filterPrefix is set, only options with that prefix are documented.
    options = if filterPrefix == "" then eval.options else eval.options."${filterPrefix}";
  };
  md =
    (runCommand "${pname}-md" { } ''
      cat >$out <<EOF
      # ${title}

      EOF
      cat ${options.optionsCommonMark} >>$out
    '').overrideAttrs
      (_o: {
        # Work around https://github.com/hercules-ci/hercules-ci-agent/issues/168
        allowSubstitutes = true;
      });
  css = fetchurl {
    url = "https://gist.githubusercontent.com/killercup/5917178/raw/40840de5352083adb2693dc742e9f75dbb18650f/pandoc.css";
    sha256 = "sha256-SzSvxBIrylxBF6B/mOImLlZ+GvCfpWNLzGFViLyOeTk=";
  };
in
# TODO Generate docs for Home-Manager modules as well.
runCommand "${pname}-html" { nativeBuildInputs = [ pandoc ]; } ''
  mkdir $out
  cp ${css} $out/pandoc.css
  pandoc --css="pandoc.css" ${md} --to=html5 -s -f markdown+smart --metadata pagetitle="${title}" -o $out/index.html
''
