
db		:= dudl
pass		:=

all: x-all
create:=

############################################################

create+=user

create+=functions

create+=pgfunc



############################################################

create+=music/publisher

create+=music/artist

create+=music/album
music/album.create: music/artist.create

create+=music/title
music/title.create: music/album.create music/artist.create

create+=music/xtitle
music/xtitle.create: storage/file.create storage/unit.create \
	storage/functions.create \
	music/album.create music/artist.create music/title.create \
	mserv/functions.create 



############################################################

create+=storage/unit

create+=storage/file
storage/file.create: storage/unit.create music/title.create

create+=storage/xfile
storage/xfile.create: storage/unit.create storage/file.create

create+=storage/functions



############################################################

create+=mserv/tag

create+=mserv/titletag
mserv/titletaf.create: mserv/tag_create music/title.create





############################################################

all:=$(patsubst %,%.create,$(create))

x-all: $(all)

%.create: %.sql
#	( echo $(pass); cat $< ) | psql $(db)
	echo $<
	echo enter y when done
	read r; [ "$$r"x = yx ] 
	@touch $@

clean:
	rm -f $(all)

