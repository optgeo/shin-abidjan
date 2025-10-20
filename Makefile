.PHONY: upload

upload:
	rsync --progress -av data/shin-abidjan.pmtiles pod@pod.local:/home/pod/x-24b/data/shin-abidjan.pmtiles
