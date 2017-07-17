# Lodgistics

## Project Information

Inventory/Procurement system for hotels

Staging site: [http://lodgistics-staging.dev.sbox.es/](http://http://lodgistics-staging.dev.sbox.es/)

Users: gm_h1@example.com, hm_h1@example.com; Password: 'password'

### Contacts

* [Nikhil Natu](mailto:nikhil@lodgistics.com)
* [Shaunak Patel](mailto:shaunak.patel@lodgistics.com)

## Development

* Ruby 2.0.0p195
* Ruby on Rails 4.0.0
* PostgreSQL 9.2.4

To get started run:

```sh
git clone git@github.com:smashingboxes/lodgistics.git
cd lodgistics
bundle
rake db:migrate
```

Make sure **PostgreSQL** is running and the correct credentials are specified in `config/database.yml`. The default for postgres installed through _brew_ is the user's username and no password.

To run the server:

```
foreman start
```

To run the console:

```
rails c
```

Letter opener is set on development so emails are intercepted.

## Seeding

db/seeds/production and development.rb are used for the appropriate environment, instead of just db/seeds.rb for both.

## Test
Minitest, Capybara, Factory Girl

Run guard while developing, open a terminal window and type:

```
bundle exec guard
```

Press enter to run all the test or modify the code to run the corresponding tests.

## UX/UI Guidelines
*   In all pages with a single form, the first field should _autofocus_
*   All email, password and password_confirmation fields outside of the sign_in view, should have _autocomplete_ off
*   Table pages:
    *   Show, Edit and Delete action in every row, followed by model specific actions
    *   Record specific alerts should: hightlight the cell, display an icon with a popover and be shown in the show page.
    *   A default order
    *   Pagination
