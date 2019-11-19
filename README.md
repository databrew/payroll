# payroll
Payroll management

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

You'll also need to generate an ssh key pair and associate it with this repo. In order to do so:

```
ssh-keygen -t rsa
```

When prompted, save to the following path:
```
/home/<user>/.ssh/payroll
```

On the github page of this repo, go to "Settings" -> "Deploy keys", and then "Add new". Copy and paste the contents of `~/.ssh/payroll.pub` where prompted. Make sure to select "allow write access". Your key is now deployed



