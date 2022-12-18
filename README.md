# Welcome to my personal nixos configuration

This is the nixos configuration for my personal laptop which I kindly want to share with you. It consists of zsh, kde, conda, julia, vscode, tiddlywiki and others.

I wrote a couple of fixes which I outsourced into clean overlays for now (they may be merged into nixpkgs someday). Take a look, they may be especially of interest to you.

Learning nixos is a great experience for me, I like it a lot, and by now also like to inspire others. It's worth giving it a try.
For nixos questions please reach out on discourse.nixos.org.


## install a single overlay

If you would like to use one of my overlays for yourself, it is as simple as copying the file to your overlays directory.

By default each user has the folder `~/.config/nixpkgs/overlays`, however if you like to have a folder under your central nixos folder, as I myself like to do, just add
`nixpkgs-overlays=/etc/nixos/overlays/` to your nixpath (see my configuration.nix for one way to do so).

Overlays don't need nixos, and can seamlessly be used with the mere nix package manager.


## install whole nixos configuration

I prefer to edit /etc/nixos as my personal user and change the rights respectively
```bash
cd /etc/nixos
chmod u+w .
```

Then you can install this nixos-configuration by simply cloning the repository into `/etc/nixos`
```bash
mv /etc/nixos/configuration.nix /etc/nixos/configuration-backup-$(date --iso-8601).nix
git clone https://github.com/schlichtanders/nixos-personal /etc/nixos
```

Finally build the nixos by running
```bash
sudo nixos-rebuild switch
```

alternatively, if you want to save the output-logs for later inspection, run
```bash
sudo nixos-rebuild switch |& tee /etc/nixos/logs/rebuild-$(date --iso-8601=seconds).txt
```


# Backup

Characters not allowed in Windows are \/:*?"<>|
we need to ignore forward slash

## Rename all files to be compatible with Windows ntfs

```bash
cd  # we need to make sure we call find from home
find . \( -path "./.*" -o -name "node_modules" -o -name ".venv" -o -name ".nox" -o -name ".git" \) -prune -o -execdir rename -n 's/[\:*?"<>|]/_/g' "{}" +
```

## Sync all files

bring all dot folders to zip files

```bash
for dotfolder in .*/; do
echo tar -zcvf $(basename $dotfolder).tar.gz $dotfolder
tar -zcvf $(basename $dotfolder).tar.gz $dotfolder
done
```

sync complete home
```bash
rsync --iconv=. --archive --no-links --whole-file --modify-window=2 --exclude '/.*/' --exclude "node_modules/" --exclude ".venv/" --exclude ".nox/" --progress /home/ssahm/ /run/media/ssahm/Seagate\ Expansion\ Drive/Backups/2022-07-23_NixOS_Home
```