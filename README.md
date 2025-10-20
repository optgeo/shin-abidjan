# shin-abidjan
Maxar 2019 Abidjan Mosaic by Cristiano Giovando in PMTiles

## Upload

To upload the PMTiles file to the server, run:

```
make upload
```

This will execute:
```
rsync --progress -av data/shin-abidjan.pmtiles pod@pod.local:/home/pod/x-24b/data/shin-abidjan.pmtiles
```
