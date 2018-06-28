#!/bin/zsh

API=mW6YDEJDt0zwvApz4R4_E0t0VUzWp9SG

cd images
for image in `ls`
do 
    curl --user api:$API  --data-binary @$image -i https://api.tinify.com/shrink > tmp
    url=`cat tmp | tail -n 1 | jq .output.url | tr -d '"'`
    curl $url -o $image 
done
rm tmp
cd ..

