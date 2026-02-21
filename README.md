# README

Activity Tracking System (Rails API)

A Rails 8 API-only application for tracking lead activities such as status changes, assignments, notes, calls, and emails.

Deployed Version:
https://activity-tracking-system.onrender.com

* Tech Stack

   - Ruby 3.2.2

   - Rails 8.0.4 (API Only)

   - PostgreSQL

   - RSpec

   - Rubocop

   - Render (Deployment)

   - Neon DB (Production Database)

* Ruby version

    ruby - 3.2.2
    rails - 8.0.4

* Features

   - Create leads

   - Track activities:

   - Status change

   - Assignment change

   - Note added

   - Call logged

   - Email sent

   - Undo last status change

   - Activity history per lead

* Local Setup
    # Clone repository:
     git clone https://github.com/Arshan-K/Activity_Tracking_System.git
     cd Activity_Tracking_System

    # Install dependencies:
     - bundle install

* Database creation
    - rails db:create

* Database initialization & Data creation
    - rails db:migrate
    - rails db:seed

* Start Server
    - rails server

* How to run the test suite
    rubocop - rubocop -A
    rspec - bundle exec rspec

* API Endpoints
    - link - https://activity-tracking-system.onrender.com (API-Only)

    # Examples :-
        - curl -X POST https://activity-tracking-system.onrender.com/leads \
        -H "Content-Type: application/json" \
        -d '{
        "lead": {
            "name": "John Doe",
            "email": "john@example.com",
            "status": "new"
        }
        }'

        curl -X PATCH https://activity-tracking-system.onrender.com/leads/1/update_status \
        -H "Content-Type: application/json" \
        -d '{
        "status": "qualified"
        }'

        curl https://activity-tracking-system.onrender.com/leads/1/activities

* ...
