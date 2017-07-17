#! /bin/bash
read -p "Did you remember to git pull? (y/n) " RESP
if [ "$RESP" = "y" ]; then
  bundle || { echo 'bundle failed' ; exit 1; }
  rake db:migrate || { echo 'rake db:migrate failed' ; exit 1; }
  rake db:seed || { echo 'rake db:seed failed' ; exit 1; }
  rake assets:precompile || { echo 'rake assets:precompile failed' ; exit 1; }
  sudo service nginx restart || { echo 'sudo service nginx restart failed' ; exit 1; }
  echo "All done now go test it in the browser!"
else
    echo "You need to pull before running this"
fi
