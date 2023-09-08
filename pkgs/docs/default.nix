# platforms: x86_64-linux, aarch64-linux
# --- pkgs/docs/default.nix
#
# Author:  tsandrini <tomas.sandrini@seznam.cz>
# URL:     https://github.com/tsandrini/tensorfiles
# License: MIT
#
# 888                                                .d888 d8b 888
# 888                                               d88P"  Y8P 888
# 888                                               888        888
# 888888 .d88b.  88888b.  .d8888b   .d88b.  888d888 888888 888 888  .d88b.  .d8888b
# 888   d8P  Y8b 888 "88b 88K      d88""88b 888P"   888    888 888 d8P  Y8b 88K
# 888   88888888 888  888 "Y8888b. 888  888 888     888    888 888 88888888 "Y8888b.
# Y88b. Y8b.     888  888      X88 Y88..88P 888     888    888 888 Y8b.          X88
#  "Y888 "Y8888  888  888  88888P'  "Y88P"  888     888    888 888  "Y8888   88888P'
{ lib, pkgs, inputs, stdenv, mkdocs, pandoc, python3, python310Packages
, runCommand, nixosOptionsDoc, nixdoc, writeText, perl, ... }:
let
  inherit (lib.tensorfiles.attrsets) flatten;
  inherit (lib.tensorfiles.modules) mapModules;

  READMEs = let
    readmeToDerivation = path: writeText "README.md" (builtins.readFile path);
  in {
    main = readmeToDerivation ../../README.md;
    hosts = {
      "spinorbundle" = readmeToDerivation ../../hosts/spinorbundle/README.md;
    };
  };

  lib-doc = let
    libsets = [
      {
        name = "asserts";
        description = "assertion functions";
      }
      {
        name = "attrsets";
        description = "attribute set functions";
      }
      {
        name = "licenses";
        description = "tensorfiles licenses";
      }
      {
        name = "lists";
        description = "list manipulation functions";
      }
      {
        name = "maintainers";
        description = "tensorfiles maintainers";
      }
      {
        name = "modules";
        description = "general modularity functions";
      }
      {
        name = "nixos";
        description = "NixOS related functionality";
      }
      {
        name = "options";
        description = "NixOS / nixpkgs option handling";
      }
      {
        name = "strings";
        description = "string manipulation functions";
      }
      {
        name = "types";
        description = "additional types definitions";
      }
    ];
  in stdenv.mkDerivation {
    name = "tensorfiles-docs-lib";
    src = ../../lib;

    buildInputs = [ nixdoc pandoc python3 ];
    installPhase = ''
      function docgen {
        name=$1
        baseName=$2
        description=$3
        if [[ -e "../lib/$baseName.nix" ]]; then
          path="$baseName.nix"
        else
          path="$baseName/default.nix"
        fi

        # First we parse the doccoments in the xml docbook format
        nixdoc --category "$name" --description "**lib.$name**: $description" --file "$path" > "$out/$name.xml"

        # Then we convert the docbook xml to smart markdown
        pandoc -f docbook -t markdown -s "$out/$name.xml" -o "$out/$name.md"

        # Remove agressive pandoc escaping
        sed -i 's/\\//g' "$out/$name.md"

        # The following commands properly parse and convert the Example blocks
        # into markdowns code blocks
        # sed -i 's/^[ \t]*```/```/g' "$out/$name.md"
        # python -c "import re, sys; print(re.sub(r'(?sm)\`\`\`([^\`]+)\`\`\`', (lambda x: '\`\`\`' + '\n'.join([line.lstrip() for line in str(x.group(1)).split('\n')]) + '\`\`\`'), sys.stdin.read()));" < "$out/$name.md" > tmp.md && mv tmp.md $out/$name.md

        # sed -E -i 's/Types:\s+(.*)$/^^Types^^: `\1`/g' "$out/$name.md"

        # Add links to the source file
        fullPath="$src/$path"
        echo "" >> "$out/$name.md"
        echo "Declared by:" >> "$out/$name.md"
        echo "- [$fullPath]($fullPath)" >> "$out/$name.md"
        echo "" >> "$out/$name.md"

        cat "$out/$name.md" >> "$out/index.md"
      }

      mkdir -p "$out"

      # Run the docgen function for every libset
      ${lib.concatMapStrings ({ name, baseName ? name, description }: ''
        docgen ${name} ${baseName} ${lib.escapeShellArg description}
      '') libsets}
    '';
  };

  options-doc = let
    eval = lib.evalModules {
      modules = let loadModulesInDir = dir: flatten (mapModules dir (x: x));
      in [{ _module.check = false; }] ++ (loadModulesInDir ../../modules/misc)
      ++ (loadModulesInDir ../../modules/programs)
      ++ (loadModulesInDir ../../modules/services)
      ++ (loadModulesInDir ../../modules/system)
      ++ (loadModulesInDir ../../modules/tasks)
      ++ (loadModulesInDir ../../modules/security);
      specialArgs = {
        # TODO: Warning!!!!
        # This is very bad practice and should be usually avoided at all costs,
        # but modules cannot be easily evaluated otherwise. In the future it would
        # be probably best to just create the inputs manually directly here.
        inherit lib pkgs inputs;
        user = "root";
        system = "x86_64-linux";
      };
    };
    optionsDoc = nixosOptionsDoc { inherit (eval) options; };
  in runCommand "options-doc.md" { } ''
    cat ${optionsDoc.optionsCommonMark} >> $out
    sed -i "s/\\\./\./g" $out
    ${perl}/bin/perl -i -0777 -pe 's/```\n(.*?)\n```/```nix linenums="1"\n\1\n```/gs' $out
  '';
in stdenv.mkDerivation {
  src = ./.;
  name = "tensorfiles-docs";

  buildInput = [ options-doc lib-doc ]
    ++ (with READMEs; [ main hosts."spinorbundle" ]);

  nativeBuildInputs = with python310Packages; [
    setuptools
    mkdocs
    mkdocs-material
    # I've had issues while trying to include files from the /nix/store
    # using the jinja macros so just for this I've included the markdown-include
    # package
    markdown-include
    pygments
    cairosvg
  ];

  buildPhase = ''
    mkdir -p docs docs/hosts

    cp -v ${READMEs.main} docs/index.md
    cp -v ${READMEs.hosts."spinorbundle"} docs/hosts/spinorbundle.md

    cp -v ${options-doc} docs/nixos-options.md
    cp -v ${lib-doc}/index.md docs/lib.md

    # Patches
    find . -type f -exec sed -i "s|pkgs/docs/docs/||g" {} +

    mkdocs build
  '';

  installPhase = ''
    mv -v site $out
  '';

  meta = with lib; {
    homepage = "https://github.com/tsandrini/tensorfiles";
    description = "The combined Documentation of the whole tensorfiles flake.";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = with tensorfiles.maintainers; [ tsandrini ];
  };
}
