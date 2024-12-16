## Local setup:
```bash
make build # build image
make bash # run bash session in app's container
rake db:migrate # setup DB
rake db:seed # load some test from db/seeds.rb if needed
```

## Start billing:

```bash
make bash # run bash session in app's container
rake schedule_renewals # start processing subscriptions
```
NOTE: [mocked_payment_gateway](config/mocked_payment_gateway.rb) emulates a payment gateway. It randomly returns one of the following statuses: `success`, `failed`, `insufficient_funds`

## Sidekiq jobs
Visit http://localhost:9292/ to check Sidekiq Web UI

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
