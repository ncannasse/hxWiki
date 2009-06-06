RSYNC_EXCLUDES=--exclude="www/favicon.ico" --exclude=".htaccess" --exclude="www/file" --exclude="www/_media" --exclude="*.out" --exclude="*.svn" --exclude="*.neko" --exclude="*.php"

all: compile

prepare: templates compile

templates:
	(cd tpl/en && temploc2 -output ../tmp/ -macros macros.mtt *.mtt)
	(cd tpl/en && temploc2 -php -output ../tmp/ -macros macros.mtt *.mtt)

compile:
	haxe project.hxml

deploy_haxe: prepare
	rsync -avz --delete $(RSYNC_EXCLUDES) tpl www ncannasse@haxe.org:/data/haxe

deploy_nc: prepare
	rsync -avz --delete $(RSYNC_EXCLUDES) tpl www ncannasse@kazegames.com:/data/ncannasse.fr

deploy_kaze: prepare
	rsync -avz --delete $(RSYNC_EXCLUDES) tpl www ncannasse@kazegames.com:/data/kazegames.com

api:
	haxe project.hxml
	neko apisync.n
