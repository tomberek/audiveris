{
  inputs.gradle2nix.url = "github:tadfisher/gradle2nix/v2";

  outputs =
    { self, gradle2nix }:
    {

      packages = builtins.mapAttrs (system: pkgs: {
        default =
          let
            jdk = pkgs.openjdk17;
            tesseract = pkgs.tesseract;
          in
          gradle2nix.builders.${system}.buildGradlePackage rec {
            pname = "audiveris";
            version = self.sourceInfo.shortRev or self.sourceInfo.dirtyShortRev or "dirty";
            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = pkgs.lib.fileset.difference ./. ./flake.nix;
            };

            lockFile = ./gradle.lock;

            buildInputs = [
              pkgs.freetype
              pkgs.musescore
              tesseract
            ];

            preBuild = "sed -i 's/git rev-parse --short HEAD/echo ${version}/' build.gradle";

            gradleFlags = [ "installDist" ];

            JAVA_HOME = jdk;
            TESSDATA_PREFIX = tesseract + "/share/tessdata";

            installPhase = ''
              cp -r build/ $out
              mkdir -p $out/bin
              cat <<EOF > $out/bin/audiveris
              #!/bin/sh
              export TESSDATA_PREFIX=$TESSDATA_PREFIX
              export AWT_FORCE_HEADFUL=true
              $JAVA_HOME/bin/java -cp "$out/install/Audiveris/lib/*" Audiveris
              EOF
              chmod +x $out/bin/audiveris
            '';
          };
      }) gradle2nix.inputs.nixpkgs.legacyPackages;
    };
}
