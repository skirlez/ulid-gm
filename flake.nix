{
  description = "";
  inputs.gamemaker-flake.url = "github:skirlez/gamemaker-flake";
  outputs =
    { self, gamemaker-flake, ... }:
    let
      system = "x86_64-linux";
      ulid-gm = gamemaker-flake.packages.x86_64-linux.buildGameMakerProject {
        src = ./.;
        runtimeVersion = "2023.4.0.113";
      };
    in
    {
      packages.x86_64-linux.default = ulid-gm;
    };
}
