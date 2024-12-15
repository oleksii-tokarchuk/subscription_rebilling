## Local setup:
```bash
make build # build image
make bash # run bash session in app's container
rake db:migrate # setup DB
rake db:seed # load some test from db/seeds.rb if needed
```

## Tests:
```bash
make bash # run bash session in app's container
APP_ENV=test rake db:migrate # setup test DB. Only when it is first time
rspec # run tests
```

## RuboCop:
```bash
make bash # run bash session in app's container
rubocop # run rubocop
```

## Start billing:

```bash
make bash # run bash session in app's container
rake schedule_renewals # start processing subscriptions
```
