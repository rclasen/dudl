
db		:= dudl

files_base	:= \
	user.sql \
	functions.sql

files_music	:= \
	publisher.sql \
	artist.sql \
	album.sql \
	title.sql

files_storage	:= \
	unit.sql \
	export.sql \
	file.sql \
	track.sql

parts		:= base music storage

path_base	:= $(files_base)
path_music	:= $(patsubst %,music/%,$(files_music))
path_storage	:= $(patsubst %,storage/%,$(files_storage))




dummy:

all:		$(parts)

base:		$(path_base)
music:		$(path_music)
storage:	$(path_storage)

.PHONY: $(parts)
$(parts):
	for f in $^ ; do \
		echo $$f ; \
		psql $(db) < $$f || exit 1 ; \
	done

	
