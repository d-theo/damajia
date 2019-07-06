docker system prune --force
docker images --no-trunc --format '{{.ID}}' | xargs docker rmi