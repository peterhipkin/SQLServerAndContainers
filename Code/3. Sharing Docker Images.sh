
# https://dbafromthecold.com/2016/11/30/sql-server-containers-part-three/


# create your own dockerlogin.txt file with your docker hub password in it
# log into the docker hub
PasswordFile=~/git/SQLServerAndContainers/dockerlogin.txt
cat $PasswordFile | docker login --username dbafromthecold --password-stdin



# check images
docker images



# tag custom image with repository name
docker tag testimage1 dbafromthecold/testsqlrepository:linuxdemo



# verify image has been tagged
docker images



# push image to the hub
docker push dbafromthecold/testsqlrepository:linuxdemo




# verify image is on the hub
docker search dbafromthecold



# clean up
docker rmi dbafromthecold/testsqlrepository:linuxdemo testimage1
