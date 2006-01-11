
db		:= dudl
pass		:=

pwd		:= $(shell pwd )

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

create+=music/xtitle
music/xtitle.create: storage/file.create storage/unit.create \
	storage/functions.create \
	music/album.create music/artist.create \
	music/functions.create

create+=music/tag

create+=music/titletag
music/titletag.create: storage/file.create music/tag.create

create+=music/functions
music/functions.create: music/titletag.create



############################################################

create+=storage/unit

create+=storage/file
storage/file.create: storage/unit.create \
	music/album.create music/artist.create

create+=storage/xfile
storage/xfile.create: storage/unit.create storage/file.create

create+=storage/functions



############################################################

create+=mserv/sfilter

create+=mserv/user

create+=mserv/artist
mserv/artist.create: music/artist.create

create+=mserv/album
mserv/album.create: music/album.create music/artist.create 

create+=mserv/track
mserv/track.create: storage/file.create storage/unit.create \
	storage/functions.create mserv/artist.create mserv/album.create

create+=mserv/history
mserv/history.create: storage/file.create mserv/user.create

create+=mserv/dupes
mserv/dupes.create: mserv/history.create

create+=mserv/xhistory
mserv/xhistory.create: mserv/history.create mserv/track.create

create+=mserv/queue
mserv/queue.create: storage/file.create mserv/user.create mserv/track.create



############################################################

all:=$(patsubst %,%.create,$(create))

x-all: $(all)

%.create: %.sql
#	( echo $(pass); cat $< ) | psql $(db)
	@echo "psql $(db) < $(pwd)/$<"
	@echo "\\i $(pwd)/$<"
	@echo enter y when done; read r; [ "$$r"x = yx ]
	@touch $@

clean:
	rm -f $(all)

