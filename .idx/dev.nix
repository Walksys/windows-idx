{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = with pkgs; [
    unzip
    openssh
    sudo
    qemu
    curl
    wget
    novnc
    websockify
  ];

  env = {
    EDITOR = "nano";
  };

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    workspace = {
      onCreate = { };

      onStart = {
        autoRun = ''
          echo "Running run.sh..."
          chmod +x ./run.sh
          ./run.sh
        '';
      };
    };

    previews = {
      enable = true;
      previews = {
        web = {
          command = [
            "bash"
            "-c"
            "echo noVNC running"
          ];
          manager = "web";
        };
      };
    };
  };
}
