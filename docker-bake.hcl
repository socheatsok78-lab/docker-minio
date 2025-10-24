variable "GITHUB_REPOSITORY_OWNER" {
  default = "minio"
}

variable "MINIO_VERSION" {
  default = "latest"
}

target "docker-metadata-action" {}
target "github-metadata-action" {}

target "default" {
  inherits = [
    "docker-metadata-action",
    "github-metadata-action",
  ]
  args = {
    GITHUB_REPOSITORY_OWNER = GITHUB_REPOSITORY_OWNER
    MINIO_VERSION = MINIO_VERSION
  }
  tags = [
    "ghcr.io/${GITHUB_REPOSITORY_OWNER}/minio:${MINIO_VERSION}"
  ]
}
