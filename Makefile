all:

deploy_haxe:
	temploc -o tpl/tmp/ -r tpl/en -m tpl/en/macros.mtt tpl/en/*.mtt
	haxe project.hxml
	rsync -avz --delete --exclude "www/favicon.ico" --exclude ".htaccess" --exclude "www/file" --exclude "www/_media" --exclude="*.out" --exclude="*.svn" --exclude="*.neko" tpl www ncannasse@haxe.org:/data/haxe

api:
	haxe project.hxml
	neko apisync.n
