if [ "$( docker container inspect -f '{{.State.Running}}' db )" != "true" ]; then
  echo "docker container db is not running"
  return
fi

heroku pg:backups:download  --app crowdbreaks-prd
docker cp latest.dump db:/latest.dump
docker exec -it db pg_restore -v --clean --no-privileges --no-owner -U postgres -d crowdbreaks_development /latest.dump
docker exec db rm /latest.dump
rm latest.dump
