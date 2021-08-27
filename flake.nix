# adapted from https://github.com/pjones/nixpkgs-jlink/blob/master/jlink.nix

{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        packages = {
          jlink =
            let
              inherit (pkgs) stdenv lib requireFile autoPatchelfHook substituteAll qt4 fontconfig freetype libusb ncurses5 udev;
              inherit (pkgs.xorg) libICE libSM libX11 libXext libXcursor libXfixes libXrender libXrandr;

              architecture = {
                x86_64-linux = "x86_64";
                i686-linux   = "i386";
                armv7l-linux = "arm";
              }.${stdenv.hostPlatform.system} or (throw "unsupported system ${stdenv.hostPlatform.system}");

              sha256 = {
                x86_64-linux = "1q0baln1f7241jywzr2pv05bdpp8nxk6bh74xigg2ln5lrvfzzdn";
              }.${stdenv.hostPlatform.system} or (throw "unsupported system ${stdenv.hostPlatform.system}");
            in stdenv.mkDerivation rec {
              pname = "jlink";
              version = "V752d";

              src = requireFile {
                name = "JLink_Linux_${version}_${architecture}.tgz";
                url = "https://www.segger.com/downloads/jlink#J-LinkSoftwareAndDocumentationPack";
                inherit sha256;
              };

              dontConfigure = true;
              dontBuild = true;
              dontStrip = true;

              nativeBuildInputs = [ autoPatchelfHook ];
              buildInputs = [
                qt4 fontconfig freetype libusb libICE libSM ncurses5
                libX11 libXext libXcursor libXfixes libXrender libXrandr
              ];

              runtimeDependencies = [ udev ];

              installPhase = ''
                mkdir -p $out/{JLink,bin}
                cp -R * $out/JLink
                ln -s $out/JLink/J* $out/bin/
                rm -r $out/bin/JLinkDevices.xml $out/JLink/libQt*
                install -D -t $out/lib/udev/rules.d 99-jlink.rules
              '';

              preFixup = ''
                patchelf --add-needed libudev.so.1 $out/JLink/libjlinkarm.so
              '';

              meta = with lib; {
                homepage = "https://www.segger.com/downloads/jlink";
                description = "SEGGER J-Link";
                license = licenses.unfree;
                platforms = platforms.linux;
                maintainers = with maintainers; [ leo60228 ];
              };
            };
        };
      }
    );
}
