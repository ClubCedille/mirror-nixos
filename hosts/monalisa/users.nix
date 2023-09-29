{pkgs, ...}: {
  # http://patorjk.com/software/taag/#p=testall&f=Stronger%20Than%20All&t=Monalisa
  users.motd = ''
    ___  ___                  _ _
    |  \/  |                 | (_)
    | .  . | ___  _ __   __ _| |_ ___  __ _
    | |\/| |/ _ \| '_ \ / _` | | / __|/ _` |
    | |  | | (_) | | | | (_| | | \__ \ (_| |
    \_|  |_/\___/|_| |_|\__,_|_|_|___/\__,_|

    Welcome to the Monalisa CEDILLE server!
  '';

  users.users.admin = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.bashInteractive;

    hashedPassword = "";
    # Will not work until initrd supports secrets
    #passwordFile = config.sops.secrets.admin-pass.path;

    #openssh.authorizedKeys.keyFiles = [ "/" ];
  };

  users.users.automation = {
    isSystemUser = true;
    createHome = false;
    group = "automation";

    uid = 900;

    #openssh.authorizedKeys.keys = [ "" ];
  };

  users.groups.automation = {};
}
