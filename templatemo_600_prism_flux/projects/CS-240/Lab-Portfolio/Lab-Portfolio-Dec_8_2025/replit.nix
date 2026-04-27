{ pkgs }: {
  deps = [
    pkgs.iputils
    pkgs.static-web-server
    pkgs.vscode-langservers-extracted
  ];
}