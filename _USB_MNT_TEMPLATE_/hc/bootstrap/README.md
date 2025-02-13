### Access to Github private bootstrap repository
To support follow on bootstrap stages (post-reboot of `00-init.sh`), we need to clone `datamonk/hamster-cannon.git` private repo. A generated github developer token hash must be populated in `./.git-token` as a pre-condition for this script to function.
  [ _ref: https://github.com/datamonk/milhouse-init/blob/main/00-init.sh#L90 ]

### Downloading & Executing `00-init.sh`
For convenience, a small bash script has been included in `./bin/bs.sh` to perform
the download of `00-init.sh` from this repo and execute bootstrap process from `/home/$USER`.

```
# run example (using default PiOS image terminal)
$ bash bin/bs.sh
```
