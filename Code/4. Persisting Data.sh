
# https://dbafromthecold.com/2017/06/21/persisting-data-in-docker-containers-partone/

## Mounting volumes from the host


# create volume on host
sudo mkdir /sqldata



# run a container mapping the host volume
docker run -d -p 15777:1433 \
    -v /sqldata:/sqlserver \
        --env ACCEPT_EULA=Y --env SA_PASSWORD=Testing1122 \
            --name testcontainer7 \
                microsoft/mssql-server-linux:latest



# verify container is running
docker ps -a



# verify volume is mapped
docker exec -it testcontainer7 bash



# create a database within the container
mssql-cli -S 'localhost,15777' -U sa -P Testing1122

CREATE DATABASE [DatabaseD]
ON PRIMARY
    (NAME = N'DatabaseD', FILENAME = N'/sqlserver/DatabaseD.mdf')
LOG ON
    (NAME = N'DatabaseD_log', FILENAME = N'/sqlserver/DatabaseD_log.ldf');



# check the database is there
SELECT [name] FROM sys.databases;



# create a test table and insert some data
USE [DatabaseD];

CREATE TABLE dbo.TestTable1(ID INT);

INSERT INTO dbo.TestTable1(ID) SELECT TOP 100 1 FROM sys.all_columns;



# query the test table
SELECT COUNT(*) AS Records FROM dbo.TestTable1;



EXIT


           


# blow away container        
docker kill testcontainer7
docker rm testcontainer7



# confirm container is gone
docker ps -a



# verify database files still in host folder
find /sqldata -type f



# spin up another container with the volume mapped
docker run -d -p 15888:1433 \
    -v /sqldata:/sqlserver \
        --env ACCEPT_EULA=Y --env SA_PASSWORD=Testing1122 \
            --name testcontainer8 \
                microsoft/mssql-server-linux:latest



# verify container is running
docker ps -a



# check database is there
mssql-cli -S 'localhost,15888' -U sa -P Testing1122

SELECT [name] FROM sys.databases;

EXIT



# 'course not! We need to attach it, first check the files are there
docker exec -it testcontainer8 bash



# now attach the database
mssql-cli -S 'localhost,15888' -U sa -P Testing1122

CREATE DATABASE [DatabaseD] ON 
(FILENAME = '/sqlserver/DatabaseD.mdf'),
(FILENAME = '/sqlserver/DatabaseD_log.ldf') FOR ATTACH;



# check database is there
SELECT [name] FROM sys.databases;



# query the test table
USE [DatabaseD];

SELECT COUNT(*) AS Records FROM dbo.TestTable1;

EXIT



# clean up
docker kill testcontainer8
docker rm testcontainer8





# https://dbafromthecold.com/2017/06/28/persisting-data-in-docker-containers-part-two/
## Named Volumes



# remove unused volumes
docker volume prune



# create the named volume
docker volume create sqlserver



# verify named volume is there
docker volume ls



# spin up a container with named volume mapped
docker run -d -p 15999:1433 \
    -v sqlserver:/sqlserver \
        --env ACCEPT_EULA=Y --env SA_PASSWORD=Testing1122 \
            --name testcontainer9 \
                microsoft/mssql-server-linux:latest



# check the container is running
docker ps -a



# create database on the named volume
mssql-cli -S 'localhost,15999' -U sa -P Testing1122 

CREATE DATABASE [DatabaseE]
ON PRIMARY
    (NAME = N'DatabaseE', FILENAME = N'/sqlserver/DatabaseE.mdf')
LOG ON
    (NAME = N'DatabaseE_log', FILENAME = N'/sqlserver/DatabaseE_log.ldf');

                

# check the database is there
SELECT [name] FROM sys.databases;



# create a test table and insert some data
USE [DatabaseE];

CREATE TABLE dbo.TestTable2(ID INT);

INSERT INTO dbo.TestTable2(ID) SELECT TOP 200 1 FROM sys.all_columns;



# query the test table
SELECT COUNT(*) AS Records FROM dbo.TestTable2;



EXIT



# blow away container
docker kill testcontainer9
docker rm testcontainer9



# check that named volume is still there
docker volume ls



# spin up another container
docker run -d -p 16100:1433 \
    -v sqlserver:/sqlserver \
        --env ACCEPT_EULA=Y --env SA_PASSWORD=Testing1122 \
            --name testcontainer10 \
                microsoft/mssql-server-linux:latest



# verify container is running
docker ps -a



# now attach the database
mssql-cli -S 'localhost,16100' -U sa -P Testing1122

CREATE DATABASE [DatabaseE] ON 
(FILENAME = '/sqlserver/DatabaseE.mdf'),
(FILENAME = '/sqlserver/DatabaseE_log.ldf') FOR ATTACH;



# check database is there
SELECT [name] FROM sys.databases;



# query the test table       
USE [DatabaseE];

SELECT COUNT(*) AS Records FROM dbo.TestTable2;



EXIT



# clean up
docker kill testcontainer10
docker rm testcontainer10
docker volume rm sqlserver





# https://dbafromthecold.com/2017/07/05/persisting-data-in-docker-containers-part-three/
## Data volume containers


# create the data volume container
docker create -v /sqldata -v /sqllog --name datastore ubuntu



# verify container
docker ps -a



# spin up a sql container with volume mapped from data container
docker run -d -p 16110:1433 \
    --volumes-from datastore \
        --env ACCEPT_EULA=Y --env SA_PASSWORD=Testing1122 \
            --name testcontainer11 \
                microsoft/mssql-server-linux:latest



# verify container
docker ps -a



# create database
mssql-cli -S 'localhost,16110' -U sa -P Testing1122

CREATE DATABASE [DatabaseF]
ON PRIMARY
    (NAME = N'DatabaseF', FILENAME = N'/sqldata/DatabaseF.mdf')
LOG ON
    (NAME = N'DatabaseF_log', FILENAME = N'/sqllog/DatabaseF_log.ldf');



# check database is there
SELECT [name] FROM sys.databases;



# create a test table and insert some data 
USE [DatabaseF];

CREATE TABLE dbo.TestTable3(ID INT);

INSERT INTO dbo.TestTable3(ID) SELECT TOP 300 1 FROM sys.all_columns;



# query the test table
SELECT COUNT(*) AS Records FROM dbo.TestTable3;



EXIT


# blow away container
docker kill testcontainer11
docker rm testcontainer11



# verify data container is still there
docker ps -a



# spin up another container
docker run -d -p 16120:1433 \
    --volumes-from datastore \
        --env ACCEPT_EULA=Y --env SA_PASSWORD=Testing1122 \
            --name testcontainer12 \
                microsoft/mssql-server-linux:latest 
            


# now attach the database
mssql-cli -S 'localhost,16120' -U sa -P Testing1122

CREATE DATABASE [DatabaseF] ON 
(FILENAME = '/sqldata/DatabaseF.mdf'),
(FILENAME = '/sqllog/DatabaseF_log.ldf') FOR ATTACH;



# check database is there
SELECT [name] FROM sys.databases;


            
# query the test table
USE [DatabaseF];

SELECT COUNT(*) AS Records FROM dbo.TestTable3;



EXIT

# clean up
docker kill testcontainer12
docker rm testcontainer12
docker rm datastore

sudo rm -rf /sqldata
