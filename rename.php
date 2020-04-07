<?php

$infile="albums.csv";
$command="/atelier-photo/Tools/flickr-cli/bin/flickr-cli ";
if (($handle = fopen($infile, "r")) !== FALSE) {
    while (($data = fgetcsv($handle, 1000, ",")) !== FALSE) {
        $num = count($data);
        if ($data[5] != $data[3]) {
            printf('%s editAlbum %d -t "%s" # (%s)'."\n", $command, $data[0], $data[5], $data[3]);
        }
    }
    fclose($handle);
}