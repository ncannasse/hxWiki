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
	rsync -avz --delete $(RSYNC_EXCLUDES) tpl www ncannasse_fr@deploy.motion-twin.com:ncannasse_fr
	ssh ncannasse_fr@deploy.motion-twin.com deploy

deploy_shiro: prepare
	rsync -avz --chmod=ug=rwX,o= --delete $(RSYNC_EXCLUDES) --exclude="www/js" tpl www upload@shirogames.com:/data/shirogames
	rsync -avz --chmod=ug=rwX,o= --delete $(RSYNC_EXCLUDES) tpl www upload@shirogames.com:/data/bible

api:
	haxe project.hxml
	neko apisync.n
