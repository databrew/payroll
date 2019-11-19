# payroll
Payroll management


## Credentials

For this app to run correctly, you'll need to create a (git-ignored) `credentials.yaml` with the authorized users in the following format:

```
username: password
username2: password2
```

The final row should also contain the following:

```
quandl_api: 12345
```

(Replace 12345 with the correct API)

## SSH key

You'll also need to generate an ssh key pair and associate it with this repo. In order to do so:

```
ssh-keygen -t rsa
```

When prompted, save to the following path:
```
/home/<user>/.ssh/payroll
```

On the github page of this repo, go to "Settings" -> "Deploy keys", and then "Add new". Copy and paste the contents of `~/.ssh/payroll.pub` where prompted. Make sure to select "allow write access". Your key is now deployed

Now, make sure to set the remote origin to ssh instead of https:

```
git remote set-url origin git@github.com:databrew/payroll.git
```

## Chron script

To set up a chron script to run the currency updater daily at 10:55, we'll open crontab:

```
crontab -e
```

And then add the following line:

```
55 10 * * * Rscript /home/joebrew/Documents/payroll/update_currency.R
```

