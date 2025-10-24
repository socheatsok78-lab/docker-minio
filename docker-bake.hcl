variable "GITHUB_REPOSITORY_OWNER" {
  default = "minio"
}

variable "MINIO_UPDATE_MINISIGN_PUBKEY" {
    type    = string
    default = "RWTx5Zr1tiHQLwG9keckT0c45M3AGeHD6IvimQHpyRywVWGbP1aVSGav"
}

variable "MINIO_VERSIONS" {
  type = list(string)
  default = [
    "latest",
  ]
}

target "docker-metadata-action" {}
target "github-metadata-action" {}

target "default" {
  matrix = {
    version = MINIO_VERSIONS
  }
  name = "minio_${sanitize(version)}"
  inherits = [
    "docker-metadata-action",
    "github-metadata-action",
  ]
  args = {
    GITHUB_REPOSITORY_OWNER = GITHUB_REPOSITORY_OWNER
    MINIO_VERSION = version
    MINIO_UPDATE_MINISIGN_PUBKEY = MINIO_UPDATE_MINISIGN_PUBKEY
  }
  labels = {
    "org.opencontainers.image.description" = "MinIO is a high-performance, S3 compatible object store"
    "org.opencontainers.image.version" = version
  }
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/consul:${version}"
  ]
}
