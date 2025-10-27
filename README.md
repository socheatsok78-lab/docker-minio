# docker-minio
The god-damn MinIO docker images

Run the following command to run the latest stable image of MinIO as a container using an ephemeral data volume:

```sh
docker run -p 9000:9000 -p 9001:9001 \
  ghcr.io/socheatsok78-lab/minio server /data
```

The MinIO deployment starts using default root credentials `minioadmin:minioadmin`. You can test the deployment using the MinIO Console, an embedded object browser built into MinIO Server. Point a web browser running on the host machine to `http://127.0.0.1:9000⁠` and log in with the root credentials. You can use the Browser to create buckets, upload objects, and browse the contents of the MinIO server.
